import '../models/models.dart';

/// The Qadam clinical rule (no AI, no dataset):
///   dT = |left - right| at the same plantar site.
///   green : max dT < 2.2 C
///   amber : max dT >= 2.2 C on this scan only
///   red   : max dT >= 2.2 C at the SAME site on the previous day as well (2 consecutive days)
/// demoMode: the previous scan counts as "yesterday", so the red case can be shown live.
class FootRule {
  static const threshold = 2.2;

  /// Accepts both firmware payloads:
  ///  ESP32 mat : {"left":{"hallux":..,"mth1":..},"right":{...}}
  ///  Uno DHT   : {"left":31.2,"right":33.6}  -> treated as a single site "mth1"
  static FootScan? fromPayload(Map<String, dynamic> p, List<FootScan> history, {bool demoMode = false}) {
    Map<String, double> side(dynamic v) {
      if (v is Map) return v.map((k, x) => MapEntry(k.toString(), (x as num).toDouble()));
      if (v is num) return {'mth1': v.toDouble()};
      return {};
    }

    final left = side(p['left']);
    final right = side(p['right']);
    if (left.isEmpty || right.isEmpty) return null;

    final dt = <String, double>{};
    for (final s in left.keys) {
      if (right.containsKey(s)) dt[s] = (left[s]! - right[s]!).abs();
    }
    if (dt.isEmpty) return null;
    final top = dt.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final now = DateTime.now();

    var status = 'green';
    if (top.value >= threshold) {
      status = 'amber';
      final prev = _previousDayScan(history, now, demoMode);
      if (prev != null && (prev.dt[top.key] ?? 0) >= threshold) status = 'red';
    }
    return FootScan(time: now, left: left, right: right, dt: dt, maxDt: top.value, site: top.key, status: status);
  }

  static FootScan? _previousDayScan(List<FootScan> history, DateTime now, bool demoMode) {
    if (history.isEmpty) return null;
    if (demoMode) return history.last;
    final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    final matches = history.where((s) =>
        s.time.year == yesterday.year && s.time.month == yesterday.month && s.time.day == yesterday.day);
    return matches.isEmpty ? null : matches.last;
  }
}
