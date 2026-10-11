import 'package:flutter/material.dart';

import 'tokens.dart';

/// Light theme only: clinical readability first, large type for older users (body 16-17 sp),
/// 52 dp touch targets on primary actions. Rubik covers Latin and Arabic with one consistent voice.
class QadamTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: QColors.navy700,
      primary: QColors.navy700,
      onPrimary: Colors.white,
      secondary: QColors.sky400,
      onSecondary: QColors.navy900,
      surface: QColors.surface,
      onSurface: QColors.ink,
      error: QColors.alert,
    );
    const ink = QColors.ink;
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: 'Rubik');
    return base.copyWith(
      scaffoldBackgroundColor: QColors.paper,
      textTheme: base.textTheme
          .copyWith(
            displaySmall: const TextStyle(fontSize: 34, fontWeight: FontWeight.w600, height: 1.1, color: ink),
            headlineMedium: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600, height: 1.2, color: ink),
            headlineSmall: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.25, color: ink),
            titleLarge: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: ink),
            titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ink),
            bodyLarge: const TextStyle(fontSize: 17, height: 1.45, color: ink),
            bodyMedium: const TextStyle(fontSize: 15, height: 1.45, color: QColors.ink2),
            bodySmall: const TextStyle(fontSize: 13, height: 1.4, color: QColors.ink3),
            labelLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          )
          .apply(fontFamily: 'Rubik'),
      appBarTheme: const AppBarTheme(
        backgroundColor: QColors.paper,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontFamily: 'Rubik', fontSize: 19, fontWeight: FontWeight.w600, color: ink),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: QColors.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(QRadius.md),
          side: const BorderSide(color: QColors.line),
        ),
      ),
      dividerTheme: const DividerThemeData(color: QColors.line, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          backgroundColor: QColors.navy700,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontFamily: 'Rubik', fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(QRadius.sm)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          foregroundColor: QColors.navy800,
          side: const BorderSide(color: QColors.lineStrong),
          textStyle: const TextStyle(fontFamily: 'Rubik', fontSize: 16, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(QRadius.sm)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: QColors.navy700,
          textStyle: const TextStyle(fontFamily: 'Rubik', fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(QRadius.sm),
          borderSide: const BorderSide(color: QColors.lineStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(QRadius.sm),
          borderSide: const BorderSide(color: QColors.lineStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(QRadius.sm),
          borderSide: const BorderSide(color: QColors.navy700, width: 2),
        ),
        labelStyle: const TextStyle(color: QColors.ink2),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: QColors.surface,
        indicatorColor: QColors.sky100,
        surfaceTintColor: Colors.transparent,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'Rubik',
            fontSize: 12.5,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? QColors.navy900 : QColors.ink2,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(color: states.contains(WidgetState.selected) ? QColors.navy900 : QColors.ink2),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: QColors.surface,
        selectedColor: QColors.sky100,
        side: const BorderSide(color: QColors.lineStrong),
        labelStyle: const TextStyle(fontFamily: 'Rubik', fontSize: 14, color: QColors.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: QColors.navy900),
      listTileTheme: const ListTileThemeData(iconColor: QColors.navy700, contentPadding: EdgeInsets.symmetric(horizontal: 16)),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : null),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? QColors.navy700 : null),
      ),
    );
  }
}
