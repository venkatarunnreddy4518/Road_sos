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

  static const _bg = Color(0xFFF7F8FA);
  static const _ink = Color(0xFF14181F);
  static const _muted = Color(0xFF9CA3AF);
  static const _line = Color(0xFFEEF0F3);
  static const _blue = Color(0xFF2563EB);
  static const _brand = Color(0xFF7C5CFC);

  Future<void> _setLanguage(BuildContext context, String code) async {
    final localeCtrl = context.read<LocaleController>();
    final signedIn = context.read<AuthState>().isAuthenticated;
    await localeCtrl.setLanguage(code);
    // Mirror to profile when signed in (FR-029).
    if (signedIn) {
      try {
        await ProfileApi().update(preferredLanguage: code);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController>();
    final auth = context.watch<AuthState>();
    final themeState = context.watch<ThemeState>();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _ink,
        title: Text(context.tr('settings'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, fontFamily: 'Outfit')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // ── Language ──
          _sectionLabel(context.tr('language'), icon: Icons.translate_rounded),
          ...AppStrings.supported.map((code) => _radioRow(
                active: locale.code == code,
                onTap: () => _setLanguage(context, code),
                child: Text(AppStrings.languageNames[code] ?? code,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
              )),
          const SizedBox(height: 18),

          // ── Theme ──
          _sectionLabel(context.tr('theme')),
          _themeRow(themeState, ThemeMode.system, Icons.computer_rounded, context.tr('theme_system')),
          _themeRow(themeState, ThemeMode.light, Icons.light_mode_rounded, context.tr('theme_light')),
          _themeRow(themeState, ThemeMode.dark, Icons.dark_mode_rounded, context.tr('theme_dark')),
          const SizedBox(height: 18),

          // ── AI settings ──
          GestureDetector(
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AiSettingsScreen())),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _line)),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: _brand.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(11)),
                    child: const Icon(Icons.psychology_rounded, size: 18, color: _brand),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(context.tr('ai_settings'),
                            style: const TextStyle(
                                fontFamily: 'Outfit', fontWeight: FontWeight.w700, fontSize: 14, color: _ink)),
                        const SizedBox(height: 2),
                        const Text('AI mechanic preferences & data',
                            style: TextStyle(fontSize: 12, color: _muted)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFC0C4CC)),
                ],
              ),
            ),
          ),

          // ── Log out ──
          if (auth.isAuthenticated) ...[
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () async {
                await context.read<AuthState>().logout();
                if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFE5484D)),
                    const SizedBox(width: 8),
                    Text(context.tr('logout'),
                        style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: Color(0xFFE5484D))),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: _muted),
            const SizedBox(width: 6),
          ],
          Text(text.toUpperCase(),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: _muted,
                  fontFamily: 'Outfit')),
        ],
      ),
    );
  }

  Widget _themeRow(ThemeState state, ThemeMode mode, IconData icon, String label) {
    final active = state.themeMode == mode;
    return _radioRow(
      active: active,
      onTap: () => state.setThemeMode(mode),
      child: Row(
        children: [
          Icon(icon, size: 17, color: active ? _blue : const Color(0xFF6B7280)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
        ],
      ),
    );
  }

  Widget _radioRow({required bool active, required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? _blue : _line, width: active ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: active ? _blue : const Color(0xFFD1D5DB), width: 2),
              ),
              child: active
                  ? Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: _blue),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
