import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../domain/book.dart';

const maxBackupBytes = 100 * 1024 * 1024;
const maxPayloadBytes = 200 * 1024 * 1024;

class BackupKey {
  final List<int> bytes;
  final String id;
  BackupKey._(this.bytes, this.id);
  String get code {
    final raw = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
    return List.generate(16, (i) => raw.substring(i * 4, i * 4 + 4)).join(' ');
  }

  String get card => jsonEncode({
    'format': 'catatanwarung-key',
    'version': 1,
    'id': id,
    'code': code,
    'petunjuk': 'Simpan di luar HP pemilik warung. Kunci ini membuka cadangan yang cocok. Jangan bagikan bersama file cadangan.',
  });
  static Future<BackupKey> generate() async => fromBytes(
    await (await AesGcm.with256bits().newSecretKey()).extractBytes(),
  );
  static Future<BackupKey> fromBytes(List<int> bytes) async {
    if (bytes.length != 32) {
      throw const BookError('Kunci harus berisi 64 huruf/angka heksadesimal.');
    }
    final digest = await Sha256().hash(bytes);
    return BackupKey._(
      List.unmodifiable(bytes),
      digest.bytes
          .take(8)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(),
    );
  }

  static Future<BackupKey> parse(String input) async {
    var value = input.trim();
    String? expected;
    if (value.startsWith('{')) {
      final card = object(jsonDecode(value));
      if (card['format'] != 'catatanwarung-key' || card['version'] != 1) {
        throw const BookError('Kartu kunci tidak dikenal.');
      }
      value = string(card, 'code', max: 100);
      expected = string(card, 'id', max: 16);
    }
    value = value.replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(value)) {
      throw const BookError(
        'Periksa kode kunci. Diperlukan 16 kelompok berisi 4 karakter.',
      );
    }
    final key = await fromBytes(
      List.generate(
        32,
        (i) => int.parse(value.substring(i * 2, i * 2 + 2), radix: 16),
      ),
    );
    if (expected != null && key.id != expected) {
      throw const BookError('Kartu kunci berubah atau tidak lengkap.');
    }
    return key;
  }
}

class RestoredBackup {
  final Book book;
  final String snapshotAt;
  RestoredBackup(this.book, this.snapshotAt);
}

class BackupCodec {
  static Map<String, dynamic> _summary(Book b) => {
    'people': b.people.length,
    'ledgers': b.ledgers.length,
    'entries': b.entries.length,
    'audits': b.audits.length,
    'customer': b.total(Category.customer),
    'supplier': b.total(Category.supplier),
  };

  static Future<Uint8List> encode(
    Book book,
    BackupKey key,
    DateTime now,
  ) async {
    book.validate();
    final payload = utf8.encode(
      jsonEncode({
        'snapshotAt': now.toUtc().toIso8601String(),
        'summary': _summary(book),
        'book': book.toJson(),
      }),
    );
    if (payload.length > maxPayloadBytes) {
      throw const BookError(
        'Catatan terlalu besar untuk satu cadangan. Tidak ada file parsial yang dibuat.',
      );
    }
    final algorithm = AesGcm.with256bits();
    final header = {
      'format': 'catatanwarung',
      'version': 1,
      'cipher': 'AES-256-GCM',
      'keyId': key.id,
    };
    final aad = utf8.encode(jsonEncode(header));
    final encrypted = await algorithm.encrypt(
      payload,
      secretKey: SecretKey(key.bytes),
      aad: aad,
    );
    final file = utf8.encode(
      jsonEncode({
        'header': header,
        'nonce': base64Encode(encrypted.nonce),
        'ciphertext': base64Encode(encrypted.cipherText),
        'tag': base64Encode(encrypted.mac.bytes),
      }),
    );
    if (file.length > maxBackupBytes) {
      throw const BookError(
        'Cadangan melewati batas file 100 MiB. Tidak ada file parsial yang dibuat.',
      );
    }
    return Uint8List.fromList(file);
  }

  static Future<RestoredBackup> decode(Uint8List bytes, BackupKey key) async {
    if (bytes.isEmpty || bytes.length > maxBackupBytes) {
      throw const BookError(
        'Ukuran file cadangan tidak valid (maksimal 100 MiB).',
      );
    }
    try {
      final envelope = object(jsonDecode(utf8.decode(bytes)));
      final h = object(envelope['header']);
      if (h['format'] != 'catatanwarung' ||
          h['version'] != 1 ||
          h['cipher'] != 'AES-256-GCM') {
        throw const BookError(
          'Format atau versi cadangan belum didukung. Perbarui aplikasi.',
        );
      }
      if (h['keyId'] != key.id) {
        throw const BookError('Kunci tidak cocok dengan file cadangan ini.');
      }
      final nonce = base64Decode(envelope['nonce'] as String);
      final cipher = base64Decode(envelope['ciphertext'] as String);
      final tag = base64Decode(envelope['tag'] as String);
      if (nonce.length != 12 ||
          tag.length != 16 ||
          cipher.length > maxPayloadBytes) {
        throw const BookError('Isi cadangan tidak valid.');
      }
      final plain = await AesGcm.with256bits().decrypt(
        SecretBox(cipher, nonce: nonce, mac: Mac(tag)),
        secretKey: SecretKey(key.bytes),
        aad: utf8.encode(jsonEncode(h)),
      );
      if (plain.length > maxPayloadBytes) {
        throw const BookError('Isi cadangan terlalu besar.');
      }
      final data = object(jsonDecode(utf8.decode(plain)));
      final snapshotAt = string(data, 'snapshotAt', max: 40);
      if (DateTime.tryParse(snapshotAt) == null) {
        throw const BookError('Waktu cadangan tidak valid.');
      }
      final book = Book.fromJson(object(data['book']));
      book.validate();
      final summary = object(data['summary']);
      if (_summary(book).entries.any((e) => summary[e.key] != e.value)) {
        throw const BookError(
          'Jumlah catatan atau saldo cadangan tidak cocok.',
        );
      }
      return RestoredBackup(book, snapshotAt);
    } on BookError {
      rethrow;
    } on SecretBoxAuthenticationError {
      throw const BookError(
        'Cadangan berubah/rusak atau kunci salah. Data aktif tidak diubah.',
      );
    } catch (_) {
      throw const BookError(
        'File bukan cadangan Catatan Warung yang valid. Data aktif tidak diubah.',
      );
    }
  }
}

