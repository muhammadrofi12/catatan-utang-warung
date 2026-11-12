import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:catatan_warung/data/book_repository.dart';
import 'package:catatan_warung/domain/book.dart';

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late BookRepository repo;
  late String ledger;
  Future<BookRepository> open() => BookRepository.open(
    path: '${dir.path}/book.db',
    rollbackPath: '${dir.path}/rollback.json',
    factory: databaseFactoryFfi,
    clock: () => DateTime(2026, 11, 11),
  );
  Future<String> add(
    EntryKind kind,
    int amount, {
    String date = '2026-11-10',
    String? target,
    String? replaces,
    String? op,
  }) => repo.saveEntry(
    EntryInput(
      ledgerId: target ?? ledger,
      kind: kind,
      amount: amount,
      date: date,
      replaces: replaces,
      reason: replaces == null ? null : reasons.first,
    ),
    op ?? newId(),
  );
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('catatan-warung-test-');
    repo = await open();
    ledger = await repo.addPerson(
      name: 'Bu Siti',
      note: 'Sebelah masjid',
      category: Category.customer,
      operationId: newId(),
    );
  });
  tearDown(() async {
    await repo.close();
    await dir.delete(recursive: true);
  });

  test(
    'PRD example, corrections stay visible, history survives reopening',
    () async {
      await add(EntryKind.opening, 20000);
      final debt = await add(EntryKind.debt, 25000);
      await add(EntryKind.payment, 10000);
      final replacement = await add(EntryKind.debt, 15000, replaces: debt);
      expect(repo.book.balance(ledger), 25000);
      expect(repo.book.entries[debt]!.active, isFalse);
      expect(repo.book.entries[replacement]!.previousId, debt);
      await add(EntryKind.payment, 25000);
      expect(repo.book.balance(ledger), 0);
      await repo.close();
      repo = await open();
      expect(repo.book.entries.length, 5);
      expect(repo.book.balance(ledger), 0);
      expect(repo.book.audits.length, 1);
    },
  );
  test('same person has independent customer and supplier balances', () async {
    final supplier = await repo.addPerson(
      name: 'Bu Siti',
      note: '',
      category: Category.supplier,
      existingPersonId: repo.book.ledgers[ledger]!.personId,
      operationId: newId(),
    );
    await add(EntryKind.debt, 25000);
    await add(EntryKind.debt, 200000, target: supplier);
    await add(EntryKind.payment, 50000, target: supplier);
    expect(repo.book.people.length, 1);
    expect(repo.book.total(Category.customer), 25000);
    expect(repo.book.total(Category.supplier), 150000);
  });
  test('concurrent retries commit exactly once', () async {
    final operation = newId();
    final ids = await Future.wait(
      List.generate(8, (_) => add(EntryKind.debt, 25000, op: operation)),
    );
    expect(ids.toSet().length, 1);
    expect(repo.book.entries.length, 1);
    expect(repo.book.balance(ledger), 25000);
  });
  test('overpayment, backdated payment and invalid correction leave all data unchanged', () async {
    final debt = await add(EntryKind.debt, 25000);
    await add(EntryKind.payment, 20000);
    final before = repo.book.canonical();
    await expectLater(add(EntryKind.payment, 6000), throwsA(isA<BookError>()));
    await expectLater(
      add(EntryKind.payment, 1000, date: '2026-11-09'),
      throwsA(isA<BookError>()),
    );
    await expectLater(
      add(EntryKind.debt, 10000, replaces: debt),
      throwsA(isA<BookError>()),
    );
    await expectLater(
      repo.cancelEntry(debt, reasons.first, '', newId()),
      throwsA(isA<BookError>()),
    );
    expect(repo.book.canonical(), before);
  });
  test(
    'failed database write does not poison retry operation or in-memory state',
    () async {
      await repo.db.execute(
        "CREATE TRIGGER fail_entry BEFORE INSERT ON entries BEGIN SELECT RAISE(ABORT, 'test write failure'); END",
      );
      final before = repo.book.canonical();
      final operation = newId();
      await expectLater(
        add(EntryKind.debt, 100, op: operation),
        throwsA(anything),
      );
      expect(repo.book.canonical(), before);
      await repo.db.execute('DROP TRIGGER fail_entry');
      await add(EntryKind.debt, 100, op: operation);
      expect(repo.book.balance(ledger), 100);
    },
  );
  test('transaction cap differs from total cap and zero/future/invalid dates reject', () async {
    await add(EntryKind.debt, maxAmount);
    await add(EntryKind.debt, maxAmount);
    expect(repo.book.balance(ledger), 1999999998);
    for (final value in [0, -1, maxAmount + 1]) {
      await expectLater(add(EntryKind.debt, value), throwsA(isA<BookError>()));
    }
    for (final date in ['2026-11-12', '1899-12-31', '2026-02-30']) {
      await expectLater(
        add(EntryKind.debt, 1, date: date),
        throwsA(isA<BookError>()),
      );
    }
    await add(EntryKind.payment, maxAmount);
    await add(EntryKind.payment, maxAmount);
    expect(repo.book.balance(ledger), 0);
  });
  test(
    'opening boundary is retained after cancellation; no second opening',
    () async {
      expect(repo.book.ledgers[ledger]!.openingDate, isNull);
      final opening = await add(EntryKind.opening, 20000, date: '2026-11-05');
      await repo.cancelEntry(opening, reasons.first, '', newId());
      expect(repo.book.ledgers[ledger]!.openingDate, '2026-11-05');
      await expectLater(
        add(EntryKind.opening, 10000),
        throwsA(isA<BookError>()),
      );
      await expectLater(
        add(EntryKind.debt, 10000, date: '2026-11-04'),
        throwsA(isA<BookError>()),
      );
      await expectLater(
        repo.deletePerson(repo.book.ledgers[ledger]!.personId, newId()),
        throwsA(isA<BookError>()),
      );
    },
  );
  test('correction chains and atomic movement preserve both ledgers', () async {
    final other = await repo.addPerson(
      name: 'Bu Ani',
      note: '',
      category: Category.customer,
      operationId: newId(),
    );
    final a = await add(EntryKind.debt, 10000);
    final b = await add(EntryKind.debt, 15000, replaces: a);
    final c = await add(EntryKind.debt, 20000, replaces: b, target: other);
    expect(repo.book.balance(ledger), 0);
    expect(repo.book.balance(other), 20000);
    await expectLater(
      repo.cancelEntry(b, reasons.first, '', newId()),
      throwsA(isA<BookError>()),
    );
    await repo.cancelEntry(c, reasons.first, '', newId());
    expect(repo.book.balance(other), 0);
    expect(repo.book.audits.length, 3);
  });
  test(
    'archive only one zero-balance category and empty-person deletion',
    () async {
      final person = repo.book.ledgers[ledger]!.personId;
      final supplier = await repo.addPerson(
        name: 'Bu Siti',
        note: '',
        category: Category.supplier,
        existingPersonId: person,
        operationId: newId(),
      );
      await add(EntryKind.debt, 100, target: supplier);
      await repo.archive(ledger, true, newId());
      expect(repo.book.ledgers[supplier]!.archived, isFalse);
      await expectLater(add(EntryKind.debt, 100), throwsA(isA<BookError>()));
      await expectLater(
        repo.archive(supplier, true, newId()),
        throwsA(isA<BookError>()),
      );
      await expectLater(
        repo.deletePerson(person, newId()),
        throwsA(isA<BookError>()),
      );
      final empty = await repo.addPerson(
        name: 'Salah buat',
        note: '',
        category: Category.customer,
        operationId: newId(),
      );
      await repo.deletePerson(repo.book.ledgers[empty]!.personId, newId());
      expect(repo.book.ledgers.containsKey(empty), isFalse);
    },
  );
  test('restore replaces, rollback persists across restart, failed restore is atomic', () async {
    await add(EntryKind.debt, 10000);
    final older = await repo.snapshot();
    await add(EntryKind.debt, 5000);
    await repo.restore(older);
    expect(repo.book.balance(ledger), 10000);
    await repo.close();
    repo = await open();
    await repo.rollback();
    expect(repo.book.balance(ledger), 15000);
    await repo.db.execute(
      "CREATE TRIGGER fail_restore BEFORE INSERT ON entries BEGIN SELECT RAISE(ABORT, 'test failure'); END",
    );
    final before = repo.book.canonical();
    await expectLater(repo.restore(older), throwsA(anything));
    expect(repo.book.canonical(), before);
    await repo.db.execute('DROP TRIGGER fail_restore');
    await repo.close();
    repo = await open();
    expect(repo.book.canonical(), before);
  });
}
