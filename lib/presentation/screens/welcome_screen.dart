import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api/google_auth_service.dart';
import '../state/auth_state.dart';
import 'auth/email_auth_screen.dart';
import 'auth/phone_otp_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  // ── State ──
  bool _isPhone = true; // true = Phone tab, false = Email tab
  bool _busy = false;
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  late final AnimationController _riseCtrl;
  late final Animation<double> _riseFade;
  late final Animation<Offset> _riseSlide;

  // ── Design tokens ──
  static const _bg = Color(0xFFFBFBFD);
  static const _ink = Color(0xFF34343A);
  static const _muted = Color(0xFF6E6E73);
  static const _line = Color(0xFFD2D2D7);
  static const _lineSoft = Color(0xFFE8E8ED);
  static const _field = Color(0xFFFFFFFF);
  static const _green = Color(0xFF0E7C52);
  static const _greenBright = Color(0xFF18B26B);
  static const _amber = Color(0xFFF5A623);

  @override
  void initState() {
    super.initState();
    _riseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _riseFade = CurvedAnimation(
      parent: _riseCtrl,
      curve: const Cubic(0.22, 0.9, 0.3, 1),
    );
    _riseSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _riseCtrl,
      curve: const Cubic(0.22, 0.9, 0.3, 1),
    ));
    _riseCtrl.forward();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _riseCtrl.dispose();
    super.dispose();
  }

  void _continue() {
    if (_isPhone) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PhoneOtpScreen()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const EmailAuthScreen()),
      );
    }
  }

  Future<void> _google() async {
    setState(() => _busy = true);
    try {
      final user = await GoogleAuthService().signIn();
      if (user != null && mounted) context.read<AuthState>().onSignedIn(user);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── Ambient radial gradients ──
          Positioned.fill(child: _buildAmbientBackground()),

          // ── Ambient rings ──
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15,
            left: 0,
            right: 0,
            child: Center(child: _AmbientRings()),
          ),

          // ── Main content ──
          SafeArea(
            child: Column(
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Beacon icon
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CustomPaint(painter: _BeaconPainter()),
                      ),
                      const SizedBox(width: 9),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                            letterSpacing: -0.15,
                          ),
                          children: [
                            TextSpan(text: 'Roadside '),
                            TextSpan(
                              text: 'SOS',
                              style: TextStyle(
                                color: _muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Scrollable body ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    child: FadeTransition(
                      opacity: _riseFade,
                      child: SlideTransition(
                        position: _riseSlide,
                        child: Column(
                          children: [
                            // ── Mark / Logo tile ──
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF1FC676),
                                    Color(0xFF0B6E47),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: _green.withValues(alpha: 0.30),
                                    blurRadius: 30,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 34,
                                  height: 34,
                                  child: CustomPaint(
                                    painter: _BeaconWhitePainter(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 26),

                            // ── Title ──
                            const Text(
                              'Sign in',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                color: _ink,
                                letterSpacing: -0.7,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // ── Subtitle ──
                            const Text(
                              'Help is one tap away.\nEnter your details to continue.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: _muted,
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // ── Segmented control ──
                            _SegmentedControl(
                              isPhone: _isPhone,
                              onChanged: (val) =>
                                  setState(() => _isPhone = val),
                            ),
                            const SizedBox(height: 18),

                            // ── Input fields ──
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: _isPhone
                                  ? _buildPhoneField()
                                  : _buildEmailField(),
                            ),
                            const SizedBox(height: 22),

                            // ── Continue button ──
                            _GradientButton(
                              onTap: _continue,
                              busy: _busy,
                            ),
                            const SizedBox(height: 26),

                            // ── Divider "or" ──
                            Row(
                              children: [
                                const Expanded(
                                    child: Divider(color: _lineSoft)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  child: Text(
                                    'or',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFFA1A1A8),
                                    ),
                                  ),
                                ),
                                const Expanded(
                                    child: Divider(color: _lineSoft)),
                              ],
                            ),
                            const SizedBox(height: 26),

                            // ── Google button ──
                            _GhostButton(
                              label: 'Continue with Google',
                              icon: Icons.g_mobiledata_rounded,
                              onTap: _busy ? null : _google,
                            ),
                            const SizedBox(height: 11),

                            // ── Apple button ──
                            _GhostButton(
                              label: 'Continue with Apple',
                              icon: Icons.apple_rounded,
                              onTap: () {
                                // TODO: Apple Sign-In
                              },
                            ),
                            const SizedBox(height: 22),

                            // ── Create account ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'New to Roadside SOS? ',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    color: _muted,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const EmailAuthScreen(),
                                    ),
                                  ),
                                  child: const Text(
                                    'Create account',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: _green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Footer ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    children: [
                      Text(
                        'Protected by one-time verification.',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF9B9BA1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _footerLink('Terms of Service'),
                          _dot(),
                          _footerLink('Privacy Policy'),
                          _dot(),
                          _footerLink('Help'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Phone field ──
  Widget _buildPhoneField() {
    return Column(
      key: const ValueKey('phone'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Country code button
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _field,
                border: Border.all(color: _line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '+91',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 16, color: _ink.withValues(alpha: 0.5)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Phone input
            Expanded(
              child: _InputField(
                controller: _phoneCtrl,
                hint: 'Phone number',
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            "We'll text a one-time code to verify it's you.",
            style: TextStyle(fontSize: 13, color: _muted),
          ),
        ),
      ],
    );
  }

  // ── Email field ──
  Widget _buildEmailField() {
    return Column(
      key: const ValueKey('email'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InputField(
          controller: _emailCtrl,
          hint: 'Email address',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            "We'll send a secure sign-in link to your inbox.",
            style: TextStyle(fontSize: 13, color: _muted),
          ),
        ),
      ],
    );
  }

  Widget _buildAmbientBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -1),
          radius: 1.2,
          colors: [
            _greenBright.withValues(alpha: 0.16),
            Colors.transparent,
          ],
          stops: const [0, 0.62],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.76, -0.8),
            radius: 0.9,
            colors: [
              _amber.withValues(alpha: 0.13),
              Colors.transparent,
            ],
            stops: const [0, 0.6],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.8, -0.6),
              radius: 0.8,
              colors: [
                _greenBright.withValues(alpha: 0.08),
                Colors.transparent,
              ],
              stops: const [0, 0.6],
            ),
          ),
        ),
      ),
    );
  }

  Widget _footerLink(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 12, color: _muted),
    );
  }

  Widget _dot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Text('·',
          style: TextStyle(fontSize: 12, color: const Color(0xFF9B9BA1))),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ── Ambient rings (faint green circles behind the card) ──
