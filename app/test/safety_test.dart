import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qadam_app/services/safety_service.dart';

void main() {
  setUpAll(() {
    SafetyService.loadFrom(
      jsonDecode(File('assets/data/red_flags.json').readAsStringSync()) as Map<String, dynamic>,
      jsonDecode(File('assets/data/assistant_library.json').readAsStringSync()) as Map<String, dynamic>,
    );
  });

  test('red flags are caught before any AI, in Derja and French', () {
    expect(SafetyService.triage('عندي جرح في ساقي', 'aeb')?.tier, 'urgent');
    expect(SafetyService.triage('صُبعي ولّات كحلة', 'aeb')?.tier, 'urgent');
    expect(SafetyService.triage("J'ai une douleur dans la poitrine", 'fr')?.tier, 'emergency');
    expect(SafetyService.triage('My foot is black and smells', 'fr')?.text, contains('190'));
  });

  test('normal questions are not flagged', () {
    expect(SafetyService.triage('نجم نمشي حافي في البحر؟', 'aeb'), isNull);
    expect(SafetyService.triage('شنوة الحمية متاع السكر؟', 'aeb'), isNull);
  });

  test('library answers the barefoot question in Derja', () {
    final a = SafetyService.libraryAnswer('نجم نمشي حافي في البحر؟', 'aeb');
    expect(a.topic, 'barefoot');
    expect(a.text, startsWith('لا'));
  });

  test('dose questions go to the treatment topic (never a dose)', () {
    expect(SafetyService.libraryAnswer('Est-ce que je peux doubler ma dose d\'insuline ?', 'fr').topic, 'treatment_change');
  });

  test('normalisation removes accents and Arabic diacritics', () {
    expect(SafetyService.normalize('Fièvre  ÉLEVÉE'), 'fievre elevee');
    expect(SafetyService.normalize('حُمّى'), 'حمي');
  });
}
