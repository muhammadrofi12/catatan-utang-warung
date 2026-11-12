import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:catatan_warung/backup/backup.dart';
import 'package:catatan_warung/data/book_repository.dart';
import 'package:catatan_warung/domain/book.dart';
import 'package:catatan_warung/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android SQLite, Keystore, encrypted restore and app startup', (
    tester,
  ) async {
    final device = DeviceBridge();
    final private = await device.privatePath();
    expect(private, contains('no_backup'));
    final key = await BackupKey.generate();
    await device.saveKey(key.card);
    expect((await BackupKey.parse((await device.readKey())!)).id, key.id);
    final path = '${await getDatabasesPath()}/integration-test.db';
    await deleteDatabase(path);
    var repo = await BookRepository.open(
      path: path,
      rollbackPath: '$private/integration-rollback.json',
    );
    final ledger = await repo.addPerson(
      name: 'Bu Siti Uji',
      note: 'Data pengujian',
      category: Category.customer,
      operationId: newId(),
    );
    await repo.saveEntry(
      EntryInput(
        ledgerId: ledger,
        kind: EntryKind.debt,
        amount: 25000,
        date: day(DateTime.now()),
      ),
      newId(),
    );
    final file = await BackupCodec.encode(
      await repo.snapshot(),
      key,
      DateTime.now(),
    );
    await repo.saveEntry(
      EntryInput(
        ledgerId: ledger,
        kind: EntryKind.payment,
        amount: 10000,
        date: day(DateTime.now()),
      ),
      newId(),
    );
    await repo.close();
    repo = await BookRepository.open(
      path: path,
      rollbackPath: '$private/integration-rollback.json',
    );
    expect(repo.book.balance(ledger), 15000);
    final restored = await BackupCodec.decode(file, key);
    await repo.restore(restored.book);
    expect(repo.book.balance(ledger), 25000);
    await repo.rollback();
    expect(repo.book.balance(ledger), 15000);
    final status = BackupStatus('$private/integration-status.json');
    await tester.pumpWidget(
      WarungApp(repository: repo, device: device, status: status),
    );
    await tester.pumpAndSettle();
    expect(find.text('Catatan Warung'), findsOneWidget);
    expect(find.text('Rp15.000'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await repo.close();
    await deleteDatabase(path);
    final rollback = File('$private/integration-rollback.json');
    if (await rollback.exists()) await rollback.delete();
  });
}