// ═══════════════════════════════════════════════════════════════════════════════
class _AmbientRings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 380,
      height: 380,
      child: CustomPaint(painter: _AmbientRingsPainter()),
    );
  }
}

class _AmbientRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF0E7C52).withValues(alpha: 0.035)
      ..strokeWidth = 1;

    for (final r in [60.0, 100.0, 145.0, 189.0]) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// ── Beacon icon painter (colored — header) ──
// ═══════════════════════════════════════════════════════════════════════════════
class _BeaconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = size.width / 100;

    // Inner dot
    canvas.drawCircle(
      Offset(cx, cy),
      8.5 * scale,
      Paint()..color = const Color(0xFF0E7C52),
    );
    // Middle ring
    canvas.drawCircle(
      Offset(cx, cy),
      19 * scale,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFF0E7C52)
        ..strokeWidth = 6 * scale,
    );
    // Outer ring (amber)
    canvas.drawCircle(
      Offset(cx, cy),
      30 * scale,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFFF5A623)
        ..strokeWidth = 6 * scale,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// ── Beacon icon painter (white — inside green tile) ──
// ═══════════════════════════════════════════════════════════════════════════════
class _BeaconWhitePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = size.width / 100;

    // Inner dot
    canvas.drawCircle(
      Offset(cx, cy),
      8.5 * scale,
      Paint()..color = Colors.white,
    );
    // Middle ring
    canvas.drawCircle(
      Offset(cx, cy),
      19 * scale,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white
        ..strokeWidth = 6 * scale,
    );
    // Outer ring (golden)
    canvas.drawCircle(
      Offset(cx, cy),
      30 * scale,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFFFFC861)
        ..strokeWidth = 6 * scale,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// ── Segmented control (Phone / Email) ──
// ═══════════════════════════════════════════════════════════════════════════════
class _SegmentedControl extends StatelessWidget {
  final bool isPhone;
  final ValueChanged<bool> onChanged;

  const _SegmentedControl({
    required this.isPhone,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFECECED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Sliding thumb
          AnimatedAlign(
            duration: const Duration(milliseconds: 320),
            curve: const Cubic(0.3, 0.8, 0.3, 1),
            alignment:
                isPhone ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(true),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: isPhone
                            ? const Color(0xFF34343A)
                            : const Color(0xFF6E6E73),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                      child: const Text('Phone'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(false),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: !isPhone
                            ? const Color(0xFF34343A)
                            : const Color(0xFF6E6E73),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                      child: const Text('Email'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ── Input field ──
// ═══════════════════════════════════════════════════════════════════════════════
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 16, color: Color(0xFF34343A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 16,
          color: Color(0xFF9B9BA1),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD2D2D7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF18B26B),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ── Gradient "Continue" button ──
// ═══════════════════════════════════════════════════════════════════════════════
class _GradientButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool busy;

  const _GradientButton({this.onTap, this.busy = false});

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1FC676), Color(0xFF0B6E47)],
            ),
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0E7C52).withValues(alpha: 0.34),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.busy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else ...[
                const Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ── Ghost button (social sign-in) ──
// ═══════════════════════════════════════════════════════════════════════════════
class _GhostButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _GhostButton({
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  State<_GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<_GhostButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: _pressed ? const Color(0xFFF5F5F7) : Colors.white,
            border: Border.all(
              color: _pressed
                  ? const Color(0xFFC3C3C8)
                  : const Color(0xFFD2D2D7),
            ),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 20, color: const Color(0xFF34343A)),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF34343A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
