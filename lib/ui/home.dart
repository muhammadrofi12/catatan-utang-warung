import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/book.dart';
import '../data/book_repository.dart';
import 'common.dart';
import 'people.dart';
import 'backup_screen.dart';
import 'ledger_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final b = app.repository.book;
    final palette = WarungPalette.of(context);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Catatan Warung'),
        centerTitle: false,
        backgroundColor: palette.header,
        foregroundColor: palette.onHeader,
        titleTextStyle: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: palette.onHeader),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          IconButton(
            tooltip: 'Pengaturan',
            onPressed: () => visit(context, const SettingsScreen()),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: PageBody(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: palette.header,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.name,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(color: palette.onHeader),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pilih catatan yang ingin dibuka.',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: palette.onHeader),
                  ),
                ],
              ),
            ),
            ColoredBox(
              color: palette.header,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final category in Category.values) ...[
                      _CategoryTile(category, b.total(category)),
                      if (category == Category.customer) const Divider(),
                    ],
                    const SizedBox(height: 12),
                    if (b.people.isEmpty) ...[
                      ActionButton(
                        'Tambah pelanggan pertama',
                        onPressed: () async {
                          final id = await visit<String>(
                            context,
                            const PersonForm(category: Category.customer),
                          );
                          if (id != null && context.mounted) {
                            await visit(context, LedgerScreen(ledgerId: id));
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (app.backup.reminder(b, DateTime.now()))
                      const Notice(
                        'Sudah waktunya membuat cadangan. Minta bantuan keluarga untuk menyimpan salinan di luar HP.',
                      ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(
                          Icons.backup_outlined,
                          color: colors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Cadangan catatan',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(app.backup.description(b)),
                    const SizedBox(height: 16),
                    ActionButton(
                      'Buka cadangan & pemulihan',
                      secondary: true,
                      onPressed: () => visit(context, const BackupScreen()),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final int amount;
  const _CategoryTile(this.category, this.amount);
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final badge = IconBadge(
      category == Category.customer
          ? Icons.people_outline_rounded
          : Icons.storefront_outlined,
      foreground: category == Category.customer
          ? colors.onPrimaryContainer
          : colors.onTertiaryContainer,
      background: category == Category.customer
          ? colors.primaryContainer
          : colors.tertiaryContainer,
    );
    final chevron = Icon(
      Icons.chevron_right_rounded,
      color: colors.primary,
      size: 24,
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(category.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        MoneyText(amount),
        const SizedBox(height: 4),
        Text(
          'Total sisa belum dibayar',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
      ],
    );
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => visit(context, PeopleScreen(category: category)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: MediaQuery.textScalerOf(context).scale(20) > 28
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [badge, const Spacer(), chevron]),
                    const SizedBox(height: 16),
                    details,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    badge,
                    const SizedBox(width: 16),
                    Expanded(child: details),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: chevron,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final name = TextEditingController();
  bool initialized = false;
  bool busy = false;
  String? message;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      name.text = AppScope.of(context).repository.book.name;
      initialized = true;
    }
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pengaturan')),
    body: PageBody(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: name,
            maxLength: 80,
            decoration: const InputDecoration(labelText: 'Nama warung'),
          ),
          const SizedBox(height: 16),
          ActionButton(
            busy ? 'Menyimpan…' : 'Simpan nama warung',
            onPressed: busy
                ? null
                : () async {
                    final repository = AppScope.of(context).repository;
                    setState(() {
                      busy = true;
                      message = null;
                    });
                    try {
                      await repository.renameBook(name.text, newId());
                      if (mounted) {
                        setState(() => message = 'Nama warung tersimpan.');
                      }
                    } catch (e) {
                      if (mounted) setState(() => message = safeError(e));
                    } finally {
                      if (mounted) setState(() => busy = false);
                    }
                  },
          ),
          if (message != null) Notice(message!),
          const SizedBox(height: 24),
          ActionButton(
            'Cadangan & pemulihan',
            secondary: true,
            onPressed: () => visit(context, const BackupScreen()),
          ),
          const SizedBox(height: 24),
          Text(
            'Privasi catatan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const Text(
            'Catatan tersimpan di HP ini. Tidak ada akun aplikasi, iklan, atau pengiriman ke server aplikasi. Sistem Android dapat mencadangkan data sesuai pengaturan backup perangkat.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Gunakan kunci layar HP untuk menjaga privasi. Orang yang dapat membuka HP juga dapat membuka catatan ini.',
          ),
          const SizedBox(height: 24),
          Text(
            'Tentang aplikasi',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const Text(
            'Catatan Warung 1.0.0\nUtang pelanggan dan utang warung dicatat terpisah. Total sisa bukan laba atau saldo kas.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Sebelum menghapus aplikasi atau mengganti HP, buat cadangan dan pastikan keluarga bisa memulihkannya.',
          ),
        ],
      ),
    ),
  );
}
