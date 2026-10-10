/// Plain data classes stored in Hive as Maps (no code generation needed).

class Profile {
  String name;
  String diabetesType; // t1 | t2 | gest | other
  int? yearDiagnosed;
  String treatment; // insulin | tablets | diet
  bool pastUlcer;
  bool numbness;
  String doctorName;
  String doctorPhone; // international format, e.g. 21650123456
  String familyName;
  String familyPhone;
  int reminderHour;

  Profile({
    required this.name,
    this.diabetesType = 't2',
    this.yearDiagnosed,
    this.treatment = 'tablets',
    this.pastUlcer = false,
    this.numbness = false,
    this.doctorName = '',
    this.doctorPhone = '',
    this.familyName = '',
    this.familyPhone = '',
    this.reminderHour = 8,
  });

  /// Simplified foot-risk level for the UI (inspired by IWGDF categories; not a clinical grade).
  String get footRisk => pastUlcer ? 'high' : (numbness ? 'moderate' : 'low');

  Map<String, dynamic> toMap() => {
        'name': name, 'diabetesType': diabetesType, 'yearDiagnosed': yearDiagnosed, 'treatment': treatment,
        'pastUlcer': pastUlcer, 'numbness': numbness, 'doctorName': doctorName, 'doctorPhone': doctorPhone,
        'familyName': familyName, 'familyPhone': familyPhone, 'reminderHour': reminderHour,
      };

  factory Profile.fromMap(Map m) => Profile(
        name: m['name'] ?? '',
        diabetesType: m['diabetesType'] ?? 't2',
        yearDiagnosed: m['yearDiagnosed'],
        treatment: m['treatment'] ?? 'tablets',
        pastUlcer: m['pastUlcer'] ?? false,
        numbness: m['numbness'] ?? false,
        doctorName: m['doctorName'] ?? '',
        doctorPhone: m['doctorPhone'] ?? '',
        familyName: m['familyName'] ?? '',
        familyPhone: m['familyPhone'] ?? '',
        reminderHour: m['reminderHour'] ?? 8,
      );
}

class GlucoseEntry {
  final DateTime time;
  final double gL; // g/L, e.g. 1.20
  final String context; // fasting | after_meal | other

  GlucoseEntry(this.time, this.gL, this.context);

  /// Default bands (editable later with the doctor): low < 0.70, high > 2.50, target depends on context.
  String get band {
    if (gL < 0.70) return 'low';
    if (gL > 2.50) return 'very_high';
    final top = context == 'fasting' ? 1.30 : 1.80;
    return (gL >= 0.80 && gL <= top) ? 'in_target' : 'out_of_target';
  }

  Map<String, dynamic> toMap() => {'time': time.toIso8601String(), 'gL': gL, 'context': context};
  factory GlucoseEntry.fromMap(Map m) =>
      GlucoseEntry(DateTime.parse(m['time']), (m['gL'] as num).toDouble(), m['context'] ?? 'other');
}

class Medication {
  final String id;
  String name;
  String dose;
  List<String> times; // "08:00", "20:00"
  Map<String, List<String>> taken; // "2026-10-10" -> ["08:00"]

  Medication({required this.id, required this.name, this.dose = '', List<String>? times, Map<String, List<String>>? taken})
      : times = times ?? ['08:00'],
        taken = taken ?? {};

  bool isTaken(DateTime day, String time) => taken[_key(day)]?.contains(time) ?? false;
  void markTaken(DateTime day, String time) => taken.putIfAbsent(_key(day), () => []).add(time);
  static String _key(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'dose': dose, 'times': times, 'taken': taken};
  factory Medication.fromMap(Map m) => Medication(
        id: m['id'],
        name: m['name'],
        dose: m['dose'] ?? '',
        times: List<String>.from(m['times'] ?? ['08:00']),
        taken: (m['taken'] as Map? ?? {}).map((k, v) => MapEntry(k as String, List<String>.from(v))),
      );
}

class FootScan {
  final DateTime time;
  final Map<String, double> left;
  final Map<String, double> right;
  final Map<String, double> dt; // |left - right| per site
  final double maxDt;
  final String site; // site with the largest difference
  final String status; // green | amber | red

  FootScan({required this.time, required this.left, required this.right, required this.dt,
      required this.maxDt, required this.site, required this.status});

  Map<String, dynamic> toMap() => {
        'time': time.toIso8601String(), 'left': left, 'right': right, 'dt': dt,
        'maxDt': maxDt, 'site': site, 'status': status,
      };

  factory FootScan.fromMap(Map m) {
    Map<String, double> d(Map? x) => (x ?? {}).map((k, v) => MapEntry(k as String, (v as num).toDouble()));
    return FootScan(
      time: DateTime.parse(m['time']), left: d(m['left']), right: d(m['right']), dt: d(m['dt']),
      maxDt: (m['maxDt'] as num).toDouble(), site: m['site'] ?? '', status: m['status'] ?? 'green',
    );
  }
}
