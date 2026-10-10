import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/diabetes_content.dart';
import '../models/models.dart';

/// Gemini REST client. Run with:
///   flutter run --dart-define=GEMINI_API_KEY=xxxx [--dart-define=GEMINI_MODEL=<current flash model>]
/// Demo only: a key inside the app can be extracted. Before any real release, proxy calls through a server.
class GeminiService {
  static const _key = String.fromEnvironment('GEMINI_API_KEY');
  static const _model = String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-2.5-flash');

  bool get isConfigured => _key.isNotEmpty;

  static String _languageName(String lang) => switch (lang) {
        'aeb' => 'Tunisian Arabic (Derja) written in Arabic script, simple everyday words',
        'ar' => 'simple Modern Standard Arabic',
        _ => 'simple French',
      };

  static String _safety(String lang) => '''
You are Qadam, a kind assistant for people with diabetes in Tunisia. Answer in ${_languageName(lang)}.
Rules you must always follow:
- You support, you never diagnose. Never change, start or stop a medication or an insulin dose: say "ask your doctor".
- For danger signs (wound, black/red hot foot, fever, glucose < 0.70 g/L with confusion, chest pain), tell the person to call SAMU 190 or go to the emergency department now.
- Keep answers short (max 4 sentences), concrete, warm. No markdown tables.
- Only use the reference text below and general well-known diabetes education. If unsure, say so and suggest the doctor.
REFERENCE:
$footCareBasics
$glucoseBasics
''';

  Future<String> _ask(String system, String user) async {
    if (!isConfigured) return '(AI non configurée : lancez l\'app avec --dart-define=GEMINI_API_KEY=...)';
    final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_key');
    final body = {
      'systemInstruction': {'parts': [{'text': system}]},
      'contents': [
        {'role': 'user', 'parts': [{'text': user}]}
      ],
      'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 400},
    };
    try {
      final r = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) return 'AI error ${r.statusCode}';
      final j = jsonDecode(r.body);
      return (j['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '').toString().trim();
    } catch (e) {
      return 'AI indisponible (réseau).';
    }
  }

  /// 1) Explain a foot scan in the patient's language.
  Future<String> explainScan(FootScan s, Profile p, String lang) => _ask(_safety(lang), '''
Explain this foot temperature scan to the patient in 2-3 sentences and give one concrete action.
Status: ${s.status} (green = normal, amber = one hot spot today, red = same hot spot two days in a row).
Largest left/right difference: ${s.maxDt.toStringAsFixed(1)} C at site ${s.site}.
Patient: diabetes ${p.diabetesType}, past foot ulcer: ${p.pastUlcer}, numbness: ${p.numbness}.''');

  /// 2) Explain a glucose reading.
  Future<String> explainGlucose(GlucoseEntry g, Profile p, String lang) => _ask(_safety(lang), '''
Explain this blood glucose reading in 2 sentences: ${g.gL.toStringAsFixed(2)} g/L, context ${g.context}, band ${g.band}.
Patient diabetes type ${p.diabetesType}, treatment ${p.treatment}. Give one practical tip.''');

  /// 3) Weekly/monthly summary for the doctor (always in French, factual).
  Future<String> doctorSummary(Profile p, List<GlucoseEntry> g, List<FootScan> scans, int medsAdherencePct) {
    final gl = g.map((e) => '${e.time.toIso8601String().substring(0, 16)} ${e.gL.toStringAsFixed(2)} ${e.context}').join('\n');
    final fs = scans.map((s) => '${s.time.toIso8601String().substring(0, 10)} ${s.status} maxDT=${s.maxDt.toStringAsFixed(1)} ${s.site}').join('\n');
    return _ask(_safety('fr'), '''
Rédige pour le médecin un résumé factuel de 6 lignes maximum (pas de conseil thérapeutique) :
Patient : ${p.name}, diabète ${p.diabetesType} depuis ${p.yearDiagnosed ?? '?'}, traitement ${p.treatment}, antécédent d'ulcère ${p.pastUlcer}.
Observance médicaments : $medsAdherencePct %.
Glycémies (g/L) :
$gl
Scans des pieds :
$fs''');
  }

  /// 4) Q&A coach grounded on the patient's diabetes type.
  Future<String> coach(String question, Profile p, String lang) => _ask(
        _safety(lang) + '\nPATIENT DIABETES TYPE INFO:\n${diabetesTypeInfo[p.diabetesType] ?? ''}',
        question,
      );
}
