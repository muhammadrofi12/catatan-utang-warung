import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show compute;

import '../backup/backup.dart';
import '../data/book_repository.dart';
import '../domain/book.dart';
import 'common.dart';

Future<Uint8List> encodeInWorker((Book, BackupKey, DateTime) request) =>
    BackupCodec.encode(request.$1, request.$2, request.$3);
Future<RestoredBackup> decodeInWorker((Uint8List, BackupKey) request) =>
    BackupCodec.decode(request.$1, request.$2);

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});
  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool busy = false;
  bool rollbackAvailable = false;
  bool largeDatabase = false;
  String? message;
  bool failed = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    checkRollback();
  }

  Future<void> checkRollback() async {
    final repo = AppScope.of(context).repository;
    final exists = await repo.hasRollback();
    var bytes = 0;
    for (final suffix in ['', '-journal', '-wal', '-shm']) {
      final file = File('${repo.db.path}$suffix');
      try {
        if (await file.exists()) bytes += await file.length();
      } catch (_) {
        /* Advisory only. */
      }
    }
    if (mounted &&
        (exists != rollbackAvailable ||
            largeDatabase != (bytes >= 20 * 1024 * 1024))) {
      setState(() {
        rollbackAvailable = exists;
        largeDatabase = bytes >= 20 * 1024 * 1024;
      });
    }
  }

  Future<void> run(Future<void> Function() work) async {
    if (busy) return;
    setState(() {
      busy = true;
      message = null;
      failed = false;
    });
    try {
      await work();
    } catch (e) {
      if (mounted) {
        setState(() {
          message = safeError(e);
          failed = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
        await checkRollback();
      }
    }
  }

  Future<void> export({bool rotate = false}) => run(() async {
    final scope = AppScope.of(context);
    BackupKey? key;
    if (!rotate) {
      final stored = await scope.device.readKey();
      if (stored != null) {
        try {
          key = await BackupKey.parse(stored);
        } catch (_) {
          /* A new verified key is required. */
        }
      }
    }
    if (key == null) {
      if (!mounted) return;
      key = await visit<BackupKey>(context, const KeySetupScreen());
      if (key == null) return;
    }
    final snapshot = await scope.repository.snapshot();
    final now = DateTime.now().toUtc();
    final exportKey = key;
    final bytes = await compute(encodeInWorker, (snapshot, exportKey, now));
    final name =
        'catatan-warung-${day(now.toLocal())}-${newId().substring(0, 8)}.catatanwarung';
    if (!await scope.device.saveFile(name, bytes)) return;
    // The external key is already verified. A failed local-key write must never
    // make the exported file unreadable or replace the old key prematurely.
    await scope.device.saveKey(key.card);
    await scope.backup.exported(snapshot, now);
    if (mounted) {
      setState(
        () => message = 'File cadangan berhasil disimpan dan diperiksa. Pastikan file serta kartu kuncinya disimpan terpisah di luar HP ini. Penyimpanan melalui Drive mengikuti proses unggah aplikasi Drive.',
      );
    }
  });
  Future<void> restore() => run(() async {
    final scope = AppScope.of(context);
    final bytes = await scope.device.openFile();
    if (bytes == null || !mounted) return;
    final key = await visit<BackupKey>(
      context,
      const KeyInputScreen(title: 'Kunci untuk pemulihan'),
    );
    if (key == null) return;
    final restored = await compute(decodeInWorker, (bytes, key));
    if (!mounted) return;
    final b = restored.book;
    final accepted = await confirm(
      context,
      'Ganti catatan di HP ini?',
      '${b.name}\nCadangan: ${displayDay(day(DateTime.parse(restored.snapshotAt).toLocal()))}\n${b.people.length} orang, ${b.entries.length} transaksi termasuk riwayat koreksi.\n\nUtang pelanggan: ${money(b.total(Category.customer))}\nUtang warung: ${money(b.total(Category.supplier))}\n\nSeluruh catatan akan diganti, bukan digabung. Catatan setelah waktu cadangan tidak ikut kembali. Salinan sebelum pemulihan tersedia di HP ini jika sudah ada catatan.',
      action: 'Pulihkan cadangan',
    );
    if (!accepted) return;
    await scope.backup.invalidate();
    await scope.repository.restore(b);
    await scope.backup.restored(b, restored.snapshotAt);
    if (mounted) {
      setState(
        () => message = 'Catatan berhasil dipulihkan. Periksa nama dan saldo. Buat cadangan baru dari HP ini.',
      );
    }
  });
  Future<void> rollback() => run(() async {
    final scope = AppScope.of(context);
    if (!await confirm(
      context,
      'Kembali ke sebelum pemulihan?',
      'Catatan aktif akan diganti dengan salinan sebelum pemulihan terakhir. Perubahan sesudahnya tidak ikut. Simpan cadangan terlebih dahulu jika masih diperlukan.',
      action: 'Kembalikan catatan',
    )) {
      return;
    }
    await scope.backup.invalidate();
    await scope.repository.rollback();
    if (mounted) {
      setState(
        () => message =
            'Catatan sebelum pemulihan sudah dikembalikan. Buat cadangan baru.',
      );
    }
  });
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Cadangan catatan')),
        body: PageBody(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Minta bantuan keluarga',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Catatan tersimpan di HP. Jika HP hilang, rusak, atau aplikasi dihapus, pulihkan dengan file cadangan dan kartu kunci yang cocok.',
              ),
              Notice(scope.backup.description(scope.repository.book)),
              if (largeDatabase)
                const Notice(
                  'Ukuran buku mencapai 20 MB. Cadangan Android memiliki batas 25 MB per aplikasi. Gunakan cadangan file agar seluruh riwayat tetap tersimpan.',
                ),
              if (message != null) Notice(message!, error: failed),
              if (busy)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: 'Sedang memproses cadangan',
                    ),
                  ),
                ),
              ActionButton('Simpan cadangan', onPressed: busy ? null : export),
              const SizedBox(height: 12),
              ActionButton(
                'Pulihkan dari file',
                secondary: true,
                onPressed: busy ? null : restore,
              ),
              const SizedBox(height: 24),
              const Text(
                'Simpan salinan di HP keluarga, komputer, atau Drive melalui pemilih file. File yang hanya ada di HP ini dapat ikut hilang. Cadangan mingguan tidak memuat transaksi yang dibuat setelahnya.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Cadangan Android dapat membantu jika tersedia. Jadwal dan pemulihannya diatur sistem dan tidak dijamin. Aplikasi tidak dapat memastikan kapan cadangan Android berhasil.',
              ),
              const SizedBox(height: 24),
              ActionButton(
                'Buat kunci dan cadangan baru',
                secondary: true,
                onPressed: busy ? null : () => export(rotate: true),
              ),
              const Text(
                'Gunakan jika kartu kunci hilang. Kunci baru tidak dapat membuka cadangan lama.',
              ),
              if (rollbackAvailable) ...[
                const SizedBox(height: 24),
                ActionButton(
                  'Kembali ke sebelum pemulihan',
                  secondary: true,
                  onPressed: busy ? null : rollback,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class KeySetupScreen extends StatefulWidget {
  const KeySetupScreen({super.key});
  @override
  State<KeySetupScreen> createState() => _KeySetupScreenState();
}

class _KeySetupScreenState extends State<KeySetupScreen> {
  BackupKey? key;
  String? error;
  bool busy = false;
  bool saved = false;
  bool outside = false;
  @override
  void initState() {
    super.initState();
    generate();
  }

  Future<void> generate() async {
    try {
      final created = await BackupKey.generate();
      if (mounted) setState(() => key = created);
    } catch (e) {
      if (mounted) setState(() => error = safeError(e));
    }
  }

  Future<void> saveCard() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final success = await AppScope.of(context).device.saveFile(
        'kunci-catatan-warung-${key!.id}.txt',
        Uint8List.fromList(utf8.encode(key!.card)),
        mime: 'text/plain',
      );
      if (mounted && success) setState(() => saved = true);
    } catch (e) {
      if (mounted) setState(() => error = safeError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> verify() async {
    final result = await visit<BackupKey>(
      context,
      KeyInputScreen(title: 'Periksa kartu yang disimpan', expectedId: key!.id),
    );
    if (result != null && mounted) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Simpan kartu kunci')),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Kunci ini diperlukan saat pindah HP atau memasang ulang aplikasi. Simpan di HP keluarga, cetak, atau foto dengan HP keluarga. Pisahkan dari file cadangan.',
            ),
            if (key == null)
              const CircularProgressIndicator()
            else ...[
              const SizedBox(height: 20),
              Text('ID kunci: ${key!.id}'),
              SelectableText(
                key!.code,
                style: const TextStyle(fontSize: 22, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 20),
              ActionButton(
                saved ? 'Simpan kartu lagi' : 'Simpan file kartu kunci',
                secondary: true,
                onPressed: busy ? null : saveCard,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: outside,
                onChanged: busy ? null : (v) => setState(() => outside = v!),
                title: const Text(
                  'Kartu sudah disimpan di luar HP ini, atau difoto/dicetak keluarga.',
                ),
              ),
              ActionButton(
                'Periksa kunci dari salinan',
                onPressed: outside && !busy ? verify : null,
              ),
            ],
            if (error != null) Notice(error!, error: true),
          ],
        ),
      ),
    ),
  );
}

