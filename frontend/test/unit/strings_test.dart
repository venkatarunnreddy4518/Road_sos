import 'package:flutter_test/flutter_test.dart';
import 'package:roadside_help/core/i18n/strings.dart';

void main() {
  group('AppStrings localization', () {
    test('returns translated value for known key/lang', () {
      expect(AppStrings.of('en', 'call'), 'Call');
      expect(AppStrings.of('hi', 'call'), isNotEmpty);
      expect(AppStrings.of('te', 'call'), isNotEmpty);
    });

    test('falls back to English for missing language', () {
      // 'xx' is unsupported -> English fallback.
      expect(AppStrings.of('xx', 'login'), AppStrings.of('en', 'login'));
    });

    test('returns key itself for unknown key', () {
      expect(AppStrings.of('en', 'no_such_key'), 'no_such_key');
    });

    test('every supported language has a display name', () {
      for (final code in AppStrings.supported) {
        expect(AppStrings.languageNames[code], isNotNull);
      }
    });
  });
}
