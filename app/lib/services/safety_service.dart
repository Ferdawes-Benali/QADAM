import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Deterministic safety layer, on the phone (works offline, zero latency on the critical triage action):
///   1. red-flag triage  -> fixed emergency / urgent message (no AI)
///   2. verified library -> answer when the hub / AI is unreachable
/// Same JSON files as the hub (shared/red_flags.json, shared/assistant_library.json).
class SafetyService {
  static Map<String, dynamic>? _flags;
  static Map<String, dynamic>? _library;

  static Future<void> load() async {
    _flags ??= jsonDecode(await rootBundle.loadString('assets/data/red_flags.json')) as Map<String, dynamic>;
    _library ??= jsonDecode(await rootBundle.loadString('assets/data/assistant_library.json')) as Map<String, dynamic>;
  }

  /// For tests: inject the JSON directly.
  static void loadFrom(Map<String, dynamic> flags, Map<String, dynamic> library) {
    _flags = flags;
    _library = library;
  }

  static final _tashkeel = RegExp('[ؐ-ًؚ-ٰٟۖ-ۭـ]');
  static const _accents = {
    'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'î': 'i', 'ï': 'i', 'í': 'i',
    'ô': 'o', 'ö': 'o', 'ó': 'o', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u', 'ç': 'c', 'ÿ': 'y', 'œ': 'oe',
  };

  static String normalize(String text) {
    var t = text.toLowerCase().replaceAll(_tashkeel, '');
    t = t
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('’', "'");
    final b = StringBuffer();
    for (final ch in t.split('')) {
      b.write(_accents[ch] ?? ch);
    }
    return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _lang(String lang) => (lang == 'ar' || lang == 'aeb') ? lang : 'fr';

  /// Returns (tier, ruleId, message) or null when no danger sign is detected.
  static ({String tier, String ruleId, String text})? triage(String question, String lang) {
    final flags = _flags;
    if (flags == null) return null;
    final q = normalize(question);
    Map<String, dynamic>? best;
    for (final r in (flags['rules'] as List).cast<Map<String, dynamic>>()) {
      final hit = (r['keywords'] as List).any((k) => q.contains(normalize(k.toString())));
      if (!hit) continue;
      if (best == null || (r['tier'] == 'emergency' && best['tier'] != 'emergency')) best = r;
    }
    if (best == null) return null;
    final tier = best['tier'].toString();
    final text = ((flags['tiers'] as Map)[tier] as Map)[_lang(lang)].toString();
    return (tier: tier, ruleId: best['id'].toString(), text: text);
  }

  /// Returns (topicId or null, answer in the requested language).
  static ({String? topic, String text}) libraryAnswer(String question, String lang) {
    final lib = _library;
    if (lib == null) return (topic: null, text: '');
    final q = normalize(question);
    Map<String, dynamic>? best;
    var bestScore = 0;
    for (final t in (lib['topics'] as List).cast<Map<String, dynamic>>()) {
      var score = 0;
      for (final l in const ['fr', 'ar', 'aeb']) {
        for (final k in ((t['keywords'] as Map)[l] as List? ?? const [])) {
          final nk = normalize(k.toString());
          if (nk.isNotEmpty && q.contains(nk)) score += nk.length;
        }
      }
      if (score > bestScore) {
        best = t;
        bestScore = score;
      }
    }
    if (best == null) return (topic: null, text: (lib['fallback'] as Map)[_lang(lang)].toString());
    return (topic: best['id'].toString(), text: (best['answer'] as Map)[_lang(lang)].toString());
  }

  /// Topic ids and their first keyword, for suggestion chips in the assistant.
  static List<String> topicIds() =>
      _library == null ? const [] : [for (final t in (_library!['topics'] as List)) (t as Map)['id'].toString()];

  static String topicAnswer(String id, String lang) {
    final lib = _library;
    if (lib == null) return '';
    for (final t in (lib['topics'] as List).cast<Map<String, dynamic>>()) {
      if (t['id'] == id) return (t['answer'] as Map)[_lang(lang)].toString();
    }
    return '';
  }
}
