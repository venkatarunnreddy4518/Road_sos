// test/presentation/i18n_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roadside_help/presentation/widgets/language_switcher.dart';
import 'package:roadside_help/presentation/state/app_state.dart';
import 'package:roadside_help/core/i18n/app_localization.dart';

void main() {
  testWidgets('LanguageSwitcher should update the app locale when a language is selected', (WidgetTester tester) async {
    final appState = AppState();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LanguageSwitcher(state: appState),
        ),
      ),
    );

    // Find the Hindi language option and tap it
    await tester.tap(find.text('Hindi'));
    await tester.pump();

    // Verify that the state was updated
    // Note: In a real app, AppState would handle the actual Locale change
    expect(appState.currentLanguage, 'hi');
  });
}
