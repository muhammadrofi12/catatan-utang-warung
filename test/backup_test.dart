import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:catatan_warung/backup/backup.dart';
import 'package:catatan_warung/domain/book.dart';
import 'package:catatan_warung/data/book_repository.dart';

void main() {
  test('encrypted snapshot roundtrip, key card and random nonce', () async {
    final b = Book(newId());
    final key = await BackupKey.generate();
    final file = await BackupCodec.encode(b, key, DateTime.utc(2026, 11, 11));
    final second = await BackupCodec.encode(b, key, DateTime.utc(2026, 11, 11));
    expect(file, isNot(second));
    expect(utf8.decode(file), isNot(contains('Warung saya')));
    expect((await BackupKey.parse(key.card)).id, key.id);
    expect((await BackupKey.parse(key.code)).id, key.id);
    expect(
      (await BackupCodec.decode(file, key)).book.canonical(),
      b.canonical(),
    );
  });
  test(
    'wrong key, modified ciphertext/header/tag and malformed file reject',
    () async {
      final key = await BackupKey.generate();
      final bytes = await BackupCodec.encode(
        Book(newId()),
        key,
        DateTime.now(),
      );
      await expectLater(
        BackupCodec.decode(bytes, await BackupKey.generate()),
        throwsA(isA<BookError>()),
      );
      for (final field in ['ciphertext', 'tag', 'nonce']) {
        final j = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        final value = base64Decode(j[field] as String);
        value[0] ^= 1;
        j[field] = base64Encode(value);
        await expectLater(
          BackupCodec.decode(
            Uint8List.fromList(utf8.encode(jsonEncode(j))),
            key,
          ),
          throwsA(isA<BookError>()),
        );
      }
      final j = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      (j['header'] as Map)['version'] = 999;
      await expectLater(
        BackupCodec.decode(Uint8List.fromList(utf8.encode(jsonEncode(j))), key),
        throwsA(isA<BookError>()),
      );
      await expectLater(
        BackupCodec.decode(Uint8List.fromList([1, 2, 3]), key),
        throwsA(isA<BookError>()),
      );
    },
  );
  test('duplicate IDs, orphan references and orphan replacement reject', () {
    final b = Book(newId());
    final p = Person(newId(), 'Siti', '');
    b.people[p.id] = p;
    final l = Ledger(newId(), p.id, Category.customer);
    b.ledgers[l.id] = l;
    final data = b.toJson();
    (data['people'] as List).add(p.toJson());
    expect(() => Book.fromJson(data), throwsA(isA<BookError>()));
    b.people.clear();
    expect(b.validate, throwsA(isA<BookError>()));
  });
  test(
    'reminders track changed revisions, saved snapshot time and restore',
    () async {
      final dir = await Directory.systemTemp.createTemp('warung-status-');
      try {
        final status = BackupStatus('${dir.path}/status.json');
        final start = DateTime.utc(2026, 11, 1);
        final book = Book(newId(), firstChange: start.toIso8601String());
        expect(
          status.reminder(book, start.add(const Duration(days: 6))),
          isFalse,
        );
        expect(
          status.reminder(book, start.add(const Duration(days: 7))),
          isTrue,
        );
        await status.exported(book, start);
        expect(
          status.reminder(book, start.add(const Duration(days: 8))),
          isFalse,
        );
        book.revision++;
        expect(
          status.reminder(book, start.add(const Duration(days: 8))),
          isTrue,
        );
        final reload = BackupStatus(status.path);
        await reload.load();
        expect(reload.dirty(book), isTrue);
        await reload.invalidate();
        await reload.restored(book, start.toIso8601String());
        expect(reload.snapshotAt, isNull);
        expect(reload.dirty(book), isTrue);
        expect(reload.reminder(book, DateTime.now()), isFalse);
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );
}
