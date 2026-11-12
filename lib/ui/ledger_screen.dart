import 'package:flutter/material.dart';

import '../domain/book.dart';
import '../data/book_repository.dart';
import 'common.dart';
import 'people.dart';
import 'entry_form.dart';

class LedgerScreen extends StatefulWidget {
  final String ledgerId;
  final bool paymentsOnly;
  final String? throughDate;
  const LedgerScreen({
    super.key,
    required this.ledgerId,
    this.paymentsOnly = false,
    this.throughDate,
  });
  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  String? message;
  bool busy = false;
  Future<void> act(Future<void> Function() action, String success) async {
    setState(() => busy = true);
    try {
      await action();
      if (mounted) setState(() => message = success);
    } catch (e) {
      if (mounted) setState(() => message = safeError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> form(EntryKind kind, {String? replaces}) async {
    final result = await visit<String>(
      context,
      EntryForm(
        ledgerId: widget.ledgerId,
        initialKind: kind,
        replaces: replaces,
      ),
    );
    if (mounted && result != null) setState(() => message = result);
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    final b = repo.book;
    final l = b.ledgers[widget.ledgerId];
    if (l == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Catatan')),
        body: const PageBody(
          child: Text(
            'Catatan sudah dihapus atau dipulihkan. Kembali ke beranda.',
          ),
        ),
      );
    }
    final p = b.people[l.personId]!;
    final history = b
        .history(l.id)
        .reversed
        .where(
          (e) =>
              !widget.paymentsOnly ||
              (e.kind == EntryKind.payment &&
                  (widget.throughDate == null ||
                      e.date.compareTo(widget.throughDate!) <= 0)),
        )
        .toList();
    final running = b.runningBalances(l.id);
    final colors = Theme.of(context).colorScheme;
    final palette = WarungPalette.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.paymentsOnly
              ? 'Pembayaran terkait'
              : 'Catatan ${l.category.person}',
        ),
      ),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconBadge(
                        l.category == Category.customer
                            ? Icons.person_outline_rounded
                            : Icons.storefront_outlined,
                        background: colors.surface,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          p.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (p.note.isNotEmpty) Text(p.note),
                  const SizedBox(height: 8),
                  Text(l.category.title),
                  const SizedBox(height: 24),
                  const Text('Sisa belum dibayar'),
                  MoneyText(b.balance(l.id), color: colors.onPrimaryContainer),
                  if (b.balance(l.id) == 0)
                    Text(
                      'Lunas',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: palette.payment,
                      ),
                    ),
                ],
              ),
            ),
            if (message != null) Notice(message!),
            if (l.archived)
              Notice(
                'Catatan ini diarsipkan. Aktifkan untuk mencatat kembali.',
                action: TextButton(
                  onPressed: busy
                      ? null
                      : () => act(
                          () => repo.archive(l.id, false, newId()),
                          'Catatan kembali aktif.',
                        ),
                  child: const Text('Aktifkan catatan'),
                ),
              )
            else if (!widget.paymentsOnly) ...[
              const SizedBox(height: 24),
              ActionButton(
                l.category.debt,
                icon: Icons.add_rounded,
                onPressed: busy ? null : () => form(EntryKind.debt),
              ),
              const SizedBox(height: 12),
              ActionButton(
                l.category.payment,
                icon: Icons.payments_outlined,
                secondary: true,
                onPressed: busy || b.balance(l.id) == 0
                    ? null
                    : () => form(EntryKind.payment),
              ),
              if (!repo.hasHistory(l.id))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextButton(
                    onPressed: () => form(EntryKind.opening),
                    child: const Text('Masukkan utang sebelumnya'),
                  ),
                ),
            ],
            const SizedBox(height: 28),
            Text(
              widget.paymentsOnly
                  ? 'Periksa pembayaran berikut'
                  : 'Riwayat catatan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (widget.paymentsOnly)
              Notice(
                '${widget.throughDate == null ? '' : 'Pembayaran hingga ${displayDay(widget.throughDate!)}. '}Pembayaran dicatat terhadap saldo keseluruhan. Jika pembayaran perlu dibatalkan sementara, perbaiki utangnya lalu catat ulang pembayaran yang benar. Setiap langkah tetap tercatat; tidak ada pembatalan otomatis.',
              ),
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Belum ada transaksi. Tambahkan utang pertama atau utang sebelumnya.',
                ),
              ),
            for (final e in history)
              _entryTile(context, b, l, e, running[e.id]),
            if (!widget.paymentsOnly) ...[
              const SizedBox(height: 24),
              const Divider(),
              TextButton(
                onPressed: busy
                    ? null
                    : () => visit(
                        context,
                        PersonForm(category: l.category, personId: p.id),
                      ),
                child: const Text('Ubah nama & pembeda'),
              ),
              if (!l.archived && b.balance(l.id) == 0)
                TextButton(
                  onPressed: busy
                      ? null
                      : () async {
                          if (await confirm(
                            context,
                            'Arsipkan catatan?',
                            'Riwayat ${p.name} tetap disimpan. Kategori lain tidak ikut diarsipkan.',
                            action: 'Arsipkan',
                          )) {
                            await act(
                              () => repo.archive(l.id, true, newId()),
                              'Catatan diarsipkan.',
                            );
                          }
                        },
                  child: const Text('Arsipkan catatan ini'),
                ),
              if (!b.entries.values.any(
                (e) => b.ledgers[e.ledgerId]?.personId == p.id,
              ))
                TextButton(
                  onPressed: busy
                      ? null
                      : () async {
                          if (!await confirm(
                            context,
                            'Hapus nama yang salah dibuat?',
                            '${p.name} belum mempunyai transaksi. Seluruh kategori kosong milik orang ini akan dihapus.',
                            action: 'Hapus nama',
                          )) {
                            return;
                          }
                          await act(
                            () => repo.deletePerson(p.id, newId()),
                            'Nama dihapus.',
                          );
                          if (context.mounted &&
                              !repo.book.people.containsKey(p.id)) {
                            Navigator.pop(context);
                          }
                        },
                  child: const Text('Hapus nama tanpa riwayat'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _entryTile(
    BuildContext context,
    Book b,
    Ledger l,
    Entry e,
    int? balance,
  ) {
    final audits = b.audits.values.where((a) => a.entryId == e.id).toList();
    final audit = audits.isEmpty ? null : audits.first;
    final label = e.kind == EntryKind.opening
        ? 'Utang sebelumnya'
        : e.kind == EntryKind.payment
        ? l.category.payment
        : 'Tambahan utang';
    final colors = Theme.of(context).colorScheme;
    final palette = WarungPalette.of(context);
    final payment = e.kind == EntryKind.payment;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(
                !e.active
                    ? Icons.history_rounded
                    : payment
                    ? Icons.payments_outlined
                    : e.kind == EntryKind.opening
                    ? Icons.menu_book_outlined
                    : Icons.receipt_long_outlined,
                foreground: !e.active
                    ? colors.onSurfaceVariant
                    : payment
                    ? palette.payment
                    : colors.onPrimaryContainer,
                background: !e.active
                    ? colors.surfaceContainerLow
                    : payment
                    ? palette.paymentSurface
                    : colors.primaryContainer,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final description = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayDay(e.date),
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    );
                    final amount = MoneyText(
                      e.amount,
                      large: false,
                      color: !e.active
                          ? colors.onSurfaceVariant
                          : payment
                          ? palette.payment
                          : colors.onSurface,
                    );
                    return constraints.maxWidth >= 420 &&
                            MediaQuery.textScalerOf(context).scale(18) <= 24
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: description),
                              const SizedBox(width: 16),
                              amount,
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              description,
                              const SizedBox(height: 8),
                              amount,
                            ],
                          );
                  },
                ),
              ),
            ],
          ),
          if (e.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(e.note),
            ),
          if (balance != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Sisa setelah catatan: ${money(balance)}'),
            ),
          if (!e.active)
            Text(
              '${audit?.replacementId == null ? 'Dibatalkan' : 'Diperbaiki'} — tidak dihitung ke saldo',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (e.previousId != null)
            const Text(
              'Catatan pengganti; nilai sebelumnya tetap ada di riwayat.',
            ),
          if (audit != null) ...[
            Text('Alasan: ${audit.reason}'),
            if (audit.note.isNotEmpty) Text(audit.note),
          ],
          if (e.active && !l.archived)
            Wrap(
              spacing: 12,
              children: [
                TextButton(
                  onPressed: busy ? null : () => form(e.kind, replaces: e.id),
                  child: const Text('Perbaiki catatan'),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () async {
                          final result = await visit<String>(
                            context,
                            CancelEntryScreen(entryId: e.id),
                          );
                          if (mounted && result != null) {
                            setState(() => message = result);
                          }
                        },
                  child: const Text('Batalkan catatan'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
