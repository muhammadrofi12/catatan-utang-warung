import 'dart:convert';

const maxAmount = 999999999;
const maxBalance = 999999999999999;
const maxRecords = 200000;
const reasons = [
  'Salah ketik nominal',
  'Salah pilih orang',
  'Salah tanggal',
  'Salah jenis catatan',
  'Tercatat dua kali',
  'Lainnya',
];

enum Category { customer, supplier }

enum EntryKind { opening, debt, payment }

extension CategoryText on Category {
  String get title => this == Category.customer
      ? 'Pelanggan belum bayar'
      : 'Warung belum bayar';
  String get person => this == Category.customer ? 'pelanggan' : 'pemasok';
  String get debt => this == Category.customer
      ? 'Tambah utang pelanggan'
      : 'Tambah utang warung';
  String get payment =>
      this == Category.customer ? 'Pelanggan bayar' : 'Warung bayar';
}

String money(int value) {
  final digits = value.abs().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );
  return '${value < 0 ? '-' : ''}Rp$digits';
}

String day(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
String displayDay(String value) {
  final d = DateTime.parse(value);
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

String normalized(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

class BookError implements Exception {
  final String message;
  final String? ledgerId;
  final String? throughDate;
  const BookError(this.message, {this.ledgerId, this.throughDate});
  @override
  String toString() => message;
}

Map<String, dynamic> object(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const BookError('Format catatan tidak valid.');
  }
  return value;
}

String string(
  Map<String, dynamic> value,
  String key, {
  int max = 300,
  bool empty = false,
}) {
  final v = value[key];
  if (v is! String || v.length > max || (!empty && v.trim().isEmpty)) {
    throw const BookError('Isi catatan tidak lengkap atau terlalu panjang.');
  }
  return v;
}

int integer(
  Map<String, dynamic> value,
  String key, {
  int min = 0,
  int max = maxBalance,
}) {
  final v = value[key];
  if (v is! int || v < min || v > max) {
    throw const BookError('Angka dalam catatan tidak valid.');
  }
  return v;
}

bool boolean(Map<String, dynamic> value, String key) {
  if (value[key] is! bool) throw const BookError('Status catatan tidak valid.');
  return value[key] as bool;
}

String identifier(Map<String, dynamic> value, String key) {
  final v = string(value, key, max: 36);
  if (!RegExp(r'^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$')
      .hasMatch(v)) {
    throw const BookError('Identitas catatan tidak valid.');
  }
  return v;
}

String validDay(String value) {
  final d = DateTime.tryParse(value);
  if (d == null || value.length != 10 || day(d) != value || d.year < 1900) {
    throw const BookError('Tanggal catatan tidak valid.');
  }
  return value;
}

class Person {
  final String id;
  String name;
  String note;
  Person(this.id, this.name, this.note);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'note': note};
  factory Person.fromJson(Map<String, dynamic> j) => Person(
    identifier(j, 'id'),
    string(j, 'name', max: 80),
    string(j, 'note', max: 80, empty: true),
  );
}

class Ledger {
  final String id;
  final String personId;
  final Category category;
  bool archived;
  String? openingDate;
  Ledger(
    this.id,
    this.personId,
    this.category, {
    this.archived = false,
    this.openingDate,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'personId': personId,
    'category': category.name,
    'archived': archived,
    'openingDate': openingDate,
  };
  factory Ledger.fromJson(Map<String, dynamic> j) {
    if (!Category.values.any((e) => e.name == j['category'])) {
      throw const BookError('Kategori tidak dikenal.');
    }
    final date = j['openingDate'];
    if (date != null && date is! String) {
      throw const BookError('Tanggal awal tidak valid.');
    }
    return Ledger(
      identifier(j, 'id'),
      identifier(j, 'personId'),
      Category.values.byName(j['category'] as String),
      archived: boolean(j, 'archived'),
      openingDate: date == null ? null : validDay(date as String),
    );
  }
}

class Entry {
  final String id;
  final String operationId;
  final String ledgerId;
  final EntryKind kind;
  final int amount;
  final String date;
  final String created;
  final int order;
  final String note;
  final String? previousId;
  bool active;
  Entry({
    required this.id,
    required this.operationId,
    required this.ledgerId,
    required this.kind,
    required this.amount,
    required this.date,
    required this.created,
    required this.order,
    this.note = '',
    this.previousId,
    this.active = true,
  });
  int get signed => kind == EntryKind.payment ? -amount : amount;
  Map<String, dynamic> toJson() => {
    'id': id,
    'operationId': operationId,
    'ledgerId': ledgerId,
    'kind': kind.name,
    'amount': amount,
    'date': date,
    'created': created,
    'order': order,
    'note': note,
    'previousId': previousId,
    'active': active,
  };
  factory Entry.fromJson(Map<String, dynamic> j) {
    if (!EntryKind.values.any((e) => e.name == j['kind'])) {
      throw const BookError('Jenis catatan tidak dikenal.');
    }
    final created = string(j, 'created', max: 40);
    if (DateTime.tryParse(created) == null) {
      throw const BookError('Waktu pencatatan tidak valid.');
    }
    return Entry(
      id: identifier(j, 'id'),
      operationId: identifier(j, 'operationId'),
      ledgerId: identifier(j, 'ledgerId'),
      kind: EntryKind.values.byName(j['kind'] as String),
      amount: integer(j, 'amount', min: 1, max: maxAmount),
      date: validDay(string(j, 'date', max: 10)),
      created: created,
      order: integer(j, 'order', min: 1),
      note: string(j, 'note', empty: true),
      previousId: j['previousId'] == null ? null : identifier(j, 'previousId'),
      active: boolean(j, 'active'),
    );
  }
}

class Audit {
  final String id;
  final String operationId;
  final String entryId;
  final String? replacementId;
  final String reason;
  final String note;
  final String created;
  Audit(
    this.id,
    this.operationId,
    this.entryId,
    this.replacementId,
    this.reason,
    this.note,
    this.created,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'operationId': operationId,
    'entryId': entryId,
    'replacementId': replacementId,
    'reason': reason,
    'note': note,
    'created': created,
  };
  factory Audit.fromJson(Map<String, dynamic> j) {
    final reason = string(j, 'reason', max: 80);
    final created = string(j, 'created', max: 40);
    if (!reasons.contains(reason) || DateTime.tryParse(created) == null) {
      throw const BookError('Riwayat perbaikan tidak valid.');
    }
    return Audit(
      identifier(j, 'id'),
      identifier(j, 'operationId'),
      identifier(j, 'entryId'),
      j['replacementId'] == null ? null : identifier(j, 'replacementId'),
      reason,
      string(j, 'note', empty: true),
      created,
    );
  }
}

class Book {
  final String id;
  String name;
  int revision;
  int nextOrder;
  String? firstChange;
  final Map<String, Person> people;
  final Map<String, Ledger> ledgers;
  final Map<String, Entry> entries;
  final Map<String, Audit> audits;
  final Map<String, String> operations;
  Book(
    this.id, {
    this.name = 'Warung saya',
    this.revision = 0,
    this.nextOrder = 1,
    this.firstChange,
    Map<String, Person>? people,
    Map<String, Ledger>? ledgers,
    Map<String, Entry>? entries,
    Map<String, Audit>? audits,
    Map<String, String>? operations,
  }) : people = people ?? {},
       ledgers = ledgers ?? {},
       entries = entries ?? {},
       audits = audits ?? {},
       operations = operations ?? {};

  List<Entry> history(String ledgerId, {bool activeOnly = false}) {
    final result = entries.values
        .where((e) => e.ledgerId == ledgerId && (!activeOnly || e.active))
        .toList();
    result.sort(compareEntries);
    return result;
  }

  static int compareEntries(Entry a, Entry b) {
    final date = a.date.compareTo(b.date);
    if (date != 0) return date;
    if ((a.kind == EntryKind.opening) != (b.kind == EntryKind.opening)) {
      return a.kind == EntryKind.opening ? -1 : 1;
    }
    final order = a.order.compareTo(b.order);
    return order == 0 ? a.id.compareTo(b.id) : order;
  }

  int balance(String ledgerId) => entries.values
      .where((e) => e.active && e.ledgerId == ledgerId)
      .fold(0, (sum, e) => sum + e.signed);
  int total(Category category) {
    final ids = ledgers.values
        .where((l) => l.category == category)
        .map((l) => l.id)
        .toSet();
    return entries.values
        .where((e) => e.active && ids.contains(e.ledgerId))
        .fold(0, (sum, e) => sum + e.signed);
  }

  Map<String, int> runningBalances(String ledgerId) {
    var sum = 0;
    return {
      for (final e in history(ledgerId, activeOnly: true))
        e.id: (sum += e.signed),
    };
  }

  Map<String, dynamic> toJson() => {
    'schema': 1,
    'id': id,
    'name': name,
    'revision': revision,
    'nextOrder': nextOrder,
    'firstChange': firstChange,
    'people': people.values.map((e) => e.toJson()).toList(),
    'ledgers': ledgers.values.map((e) => e.toJson()).toList(),
    'entries': entries.values.map((e) => e.toJson()).toList(),
    'audits': audits.values.map((e) => e.toJson()).toList(),
    'operations': operations,
  };
  Book copy() => Book.fromJson(toJson());
  factory Book.fromJson(Map<String, dynamic> j) {
    if (j['schema'] != 1) {
      throw const BookError('Versi catatan belum didukung. Perbarui aplikasi.');
    }
    List<dynamic> list(String key) {
      final v = j[key];
      if (v is! List || v.length > maxRecords) {
        throw const BookError('Jumlah catatan melewati batas pemulihan.');
      }
      return v;
    }

    Map<String, T> records<T>(
      String key,
      T Function(Map<String, dynamic>) parse,
      String Function(T) id,
    ) {
      final result = <String, T>{};
      for (final raw in list(key)) {
        final item = parse(object(raw));
        if (result.containsKey(id(item))) {
          throw const BookError('Ada identitas catatan yang terduplikasi.');
        }
        result[id(item)] = item;
      }
      return result;
    }

    final ops = object(j['operations']);
    if (ops.length > maxRecords * 3 || ops.values.any((v) => v is! String)) {
      throw const BookError('Daftar operasi tidak valid.');
    }
    final first = j['firstChange'];
    if (first != null &&
        (first is! String || DateTime.tryParse(first) == null)) {
      throw const BookError('Waktu awal tidak valid.');
    }
    return Book(
      identifier(j, 'id'),
      name: string(j, 'name', max: 80),
      revision: integer(j, 'revision'),
      nextOrder: integer(j, 'nextOrder', min: 1),
      firstChange: first as String?,
      people: records('people', Person.fromJson, (p) => p.id),
      ledgers: records('ledgers', Ledger.fromJson, (l) => l.id),
      entries: records('entries', Entry.fromJson, (e) => e.id),
      audits: records('audits', Audit.fromJson, (a) => a.id),
      operations: Map<String, String>.from(ops),
    );
  }

  void validate() {
    if (people.length + ledgers.length + entries.length + audits.length >
        maxRecords) {
      throw const BookError('Jumlah catatan melewati batas pemulihan.');
    }
    final groups = <String, List<Entry>>{
      for (final l in ledgers.values) l.id: [],
    };
    final unique = <String>{};
    for (final l in ledgers.values) {
      if (!people.containsKey(l.personId) ||
          !unique.add('${l.personId}/${l.category.name}')) {
        throw const BookError('Relasi orang dan kategori tidak valid.');
      }
    }
    for (final e in entries.values) {
      if (!groups.containsKey(e.ledgerId) ||
          e.order >= nextOrder ||
          e.amount < 1 ||
          e.amount > maxAmount) {
        throw const BookError('Relasi atau nominal transaksi tidak valid.');
      }
      if (e.previousId != null &&
          (!entries.containsKey(e.previousId) ||
              entries[e.previousId]!.active)) {
        throw const BookError('Rantai perbaikan tidak valid.');
      }
      groups[e.ledgerId]!.add(e);
    }
    final totals = <Category, int>{for (final c in Category.values) c: 0};
    for (final l in ledgers.values) {
      final all = groups[l.id]!;
      final active = all.where((e) => e.active).toList()..sort(compareEntries);
      if (all.any((e) => e.kind == EntryKind.opening) !=
          (l.openingDate != null)) {
        throw const BookError('Tanggal batas saldo awal tidak sesuai.');
      }
      if (active.where((e) => e.kind == EntryKind.opening).length > 1) {
        throw const BookError('Saldo awal tidak boleh dicatat dua kali.');
      }
      var sum = 0;
      for (final e in active) {
        if (l.openingDate != null &&
            (e.date.compareTo(l.openingDate!) < 0 ||
                (e.kind == EntryKind.opening && e.date != l.openingDate))) {
          throw const BookError(
            'Tanggal catatan lebih awal dari batas saldo awal.',
          );
        }
        sum += e.signed;
        if (sum < 0) {
          throw BookError(
            'Jumlah bayar pada ${displayDay(e.date)} lebih besar dari sisa ${money(sum - e.signed)}. Periksa pembayaran terkait terlebih dahulu.',
            ledgerId: l.id,
            throughDate: e.date,
          );
        }
        if (sum > maxBalance) {
          throw const BookError(
            'Total sisa melewati batas Rp999.999.999.999.999.',
          );
        }
      }
      if (l.archived && sum != 0) {
        throw const BookError(
          'Catatan yang belum lunas tidak dapat diarsipkan.',
        );
      }
      totals[l.category] = totals[l.category]! + sum;
    }
    if (totals.values.any((v) => v > maxBalance)) {
      throw const BookError('Total kategori melewati batas saldo.');
    }
    final invalidated = <String>{};
    final replacements = <String>{};
    for (final a in audits.values) {
      final old = entries[a.entryId];
      if (old == null || old.active || !invalidated.add(a.entryId)) {
        throw const BookError('Riwayat pembatalan tidak sesuai.');
      }
      if (a.replacementId != null) {
        final replacement = entries[a.replacementId];
        if (replacement == null ||
            replacement.previousId != old.id ||
            !replacements.add(replacement.id) ||
            replacement.operationId != a.operationId ||
            ledgers[replacement.ledgerId]!.category !=
                ledgers[old.ledgerId]!.category) {
          throw const BookError('Riwayat pengganti tidak sesuai.');
        }
      }
    }
    if (entries.values.any((e) => !e.active && !invalidated.contains(e.id))) {
      throw const BookError(
        'Catatan nonaktif tidak mempunyai riwayat pembatalan.',
      );
    }
    for (final e in entries.values.where((e) => e.previousId != null)) {
      if (!replacements.contains(e.id)) {
        throw const BookError('Pengganti tidak mempunyai riwayat koreksi.');
      }
      final seen = <String>{e.id};
      var prev = e.previousId;
      while (prev != null) {
        if (!seen.add(prev)) {
          throw const BookError('Rantai koreksi berulang tidak valid.');
        }
        prev = entries[prev]?.previousId;
      }
    }
  }

  String canonical() => jsonEncode(toJson());
}
