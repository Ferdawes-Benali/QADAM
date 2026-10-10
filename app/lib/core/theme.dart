import 'package:flutter/material.dart';

/// "Warm & friendly" palette: cream background, coral primary, teal secondary.
/// Green / amber / red are reserved for health status only.
class QadamColors {
  static const cream = Color(0xFFFFF8F0);
  static const coral = Color(0xFFE07A5F);
  static const teal = Color(0xFF3D9A8B);
  static const ink = Color(0xFF2F2A26);
  static const ok = Color(0xFF4CAF50);
  static const watch = Color(0xFFF2A541);
  static const alert = Color(0xFFE05252);

  static Color forStatus(String status) => switch (status) {
        'red' => alert,
        'amber' => watch,
        'green' => ok,
        _ => Colors.grey,
      };
}

class QadamTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: QadamColors.coral,
      primary: QadamColors.coral,
      secondary: QadamColors.teal,
      surface: QadamColors.cream,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: QadamColors.cream,
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.w700, color: QadamColors.ink),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: QadamColors.ink),
        bodyLarge: TextStyle(fontSize: 17, color: QadamColors.ink), // large text for older users
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
