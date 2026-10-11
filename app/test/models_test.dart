import 'package:flutter_test/flutter_test.dart';
import 'package:qadam_app/models/models.dart';

void main() {
  test('glucose bands match the hub (domain.glucose_band)', () {
    GlucoseEntry g(double v, String c) => GlucoseEntry(id: 'x', time: DateTime(2026), gL: v, context: c);
    expect(g(0.65, 'fasting').band, 'low');
    expect(g(1.20, 'fasting').band, 'in_target');
    expect(g(1.50, 'fasting').band, 'out_of_target');
    expect(g(1.50, 'after_meal').band, 'in_target');
    expect(g(2.80, 'after_meal').band, 'very_high');
  });

  test('scan round-trips through storage maps', () {
    final s = FootScan(
      id: 'a', time: DateTime(2026, 10, 11), left: {'mth1': 30.8}, right: {'mth1': 33.6}, dt: {'mth1': 2.8},
      maxDt: 2.8, site: 'mth1', warmerSide: 'right', level: 'amber', consecutiveDays: 1, confidence: 100,
      confidenceLabel: 'high', factors: {'samples': 1}, samples: 4, spreadLeft: 0.1, spreadRight: 0.2,
      source: 'hardware', demo: true,
    );
    final back = FootScan.fromMap(s.toMap());
    expect(back.level, 'amber');
    expect(back.right['mth1'], 33.6);
    expect(back.source, 'hardware');
  });

  test('medication dose toggling', () {
    final m = Medication(id: '1', name: 'Metformine', times: ['08:00', '20:00']);
    final d = DateTime(2026, 10, 11);
    m.toggle(d, '08:00');
    expect(m.isTaken(d, '08:00'), isTrue);
    m.toggle(d, '08:00');
    expect(m.isTaken(d, '08:00'), isFalse);
  });
}
