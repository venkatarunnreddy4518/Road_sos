import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../data/api/google_auth_service.dart';
import '../state/auth_state.dart';
import 'auth/email_auth_screen.dart';
import 'auth/phone_otp_screen.dart';
import 'settings_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _busy = false;

  Future<void> _google() async {
    setState(() => _busy = true);
    try {
      // Uses the real native Google flow when GOOGLE_CLIENT_ID is defined,
      // otherwise the labelled dev fallback.
      final user = await GoogleAuthService().signIn();
      if (user != null && mounted) context.read<AuthState>().onSignedIn(user);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.language),
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
              ),
              const Spacer(),
              Container(
                height: 96,
                width: 96,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(Icons.car_repair, size: 56, color: Theme.of(context).colorScheme.onPrimary),
              ),
              const SizedBox(height: 24),
              Text(context.tr('app_title'),
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(context.tr('welcome_tagline'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.tertiary)),
              const Spacer(),
              _primary(
                context: context,
                icon: Icons.mail_outline,
                label: context.tr('continue_email'),
                onTap: () => _push(const EmailAuthScreen()),
              ),
              const SizedBox(height: 12),
              _secondary(
                icon: Icons.phone_iphone,
                label: context.tr('continue_phone'),
                onTap: () => _push(const PhoneOtpScreen()),
              ),
              const SizedBox(height: 12),
              _secondary(
                icon: Icons.g_mobiledata,
                label: context.tr('continue_google'),
                onTap: _busy ? null : _google,
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: () => context.read<AuthState>().continueAsGuest(),
                child: Text(context.tr('continue_guest')),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _push(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  Widget _primary({required BuildContext context, required IconData icon, required String label, VoidCallback? onTap}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _secondary({required IconData icon, required String label, VoidCallback? onTap}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
