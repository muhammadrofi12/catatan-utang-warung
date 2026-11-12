// Render isolated, synthetic UI previews. Never opens the installed app's data.
// flutter test tool/preview_screens.dart --no-pub
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:catatan_warung/backup/backup.dart';
import 'package:catatan_warung/data/book_repository.dart';
import 'package:catatan_warung/domain/book.dart';
import 'package:catatan_warung/ui/common.dart';
import 'package:catatan_warung/ui/home.dart';
import 'package:catatan_warung/ui/people.dart';
import 'package:catatan_warung/ui/ledger_screen.dart';
import 'package:catatan_warung/ui/entry_form.dart';
import 'package:catatan_warung/ui/backup_screen.dart';

void main() {
  testWidgets('render reference-inspired UI with synthetic records', (
    tester,
  ) async {
    sqfliteFfiInit();
    late Directory dir;
    late BookRepository repo;
    final output = Directory('artifacts/ui-redesign');
    await tester.runAsync(() async {
      dir = await Directory.systemTemp.createTemp('warung-preview-');
      await output.create(recursive: true);
      final sdk =
          Platform.environment['CATATAN_FLUTTER_SDK'] ??
          'C:/src/flutter-ocs-pos-stable';
      final font = FontLoader('Roboto');
      for (final name in [
        'roboto-regular.ttf',
        'roboto-medium.ttf',
        'roboto-bold.ttf',
      ]) {
        final bytes = await File(
          '$sdk/bin/cache/artifacts/material_fonts/$name',
        ).readAsBytes();
        font.addFont(Future.value(ByteData.sublistView(bytes)));
      }
      await font.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(
        File(
          '$sdk/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
        ).readAsBytes().then(ByteData.sublistView),
      );
      await icons.load();
      repo = await BookRepository.open(
        path: '${dir.path}/preview.db',
        rollbackPath: '${dir.path}/rollback',
        factory: databaseFactoryFfi,
      );
      for (final data in [
        ('Bu Siti', Category.customer, 85000),
        ('Bu Ani', Category.customer, 35000),
        ('Toko Makmur', Category.supplier, 200000),
      ]) {
        final ledger = await repo.addPerson(
          name: data.$1,
          note: data.$1 == 'Bu Siti' ? 'Dekat masjid' : '',
          category: data.$2,
          operationId: newId(),
        );
        await repo.saveEntry(
          EntryInput(
            ledgerId: ledger,
            kind: EntryKind.debt,
            amount: data.$3,
            date: day(DateTime.now()),
            note: 'Catatan contoh untuk pratinjau',
          ),
          newId(),
        );
        if (data.$1 == 'Bu Siti') {
          await repo.saveEntry(
            EntryInput(
              ledgerId: ledger,
              kind: EntryKind.payment,
              amount: 25000,
              date: day(DateTime.now()),
            ),
            newId(),
          );
        }
      }
    });
    final ledger = repo.book.ledgers.keys.first;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scenarios = <(String, Widget, double, Brightness)>[
      ('home', const HomeScreen(), 1, Brightness.light),
      (
        'customers',
        const PeopleScreen(category: Category.customer),
        1,
        Brightness.light,
      ),
      ('ledger', LedgerScreen(ledgerId: ledger), 1, Brightness.light),
      (
        'payment',
        EntryForm(ledgerId: ledger, initialKind: EntryKind.payment),
        1,
        Brightness.light,
      ),
      ('backup', const BackupScreen(), 1, Brightness.light),
      ('home-large-text', const HomeScreen(), 2, Brightness.light),
      ('home-dark', const HomeScreen(), 1, Brightness.dark),
    ];
    try {
      for (final scenario in scenarios) {
        final key = GlobalKey();
        await tester.pumpWidget(
          AppScope(
            repository: repo,
            device: DeviceBridge(),
            backup: BackupStatus('${dir.path}/status'),
            child: RepaintBoundary(
              key: key,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: warungTheme(scenario.$4),
                locale: const Locale('id'),
                supportedLocales: const [Locale('id')],
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scenario.$3)),
                  child: child!,
                ),
                home: scenario.$2,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: scenario.$1);
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final rendered = await boundary.toImage(pixelRatio: 2);
          final bytes = await rendered.toByteData(
            format: ui.ImageByteFormat.png,
          );
          await File('${output.path}/${scenario.$1}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          rendered.dispose();
        });
        await tester.pumpWidget(const SizedBox());
      }
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await repo.close();
        if (!dir.path.contains('warung-preview-')) {
          throw StateError('Unexpected temporary path');
        }
        await dir.delete(recursive: true);
      });
    }
  });
}
