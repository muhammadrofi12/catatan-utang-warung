import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:catatan_warung/backup/backup.dart';
import 'package:catatan_warung/data/book_repository.dart';
import 'package:catatan_warung/domain/book.dart';

void main() {
  test(
    '500 people, 1000 ledgers, 20000 entries/audits survive encrypted restore',
    () async {
      sqfliteFfiInit();
      final dir = await Directory.systemTemp.createTemp('warung-volume-');
      final repo = await BookRepository.open(
        path: '${dir.path}/book.db',
        rollbackPath: '${dir.path}/rollback',
        factory: databaseFactoryFfi,
      );
      try {
        final b = Book(
          newId(),
          revision: 20000,
          firstChange: '2026-01-01T00:00:00.000Z',
        );
        for (var i = 0; i < 500; i++) {
          final person = Person(
            newId(),
            'Pelanggan uji bernama panjang nomor $i',
            'Pembeda rumah dekat pasar nomor $i',
          );
          b.people[person.id] = person;
          for (final category in Category.values) {
            final ledger = Ledger(
              newId(),
              person.id,
              category,
              archived: i.isEven,
            );
            b.ledgers[ledger.id] = ledger;
            Entry? first;
            for (var n = 0; n < 17; n++) {
              final e = Entry(
                id: newId(),
                operationId: newId(),
                ledgerId: ledger.id,
                kind: EntryKind.debt,
                amount: 1000,
                date: '2026-01-01',
                created: '2026-01-01T00:00:00.000Z',
                order: b.nextOrder++,
                note: 'Barang uji',
              );
              b.entries[e.id] = e;
              first ??= e;
              b.operations[e.operationId] = e.id;
            }
            first!.active = false;
            final replacement = Entry(
              id: newId(),
              operationId: newId(),
              ledgerId: ledger.id,
              kind: EntryKind.debt,
              amount: 1000,
              date: '2026-01-01',
              created: '2026-01-01T00:00:00.000Z',
              order: first.order,
              note: 'Keterangan diperbaiki',
              previousId: first.id,
            );
            b.entries[replacement.id] = replacement;
            b.operations[replacement.operationId] = replacement.id;
            final audit = Audit(
              newId(),
              replacement.operationId,
              first.id,
              replacement.id,
              'Lainnya',
              '',
              replacement.created,
            );
            b.audits[audit.id] = audit;
            final payment = Entry(
              id: newId(),
              operationId: newId(),
              ledgerId: ledger.id,
              kind: EntryKind.payment,
              amount: i.isEven ? 17000 : 5000,
              date: '2026-01-02',
              created: '2026-01-02T00:00:00.000Z',
              order: b.nextOrder++,
            );
            b.entries[payment.id] = payment;
            b.operations[payment.operationId] = payment.id;
          }
        }
        b.validate();
        expect(b.entries.length + b.audits.length, 20000);
        expect(b.total(Category.customer), 3000000);
        expect(b.total(Category.supplier), 3000000);
        final key = await BackupKey.generate();
        final encoded = await BackupCodec.encode(b, key, DateTime.now());
        final restored = await BackupCodec.decode(encoded, key);
        await repo.restore(restored.book);
        expect(repo.book.canonical(), b.canonical());
        final ledger = b.ledgers.values.firstWhere((l) => !l.archived);
        await repo.saveEntry(
          EntryInput(
            ledgerId: ledger.id,
            kind: EntryKind.payment,
            amount: 1000,
            date: '2026-01-03',
          ),
          newId(),
        );
        expect(repo.book.balance(ledger.id), 11000);
      } finally {
        await repo.close();
        await dir.delete(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
