// lib/presentation/widgets/google_sign_in_button_web.dart
//
// Web implementation: a standard custom button that opens Google's OAuth2
// account-chooser popup (via the window.googleOAuthSignIn helper in index.html),
// obtains an access token, and exchanges it with the backend for our session.
import 'dart:js_interop';

import 'package:flutter/material.dart';

import '../../data/api/auth_api.dart';
import '../../data/models/app_user.dart';

@JS('googleOAuthSignIn')
external JSPromise<JSString> _googleOAuthSignIn();

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
  final AuthApi _api = AuthApi();
  bool _loading = false;

  Future<void> _start() async {
    setState(() => _loading = true);
    try {
      final token = (await _googleOAuthSignIn().toDart).toDart;
      final user = await _api.google(accessToken: token);
      if (mounted) widget.onSignedIn(user);
    } catch (e) {
      // Don't surface the user simply closing the Google popup.
      final msg = '$e';
      if (mounted && !msg.contains('popup-closed') && !msg.contains('closed')) {
        widget.onError(e);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(_loading ? null : _start, _loading);
}
