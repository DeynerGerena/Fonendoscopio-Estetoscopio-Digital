import 'dart:typed_data';

const int kFs = 8000;

class Recording {
  final String id;
  final DateTime date;
  final Int16List samples;
  final Uint8List motion; // 1 byte por muestra (1 = movimiento)
  Recording(this.id, this.date, this.samples, this.motion);
  double get seconds => samples.length / kFs;
}

class RecMeta {
  final String id;
  final DateTime date;
  final double seconds;
  RecMeta(this.id, this.date, this.seconds);
  Map<String, dynamic> toJson() => {'id': id, 'date': date.toIso8601String(), 's': seconds};
  factory RecMeta.fromJson(Map<String, dynamic> j) =>
      RecMeta(j['id'], DateTime.parse(j['date']), (j['s'] as num).toDouble());
}

class Patient {
  final String id;
  String name;
  int age;
  String notes;
  List<RecMeta> recs;
  Patient(this.id, this.name, this.age, this.notes, [List<RecMeta>? r]) : recs = r ?? [];
  DateTime? get last => recs.isEmpty ? null : recs.first.date;
  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'age': age, 'notes': notes, 'recs': recs.map((e) => e.toJson()).toList()};
  factory Patient.fromJson(Map<String, dynamic> j) => Patient(j['id'], j['name'], j['age'], j['notes'] ?? '',
      (j['recs'] as List).map((e) => RecMeta.fromJson(e as Map<String, dynamic>)).toList());
}
