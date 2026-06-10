import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/app_theme.dart';
import 'presentation/screens/problem_selection_screen.dart';

void main() {
  runApp(const RoadsideHelpApp());
}

class RoadsideHelpApp extends StatelessWidget {
  const RoadsideHelpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roadside Help',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
      ],
      home: const ProblemSelectionScreen(),
    );
  }
}
