import 'package:flutter_test/flutter_test.dart';
import 'package:qadam_app/services/foot_rule.dart';

void main() {
  final normal = {
    'left': {'hallux': 30.5, 'mth1': 30.8, 'mth5': 30.2, 'heel': 29.6},
    'right': {'hallux': 30.7, 'mth1': 31.0, 'mth5': 30.1, 'heel': 29.9},
  };
  final hot = {
    'left': {'hallux': 30.5, 'mth1': 30.8, 'mth5': 30.2, 'heel': 29.6},
    'right': {'hallux': 30.7, 'mth1': 33.6, 'mth5': 30.1, 'heel': 29.9},
  };

  test('normal scan is green', () {
    final s = FootRule.fromPayload(normal, [])!;
    expect(s.status, 'green');
    expect(s.maxDt, lessThan(2.2));
  });

  test('one hot scan is amber at mth1', () {
    final s = FootRule.fromPayload(hot, [])!;
    expect(s.status, 'amber');
    expect(s.site, 'mth1');
  });

  test('two hot scans in demo mode turn red', () {
    final first = FootRule.fromPayload(hot, [], demoMode: true)!;
    final second = FootRule.fromPayload(hot, [first], demoMode: true)!;
    expect(second.status, 'red');
  });

  test('Uno DHT payload is accepted as one site', () {
    final s = FootRule.fromPayload({'left': 31.0, 'right': 33.5}, [])!;
    expect(s.site, 'mth1');
    expect(s.status, 'amber');
  });
}
