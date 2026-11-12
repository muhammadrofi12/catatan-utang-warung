import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:catatan_warung/backup/backup.dart';
import 'package:catatan_warung/data/book_repository.dart';
import 'package:catatan_warung/domain/book.dart';
import 'package:catatan_warung/ui/common.dart';
import 'package:catatan_warung/ui/home.dart';
import 'package:catatan_warung/ui/people.dart';
import 'package:catatan_warung/ui/entry_form.dart';
import 'package:catatan_warung/ui/ledger_screen.dart';
import 'package:catatan_warung/ui/backup_screen.dart';

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late BookRepository repo;
  late BackupStatus status;
  late String ledger;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('warung-screen-');
    repo = await BookRepository.open(
      path: '${dir.path}/book.db',
      rollbackPath: '${dir.path}/rollback',
      factory: databaseFactoryFfi,
    );
    status = BackupStatus('${dir.path}/status');
    ledger = await repo.addPerson(
      name: 'Bu Siti',
      note: 'Dekat masjid',
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
  });
  tearDown(() async {
    await repo.close();
    await dir.delete(recursive: true);
  });
  Widget app(
    Widget home, {
    double scale = 1,
    Brightness brightness = Brightness.light,
  }) => AppScope(
    repository: repo,
    device: DeviceBridge(),
    backup: status,
    child: MaterialApp(
      locale: const Locale('id'),
      supportedLocales: const [Locale('id')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: warungTheme(brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: home,
    ),
  );
  for (final brightness in Brightness.values) {
    testWidgets('readable body and category text in $brightness', (
      tester,
    ) async {
      await tester.pumpWidget(app(const HomeScreen(), brightness: brightness));
      await tester.pumpAndSettle();
      final theme = warungTheme(brightness);
      for (final item in [
        ('Warung saya', theme.extension<WarungPalette>()!.header),
        (
          'Pilih catatan yang ingin dibuka.',
          theme.extension<WarungPalette>()!.header,
        ),
        ('Pelanggan belum bayar', theme.colorScheme.surface),
        ('Warung belum bayar', theme.colorScheme.surface),
      ]) {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(item.$1),
        );
        final color = paragraph.text.style!.color!;
        final foreground = color.computeLuminance();
        final background = item.$2.computeLuminance();
        final contrast = foreground > background
            ? (foreground + .05) / (background + .05)
            : (background + .05) / (foreground + .05);
        expect(contrast, greaterThanOrEqualTo(4.5), reason: item.$1);
      }
    });
  }
  for (final scale in [1.0, 2.0]) {
    testWidgets('main screens fit 360px at ${scale}x text', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final screen in <Widget>[
        const HomeScreen(),
        const PeopleScreen(category: Category.customer),
        const PersonForm(category: Category.supplier),
        LedgerScreen(ledgerId: ledger),
        EntryForm(ledgerId: ledger, initialKind: EntryKind.payment),
        EntryForm(
          ledgerId: ledger,
          initialKind: EntryKind.debt,
          replaces: repo.book.entries.keys.first,
        ),
        CancelEntryScreen(entryId: repo.book.entries.keys.first),
        const BackupScreen(),
      ]) {
        await tester.pumpWidget(app(screen, scale: scale));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${screen.runtimeType} overflow',
        );
        final scroll = find.byType(Scrollable).first;
        for (var i = 0; i < 4; i++) {
          await tester.drag(scroll, const Offset(0, -500));
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${screen.runtimeType} scroll overflow',
          );
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    });
  }
  testWidgets('home keeps separate customer and supplier navigation', (
    tester,
  ) async {
    await tester.pumpWidget(app(const HomeScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pelanggan belum bayar'));
    await tester.pumpAndSettle();
    expect(find.text('Pelanggan'), findsOneWidget);
    expect(find.text('Bu Siti'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Warung belum bayar'));
    await tester.tap(find.text('Warung belum bayar'));
    await tester.pumpAndSettle();
    expect(find.text('Pemasok'), findsOneWidget);
    expect(find.text('Bu Siti'), findsNothing);
  });
  testWidgets('large-text search remains usable above the keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      app(const PeopleScreen(category: Category.customer), scale: 2),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Siti');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('payment form commits and displays 15000 remaining', (
    tester,
  ) async {
    await tester.pumpWidget(app(LedgerScreen(ledgerId: ledger)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pelanggan bayar').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '10000');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Simpan catatan'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(EntryForm),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan catatan'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(repo.book.balance(ledger), 15000);
    expect(find.text('Tersimpan. Sisa terbaru Rp15.000.'), findsOneWidget);
  });
}
