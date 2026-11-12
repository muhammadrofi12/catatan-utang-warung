import 'package:flutter/material.dart';

import '../domain/book.dart';
import '../data/book_repository.dart';
import 'common.dart';
import 'ledger_screen.dart';

class EntryForm extends StatefulWidget {
  final String ledgerId;
  final EntryKind initialKind;
  final String? replaces;
  const EntryForm({
    super.key,
    required this.ledgerId,
    required this.initialKind,
    this.replaces,
  });
  @override
  State<EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<EntryForm> {
  final amount = TextEditingController();
  final note = TextEditingController();
  final reasonNote = TextEditingController();
  final form = GlobalKey<FormState>();
  final operation = newId();
  late String ledgerId;
  late EntryKind kind;
  late String date;
  String? reason;
  String? error;
  String? related;
  String? throughDate;
  bool loaded = false;
  bool dirty = false;
  bool busy = false;
  bool saved = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (loaded) return;
    final original = AppScope.of(context)
        .repository
        .book
        .entries[widget.replaces];
    ledgerId = widget.ledgerId;
    kind = original?.kind ?? widget.initialKind;
    date = original?.date ?? day(DateTime.now());
    if (original != null) {
      amount.text = money(original.amount).substring(2);
      note.text = original.note;
    }
    loaded = true;
  }

  @override
  void dispose() {
    amount.dispose();
    note.dispose();
    reasonNote.dispose();
    super.dispose();
  }

