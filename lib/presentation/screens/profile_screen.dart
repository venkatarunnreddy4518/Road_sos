import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import '../../core/i18n/l10n_ext.dart';
import '../../core/i18n/strings.dart';

import '../state/auth_state.dart';
import 'auth/email_auth_screen.dart';
import 'provider/provider_inbox_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── Design tokens from HTML ──
  static const Color _bg = Color(0xFFF7F8FC);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFECEEF4);
  static const Color _primary = Color(0xFF2563EB);
  static const Color _primaryLight = Color(0xFFEEF3FF);
  static const Color _green = Color(0xFF16A34A);
  static const Color _greenLight = Color(0xFFDCFCE7);
  static const Color _text = Color(0xFF0F172A);
  static const Color _sub = Color(0xFF64748B);
  static const Color _muted = Color(0xFF94A3B8);
  static const Color _red = Color(0xFFDC2626);

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 18, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _sub,
          letterSpacing: 0.4,
          fontFamily: 'Outfit',
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildItem({
    required String emoji,
    required String title,
    String? subtitle,
    Widget? trailing,
    bool isLast = false,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: titleColor ?? _text,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _muted,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing
                else
                  const Text(
                    '›',
                    style: TextStyle(
                      fontSize: 18,
                      color: _muted,
                    ),
                  ),
              ],
            ),
          ),
          if (!isLast)
            const Divider(
              height: 1,
              thickness: 1,
              color: _border,
              indent: 0,
              endIndent: 0,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    if (!auth.isAuthenticated) {
      return const _GuestPrompt();
    }

    final user = auth.user!;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 90),
          children: [
            // Header (c2-top)
            Container(
              color: _white,
              padding: const EdgeInsets.only(top: 30, bottom: 20, left: 20, right: 20),
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: _primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _primary,
                        width: 3,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '👤',
                      style: TextStyle(fontSize: 36),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.displayName.isNotEmpty ? user.displayName : 'Arunn Reddy',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: _text,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? user.phone ?? 'demo.user@gmail.com',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _muted,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: _greenLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('⭐', style: TextStyle(fontSize: 11)),
                            SizedBox(width: 4),
                            Text(
                              '4.8 Rating',
                              style: TextStyle(
                                color: _green,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Outfit',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: _primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🚗', style: TextStyle(fontSize: 11)),
                            SizedBox(width: 4),
                            Text(
                              '2 Vehicles',
                              style: TextStyle(
                                color: _primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Outfit',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: _border),

            // Account Section
            _AnimatedCard(
              delay: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Account'),
                  _buildSectionCard([
                    _buildItem(
                      emoji: '🚗',
                      title: context.tr('saved_vehicles'),
                      subtitle: '2 ${context.tr('vehicles_suffix')}',
                      onTap: () {},
                    ),
                    _buildItem(
                      emoji: '💳',
                      title: context.tr('payments'),
                      onTap: () {},
                    ),
                    _buildItem(
                      emoji: '🕐',
                      title: context.tr('my_sos'),
                      isLast: true,
                      onTap: () {},
                    ),
                  ]),
                ],
              ),
            ),

            // Safety Section
            _AnimatedCard(
              delay: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Safety'),
                  _buildSectionCard([
                    _buildItem(
                      emoji: '🛡️',
                      title: context.tr('safety'),
                      onTap: () {},
                    ),
                    _buildItem(
                      emoji: '📞',
                      title: context.tr('emergency_contacts'),
                      subtitle: '2 ${context.tr('added_suffix')}',
                      isLast: true,
                      onTap: () {},
                    ),
                  ]),
                ],
              ),
            ),

            // More Section
            _AnimatedCard(
              delay: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('More'),
                  _buildSectionCard([
                    _buildItem(
                      emoji: '🎁',
                      title: context.tr('refer_earn'),
                      subtitle: context.tr('get_50'),
                      onTap: () {},
                    ),
                    _buildItem(
                      emoji: '🌐',
                      title: context.tr('app_language'),
                      subtitle: AppStrings.languageNames[context.watch<LocaleController>().code],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      ),
                    ),
                    _buildItem(
                      emoji: '❓',
                      title: context.tr('help_support'),
                      onTap: () {},
                    ),
                    _buildItem(
                      emoji: '🛠️',
                      title: context.tr('provider_mode'),
                      subtitle: context.tr('provider_sub'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ProviderInboxScreen()),
                      ),
                    ),
                    _buildItem(
                      emoji: '🚪',
                      title: context.tr('sign_out'),
                      titleColor: _red,
                      trailing: const Text(
                        '›',
                        style: TextStyle(
                          fontSize: 18,
                          color: _red,
                        ),
                      ),
                      isLast: true,
                      onTap: () async {
                        await context.read<AuthState>().logout();
                        if (context.mounted) {
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        }
                      },
                    ),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Version text
            const Center(
              child: Text(
                'Roadside SOS · v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: _muted,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Outfit',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ── Animated card wrapper ────────────────────────────────────────────────────

class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedCard({required this.child, this.delay = 0});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: AnimatedBuilder(
        animation: _slide,
        builder: (context, child) {
          return Transform.translate(
            offset: _slide.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

// ── Guest prompt ─────────────────────────────────────────────────────────────
class _GuestPrompt extends StatelessWidget {
  const _GuestPrompt();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    final card = theme.colorScheme.surface;
    final text = theme.colorScheme.onSurface;
    final muted = theme.colorScheme.tertiary;
    final green = theme.colorScheme.primary;
    final greenSoft = isDark ? const Color(0xFF143022) : const Color(0xFFE7F6EE);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: greenSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Icon(Icons.person_outline_rounded,
                        size: 36, color: green),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  context.tr('sign_in_continue'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('sign_in_profile_prompt'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [theme.colorScheme.secondary, theme.colorScheme.primary],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: green.withValues(alpha: 0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const EmailAuthScreen()),
                        ),
                        child: Center(
                          child: Text(
                            context.tr('login'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
