import 'package:flutter/material.dart';

/// Qadam design tokens. Same values as hub/static/styles.css (see docs/design-system.md).
/// Brand colours are sampled from the official logo: navy #102D4B (wordmark) and sky #8DBADB (footprint).
class QColors {
  // brand
  static const navy900 = Color(0xFF102D4B);
  static const navy800 = Color(0xFF173A5E);
  static const navy700 = Color(0xFF1F4C78);
  static const navy600 = Color(0xFF2A5F92);
  static const sky400 = Color(0xFF8DBADB);
  static const sky200 = Color(0xFFC9DFEF);
  static const sky100 = Color(0xFFE4EFF8);
  static const sky50 = Color(0xFFF2F7FC);
  // neutrals: warm paper rather than clinical grey
  static const paper = Color(0xFFF7F5F1);
  static const surface = Color(0xFFFFFFFF);
  static const line = Color(0xFFE2DED6);
  static const lineStrong = Color(0xFFCFC9BD);
  static const ink = Color(0xFF102D4B);
  static const ink2 = Color(0xFF4A5B6E);
  static const ink3 = Color(0xFF5F6B78);
  // semantic: reserved for health status, always paired with a shape and a word
  static const ok = Color(0xFF1E7A4F);
  static const okBg = Color(0xFFE4F3EA);
  static const watch = Color(0xFF8A5300);
  static const watchFill = Color(0xFFF2A93B);
  static const watchBg = Color(0xFFFFF2DA);
  static const alert = Color(0xFFB42318);
  static const alertBg = Color(0xFFFDE8E6);
  static const sim = Color(0xFF475467);
  static const simBg = Color(0xFFEEF0F3);

  static Color level(String level) => switch (level) {
        'red' => alert,
        'amber' => watchFill,
        'green' => ok,
        _ => ink3,
      };
  static Color levelText(String level) => switch (level) {
        'red' => alert,
        'amber' => watch,
        'green' => ok,
        _ => ink3,
      };
  static Color levelBg(String level) => switch (level) {
        'red' => alertBg,
        'amber' => watchBg,
        'green' => okBg,
        _ => simBg,
      };
}

class QSpace {
  static const s1 = 4.0, s2 = 8.0, s3 = 12.0, s4 = 16.0, s5 = 24.0, s6 = 32.0, s7 = 48.0;
}

class QRadius {
  static const sm = 8.0, md = 12.0, lg = 18.0;
}