/// All device-specific capabilities are explicit, keeping encryption and ledger
/// rules testable without mocking SQLite or assuming a cloud upload succeeded.
class DeviceBridge {
  static const channel = MethodChannel('id.catatanwarung/device');
  Future<String> privatePath() async =>
      (await channel.invokeMethod<String>('privatePath'))!;
  Future<Uint8List?> openFile({int maxBytes = maxBackupBytes}) =>
      channel.invokeMethod<Uint8List>('openDocument', {'maxBytes': maxBytes});
  Future<bool> saveFile(
    String filename,
    Uint8List bytes, {
    String mime = 'application/octet-stream',
  }) async =>
      await channel.invokeMethod<bool>('saveDocument', {
        'name': filename,
        'bytes': bytes,
        'mime': mime,
      }) ??
      false;
  Future<String?> readKey() => channel.invokeMethod<String>('readKey');
  Future<void> saveKey(String card) =>
      channel.invokeMethod<void>('saveKey', {'value': card});
}

class BackupStatus extends ChangeNotifier {
  String? bookId;
  int? revision;
  DateTime? snapshotAt;
  DateTime? restoredAt;
  String? restoredSnapshot;
  final String path;
  BackupStatus(this.path);
  Future<void> load() async {
    try {
      final file = File(path);
      if (!await file.exists()) return;
      final j = object(jsonDecode(await file.readAsString()));
      bookId = j['bookId'] as String?;
      revision = j['revision'] as int?;
      snapshotAt = DateTime.tryParse(j['snapshotAt'] as String? ?? '');
      restoredAt = DateTime.tryParse(j['restoredAt'] as String? ?? '');
      restoredSnapshot = j['restoredSnapshot'] as String?;
    } catch (_) {
      bookId = null;
      revision = null;
      snapshotAt = null;
      restoredAt = null;
    }
  }

  bool dirty(Book b) => bookId != b.id || revision != b.revision;
  bool reminder(Book b, DateTime now) {
    if (!dirty(b) || (b.firstChange == null && restoredAt == null)) {
      return false;
    }
    final baseline = bookId == b.id ? (snapshotAt ?? restoredAt) : null;
    final date = baseline ?? DateTime.tryParse(b.firstChange ?? '');
    return date != null &&
        now.toUtc().difference(date.toUtc()) >= const Duration(days: 7);
  }

  String description(Book b) {
    if (bookId == b.id && snapshotAt != null) {
      return 'File terakhir: ${displayDay(day(snapshotAt!.toLocal()))}. ${dirty(b) ? 'Ada perubahan yang belum masuk cadangan.' : 'Catatan saat ini sudah masuk file.'} Pastikan salinannya ada di luar HP.';
    }
    if (bookId == b.id && restoredSnapshot != null) {
      return 'Catatan dipulihkan dari ${displayDay(day(DateTime.parse(restoredSnapshot!).toLocal()))}. Buat cadangan baru di perangkat ini.';
    }
    return 'Belum pernah dicadangkan di perangkat ini. Keluarga dapat membantu menyimpan salinan di luar HP.';
  }

  Future<void> exported(Book b, DateTime snapshot) async {
    final value = {
      'bookId': b.id,
      'revision': b.revision,
      'snapshotAt': snapshot.toUtc().toIso8601String(),
      'restoredAt': null,
      'restoredSnapshot': null,
    };
    await _write(value);
    bookId = b.id;
    revision = b.revision;
    snapshotAt = snapshot;
    restoredAt = null;
    restoredSnapshot = null;
    notifyListeners();
  }

  Future<void> restored(Book b, String snapshot) async {
    final now = DateTime.now().toUtc();
    await _write({
      'bookId': b.id,
      'revision': null,
      'snapshotAt': null,
      'restoredAt': now.toIso8601String(),
      'restoredSnapshot': snapshot,
    });
    bookId = b.id;
    revision = null;
    snapshotAt = null;
    restoredAt = now;
    restoredSnapshot = snapshot;
    notifyListeners();
  }

  Future<void> invalidate() async {
    await _write({});
    bookId = null;
    revision = null;
    snapshotAt = null;
    restoredAt = null;
    restoredSnapshot = null;
    notifyListeners();
  }

  Future<void> _write(Map<String, dynamic> value) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    final temp = File('$path.tmp');
    await temp.writeAsString(jsonEncode(value), flush: true);
    await temp.rename(path);
  }
}
