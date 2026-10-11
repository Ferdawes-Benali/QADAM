import 'package:flutter_test/flutter_test.dart';
import 'package:qadam_app/core/strings.dart';

void main() {
  test('every string exists in French, Arabic and Derja', () {
    allStrings.forEach((key, v) {
      expect(v.length, 3, reason: key);
      for (final s in v) {
        expect(s.trim(), isNotEmpty, reason: key);
      }
    });
  });

  test('placeholders are replaced', () {
    expect(translate('fr', 'time.m', {'n': '3'}), 'il y a 3 min');
    expect(translate('aeb', 'pair.ok', {'ref': 'QDM-2048'}), contains('QDM-2048'));
  });

  test('unknown language falls back to French, unknown key to the key', () {
    expect(translate('xx', 'common.yes'), 'Oui');
    expect(translate('fr', 'no.such.key'), 'no.such.key');
  });
}
