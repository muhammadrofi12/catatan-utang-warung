import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'backup/backup.dart';
import 'data/book_repository.dart';
import 'ui/common.dart';
import 'ui/home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Bootstrap());
}

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});
  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  BookRepository? repository;
  BackupStatus? status;
  final device = DeviceBridge();
  String? error;
  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    setState(() => error = null);
    try {
      final private = await device.privatePath();
      final backup = BackupStatus(p.join(private, 'backup-status.json'));
      await backup.load();
      final repo = await BookRepository.open(
        path: p.join(await getDatabasesPath(), 'catatan_warung.db'),
        rollbackPath: p.join(private, 'before-restore.json'),
      );
      if (!mounted) {
        await repo.close();
        return;
      }
      setState(() {
        repository = repo;
        status = backup;
      });
    } catch (e) {
      if (mounted) setState(() => error = safeError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (repository != null) {
      return WarungApp(
        repository: repository!,
        device: device,
        status: status!,
      );
    }
    return MaterialApp(
      theme: warungTheme(Brightness.light),
      home: Scaffold(
        body: PageBody(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: error == null
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Notice(error!, error: true),
                      const Text(
                        'Jangan hapus data aplikasi. Minta bantuan keluarga jika masalah berlanjut.',
                      ),
                      ActionButton('Coba lagi', onPressed: initialize),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class WarungApp extends StatelessWidget {
  final BookRepository repository;
  final DeviceBridge device;
  final BackupStatus status;
  const WarungApp({
    super.key,
    required this.repository,
    required this.device,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return AppScope(
      repository: repository,
      device: device,
      backup: status,
      child: MaterialApp(
        title: 'Catatan Warung',
        debugShowCheckedModeBanner: false,
        locale: const Locale('id'),
        supportedLocales: const [Locale('id')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: warungTheme(Brightness.light),
        darkTheme: warungTheme(Brightness.dark),
        home: const HomeScreen(),
      ),
    );
  }
}
