// lib/presentation/widgets/language_switcher.dart
import 'package:flutter/material.dart';
import 'package:roadside_help/presentation/state/app_state.dart';

class LanguageSwitcher extends StatelessWidget {
  final AppState state;

  const LanguageSwitcher({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: state.currentLanguage,
      items: const [
        DropdownMenuItem(value: 'en', child: Text('English')),
        DropdownMenuItem(value: 'hi', child: Text('Hindi')),
        DropdownMenuItem(value: 'ta', child: Text('Tamil')),
        DropdownMenuItem(value: 'te', child: Text('Telugu')),
      ],
      onChanged: (value) {
        if (value != null) {
          state.setLanguage(value);
        }
      },
    );
  }
}
