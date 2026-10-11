import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/strings.dart';
import '../models/models.dart';
import '../services/foot_rule.dart';
import '../services/hub_service.dart';
import '../services/mqtt_service.dart';
import '../services/safety_service.dart';
import '../services/storage_service.dart';

enum Phase { onboarding, locked, ready }

/// Device link as the patient sees it. Never "online" unless a valid frame arrived in the last 15 s.
enum DeviceState { notConfigured, connecting, brokerDown, waiting, online, stale, fault, bridgeError }

enum ScanPhase { idle, measuring, done, error }

class AppState extends ChangeNotifier {
  Phase phase = Phase.onboarding;
  String lang = 'aeb';
  Profile? profile;

  // settings (encrypted box)
  bool demoMode = true;
  bool advanced = false;
  String mqttHost = '';
  int mqttPort = 1883;
  String deviceId = 'bench-01';
  String hubUrl = '';
  String? hubToken;
  String? patientRef;
  bool consentShare = false;
  bool consentAi = false;
  bool shareContextWithAi = true;

  List<GlucoseEntry> glucose = [];
  List<Medication> meds = [];
  List<FootScan> scans = [];
  List<HubAlert> hubAlerts = [];

  // live link
  final mqtt = MqttService();
  bool brokerConnected = false;
  bool connecting = false;
  Map<String, dynamic>? lastFrame;
  DateTime? lastFrameAt;
  Map<String, dynamic>? bridgeStatus;
  StreamSubscription? _framesSub, _statusSub, _connSub;
  Timer? _ticker;

  // scan
  ScanPhase scanPhase = ScanPhase.idle;
  double scanProgress = 0;
  String? scanError;
  FootScan? lastScanResult;

  // sync
  String syncState = 'idle'; // idle | syncing | ok | offline | error | notPaired
  DateTime? lastSyncAt;
  int get pendingSync => StorageService.isUnlocked ? StorageService.all('outbox').length : 0;
  bool get paired => hubToken != null && hubUrl.isNotEmpty;

  // assistant (kept in memory only: questions are not stored)
  final List<ChatMessage> chat = [];
  bool asking = false;

  String t(String key, [Map<String, String>? args]) => translate(lang, key, args);
  bool get rtl => lang != 'fr';

  // ------------------------------------------------------------------ lifecycle
  Future<void> boot() async {
    await SafetyService.load();
    lang = StorageService.metaLang ?? 'aeb';
    phase = StorageService.hasPin ? Phase.locked : Phase.onboarding;
    notifyListeners();
  }

  Future<bool> unlock(String pin) async {
    final ok = await StorageService.unlock(pin);
    if (!ok) return false;
    await _loadAll();
    phase = Phase.ready;
    _startBackground();
    notifyListeners();
    return true;
  }

  /// End of onboarding: PIN creates the encryption key, then the profile is written encrypted.
  Future<void> completeOnboarding(Profile p, String pin, {required bool share, required bool ai}) async {
    await StorageService.createPin(pin);
    profile = p;
    consentShare = share;
    consentAi = ai;
    await StorageService.set('profile', p.toMap());
    await StorageService.set('lang', lang);
    await _saveSettings();
    await _loadAll();
    phase = Phase.ready;
    _startBackground();
    notifyListeners();
  }

  Future<void> lockNow() async {
    _stopBackground();
    await mqtt.disconnect();
    await StorageService.lock();
    phase = Phase.locked;
    chat.clear();
    notifyListeners();
  }

