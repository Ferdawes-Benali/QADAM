import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/strings.dart';
import '../models/models.dart';
import '../services/foot_rule.dart';
import '../services/mqtt_service.dart';
import '../services/storage_service.dart';

/// Single app-wide state (provider + ChangeNotifier): simple and enough for a hackathon app.
class AppState extends ChangeNotifier {
  Profile? profile;
  String lang = 'aeb'; // aeb | ar | fr
  bool advancedMode = false;
  bool demoMode = true;
  String mqttHost = '192.168.43.1'; // laptop IP on the hotspot: change in Profile > Settings

  List<GlucoseEntry> glucose = [];
  List<Medication> meds = [];
  List<FootScan> scans = [];

  final mqtt = MqttService();
  bool mqttConnected = false;
  FootScan? lastLiveScan; // most recent scan received from the mat
  final _newScans = StreamController<FootScan>.broadcast();
  Stream<FootScan> get newScans => _newScans.stream; // UI listens to show the alert screen
  StreamSubscription? _sub;

  String t(String key) => translate(lang, key);

  Future<void> load() async {
    final p = StorageService.get<Map>('profile');
    profile = p == null ? null : Profile.fromMap(p);
    lang = StorageService.get<String>('lang') ?? 'aeb';
    advancedMode = StorageService.get<bool>('advanced') ?? false;
    demoMode = StorageService.get<bool>('demo') ?? true;
    mqttHost = StorageService.get<String>('mqttHost') ?? mqttHost;
    glucose = StorageService.all('glucose').map(GlucoseEntry.fromMap).toList()..sort((a, b) => a.time.compareTo(b.time));
    meds = StorageService.all('meds').map(Medication.fromMap).toList();
    scans = StorageService.all('scans').map(FootScan.fromMap).toList()..sort((a, b) => a.time.compareTo(b.time));
    notifyListeners();
  }

  // ---------- settings ----------
  Future<void> setLang(String v) async { lang = v; await StorageService.set('lang', v); notifyListeners(); }
  Future<void> setAdvanced(bool v) async { advancedMode = v; await StorageService.set('advanced', v); notifyListeners(); }
  Future<void> setDemo(bool v) async { demoMode = v; await StorageService.set('demo', v); notifyListeners(); }
  Future<void> saveProfile(Profile p) async { profile = p; await StorageService.set('profile', p.toMap()); notifyListeners(); }

  // ---------- glucose ----------
  Future<void> addGlucose(GlucoseEntry e) async {
    glucose.add(e);
    await StorageService.add('glucose', e.toMap());
    notifyListeners();
  }

  // ---------- medication ----------
  Future<void> saveMed(Medication m) async {
    final i = meds.indexWhere((x) => x.id == m.id);
    if (i >= 0) {
      meds[i] = m;
    } else {
      meds.add(m);
    }
    await StorageService.put('meds', m.id, m.toMap());
    notifyListeners();
  }

  int adherencePct({int days = 7}) {
    var planned = 0, done = 0;
    for (var d = 0; d < days; d++) {
      final day = DateTime.now().subtract(Duration(days: d));
      for (final m in meds) {
        for (final t in m.times) {
          planned++;
          if (m.isTaken(day, t)) done++;
        }
      }
    }
    return planned == 0 ? 100 : (100 * done / planned).round();
  }

  // ---------- mat / MQTT ----------
  Future<bool> connectMat({String? host}) async {
    if (host != null) { mqttHost = host; await StorageService.set('mqttHost', host); }
    mqttConnected = await mqtt.connect(host: mqttHost);
    await _sub?.cancel();
    _sub = mqtt.messages.listen(_onPayload);
    notifyListeners();
    return mqttConnected;
  }

  Future<void> _onPayload(Map<String, dynamic> p) async {
    final scan = FootRule.fromPayload(p, scans, demoMode: demoMode);
    if (scan == null) return;
    // the bridge publishes with "retain": skip the replayed message if we already stored it
    if (scans.isNotEmpty && scan.maxDt == scans.last.maxDt && scan.left.toString() == scans.last.left.toString()) {
      lastLiveScan = scans.last;
      notifyListeners();
      return;
    }
    scans.add(scan);
    lastLiveScan = scan;
    await StorageService.add('scans', scan.toMap());
    _newScans.add(scan);
    notifyListeners();
  }

  // ---------- home: today's plan ----------
  /// Tasks: 1 foot scan, 1 glucose reading, each medication dose.
  (int done, int total) todayPlan() {
    final now = DateTime.now();
    bool sameDay(DateTime a) => a.year == now.year && a.month == now.month && a.day == now.day;
    var total = 2, done = 0;
    if (scans.any((s) => sameDay(s.time))) done++;
    if (glucose.any((g) => sameDay(g.time))) done++;
    for (final m in meds) {
      for (final t in m.times) {
        total++;
        if (m.isTaken(now, t)) done++;
      }
    }
    return (done, total);
  }

  int scanStreak() {
    var streak = 0;
    var day = DateTime.now();
    while (scans.any((s) => s.time.year == day.year && s.time.month == day.month && s.time.day == day.day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
