import 'dart:math' as math;

import '../models/models.dart';

/// Qadam foot-temperature rule — deterministic and explainable, no AI.
/// Same algorithm as hub/qadam_hub/rule.py; both are tested against shared/rule_vectors.json.
///
///   dT(site) = |left - right| at the same plantar site (rounded to 0.01 C)
///   green : max dT <  2.2 C
///   amber : max dT >= 2.2 C today only
///   red   : max dT >= 2.2 C at the SAME site on the previous calendar day too
///           (demo mode: the previous scan counts as "yesterday")
///
/// Confidence (0-100) = reliability of this measurement, NOT a probability of disease:
///   samples min(1, n/4) x stability clamp(1-(spread-0.3)/0.7, .2, 1) x margin 0.5+0.5*clamp(|dT-2.2|/0.5, 0, 1)
class PastScan {
  final DateTime day;
  final Map<String, double> dt;
  PastScan(this.day, this.dt);
}

class RuleResult {
  final String level;
  final double maxDt;
  final String site;
  final String warmerSide;
  final Map<String, double> dt;
  final int consecutiveDays;
  final int confidence;
  final String confidenceLabel;
  final Map<String, double> factors;

  RuleResult(this.level, this.maxDt, this.site, this.warmerSide, this.dt, this.consecutiveDays, this.confidence,
      this.confidenceLabel, this.factors);
}

class FootRule {
  static const threshold = 2.2;
  static const plausibleMin = 10.0;
  static const plausibleMax = 45.0;

  static double round2(double x) => (x * 100 + 0.5).floorToDouble() / 100;
  static double _clamp(double x, double lo, double hi) => math.max(lo, math.min(hi, x));

  static ({int value, String label, Map<String, double> factors}) confidence(double maxDt,
      {int samples = 4, double spreadLeft = 0, double spreadRight = 0}) {
    final s = math.min(1.0, samples / 4.0);
    final spread = math.max(spreadLeft, spreadRight);
    final st = _clamp(1 - (spread - 0.3) / 0.7, 0.2, 1.0);
    final m = 0.5 + 0.5 * _clamp((maxDt - threshold).abs() / 0.5, 0.0, 1.0);
    final value = (100 * s * st * m + 0.5).floor();
    final label = value >= 75 ? 'high' : (value >= 50 ? 'medium' : 'low');
    return (value: value, label: label, factors: {'samples': round2(s), 'stability': round2(st), 'margin': round2(m)});
  }

  /// Returns null when the input is not a valid scan (missing side or implausible temperature).
  static RuleResult? evaluate(
    Map<String, double> left,
    Map<String, double> right,
    List<PastScan> history,
    DateTime today, {
    bool demo = false,
    int samples = 4,
    double spreadLeft = 0,
    double spreadRight = 0,
  }) {
    if (left.isEmpty || right.isEmpty) return null;
    for (final v in [...left.values, ...right.values]) {
      if (v.isNaN || v < plausibleMin || v > plausibleMax) return null;
    }
    final dt = <String, double>{};
    for (final s in left.keys) {
      if (right.containsKey(s)) dt[s] = round2((left[s]! - right[s]!).abs());
    }
    if (dt.isEmpty) return null;
    var site = dt.keys.first;
    for (final e in dt.entries) {
      if (e.value > dt[site]!) site = e.key;
    }
    final maxDt = dt[site]!;
    final warmer = left[site]! > right[site]! ? 'left' : 'right';

    var level = 'green';
    var days = 0;
    if (maxDt >= threshold) {
      level = 'amber';
      days = 1;
      final prev = _previous(history, today, demo);
      if (prev != null && (prev.dt[site] ?? 0) >= threshold) {
        level = 'red';
        days = 2;
      }
    }
    final c = confidence(maxDt, samples: samples, spreadLeft: spreadLeft, spreadRight: spreadRight);
    return RuleResult(level, maxDt, site, warmer, dt, days, c.value, c.label, c.factors);
  }

  static PastScan? _previous(List<PastScan> history, DateTime today, bool demo) {
    if (history.isEmpty) return null;
    if (demo) return history.last;
    final y = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 1));
    PastScan? found;
    for (final h in history) {
      if (h.day.year == y.year && h.day.month == y.month && h.day.day == y.day) found = h;
    }
    return found;
  }

  /// Builds a stored scan from the averaged frame of the mat, using the local scan history.
  static FootScan? scanFromFrame({
    required Map<String, double> left,
    required Map<String, double> right,
    required List<FootScan> history,
    required String source,
    required bool demo,
    int samples = 4,
    double spreadLeft = 0,
    double spreadRight = 0,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final r = evaluate(left, right, [for (final s in history) PastScan(s.time, s.dt)], t,
        demo: demo, samples: samples, spreadLeft: spreadLeft, spreadRight: spreadRight);
    if (r == null) return null;
    return FootScan(
      id: newId(),
      time: t,
      left: left,
      right: right,
      dt: r.dt,
      maxDt: r.maxDt,
      site: r.site,
      warmerSide: r.warmerSide,
      level: r.level,
      consecutiveDays: r.consecutiveDays,
      confidence: r.confidence,
      confidenceLabel: r.confidenceLabel,
      factors: r.factors,
      samples: samples,
      spreadLeft: spreadLeft,
      spreadRight: spreadRight,
      source: source,
      demo: demo,
    );
  }
}
