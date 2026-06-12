import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/i18n/strings.dart';
import '../../data/api/profile_api.dart';
import '../state/auth_state.dart';
import '../state/theme_state.dart';
import 'ai_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController>();
    final auth = context.watch<AuthState>();
    final themeState = context.watch<ThemeState>();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings'))),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(context.tr('language'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          ...AppStrings.supported.map((code) {
            return RadioListTile<String>(
              value: code,
              groupValue: locale.code,
              title: Text(AppStrings.languageNames[code] ?? code),
              onChanged: (v) async {
                if (v == null) return;
                final localeCtrl = context.read<LocaleController>();
                final signedIn = context.read<AuthState>().isAuthenticated;
                await localeCtrl.setLanguage(v);
                // Mirror to profile when signed in (FR-029).
                if (signedIn) {
                  try {
                    await ProfileApi().update(preferredLanguage: v);
                  } catch (_) {}
                }
              },
            );
          }),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(context.tr('theme'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.system,
            groupValue: themeState.themeMode,
            title: Text(context.tr('theme_system')),
            onChanged: (v) {
              if (v != null) themeState.setThemeMode(v);
            },
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.light,
            groupValue: themeState.themeMode,
            title: Text(context.tr('theme_light')),
            onChanged: (v) {
              if (v != null) themeState.setThemeMode(v);
            },
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.dark,
            groupValue: themeState.themeMode,
            title: Text(context.tr('theme_dark')),
            onChanged: (v) {
              if (v != null) themeState.setThemeMode(v);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.psychology, color: Color(0xFF0E7C52)),
            title: Text(context.tr('ai_settings')),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AiSettingsScreen()),
              );
            },
          ),
          if (auth.isAuthenticated) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFB3261E)),
              title: Text(context.tr('logout'), style: const TextStyle(color: Color(0xFFB3261E))),
              onTap: () async {
                await context.read<AuthState>().logout();
                if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
              },
            ),
          ],
        ],
      ),
    );
  }
}
