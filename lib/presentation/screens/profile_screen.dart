import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';

import '../../core/i18n/l10n_ext.dart';

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
  static const _bg = Color(0xFFF6F8F7);
  static const _card = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE7ECEA);
  static const _line = Color(0xFFEEF1F0);
  static const _green = Color(0xFF0E7C52);

  static const _greenSoft = Color(0xFFE7F6EE);
  static const _amber = Color(0xFFF5A623);
  static const _text = Color(0xFF14201B);
  static const _muted = Color(0xFF7C887F);
  static const _iconColor = Color(0xFF44505F);
  static const _chevColor = Color(0xFFC2C9CE);

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
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 14, left: 4),
              child: Text(
                'Profile',
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
                                child: const Center(
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
                                    style: const TextStyle(
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
                                    style: const TextStyle(
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
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
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
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: _text,
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                  children: [
                                    TextSpan(text: '4.80 '),
                                    TextSpan(
                                      text: 'My Rating',
                                      style: TextStyle(
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
                      title: 'Help & support',
                      isFirst: true,
                      onTap: () {},
                    ),
                    _menuRow(
                      icon: Icons.directions_car_outlined,
                      title: 'Saved vehicles',
                      subtitle: '2 vehicles',
                      onTap: () {},
                    ),
                    _menuRow(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Payments',
                      onTap: () {},
                    ),
                    _menuRow(
                      icon: Icons.history_rounded,
                      title: 'My SOS requests',
                      onTap: () {},
                    ),
                    _menuRow(
                      icon: Icons.shield_outlined,
                      title: 'Safety',
                      onTap: () {},
                    ),
                    _menuRow(
                      icon: Icons.phone_outlined,
                      title: 'Emergency contacts',
                      subtitle: '2 added',
                      onTap: () {},
                    ),
                    _menuRow(
                      icon: Icons.card_giftcard_rounded,
                      title: 'Refer and earn',
                      subtitle: 'Get ₹50',
                      subtitleGreen: true,
                      onTap: () {},
                    ),
                    _menuRow(
                      icon: Icons.emoji_events_outlined,
                      title: 'My rewards',
                      onTap: () {},
                    ),
                    _menuRow(
                      icon: Icons.language_rounded,
                      title: 'App language',
                      pill: 'English',
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
                  subtitle: 'Receive roadside requests',
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
                  side: const BorderSide(color: _border, width: 1.5),
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
                child: const Text(
                  'Sign out',
                  style: TextStyle(
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
  static Widget _chevron() {
    return const Icon(
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
                        style: const TextStyle(
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
                      style: const TextStyle(
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
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
                    color: const Color(0xFFE7F6EE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(Icons.person_outline_rounded,
                        size: 36, color: Color(0xFF0E7C52)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Sign in to continue',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF14201B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('sign_in_profile_prompt'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7C887F),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF18B26B), Color(0xFF0E7C52)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0E7C52).withValues(alpha: 0.3),
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
