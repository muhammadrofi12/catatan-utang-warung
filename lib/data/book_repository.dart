import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

import '../domain/book.dart';

const _uuid = Uuid();
String newId() => _uuid.v4();

class EntryInput {
  final String ledgerId;
  final EntryKind kind;
  final int amount;
  final String date;
  final String note;
  final String? replaces;
  final String? reason;
  final String reasonNote;
  const EntryInput({
    required this.ledgerId,
    required this.kind,
    required this.amount,
    required this.date,
    this.note = '',
    this.replaces,
    this.reason,
    this.reasonNote = '',
  });
}

/// Sole writer. Database transactions and the in-process lock make retries,
/// restore and corrections all-or-nothing. Nothing publishes before commit.
class BookRepository extends ChangeNotifier {
  final Database db;
  final String rollbackPath;
  final DateTime Function() clock;
  final Lock _lock = Lock();
  late Book book;
  BookRepository._(this.db, this.rollbackPath, this.clock);

  static Future<BookRepository> open({
    required String path,
    required String rollbackPath,
    DatabaseFactory? factory,
    DateTime Function()? clock,
  }) async {
    final db = await (factory ?? databaseFactory).openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
          await db.execute('PRAGMA synchronous = FULL');
        },
        onCreate: (db, version) async {
          for (final table in [
            'meta',
            'people',
            'ledgers',
            'entries',
            'audits',
            'operations',
          ]) {
            await db.execute(
              'CREATE TABLE $table (id TEXT PRIMARY KEY NOT NULL, data TEXT NOT NULL)',
            );
          }
          final initial = Book(newId());
          await db.insert('meta', {
            'id': 'book',
            'data': jsonEncode(_meta(initial)),
          });
        },
        onDowngrade: (db, old, next) => throw const BookError(
          'Database lebih baru. Perbarui aplikasi; jangan hapus data.',
        ),
      ),
    );
    final repository = BookRepository._(
      db,
      rollbackPath,
      clock ?? DateTime.now,
    );
    repository.book = await repository._load(db);
    repository.book.validate();
    return repository;
  }

  static Map<String, dynamic> _meta(Book b) => {
    'schema': 1,
    'id': b.id,
    'name': b.name,
    'revision': b.revision,
    'nextOrder': b.nextOrder,
    'firstChange': b.firstChange,
  };
  Future<Book> _load(DatabaseExecutor tx) async {
    final meta = await tx.query('meta', where: 'id = ?', whereArgs: ['book']);
    if (meta.length != 1) {
      throw const BookError('Database tidak lengkap. Pulihkan dari cadangan.');
    }
    final j = object(jsonDecode(meta.single['data'] as String));
    for (final table in ['people', 'ledgers', 'entries', 'audits']) {
      j[table] = (await tx.query(
        table,
        orderBy: 'rowid',
      )).map((row) => jsonDecode(row['data'] as String)).toList();
    }
    j['operations'] = {
      for (final row in await tx.query('operations'))
        row['id'] as String: jsonDecode(row['data'] as String),
    };
    return Book.fromJson(j);
  }

  Future<void> _persist(
    DatabaseExecutor tx,
    Book before,
    Book next, {
    bool replace = false,
  }) async {
    final data = next.toJson();
    final previous = before.toJson();
    final batch = tx.batch();
    for (final table in [
      'people',
      'ledgers',
      'entries',
      'audits',
      'operations',
    ]) {
      Map<String, String> encoded(Map<String, dynamic> value) {
        if (table == 'operations') {
          return (value[table] as Map<String, String>).map(
            (key, value) => MapEntry(key, jsonEncode(value)),
          );
        }
        return {
          for (final row in value[table] as List)
            row['id'] as String: jsonEncode(row),
        };
      }

      final old = replace ? <String, String>{} : encoded(previous);
      final current = encoded(data);
      if (replace) batch.delete(table);
      for (final id in old.keys.where((id) => !current.containsKey(id))) {
        batch.delete(table, where: 'id = ?', whereArgs: [id]);
      }
      for (final item in current.entries.where((e) => old[e.key] != e.value)) {
        batch.insert(table, {
          'id': item.key,
          'data': item.value,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    batch.insert('meta', {
      'id': 'book',
      'data': jsonEncode(_meta(next)),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await batch.commit(noResult: true);
  }

  Future<String> _change(String operationId, String Function(Book) edit) =>
      _lock.synchronized(() async {
        if (book.operations.containsKey(operationId)) {
          return book.operations[operationId]!;
        }
        final next = book.copy();
        final result = edit(next);
        next.operations[operationId] = result;
        next.revision++;
        next.firstChange ??= clock().toUtc().toIso8601String();
        next.validate();
        await db.transaction((tx) => _persist(tx, book, next));
        book = next;
        notifyListeners();
        return result;
      });

  Future<String> addPerson({
    required String name,
    required String note,
    required Category category,
    required String operationId,
    String? existingPersonId,
  }) => _change(operationId, (b) {
    final cleaned = name.trim();
    if (cleaned.isEmpty || cleaned.length > 80 || note.trim().length > 80) {
      throw const BookError(
        'Isi nama 1–80 karakter; pembeda maksimal 80 karakter.',
      );
    }
    final personId = existingPersonId ?? newId();
    if (existingPersonId != null && !b.people.containsKey(personId)) {
      throw const BookError('Nama ini sudah tidak tersedia.');
    }
    b.people.putIfAbsent(
      personId,
      () => Person(personId, cleaned, note.trim()),
    );
    final existing = b.ledgers.values.where(
      (l) => l.personId == personId && l.category == category,
    );
    if (existing.isNotEmpty) return existing.first.id;
    final ledger = Ledger(newId(), personId, category);
    b.ledgers[ledger.id] = ledger;
    return ledger.id;
  });

  Future<void> updatePerson(
    String personId,
    String name,
    String note,
    String operationId,
  ) async {
    await _change(operationId, (b) {
      if (name.trim().isEmpty ||
          name.trim().length > 80 ||
          note.trim().length > 80) {
        throw const BookError('Periksa panjang nama dan pembeda.');
      }
      final p = b.people[personId];
      if (p == null) throw const BookError('Orang tidak ditemukan.');
      p.name = name.trim();
      p.note = note.trim();
      return personId;
    });
  }

  Future<void> renameBook(String name, String operationId) async {
    await _change(operationId, (b) {
      if (name.trim().isEmpty || name.trim().length > 80) {
        throw const BookError('Nama warung harus berisi 1–80 karakter.');
      }
      b.name = name.trim();
      return b.id;
    });
  }

  bool hasHistory(String ledgerId) =>
      book.entries.values.any((e) => e.ledgerId == ledgerId);

  String _applyEntry(Book b, EntryInput input, String operationId) {
    final ledger = b.ledgers[input.ledgerId];
    if (ledger == null || ledger.archived) {
      throw const BookError('Aktifkan kembali catatan sebelum mengubahnya.');
    }
    validDay(input.date);
    if (input.date.compareTo(day(clock())) > 0) {
      throw const BookError(
        'Tanggal tidak boleh melewati hari ini. Periksa jam HP.',
      );
    }
    if (input.amount < 1 || input.amount > maxAmount) {
      throw const BookError('Jumlah harus Rp1 sampai Rp999.999.999.');
    }
    if (input.note.trim().length > 300 ||
        input.reasonNote.trim().length > 300) {
      throw const BookError('Keterangan maksimal 300 karakter.');
    }
    final old = input.replaces == null ? null : b.entries[input.replaces];
    if (input.replaces != null && (old == null || !old.active)) {
      throw const BookError('Catatan ini sudah diperbaiki atau dibatalkan.');
    }
    if (old != null) {
      final origin = b.ledgers[old.ledgerId]!;
      if (origin.archived) {
        throw const BookError('Aktifkan catatan asal terlebih dahulu.');
      }
      if (origin.category != ledger.category) {
        throw const BookError(
          'Koreksi hanya dapat dilakukan dalam kategori yang sama.',
        );
      }
      if (!reasons.contains(input.reason)) {
        throw const BookError('Pilih alasan perbaikan.');
      }
      if ((old.kind == EntryKind.opening || input.kind == EntryKind.opening) &&
          (old.kind != input.kind || old.ledgerId != ledger.id)) {
        throw const BookError(
          'Saldo awal tidak dapat dipindahkan atau diubah menjadi pembayaran.',
        );
      }
      old.active = false;
    }
    if (input.kind == EntryKind.opening) {
      if (old == null && b.entries.values.any((e) => e.ledgerId == ledger.id)) {
        throw const BookError(
          'Saldo awal hanya dapat dibuat sebelum ada riwayat.',
        );
      }
      ledger.openingDate = input.date;
    }
    final entry = Entry(
      id: newId(),
      operationId: operationId,
      ledgerId: ledger.id,
      kind: input.kind,
      amount: input.amount,
      date: input.date,
      created: clock().toUtc().toIso8601String(),
      order: old != null && old.ledgerId == ledger.id
          ? old.order
          : b.nextOrder++,
      note: input.note.trim(),
      previousId: old?.id,
    );
    b.entries[entry.id] = entry;
    if (old != null) {
      final audit = Audit(
        newId(),
        operationId,
        old.id,
        entry.id,
        input.reason!,
        input.reasonNote.trim(),
        entry.created,
      );
      b.audits[audit.id] = audit;
    }
    return entry.id;
  }

  Book preview(EntryInput input) {
    final trial = book.copy();
    _applyEntry(trial, input, newId());
    trial.validate();
    return trial;
  }

  Future<String> saveEntry(EntryInput input, String operationId) =>
      _change(operationId, (b) => _applyEntry(b, input, operationId));

  Future<void> cancelEntry(
    String entryId,
    String reason,
    String note,
    String operationId,
  ) async {
    await _change(operationId, (b) {
      final e = b.entries[entryId];
      if (e == null || !e.active) {
        throw const BookError('Catatan sudah dibatalkan atau diperbaiki.');
      }
      if (b.ledgers[e.ledgerId]!.archived) {
        throw const BookError(
          'Aktifkan catatan sebelum membatalkan transaksi.',
        );
      }
      if (!reasons.contains(reason) || note.length > 300) {
        throw const BookError('Pilih alasan pembatalan yang valid.');
      }
      e.active = false;
      final audit = Audit(
        newId(),
        operationId,
        e.id,
        null,
        reason,
        note.trim(),
        clock().toUtc().toIso8601String(),
      );
      b.audits[audit.id] = audit;
      return e.id;
    });
  }

  Future<void> archive(
    String ledgerId,
    bool archived,
    String operationId,
  ) async {
    await _change(operationId, (b) {
      final l = b.ledgers[ledgerId];
      if (l == null) throw const BookError('Catatan tidak ditemukan.');
      if (archived && b.balance(l.id) != 0) {
        throw const BookError('Lunasi catatan sebelum mengarsipkan.');
      }
      l.archived = archived;
      return l.id;
    });
  }

  Future<void> deletePerson(String personId, String operationId) async {
    await _change(operationId, (b) {
      final ids = b.ledgers.values
          .where((l) => l.personId == personId)
          .map((l) => l.id)
          .toSet();
      if (b.entries.values.any((e) => ids.contains(e.ledgerId))) {
        throw const BookError(
          'Orang dengan riwayat tidak dapat dihapus. Gunakan arsip setelah lunas.',
        );
      }
      for (final id in ids) {
        b.ledgers.remove(id);
      }
      b.people.remove(personId);
      return personId;
    });
  }

  Future<Book> snapshot() => _lock.synchronized(() async => book.copy());
  Future<bool> hasRollback() => File(rollbackPath).exists();

  Future<void> restore(Book source, {bool rollback = false}) =>
      _lock.synchronized(() async {
        final incoming = Book.fromJson(source.toJson());
        incoming.validate();
        if (!rollback && (book.people.isNotEmpty || book.entries.isNotEmpty)) {
          final file = File(rollbackPath);
          await file.parent.create(recursive: true);
          final temporary = File('$rollbackPath.tmp');
          await temporary.writeAsString(jsonEncode(book.toJson()), flush: true);
          final check = Book.fromJson(
            object(jsonDecode(await temporary.readAsString())),
          );
          check.validate();
          await temporary.rename(rollbackPath);
        }
        await db.transaction(
          (tx) => _persist(tx, book, incoming, replace: true),
        );
        book = incoming;
        notifyListeners();
      });

  Future<void> rollback() async {
    final file = File(rollbackPath);
    if (!await file.exists()) {
      throw const BookError('Tidak ada catatan sebelum pemulihan.');
    }
    if (await file.length() > 200 * 1024 * 1024) {
      throw const BookError('Snapshot pengaman terlalu besar.');
    }
    final source = Book.fromJson(object(jsonDecode(await file.readAsString())));
    await restore(source, rollback: true);
  }

  Future<void> close() async {
    await db.close();
  }
}
