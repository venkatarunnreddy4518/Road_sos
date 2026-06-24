// lib/presentation/widgets/google_sign_in_button_io.dart
//
// Non-web implementation: the same custom button, wired to the native
// google_sign_in flow. The web build swaps this file out via the conditional
// export in google_sign_in_button.dart.
import 'package:flutter/material.dart';

import '../../data/api/google_auth_service.dart';
import '../../data/models/app_user.dart';

class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({
    super.key,
    required this.onSignedIn,
    required this.onError,
    required this.builder,
  });

  final void Function(AppUser user) onSignedIn;
  final void Function(Object error) onError;

  /// Builds the visible button. [onPressed] starts sign-in; [loading] is true
  /// while a sign-in is in progress.
  final Widget Function(VoidCallback? onPressed, bool loading) builder;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _loading = false;

  Future<void> _start() async {
    setState(() => _loading = true);
    try {
      final user = await GoogleAuthService().signIn();
      if (user != null && mounted) widget.onSignedIn(user);
    } catch (e) {
      if (mounted) widget.onError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(_loading ? null : _start, _loading);
}
