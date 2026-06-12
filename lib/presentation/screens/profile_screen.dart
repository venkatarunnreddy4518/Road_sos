import 'package:flutter/material.dart';
import 'dart:math' as math;
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
  // ── Design tokens ──
  Color get _bg => Theme.of(context).scaffoldBackgroundColor;
  Color get _card => Theme.of(context).colorScheme.surface;
  Color get _border => Theme.of(context).colorScheme.outline;
  Color get _line => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1F2B24) : const Color(0xFFEEF1F0);
  Color get _green => Theme.of(context).colorScheme.primary;
  Color get _greenSoft => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF143022) : const Color(0xFFE7F6EE);
  Color get _text => Theme.of(context).colorScheme.onSurface;
  Color get _muted => Theme.of(context).colorScheme.tertiary;
  Color get _iconColor => Theme.of(context).brightness == Brightness.dark ? const Color(0xFFA1B2A7) : const Color(0xFF44505F);
  Color get _chevColor => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF3E4E45) : const Color(0xFFC2C9CE);
  static const _amber = Color(0xFFF5A623);

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
          padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 90),
          children: [
            // ── Top bar ──
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 14, left: 4),
              child: Text(
                context.tr('profile'),
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: _text,
                  letterSpacing: -0.4,
                ),
              ),
            ),

            // ── User card ──
            _AnimatedCard(
              delay: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12142E1E),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // User row
                    InkWell(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18)),
                      onTap: () {
                        // TODO: Navigate to edit profile
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 18),
                        child: Row(
                          children: [
                            // Avatar with ring
                            SizedBox(
                              width: 56,
                              height: 56,
                              child: CustomPaint(
                                painter: _AvatarRingPainter(progress: 0.75),
                              child: Center(
                                child: Icon(
                                  Icons.person_outline_rounded,
                                  size: 26,
                                  color: _muted,
                                ),
                              ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Name & phone
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName.isNotEmpty
                                        ? user.displayName
                                        : 'User',
                                    style: TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w800,
                                      color: _text,
                                      height: 1.2,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    user.phone ?? user.email ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _muted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _chevron(),
                          ],
                        ),
                      ),
                    ),

                    // Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(height: 1, color: _line),
                    ),

                    // Rating row
                    InkWell(
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(18)),
                      onTap: () {
                        // TODO: Navigate to rating details
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 15),
                        child: Row(
                          children: [
                            // Star
                            const SizedBox(
                              width: 34,
                              child: Center(
                                child: Icon(Icons.star_rounded,
                                    size: 24, color: _amber),
                              ),
                            ),
                            const SizedBox(width: 13),
                            // Rating text
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: _text,
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                  children: [
                                    const TextSpan(text: '4.80 '),
                                    TextSpan(
                                      text: context.tr('my_rating'),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            _chevron(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Menu card ──
            _AnimatedCard(
              delay: 60,
              child: Container(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12142E1E),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _menuRow(
                      icon: Icons.help_outline_rounded,
                      title: context.tr('help_support'),
                      isFirst: true,
                      onTap: () {},
                    ),
                    _menuRow(
                      icon: Icons.directions_car_outlined,
                      title: context.tr('saved_vehicles'),
                      subtitle: '2 ${context.tr('vehicles_suffix')}',
                      onTap: () {},
                    ),
                    _menuRow(
                      icon: Icons.account_balance_wallet_outlined,
                      title: context.tr('payments'),
                      onTap: () {},
                    ),
                    _menuRow(
                      icon: Icons.history_rounded,
                      title: context.tr('my_sos'),
                      onTap: () {},
                    ),
                    _menuRow(
                      icon: Icons.shield_outlined,
                      title: context.tr('safety'),
                      onTap: () {},
                    ),
                    _menuRow(
                      icon: Icons.phone_outlined,
                      title: context.tr('emergency_contacts'),
                      subtitle: '2 ${context.tr('added_suffix')}',
                      onTap: () {},
                    ),
                    _menuRow(
                      icon: Icons.card_giftcard_rounded,
                      title: context.tr('refer_earn'),
                      subtitle: context.tr('get_50'),
                      subtitleGreen: true,
                      onTap: () {},
                    ),
                    _menuRow(
                      icon: Icons.emoji_events_outlined,
                      title: context.tr('my_rewards'),
                      onTap: () {},
                    ),
                    _menuRow(
                      icon: Icons.language_rounded,
                      title: context.tr('app_language'),
                      pill: AppStrings.languageNames[
                          context.watch<LocaleController>().code],
                      isLast: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Provider mode ──
            _AnimatedCard(
              delay: 120,
              child: Container(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12142E1E),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: _menuRow(
                  icon: Icons.handyman_outlined,
                  title: context.tr('provider_mode'),
                  subtitle: context.tr('provider_sub'),
                  isFirst: true,
                  isLast: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ProviderInboxScreen()),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Sign out button ──
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFC0392B),
                  side: BorderSide(color: _border, width: 1.5),
                  backgroundColor: _card,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  await context.read<AuthState>().logout();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  }
                },
                child: Text(
                  context.tr('sign_out'),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Version text ──
            const Center(
              child: Text(
                'Roadside SOS · v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFA8B0AC),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Chevron icon ──
  Widget _chevron() {
    return Icon(
      Icons.chevron_right_rounded,
      size: 20,
      color: _chevColor,
    );
  }

  // ── Menu row builder ──
  Widget _menuRow({
    required IconData icon,
    required String title,
    String? subtitle,
    bool subtitleGreen = false,
    String? pill,
    bool isFirst = false,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        if (!isFirst)
          Padding(
            padding: const EdgeInsets.only(left: 54),
            child: Container(height: 1, color: _line),
          ),
        InkWell(
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(18) : Radius.zero,
            bottom: isLast ? const Radius.circular(18) : Radius.zero,
          ),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Center(
                    child: Icon(icon, size: 23, color: _iconColor),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: _text,
                          letterSpacing: -0.1,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: subtitleGreen ? _green : _muted,
                            fontWeight: subtitleGreen
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (pill != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _greenSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      pill,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _green,
                      ),
                    ),
                  )
                else
                  _chevron(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Avatar ring painter ──────────────────────────────────────────────────────
class _AvatarRingPainter extends CustomPainter {
  final double progress;
  _AvatarRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1.5;

    // Background circle
    final bgPaint = Paint()
      ..color = const Color(0xFFE7ECEA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final arcPaint = Paint()
      ..color = const Color(0xFF0E7C52)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AvatarRingPainter old) =>
      old.progress != progress;
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