  EntryInput get input => EntryInput(
    ledgerId: ledgerId,
    kind: kind,
    amount: int.tryParse(amount.text.replaceAll('.', '')) ?? 0,
    date: date,
    note: note.text,
    replaces: widget.replaces,
    reason: reason,
    reasonNote: reasonNote.text,
  );
  void changed() => setState(() => dirty = true);

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final repo = AppScope.of(context).repository;
    setState(() {
      busy = true;
      error = null;
      related = null;
    });
    try {
      final preview = repo.preview(input);
      if (widget.replaces != null) {
        final old = repo.book.entries[widget.replaces]!;
        final l = preview.ledgers[ledgerId]!;
        if (!await confirm(
          context,
          'Simpan perbaikan?',
          '${money(old.amount)} pada ${displayDay(old.date)} diganti menjadi ${money(input.amount)} pada ${displayDay(date)}.\n\n${preview.people[l.personId]!.name}\nSisa setelah perbaikan: ${money(preview.balance(ledgerId))}.\n\nCatatan lama tetap ada di riwayat.',
          action: 'Simpan perbaikan',
        )) {
          if (mounted) setState(() => busy = false);
          return;
        }
      }
      await repo.saveEntry(input, operation);
      if (!mounted) return;
      setState(() {
        saved = true;
        busy = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(
            context,
            'Tersimpan. Sisa terbaru ${money(repo.book.balance(ledgerId))}.',
          );
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = safeError(e);
          related = e is BookError ? e.ledgerId : null;
          throughDate = e is BookError ? e.throughDate : null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = AppScope.of(context).repository.book;
    final l = b.ledgers[ledgerId];
    if (l == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Catatan tidak tersedia')),
        body: const Center(child: Text('Kembali dan pilih orang lagi.')),
      );
    }
    final p = b.people[l.personId]!;
    final old = b.entries[widget.replaces];
    final payable =
        b.balance(ledgerId) +
        (old?.ledgerId == ledgerId && old?.kind == EntryKind.payment
            ? old!.amount
            : 0);
    final projected =
        b.balance(ledgerId) -
        (old?.ledgerId == ledgerId ? old!.signed : 0) +
        (kind == EntryKind.payment ? -input.amount : input.amount);
    final title = widget.replaces != null
        ? 'Perbaiki catatan'
        : kind == EntryKind.opening
        ? 'Utang sebelumnya'
        : kind == EntryKind.payment
        ? l.category.payment
        : l.category.debt;
    return DirtyGuard(
      dirty: dirty && !saved,
      busy: busy,
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: PageBody(
          child: Form(
            key: form,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(p.name, style: Theme.of(context).textTheme.headlineMedium),
                if (p.note.isNotEmpty) Text(p.note),
                Text(l.category.title),
                const SizedBox(height: 12),
                Text('Sisa sekarang: ${money(b.balance(ledgerId))}'),
                const SizedBox(height: 24),
                if (widget.replaces != null && kind != EntryKind.opening) ...[
                  DropdownButtonFormField<String>(
                    initialValue: ledgerId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Nama tujuan'),
                    items: [
                      for (final target in b.ledgers.values.where(
                        (v) => v.category == l.category && !v.archived,
                      ))
                        DropdownMenuItem(
                          value: target.id,
                          child: Text(
                            '${b.people[target.personId]!.name}${b.people[target.personId]!.note.isEmpty ? '' : ' · ${b.people[target.personId]!.note}'}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: busy
                        ? null
                        : (value) => setState(() {
                            ledgerId = value!;
                            dirty = true;
                          }),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<EntryKind>(
                    initialValue: kind,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Jenis catatan',
                    ),
                    items: [
                      DropdownMenuItem(
                        value: EntryKind.debt,
                        child: Text(l.category.debt),
                      ),
                      DropdownMenuItem(
                        value: EntryKind.payment,
                        child: Text(l.category.payment),
                      ),
                    ],
                    onChanged: busy
                        ? null
                        : (value) => setState(() {
                            kind = value!;
                            dirty = true;
                          }),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: amount,
                  enabled: !busy,
                  keyboardType: TextInputType.number,
                  inputFormatters: [AmountFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Jumlah uang',
                    prefixText: 'Rp ',
                    helperText: 'Maksimal Rp999.999.999 per catatan',
                  ),
                  onChanged: (_) => changed(),
                  validator: (_) => input.amount < 1 || input.amount > maxAmount
                      ? 'Isi jumlah Rp1 sampai Rp999.999.999.'
                      : null,
                ),
                if (kind == EntryKind.payment) ...[
                  const SizedBox(height: 8),
                  ActionButton(
                    'Isi sejumlah sisa',
                    secondary: true,
                    onPressed: busy || payable < 1 || payable > maxAmount
                        ? null
                        : () => setState(() {
                            amount.text = money(payable).substring(2);
                            dirty = true;
                          }),
                  ),
                  if (payable > maxAmount)
                    const Notice(
                      'Sisa melebihi batas satu pembayaran. Catat pembayaran bertahap.',
                    ),
                ],
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          final now = DateTime.now();
                          final current = DateTime.parse(date);
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: current.isAfter(now) ? now : current,
                            firstDate: DateTime(1900),
                            lastDate: now,
                            helpText: 'Pilih tanggal catatan',
                            cancelText: 'Kembali',
                            confirmText: 'Pakai tanggal',
                          );
                          if (picked != null && mounted) {
                            setState(() {
                              date = day(picked);
                              dirty = true;
                            });
                          }
                        },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('Tanggal: ${displayDay(date)}'),
                ),
                if (kind == EntryKind.opening)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Jika tanggal asal tidak diketahui, gunakan tanggal mulai mencatat sebagai batas buku.',
                    ),
                  ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: note,
                  enabled: !busy,
                  maxLength: 300,
                  minLines: 2,
                  maxLines: 4,
                  onChanged: (_) => changed(),
                  decoration: const InputDecoration(
                    labelText: 'Keterangan (boleh kosong)',
                    hintText: 'Contoh: beras dan telur',
                  ),
                ),
                if (widget.replaces != null) ...[
                  const SizedBox(height: 16),
                  reasonField(
                    reason,
                    busy
                        ? null
                        : (v) => setState(() {
                            reason = v;
                            dirty = true;
                          }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonNote,
                    enabled: !busy,
                    maxLength: 300,
                    onChanged: (_) => changed(),
                    decoration: const InputDecoration(
                      labelText: 'Penjelasan alasan (boleh kosong)',
                    ),
                  ),
                ],
                if (input.amount > 0) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Sisa setelah disimpan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  MoneyText(projected),
                  const SizedBox(height: 8),
                  Text(
                    '${p.name} · ${kind == EntryKind.payment
                        ? l.category.payment
                        : kind == EntryKind.opening
                        ? 'Utang sebelumnya'
                        : l.category.debt}',
                  ),
                ],
                if (error != null)
                  Notice(
                    error!,
                    error: true,
                    action: related == null
                        ? null
                        : TextButton(
                            onPressed: () => visit(
                              context,
                              LedgerScreen(
                                ledgerId: related!,
                                paymentsOnly: true,
                                throughDate: throughDate,
                              ),
                            ),
                            child: const Text('Lihat pembayaran terkait'),
                          ),
                  ),
                const SizedBox(height: 24),
                ActionButton(
                  busy
                      ? 'Menyimpan…'
                      : widget.replaces == null
                      ? 'Simpan catatan'
                      : 'Simpan perbaikan',
                  onPressed: busy ? null : save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget reasonField(String? value, ValueChanged<String?>? onChanged) =>
    DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Alasan'),
      items: [
        for (final reason in reasons)
          DropdownMenuItem(value: reason, child: Text(reason)),
      ],
      onChanged: onChanged,
      validator: (v) => v == null ? 'Pilih salah satu alasan.' : null,
    );

class CancelEntryScreen extends StatefulWidget {
  final String entryId;
  const CancelEntryScreen({super.key, required this.entryId});
  @override
  State<CancelEntryScreen> createState() => _CancelEntryScreenState();
}

class _CancelEntryScreenState extends State<CancelEntryScreen> {
  final form = GlobalKey<FormState>();
  final note = TextEditingController();
  final operation = newId();
  String? reason;
  String? error;
  String? related;
  String? throughDate;
  bool busy = false;
  bool saved = false;
  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).repository;
    final e = repo.book.entries[widget.entryId];
    if (e == null) {
      return const Scaffold(
        body: Center(
          child: Text('Catatan tidak tersedia. Kembali ke beranda.'),
        ),
      );
    }
    final ledger = repo.book.ledgers[e.ledgerId]!;
    return DirtyGuard(
      dirty: !saved && (reason != null || note.text.isNotEmpty),
      busy: busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Batalkan catatan')),
        body: PageBody(
          child: Form(
            key: form,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  repo.book.people[ledger.personId]!.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(displayDay(e.date)),
                MoneyText(e.amount),
                const SizedBox(height: 16),
                const Text(
                  'Catatan tetap terlihat dalam riwayat, tetapi tidak lagi dihitung ke saldo.',
                ),
                const SizedBox(height: 24),
                reasonField(
                  reason,
                  busy ? null : (v) => setState(() => reason = v),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: note,
                  enabled: !busy,
                  maxLength: 300,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Penjelasan (boleh kosong)',
                  ),
                ),
                Text(
                  'Sisa setelah pembatalan: ${money(repo.book.balance(e.ledgerId) - e.signed)}',
                ),
                if (error != null)
                  Notice(
                    error!,
                    error: true,
                    action: related == null
                        ? null
                        : TextButton(
                            onPressed: () => visit(
                              context,
                              LedgerScreen(
                                ledgerId: related!,
                                paymentsOnly: true,
                                throughDate: throughDate,
                              ),
                            ),
                            child: const Text('Lihat pembayaran terkait'),
                          ),
                  ),
                const SizedBox(height: 24),
                ActionButton(
                  busy ? 'Menyimpan…' : 'Batalkan catatan ini',
                  onPressed: busy
                      ? null
                      : () async {
                          if (!form.currentState!.validate()) return;
                          if (!await confirm(
                            context,
                            'Batalkan catatan ini?',
                            'Nominal ${money(e.amount)} tidak lagi dihitung.\nSisa setelah pembatalan: ${money(repo.book.balance(e.ledgerId) - e.signed)}.',
                            action: 'Ya, batalkan catatan',
                          )) {
                            return;
                          }
                          if (!mounted) return;
                          setState(() {
                            busy = true;
                            error = null;
                          });
                          try {
                            await repo.cancelEntry(
                              e.id,
                              reason!,
                              note.text,
                              operation,
                            );
                            if (!mounted) return;
                            setState(() {
                              busy = false;
                              saved = true;
                            });
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                Navigator.pop(
                                  context,
                                  'Pembatalan tersimpan. Riwayat tetap tersedia.',
                                );
                              }
                            });
                          } catch (e) {
                            if (mounted) {
                              setState(() {
                                busy = false;
                                error = safeError(e);
                                related = e is BookError ? e.ledgerId : null;
                                throughDate = e is BookError
                                    ? e.throughDate
                                    : null;
                              });
                            }
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
