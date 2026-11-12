import 'package:flutter/material.dart';

import '../domain/book.dart';
import '../data/book_repository.dart';
import 'common.dart';
import 'ledger_screen.dart';

class PeopleScreen extends StatefulWidget {
  final Category category;
  const PeopleScreen({super.key, required this.category});
  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  String query = '';
  String filter = 'Belum lunas';
  @override
  Widget build(BuildContext context) {
    final b = AppScope.of(context).repository.book;
    final balances = <String, int>{};
    final recent = <String, String>{};
    for (final e in b.entries.values) {
      if (e.active) {
        balances.update(
          e.ledgerId,
          (v) => v + e.signed,
          ifAbsent: () => e.signed,
        );
      }
      if (e.created.compareTo(recent[e.ledgerId] ?? '') > 0) {
        recent[e.ledgerId] = e.created;
      }
    }
    final list =
        b.ledgers.values.where((l) {
          final p = b.people[l.personId]!;
          return l.category == widget.category &&
              (filter == 'Arsip' ? l.archived : !l.archived) &&
              (filter != 'Belum lunas' || (balances[l.id] ?? 0) > 0) &&
              normalized('${p.name} ${p.note}').contains(normalized(query));
        }).toList()..sort((a, z) {
          final byTime = (recent[z.id] ?? '').compareTo(recent[a.id] ?? '');
          if (byTime != 0) return byTime;
          final byName = b.people[a.personId]!.name.compareTo(
            b.people[z.personId]!.name,
          );
          return byName == 0 ? a.id.compareTo(z.id) : byName;
        });
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category.person == 'pelanggan' ? 'Pelanggan' : 'Pemasok',
        ),
      ),
      body: PageBody(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) => setState(() => query = value),
                      decoration: InputDecoration(
                        labelText: 'Cari ${widget.category.person}',
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final f in ['Belum lunas', 'Semua', 'Arsip'])
                            ChoiceChip(
                              label: Text(f),
                              showCheckmark: false,
                              labelStyle: TextStyle(
                                color: f == filter
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              selected: f == filter,
                              onSelected: (_) => setState(() => filter = f),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (list.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Icon(
                        Icons.people_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        query.isNotEmpty
                            ? 'Nama belum ditemukan'
                            : filter == 'Belum lunas'
                            ? 'Belum ada utang yang tercatat'
                            : 'Belum ada catatan di sini',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        query.isNotEmpty
                            ? 'Coba nama atau pembeda lain.'
                            : 'Tambahkan ${widget.category.person}, atau buka “Semua” untuk melihat catatan yang sudah lunas.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final l = list[index];
                    final p = b.people[l.personId]!;
                    final balance = balances[l.id] ?? 0;
                    return ListTile(
                      leading: IconBadge(
                        widget.category == Category.customer
                            ? Icons.person_outline_rounded
                            : Icons.storefront_outlined,
                        background: widget.category == Category.customer
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.tertiaryContainer,
                        foreground: widget.category == Category.customer
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                      titleAlignment: ListTileTitleAlignment.top,
                      horizontalTitleGap: 16,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 16,
                      ),
                      title: Text(
                        p.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p.note.isNotEmpty) Text(p.note),
                          const SizedBox(height: 8),
                          MoneyText(balance, large: false),
                          Text(
                            l.archived
                                ? 'Diarsipkan'
                                : balance == 0
                                ? 'Lunas'
                                : 'Sisa belum dibayar',
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => visit(context, LedgerScreen(ledgerId: l.id)),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ActionButton(
                'Tambah ${widget.category.person}',
                icon: Icons.add_rounded,
                onPressed: () async {
                  final id = await visit<String>(
                    context,
                    PersonForm(category: widget.category),
                  );
                  if (context.mounted && id != null) {
                    await visit(context, LedgerScreen(ledgerId: id));
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PersonForm extends StatefulWidget {
  final Category category;
  final String? personId;
  const PersonForm({super.key, required this.category, this.personId});
  @override
  State<PersonForm> createState() => _PersonFormState();
}

class _PersonFormState extends State<PersonForm> {
  final name = TextEditingController();
  final note = TextEditingController();
  final form = GlobalKey<FormState>();
  final operation = newId();
  bool loaded = false;
  bool busy = false;
  bool saved = false;
  String? error;
  String initialName = '';
  String initialNote = '';
  String? existingPerson;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!loaded) {
      final p = AppScope.of(context).repository.book.people[widget.personId];
      if (p != null) {
        name.text = initialName = p.name;
        note.text = initialNote = p.note;
      }
      loaded = true;
    }
  }

  @override
  void dispose() {
    name.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final repo = AppScope.of(context).repository;
    final duplicates = repo.book.people.values
        .where(
          (p) =>
              p.id != widget.personId &&
              normalized(p.name) == normalized(name.text),
        )
        .toList();
    if (existingPerson == null && duplicates.isNotEmpty) {
      if (!await confirm(
        context,
        'Nama yang sama sudah ada',
        'Pastikan ini orang yang berbeda. Tambahkan pembeda seperti “dekat masjid” agar tidak tertukar.',
        action: widget.personId == null
            ? 'Buat orang berbeda'
            : 'Simpan perubahan',
      )) {
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      String? id;
      if (widget.personId != null) {
        await repo.updatePerson(
          widget.personId!,
          name.text,
          note.text,
          operation,
        );
      } else {
        id = await repo.addPerson(
          name: name.text,
          note: note.text,
          category: widget.category,
          operationId: operation,
          existingPersonId: existingPerson,
        );
      }
      if (!mounted) return;
      setState(() {
        saved = true;
        busy = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, id);
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          error = safeError(e);
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final matches = widget.personId == null && name.text.trim().isNotEmpty
        ? AppScope.of(context).repository.book.people.values
              .where((p) => normalized(p.name).contains(normalized(name.text)))
              .take(5)
              .toList()
        : <Person>[];
    return DirtyGuard(
      dirty: !saved && (name.text != initialName || note.text != initialNote),
      busy: busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.personId == null
                ? 'Tambah ${widget.category.person}'
                : 'Ubah nama',
          ),
        ),
        body: PageBody(
          child: Form(
            key: form,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  widget.category.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: name,
                  enabled: !busy,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() => existingPerson = null),
                  decoration: const InputDecoration(
                    labelText: 'Nama atau panggilan',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Isi nama terlebih dahulu.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: note,
                  enabled: !busy && existingPerson == null,
                  maxLength: 80,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Pembeda (boleh kosong)',
                    hintText: 'Contoh: dekat masjid',
                  ),
                ),
                if (matches.isNotEmpty && existingPerson == null) ...[
                  const SizedBox(height: 12),
                  const Text('Orang yang sudah ada:'),
                  for (final p in matches)
                    ListTile(
                      title: Text(p.name),
                      subtitle: Text(p.note.isEmpty ? 'Tanpa pembeda' : p.note),
                      trailing: const Icon(Icons.person_add_alt_1),
                      onTap: () => setState(() {
                        existingPerson = p.id;
                        name.text = p.name;
                        note.text = p.note;
                      }),
                    ),
                ],
                if (existingPerson != null)
                  const Notice(
                    'Menggunakan orang yang sudah ada. Saldo pelanggan dan pemasok tetap terpisah.',
                  ),
                if (error != null) Notice(error!, error: true),
                const SizedBox(height: 24),
                ActionButton(
                  busy ? 'Menyimpan…' : 'Simpan nama',
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
