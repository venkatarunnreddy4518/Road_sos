// lib/core/constants/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    const ink = Color(0xFF111111);
    const softGray = Color(0xFFFAFAFB);
    const borderGray = Color(0xFFE5E5E7);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: softGray,
      colorScheme: const ColorScheme.light(
        primary: ink,
        onPrimary: Colors.white,
        secondary: Color(0xFF333333),
        onSecondary: Colors.white,
        tertiary: Color(0xFF666666),
        surface: Colors.white,
        onSurface: ink,
        outline: borderGray,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: ink,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderGray, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: borderGray, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    const paperWhite = Color(0xFFF5F5F7);
    const deepBlack = Color(0xFF0F0F10);
    const surfaceCharcoal = Color(0xFF18181A);
    const borderCharcoal = Color(0xFF2C2C2E);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepBlack,
      colorScheme: const ColorScheme.dark(
        primary: paperWhite,
        onPrimary: deepBlack,
        secondary: Color(0xFFCCCCCC),
        onSecondary: deepBlack,
        tertiary: Color(0xFF999999),
        surface: surfaceCharcoal,
        onSurface: paperWhite,
        outline: borderCharcoal,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceCharcoal,
        foregroundColor: paperWhite,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surfaceCharcoal,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderCharcoal, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: paperWhite,
          foregroundColor: deepBlack,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: paperWhite,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: borderCharcoal, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