class KeyInputScreen extends StatefulWidget {
  final String title;
  final String? expectedId;
  const KeyInputScreen({super.key, required this.title, this.expectedId});
  @override
  State<KeyInputScreen> createState() => _KeyInputScreenState();
}

class _KeyInputScreenState extends State<KeyInputScreen> {
  final code = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  Future<void> check(String input) async {
    final key = await BackupKey.parse(input);
    if (widget.expectedId != null && key.id != widget.expectedId) {
      throw const BookError(
        'Kunci tidak cocok. Periksa salinan kartu yang baru disimpan.',
      );
    }
    if (mounted) Navigator.pop(context, key);
  }

  Future<void> submit({bool file = false}) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (file) {
        final bytes = await AppScope.of(context).device
            .openFile(maxBytes: 4096);
        if (bytes != null) await check(utf8.decode(bytes));
      } else {
        await check(code.text);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is BookError ? e.message : 'Kartu kunci tidak dapat dibaca. Periksa file atau kode yang dimasukkan.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: PageBody(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Buka file kartu kunci, atau ketik kode dari foto/cetakan. Kunci lama tetap diperlukan untuk cadangan lama.',
          ),
          const SizedBox(height: 20),
          ActionButton(
            'Buka file kartu kunci',
            secondary: true,
            onPressed: busy ? null : () => submit(file: true),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: code,
            maxLines: 4,
            maxLength: 100,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'Kode kunci',
              alignLabelWithHint: true,
            ),
          ),
          if (error != null) Notice(error!, error: true),
          ActionButton('Periksa kunci', onPressed: busy ? null : submit),
        ],
      ),
    ),
  );
}
