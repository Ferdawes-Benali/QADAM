import 'dart:math';

/// Plain data classes stored in Hive as Maps (no code generation needed).

String newId() => '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(0x7fffffff)}';

double _d(dynamic v, [double fallback = 0]) => v is num ? v.toDouble() : fallback;
Map<String, double> _dm(dynamic x) =>
    x is Map ? x.map((k, v) => MapEntry(k.toString(), _d(v))) : <String, double>{};

class Profile {
  String name; // stays on the phone, never sent to the hub
  String diabetesType; // t1 | t2 | gest | other
  int? yearDiagnosed;
  String treatment; // insulin | tablets | both | diet
  bool pastUlcer;
  bool numbness;
  String doctorName;
  String doctorPhone; // international format without '+', e.g. 21671000000
  String familyName;
  String familyPhone;

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
  });

  /// Simplified foot-risk level (inspired by IWGDF risk categories; not a clinical grading).
  String get footRisk => pastUlcer ? 'high' : (numbness ? 'moderate' : 'low');

  Map<String, dynamic> toMap() => {
        'name': name,
        'diabetesType': diabetesType,
        'yearDiagnosed': yearDiagnosed,
        'treatment': treatment,
        'pastUlcer': pastUlcer,
        'numbness': numbness,
        'doctorName': doctorName,
        'doctorPhone': doctorPhone,
        'familyName': familyName,
        'familyPhone': familyPhone,
      };

  factory Profile.fromMap(Map m) => Profile(
        name: (m['name'] ?? '').toString(),
        diabetesType: (m['diabetesType'] ?? 't2').toString(),
        yearDiagnosed: m['yearDiagnosed'] is int ? m['yearDiagnosed'] as int : null,
        treatment: (m['treatment'] ?? 'tablets').toString(),
        pastUlcer: m['pastUlcer'] == true,
        numbness: m['numbness'] == true,
        doctorName: (m['doctorName'] ?? '').toString(),
        doctorPhone: (m['doctorPhone'] ?? '').toString(),
        familyName: (m['familyName'] ?? '').toString(),
        familyPhone: (m['familyPhone'] ?? '').toString(),
      );
}

class GlucoseEntry {
  final String id;
  final DateTime time;
  final double gL; // g/L, e.g. 1.20
  final String context; // fasting | after_meal | other

  GlucoseEntry({required this.id, required this.time, required this.gL, required this.context});

  /// Default bands, identical to the hub (domain.glucose_band). To be personalised by the doctor.
  String get band {
    if (gL < 0.70) return 'low';
    if (gL > 2.50) return 'very_high';
    final top = context == 'fasting' ? 1.30 : 1.80;
    return (gL >= 0.80 && gL <= top) ? 'in_target' : 'out_of_target';
  }

  Map<String, dynamic> toMap() => {'id': id, 'time': time.toIso8601String(), 'gL': gL, 'context': context};
  factory GlucoseEntry.fromMap(Map m) => GlucoseEntry(
        id: (m['id'] ?? newId()).toString(),
        time: DateTime.parse(m['time'].toString()),
        gL: _d(m['gL']),
        context: (m['context'] ?? 'other').toString(),
      );
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

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  bool isTaken(DateTime day, String time) => taken[dayKey(day)]?.contains(time) ?? false;
  void toggle(DateTime day, String time) {
    final list = taken.putIfAbsent(dayKey(day), () => <String>[]);
    list.contains(time) ? list.remove(time) : list.add(time);
  }

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'dose': dose, 'times': times, 'taken': taken};
  factory Medication.fromMap(Map m) => Medication(
        id: m['id'].toString(),
        name: (m['name'] ?? '').toString(),
        dose: (m['dose'] ?? '').toString(),
        times: List<String>.from((m['times'] as List?) ?? const ['08:00']),
        taken: ((m['taken'] as Map?) ?? const {})
            .map((k, v) => MapEntry(k.toString(), List<String>.from((v as List?) ?? const []))),
      );
}

class FootScan {
  final String id;
  final DateTime time;
  final Map<String, double> left;
  final Map<String, double> right;
  final Map<String, double> dt; // |left - right| per site, rounded to 0.01
  final double maxDt;
  final String site;
  final String warmerSide; // left | right
  final String level; // green | amber | red
  final int consecutiveDays;
  final int confidence; // 0-100: reliability of the measurement (not a probability of disease)
  final String confidenceLabel; // high | medium | low
  final Map<String, double> factors; // samples, stability, margin
  final int samples;
  final double spreadLeft;
  final double spreadRight;
  final String source; // hardware | simulated | manual
  final bool demo; // evaluated in demo mode (1 scan = 1 day)
  // filled after sync with the care team's hub
  String? hubLevel;
  int? alertId;
  String? reviewStatus; // open | confirmed | dismissed
  String? reviewNote;
  DateTime? acknowledgedAt;

