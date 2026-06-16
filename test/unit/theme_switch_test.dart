import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadside_help/presentation/state/theme_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeState', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to light theme', () async {
      // The app opens in light mode unless the user has explicitly chosen
      // another mode in Settings (see ThemeState._themeMode default).
      final state = ThemeState();
      await state.restore();
      expect(state.themeMode, ThemeMode.light);
    });

    test('sets theme mode and persists it', () async {
      final state = ThemeState();
      await state.restore();
      
      await state.setThemeMode(ThemeMode.dark);
      expect(state.themeMode, ThemeMode.dark);

      // Restore in a new instance and verify persistence
      final state2 = ThemeState();
      await state2.restore();
      expect(state2.themeMode, ThemeMode.dark);
    });

    test('restores custom theme if saved', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'light',
      });
      final state = ThemeState();
      await state.restore();
      expect(state.themeMode, ThemeMode.light);
    });
  });
}
