// lib/core/constants/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    const primaryGreen = Color(0xFF0E7C52);
    const brightGreen = Color(0xFF18B26B);
    const bg = Color(0xFFF6F8F7);
    const card = Color(0xFFFFFFFF);
    const border = Color(0xFFE7ECEA);
    const text = Color(0xFF14201B);
    const muted = Color(0xFF7C887F);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      fontFamily: 'Plus Jakarta Sans',
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        onPrimary: Colors.white,
        secondary: brightGreen,
        onSecondary: Colors.white,
        tertiary: muted,
        surface: card,
        onSurface: text,
        outline: border,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    const primaryGreen = Color(0xFF109B66);
    const brightGreen = Color(0xFF22C7A9);
    const bg = Color(0xFF0D110F);
    const card = Color(0xFF161C19);
    const border = Color(0xFF26322C);
    const text = Color(0xFFF0F4F2);
    const muted = Color(0xFF8B9E94);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      fontFamily: 'Plus Jakarta Sans',
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        onPrimary: Colors.white,
        secondary: brightGreen,
        onSecondary: Colors.black,
        tertiary: muted,
        surface: card,
        onSurface: text,
        outline: border,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
