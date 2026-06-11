import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import '../../../data/api/auth_api.dart';
import '../../state/auth_state.dart';

class PhoneOtpScreen extends StatefulWidget {
  final String? initialPhone;
  const PhoneOtpScreen({super.key, this.initialPhone});

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _phone;
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _api = AuthApi();

  bool _codeSent = false;
  bool _busy = false;
  String? _error;
  String? _devCode;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // ── Design tokens ──
  static const _bg = Color(0xFFFBFBFD);
  static const _ink = Color(0xFF34343A);
  static const _muted = Color(0xFF6E6E73);
  static const _line = Color(0xFFD2D2D7);
  static const _lineSoft = Color(0xFFE8E8ED);
  static const _field = Color(0xFFFFFFFF);
  static const _greenDeep = Color(0xFF0B6E47);
  static const _greenBright = Color(0xFF1FC676);
  static const _green = Color(0xFF0E7C52);

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.initialPhone);
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Auto-trigger OTP request if phone number was pre-populated
    if (widget.initialPhone != null && widget.initialPhone!.trim().length >= 6) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendCode();
      });
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _name.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_phone.text.trim().length < 6) {
      setState(() => _error = 'Enter a valid phone number');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final dev = await _api.requestOtp(_phone.text.trim());
      setState(() {
        _codeSent = true;
        _devCode = dev;
      });
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await _api.verifyOtp(_phone.text.trim(), _code.text.trim(),
          name: _name.text.trim());
      if (!mounted) return;
      context.read<AuthState>().onSignedIn(user);
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: _lineSoft),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: _ink),
          ),
        ),
        title: Text(
          _codeSent ? 'Verify OTP' : 'Phone sign in',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header icon ──
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_greenBright, _greenDeep],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _greenDeep.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.phone_iphone_rounded,
                          size: 24, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _codeSent ? 'Enter verification code' : 'Phone sign in',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _codeSent
                        ? 'We sent a 6-digit code to ${_phone.text}'
                        : 'We\'ll send you a one-time verification code',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: _muted),
                  ),
                  const SizedBox(height: 28),

                  // ── Form card ──
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: _field,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _lineSoft),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Phone field ──
                        _label('Phone number'),
                        const SizedBox(height: 6),
                        _textField(
                          controller: _phone,
                          enabled: !_codeSent,
                          hint: '+91 98765 43210',
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_outlined,
                        ),

                        if (_codeSent) ...[
                          const SizedBox(height: 16),

                          // ── Name (optional) ──
                          _label('Name (optional)'),
                          const SizedBox(height: 6),
                          _textField(
                            controller: _name,
                            hint: 'Your name',
                            prefixIcon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 16),

                          // ── OTP code ──
                          _label('Verification code'),
                          const SizedBox(height: 6),
                          _textField(
                            controller: _code,
                            hint: '000000',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.pin_outlined,
                          ),

                          // ── Dev hint ──
                          if (_devCode != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F7F4),
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: const Color(0xFFB2DFC7)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded,
                                      size: 16, color: _green),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Dev mode: your code is $_devCode',
                                    style: const TextStyle(
                                        fontSize: 12, color: _green),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],

                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFFFCA5A5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    size: 16, color: Color(0xFFDC2626)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFDC2626)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 22),

                        // ── Action button ──
                        _GradientButton(
                          label: _codeSent ? 'Verify code' : 'Send code',
                          busy: _busy,
                          onTap:
                              _busy ? null : (_codeSent ? _verify : _sendCode),
                        ),

                        if (_codeSent) ...[
                          const SizedBox(height: 14),
                          Center(
                            child: GestureDetector(
                              onTap: _busy ? null : _sendCode,
                              child: const Text(
                                'Resend code',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _green,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _ink,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    bool enabled = true,
    TextInputType? keyboardType,
    IconData? prefixIcon,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: _ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: _muted.withOpacity(0.5)),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: _muted)
            : null,
        filled: true,
        fillColor: enabled ? _bg : const Color(0xFFF0F0F5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _line),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _lineSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _green, width: 1.5),
        ),
      ),
    );
  }
}

// ── Gradient CTA Button ──────────────────────────────────────────────────────
class _GradientButton extends StatefulWidget {
  final String label;
  final bool busy;
  final VoidCallback? onTap;

  const _GradientButton({
    required this.label,
    this.busy = false,
    this.onTap,
  });

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
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1FC676), Color(0xFF0B6E47)],
            ),
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B6E47).withOpacity(0.3),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: widget.busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
