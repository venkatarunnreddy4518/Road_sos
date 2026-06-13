import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_theme.dart';
import 'core/i18n/strings.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/welcome_screen.dart';
import 'presentation/state/ai_config_state.dart';
import 'presentation/state/auth_state.dart';
import 'presentation/state/theme_state.dart';

void main() {
  runApp(const RoadsideHelpApp());
}

class RoadsideHelpApp extends StatelessWidget {
  const RoadsideHelpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleController()..load()),
        ChangeNotifierProvider(create: (_) => AuthState()..restore()),
        ChangeNotifierProvider(create: (_) => ThemeState()..restore()),
        ChangeNotifierProvider(create: (_) => AiConfigState()..load()),
      ],
      child: Consumer2<LocaleController, ThemeState>(
        builder: (context, locale, themeState, _) {
          return MaterialApp(
            title: 'Roadside Help',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeState.themeMode,
            locale: locale.locale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppStrings.supported.map((c) => Locale(c)),
            home: const _Root(),
          );
        },
      ),
    );
  }
}

/// Routes between welcome and home based on the session state (FR-002/FR-005).
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
      case AuthStatus.guest:
        return const HomeScreen();
      case AuthStatus.unauthenticated:
        return const WelcomeScreen();
    }
  }
}