  Future<void> _loadAll() async {
    final p = StorageService.get<Map>('profile');
    profile = p == null ? null : Profile.fromMap(p);
    lang = StorageService.get<String>('lang') ?? lang;
    demoMode = StorageService.get<bool>('demoMode') ?? true;
    advanced = StorageService.get<bool>('advanced') ?? false;
    mqttHost = StorageService.get<String>('mqttHost') ?? '';
    mqttPort = StorageService.get<int>('mqttPort') ?? 1883;
    deviceId = StorageService.get<String>('deviceId') ?? 'bench-01';
    hubUrl = StorageService.get<String>('hubUrl') ?? '';
    hubToken = StorageService.get<String>('hubToken');
    patientRef = StorageService.get<String>('patientRef');
    consentShare = StorageService.get<bool>('consentShare') ?? consentShare;
    consentAi = StorageService.get<bool>('consentAi') ?? consentAi;
    shareContextWithAi = StorageService.get<bool>('shareContextWithAi') ?? true;
    final lsa = StorageService.get<String>('lastSyncAt');
    lastSyncAt = lsa == null ? null : DateTime.tryParse(lsa);
    glucose = StorageService.all('glucose').map(GlucoseEntry.fromMap).toList()..sort((a, b) => a.time.compareTo(b.time));
    meds = StorageService.all('meds').map(Medication.fromMap).toList();
    scans = StorageService.all('scans').map(FootScan.fromMap).toList()..sort((a, b) => a.time.compareTo(b.time));
    hubAlerts = StorageService.all('hubalerts').map(HubAlert.fromJson).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _saveSettings() async {
    await StorageService.set('demoMode', demoMode);
    await StorageService.set('advanced', advanced);
    await StorageService.set('mqttHost', mqttHost);
    await StorageService.set('mqttPort', mqttPort);
    await StorageService.set('deviceId', deviceId);
    await StorageService.set('hubUrl', hubUrl);
    await StorageService.set('consentShare', consentShare);
    await StorageService.set('consentAi', consentAi);
    await StorageService.set('shareContextWithAi', shareContextWithAi);
    if (hubToken != null) await StorageService.set('hubToken', hubToken);
    if (patientRef != null) await StorageService.set('patientRef', patientRef);
  }

  void _startBackground() {
    _ticker?.cancel();
    var n = 0;
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) {
      n++;
      notifyListeners(); // refreshes "last frame x s ago" and staleness
      if (n % 12 == 0) syncNow(); // every minute
    });
    if (mqttHost.isNotEmpty) connectMat();
    syncNow();
  }

  void _stopBackground() {
    _ticker?.cancel();
    _ticker = null;
  }

  // ------------------------------------------------------------------ settings
  Future<void> setLang(String v) async {
    lang = v;
    await StorageService.setMetaLang(v);
    if (StorageService.isUnlocked) await StorageService.set('lang', v);
    notifyListeners();
  }

  Future<void> setDemoMode(bool v) async {
    demoMode = v;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setAdvanced(bool v) async {
    advanced = v;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setConsents({bool? share, bool? ai, bool? context}) async {
    consentShare = share ?? consentShare;
    consentAi = ai ?? consentAi;
    shareContextWithAi = context ?? shareContextWithAi;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> saveProfile(Profile p) async {
    profile = p;
    await StorageService.set('profile', p.toMap());
    notifyListeners();
  }

  // ------------------------------------------------------------------ mat link (MQTT)
  DeviceState get deviceState {
    if (mqttHost.isEmpty) return DeviceState.notConfigured;
    if (connecting) return DeviceState.connecting;
    if (!brokerConnected) return DeviceState.brokerDown;
    if (bridgeStatus != null && (bridgeStatus!['state'] == 'error' || bridgeStatus!['state'] == 'offline') && !_fresh) {
      return DeviceState.bridgeError;
    }
    if (lastFrameAt == null) return DeviceState.waiting;
    if (!_fresh) return DeviceState.stale;
    final faults = (lastFrame?['faults'] as List?) ?? const [];
    if (faults.isNotEmpty) return DeviceState.fault;
    return DeviceState.online;
  }

  bool get _fresh => lastFrameAt != null && DateTime.now().difference(lastFrameAt!).inSeconds <= 15;
  String? get liveSource => lastFrame?['source'] as String?;
  bool get liveSimulated => liveSource == 'simulated';

  double? liveTemp(String side) {
    final m = lastFrame?[side];
    if (m is Map && m.isNotEmpty && m.values.first is num) return (m.values.first as num).toDouble();
    return null;
  }

  Future<bool> connectMat({String? host, int? port, String? device}) async {
    if (host != null) mqttHost = host.trim();
    if (port != null) mqttPort = port;
    if (device != null && device.trim().isNotEmpty) deviceId = device.trim();
    await _saveSettings();
    if (mqttHost.isEmpty) return false;
    connecting = true;
    lastFrame = null;
    lastFrameAt = null;
    bridgeStatus = null;
    notifyListeners();
    await _framesSub?.cancel();
    await _statusSub?.cancel();
    await _connSub?.cancel();
    _framesSub = mqtt.frames.listen(_onFrame);
    _statusSub = mqtt.status.listen((s) {
      bridgeStatus = s;
      notifyListeners();
    });
    _connSub = mqtt.connection.listen((c) {
      brokerConnected = c;
      notifyListeners();
    });
    brokerConnected = await mqtt.connect(host: mqttHost, port: mqttPort, device: deviceId);
    connecting = false;
    notifyListeners();
    return brokerConnected;
  }

  void _onFrame(Map<String, dynamic> f) {
    // integrity: only frames validated by the bridge (CRC) and labelled with their source are accepted
    if (f['integrity'] != 'ok' || (f['source'] != 'hardware' && f['source'] != 'simulated')) {
      mqtt.rejected++;
      return;
    }
    // A retained message replayed at subscribe time may be hours old: its own timestamp decides staleness.
    // Live messages use the phone's receive time (immune to clock differences between laptop and phone).
    final ts = f['ts'];
    final now = DateTime.now();
    var at = now;
    if (f['_retained'] == true && ts is num) {
      final sent = DateTime.fromMillisecondsSinceEpoch(ts.toInt());
      if (sent.isBefore(now)) at = sent;
    }
    lastFrame = f;
    lastFrameAt = at;
    _scanFrames?.add(f);
    notifyListeners();
  }

  // ------------------------------------------------------------------ foot scan
  List<Map<String, dynamic>>? _scanFrames;

  /// Patient stands on the mat; we collect ~10 s of frames and use the last stable averaged window.
  Future<FootScan?> startScan() async {
    if (scanPhase == ScanPhase.measuring) return null;
    scanError = null;
    lastScanResult = null;
    final state = deviceState;
    if (state != DeviceState.online && state != DeviceState.fault) {
      scanPhase = ScanPhase.error;
      scanError = 'scan.err.noDevice';
      notifyListeners();
      return null;
    }
    scanPhase = ScanPhase.measuring;
    scanProgress = 0;
    _scanFrames = [];
    notifyListeners();
    const total = 10;
    for (var i = 1; i <= total * 4; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      scanProgress = i / (total * 4);
      if (i % 4 == 0) notifyListeners();
    }
    final frames = _scanFrames ?? [];
    _scanFrames = null;
    Map<String, dynamic>? best;
    var sawFault = false, sawWarming = false;
    for (final f in frames) {
      final faults = (f['faults'] as List?) ?? const [];
      final l = f['left'], r = f['right'];
      if (faults.isNotEmpty || l is! Map || r is! Map || l.isEmpty || r.isEmpty) {
        sawFault = true;
        continue;
      }
      if (f['warming_up'] == true) {
        sawWarming = true;
        continue;
      }
      best = f; // latest valid window wins
    }
    if (best == null) {
      scanPhase = ScanPhase.error;
      scanError = sawFault ? 'scan.err.fault' : (sawWarming ? 'scan.err.warming' : 'scan.err.noData');
      notifyListeners();
      return null;
    }
    Map<String, double> side(dynamic m) => (m as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
    final spread = (best['spread'] as Map?) ?? const {};
    final scan = FootRule.scanFromFrame(
      left: side(best['left']),
      right: side(best['right']),
      history: scans,
      source: (best['source'] ?? 'hardware').toString(),
      demo: demoMode,
      samples: (best['samples'] as num?)?.toInt() ?? 1,
      spreadLeft: (spread['left'] as num?)?.toDouble() ?? 0,
      spreadRight: (spread['right'] as num?)?.toDouble() ?? 0,
    );
    if (scan == null) {
      scanPhase = ScanPhase.error;
      scanError = 'scan.err.implausible';
      notifyListeners();
      return null;
    }
    scans.add(scan);
    await StorageService.put('scans', scan.id, scan.toMap());
    await _enqueue({
      'type': 'scan',
      'id': scan.id,
      'ts': scan.time.millisecondsSinceEpoch,
      'left': scan.left,
      'right': scan.right,
      'samples': scan.samples,
      'spread_left': scan.spreadLeft,
      'spread_right': scan.spreadRight,
      'source': scan.source,
      'app_level': scan.level,
    });
    lastScanResult = scan;
    scanPhase = ScanPhase.done;
    notifyListeners();
    syncNow();
    return scan;
  }

  void resetScan() {
    scanPhase = ScanPhase.idle;
    scanError = null;
    notifyListeners();
  }

  Future<void> acknowledge(FootScan s) async {
    s.acknowledgedAt = DateTime.now();
    await StorageService.put('scans', s.id, s.toMap());
    await _enqueue({'type': 'ack', 'id': 'ack-${s.id}', 'scan_id': s.id});
    notifyListeners();
    syncNow();
  }

  FootScan? get lastScan => scans.isEmpty ? null : scans.last;

  // ------------------------------------------------------------------ glucose & medication
  Future<GlucoseEntry> addGlucose(double gL, String context) async {
    final e = GlucoseEntry(id: newId(), time: DateTime.now(), gL: gL, context: context);
    glucose.add(e);
    await StorageService.put('glucose', e.id, e.toMap());
    await _enqueue({'type': 'glucose', 'id': e.id, 'ts': e.time.millisecondsSinceEpoch, 'g_l': e.gL, 'context': e.context});
    notifyListeners();
    syncNow();
    return e;
  }

  Future<void> deleteGlucose(GlucoseEntry e) async {
    glucose.removeWhere((x) => x.id == e.id);
    await StorageService.delete('glucose', e.id);
    await StorageService.delete('outbox', e.id); // not yet synced: never leaves the phone
    notifyListeners();
  }

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

  Future<void> deleteMed(Medication m) async {
    meds.removeWhere((x) => x.id == m.id);
    await StorageService.delete('meds', m.id);
    notifyListeners();
  }

  Future<void> toggleDose(Medication m, String time) async {
    final today = DateTime.now();
    m.toggle(today, time);
    await StorageService.put('meds', m.id, m.toMap());
    final day = Medication.dayKey(today);
    final planned = meds.fold<int>(0, (a, x) => a + x.times.length);
    final taken = meds.fold<int>(0, (a, x) => a + x.times.where((tm) => x.isTaken(today, tm)).length);
    await _enqueue({'type': 'adherence', 'id': 'adh-$day', 'day': day, 'planned': planned, 'taken': taken});
    notifyListeners();
  }

  int adherencePct({int days = 7}) {
    var planned = 0, done = 0;
    for (var d = 0; d < days; d++) {
      final day = DateTime.now().subtract(Duration(days: d));
      for (final m in meds) {
        for (final tm in m.times) {
          planned++;
          if (m.isTaken(day, tm)) done++;
        }
      }
    }
    return planned == 0 ? 100 : (100 * done / planned).round();
  }

  ({int done, int total}) todayPlan() {
    final now = DateTime.now();
    bool same(DateTime a) => a.year == now.year && a.month == now.month && a.day == now.day;
    var total = 2, done = 0;
    if (scans.any((s) => same(s.time))) done++;
    if (glucose.any((g) => same(g.time))) done++;
    for (final m in meds) {
      for (final tm in m.times) {
        total++;
        if (m.isTaken(now, tm)) done++;
      }
    }
    return (done: done, total: total);
  }

  int scanStreak() {
    var streak = 0;
    var day = DateTime.now();
    bool has(DateTime d) => scans.any((s) => s.time.year == d.year && s.time.month == d.month && s.time.day == d.day);
    if (!has(day)) day = day.subtract(const Duration(days: 1)); // today not done yet does not break the streak
    while (has(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ------------------------------------------------------------------ care team hub: pairing & sync
  Future<String?> pair(String url, String code) async {
    try {
      final res = await HubService(url).pair(code,
          share: consentShare, ai: consentAi, diabetesType: profile?.diabetesType, footRisk: profile?.footRisk);
      hubUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
      hubToken = res['token'] as String;
      patientRef = res['patient_ref'] as String?;
      final dev = (res['device_id'] ?? '').toString();
      if (dev.isNotEmpty) deviceId = dev;
      await _saveSettings();
      notifyListeners();
      if (mqttHost.isEmpty) {
        final host = Uri.tryParse(hubUrl)?.host ?? '';
        if (host.isNotEmpty) await connectMat(host: host);
      } else {
        await connectMat();
      }
      await syncNow();
      return null;
    } on HubException catch (e) {
      return e.status == 0 ? 'pair.err.network' : (e.status == 404 ? 'pair.err.code' : 'pair.err.other');
    } catch (_) {
      return 'pair.err.other'; // unexpected response from the hub
    }
  }

  Future<void> unpair() async {
    hubToken = null;
    patientRef = null;
    await StorageService.remove('hubToken');
    await StorageService.remove('patientRef');
    syncState = 'notPaired';
    notifyListeners();
  }

  Future<void> _enqueue(Map<String, dynamic> item) async {
    await StorageService.put('outbox', item['id'].toString(), item);
  }

  bool _syncing = false;

  /// Asynchronous, offline-tolerant: items wait in the encrypted outbox until the hub is reachable.
  Future<void> syncNow() async {
    if (_syncing || phase != Phase.ready) return;
    if (!paired) {
      syncState = 'notPaired';
      return;
    }
    if (!consentShare) {
      syncState = 'idle';
      return;
    }
    _syncing = true;
    syncState = 'syncing';
    notifyListeners();
    final hub = HubService(hubUrl, token: hubToken);
    try {
      final items = StorageService.all('outbox').map((m) => Map<String, dynamic>.from(m)).take(100).toList();
      if (items.isNotEmpty) {
        final res = await hub.sync(items);
        final done = <String>{
          ...((res['accepted'] as List?) ?? const []).map((e) => e.toString()),
          ...((res['rejected'] as List?) ?? const []).map((e) => (e as Map)['id'].toString()),
        };
        for (final id in done) {
          await StorageService.delete('outbox', id);
        }
        final results = (res['results'] as Map?) ?? const {};
        for (final s in scans) {
          final r = results[s.id];
          if (r is Map) {
            s.hubLevel = r['level'] as String?;
            s.alertId = (r['alert_id'] as num?)?.toInt();
            await StorageService.put('scans', s.id, s.toMap());
          }
        }
      }
      final alerts = await hub.alerts();
      await StorageService.clear('hubalerts');
      hubAlerts = [];
      for (final a in alerts) {
        final h = HubAlert.fromJson(a);
        hubAlerts.add(h);
        await StorageService.put('hubalerts', h.id.toString(), h.toJson());
        for (final s in scans) {
          if (s.id == h.scanId && (s.reviewStatus != h.status || s.reviewNote != h.reviewNote)) {
            s.reviewStatus = h.status;
            s.reviewNote = h.reviewNote;
            await StorageService.put('scans', s.id, s.toMap());
          }
        }
      }
      lastSyncAt = DateTime.now();
      await StorageService.set('lastSyncAt', lastSyncAt!.toIso8601String());
      syncState = 'ok';
    } on HubException catch (e) {
      syncState = e.status == 0 ? 'offline' : 'error';
      if (e.status == 401) await unpair();
    } catch (_) {
      syncState = 'error'; // malformed response or storage closed (lock during sync): retried next minute
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------ assistant
  Map<String, dynamic>? _aiContext() {
    if (!shareContextWithAi) return null;
    final s = lastScan;
    final g = glucose.isEmpty ? null : glucose.last;
    return {
      'diabetes_type': profile?.diabetesType,
      if (s != null) 'last_scan': {'level': s.level, 'max_dt': s.maxDt, 'site': s.site},
      if (g != null) 'last_glucose': {'g_l': g.gL, 'context': g.context},
    };
  }

  Future<void> ask(String question) async {
    final q = question.trim();
    if (q.isEmpty || asking) return;
    chat.add(ChatMessage(fromUser: true, text: q, kind: 'question', source: 'user'));
    // 1. on-device red-flag triage first: instant, works offline, never depends on the AI
    final tri = SafetyService.triage(q, lang);
    if (tri != null) {
      chat.add(ChatMessage(fromUser: false, text: tri.text, kind: tri.tier, source: 'rules'));
      notifyListeners();
      return;
    }
    asking = true;
    notifyListeners();
    try {
      if (paired && consentAi) {
        final r = await HubService(hubUrl, token: hubToken).ask(q, lang, _aiContext());
        chat.add(ChatMessage(
          fromUser: false,
          text: (r['text'] ?? '').toString(),
          kind: (r['kind'] ?? 'answer').toString(),
          source: (r['source'] ?? 'library').toString(),
        ));
        return;
      }
      throw HubException(0, 'local');
    } catch (_) {
      // hub unreachable, not paired or no AI consent: verified library, clearly labelled as such
      final lib = SafetyService.libraryAnswer(q, lang);
      chat.add(ChatMessage(fromUser: false, text: lib.text, kind: 'answer', source: 'offline'));
    } finally {
      asking = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------ data rights
  String exportJson() {
    final data = StorageService.exportAll()..remove('outbox');
    final settings = Map<String, dynamic>.from((data['settings'] as Map?) ?? const {});
    if (settings.containsKey('hubToken')) settings['hubToken'] = '***';
    data['settings'] = settings;
    return const JsonEncoder.withIndent('  ').convert({'exported_at': DateTime.now().toIso8601String(), 'app': 'Qadam', ...data});
  }

  Future<void> eraseEverything({bool remote = true}) async {
    if (remote && paired) {
      try {
        await HubService(hubUrl, token: hubToken).eraseRemote();
      } on HubException {
        // offline: local erase still happens; the care team can erase on the hub
      }
    }
    _stopBackground();
    await mqtt.disconnect();
    await StorageService.eraseEverything();
    profile = null;
    glucose = [];
    meds = [];
    scans = [];
    hubAlerts = [];
    chat.clear();
    hubToken = null;
    patientRef = null;
    hubUrl = '';
    mqttHost = '';
    phase = Phase.onboarding;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopBackground();
    mqtt.disconnect();
    super.dispose();
  }
}
