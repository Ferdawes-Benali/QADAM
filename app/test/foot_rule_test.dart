import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qadam_app/services/foot_rule.dart';

/// Same vectors as hub/tests (Python): both implementations must agree on every case.
void main() {
  final vectors = jsonDecode(File('../shared/rule_vectors.json').readAsStringSync()) as Map<String, dynamic>;
  Map<String, double> m(dynamic x) => (x as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));

  test('threshold matches shared vectors', () => expect(FootRule.threshold, vectors['threshold_c']));

  for (final c in (vectors['cases'] as List).cast<Map<String, dynamic>>()) {
    test(c['name'], () {
      final today = DateTime(2026, 10, 11, 9);
      final history = [
        for (final h in (c['history'] as List).cast<Map<String, dynamic>>())
          PastScan(today.subtract(Duration(days: h['days_ago'] as int)), m(h['dt']))
      ];
      final r = FootRule.evaluate(m(c['left']), m(c['right']), history, today,
          demo: c['demo'] as bool,
          samples: (c['samples'] as int?) ?? 4,
          spreadLeft: ((c['spread_left'] as num?) ?? 0).toDouble(),
          spreadRight: ((c['spread_right'] as num?) ?? 0).toDouble());
      final e = c['expect'] as Map<String, dynamic>;
      if (e['invalid'] == true) {
        expect(r, isNull);
        return;
      }
      expect(r, isNotNull);
      if (e.containsKey('level')) expect(r!.level, e['level']);
      if (e.containsKey('max_dt')) expect(r!.maxDt, closeTo((e['max_dt'] as num).toDouble(), 1e-9));
      if (e.containsKey('site')) expect(r!.site, e['site']);
      if (e.containsKey('confidence')) expect(r!.confidence, e['confidence']);
      if (e.containsKey('confidence_label')) expect(r!.confidenceLabel, e['confidence_label']);
      if (e.containsKey('warmer_side')) expect(r!.warmerSide, e['warmer_side']);
      if (e.containsKey('consecutive_days')) expect(r!.consecutiveDays, e['consecutive_days']);
    });
  }

  test('scanFromFrame builds a labelled scan and escalates in demo mode', () {
    final first = FootRule.scanFromFrame(
        left: {'mth1': 30.8}, right: {'mth1': 33.6}, history: [], source: 'simulated', demo: true)!;
    expect(first.level, 'amber');
    expect(first.isSimulated, isTrue);
    final second = FootRule.scanFromFrame(
        left: {'mth1': 30.8}, right: {'mth1': 33.6}, history: [first], source: 'simulated', demo: true)!;
    expect(second.level, 'red');
  });
}
