// lib/presentation/state/theme_state.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState extends ChangeNotifier {
  // Default to light: the app should open in light mode unless the user has
  // explicitly chosen another mode in Settings.
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode');
    if (saved != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => ThemeMode.light,
      );
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }
}