  FootScan({
    required this.id,
    required this.time,
    required this.left,
    required this.right,
    required this.dt,
    required this.maxDt,
    required this.site,
    required this.warmerSide,
    required this.level,
    required this.consecutiveDays,
    required this.confidence,
    required this.confidenceLabel,
    required this.factors,
    required this.samples,
    required this.spreadLeft,
    required this.spreadRight,
    required this.source,
    required this.demo,
    this.hubLevel,
    this.alertId,
    this.reviewStatus,
    this.reviewNote,
    this.acknowledgedAt,
  });

  bool get isSimulated => source == 'simulated';

  Map<String, dynamic> toMap() => {
        'id': id,
        'time': time.toIso8601String(),
        'left': left,
        'right': right,
        'dt': dt,
        'maxDt': maxDt,
        'site': site,
        'warmerSide': warmerSide,
        'level': level,
        'consecutiveDays': consecutiveDays,
        'confidence': confidence,
        'confidenceLabel': confidenceLabel,
        'factors': factors,
        'samples': samples,
        'spreadLeft': spreadLeft,
        'spreadRight': spreadRight,
        'source': source,
        'demo': demo,
        'hubLevel': hubLevel,
        'alertId': alertId,
        'reviewStatus': reviewStatus,
        'reviewNote': reviewNote,
        'acknowledgedAt': acknowledgedAt?.toIso8601String(),
      };

  factory FootScan.fromMap(Map m) => FootScan(
        id: (m['id'] ?? newId()).toString(),
        time: DateTime.parse(m['time'].toString()),
        left: _dm(m['left']),
        right: _dm(m['right']),
        dt: _dm(m['dt']),
        maxDt: _d(m['maxDt']),
        site: (m['site'] ?? 'mth1').toString(),
        warmerSide: (m['warmerSide'] ?? 'right').toString(),
        level: (m['level'] ?? m['status'] ?? 'green').toString(),
        consecutiveDays: (m['consecutiveDays'] as num?)?.toInt() ?? 0,
        confidence: (m['confidence'] as num?)?.toInt() ?? 0,
        confidenceLabel: (m['confidenceLabel'] ?? 'low').toString(),
        factors: _dm(m['factors']),
        samples: (m['samples'] as num?)?.toInt() ?? 0,
        spreadLeft: _d(m['spreadLeft']),
        spreadRight: _d(m['spreadRight']),
        source: (m['source'] ?? 'manual').toString(),
        demo: m['demo'] == true,
        hubLevel: m['hubLevel'] as String?,
        alertId: (m['alertId'] as num?)?.toInt(),
        reviewStatus: m['reviewStatus'] as String?,
        reviewNote: m['reviewNote'] as String?,
        acknowledgedAt: m['acknowledgedAt'] == null ? null : DateTime.tryParse(m['acknowledgedAt'].toString()),
      );
}

/// Alert as returned by the care team's hub (GET /api/patient/alerts), cached for offline display.
class HubAlert {
  final int id;
  final String? scanId;
  final String kind; // foot | glucose_low | glucose_high
  final String level;
  final DateTime createdAt;
  final String title;
  final String status; // open | confirmed | dismissed
  final String? reviewNote;
  final DateTime? reviewedAt;

  HubAlert({
    required this.id,
    required this.scanId,
    required this.kind,
    required this.level,
    required this.createdAt,
    required this.title,
    required this.status,
    this.reviewNote,
    this.reviewedAt,
  });

  static DateTime _ts(dynamic v) =>
      v is num ? DateTime.fromMillisecondsSinceEpoch((v * 1000).round()) : DateTime.tryParse('$v') ?? DateTime.now();

  factory HubAlert.fromJson(Map m) => HubAlert(
        id: (m['id'] as num).toInt(),
        scanId: m['scan_id'] as String?,
        kind: (m['kind'] ?? 'foot').toString(),
        level: (m['level'] ?? 'amber').toString(),
        createdAt: _ts(m['created_at']),
        title: (m['title'] ?? '').toString(),
        status: (m['status'] ?? 'open').toString(),
        reviewNote: (m['review_note'] as String?)?.trim().isEmpty ?? true ? null : m['review_note'] as String,
        reviewedAt: m['reviewed_at'] == null ? null : _ts(m['reviewed_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'scan_id': scanId,
        'kind': kind,
        'level': level,
        'created_at': createdAt.millisecondsSinceEpoch / 1000,
        'title': title,
        'status': status,
        'review_note': reviewNote,
        'reviewed_at': reviewedAt == null ? null : reviewedAt!.millisecondsSinceEpoch / 1000,
      };
}

class ChatMessage {
  final bool fromUser;
  final String text;
  final String kind; // question | answer | urgent | emergency
  final String source; // user | rules | gemini | library | offline
  final DateTime time;

  ChatMessage({required this.fromUser, required this.text, required this.kind, required this.source, DateTime? time})
      : time = time ?? DateTime.now();
}
