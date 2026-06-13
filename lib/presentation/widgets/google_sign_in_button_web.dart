// lib/presentation/widgets/google_sign_in_button_web.dart
//
// Web implementation: renders Google's official GIS button. When the user picks an
// account, Google returns an ID token, which we exchange with the backend
// (/auth/google) for our app session — exactly the documented web flow for
// google_sign_in 6.x (programmatic signIn() is unsupported on web).
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi_web;

import '../../data/api/auth_api.dart';
import '../../data/models/app_user.dart';

class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({
    super.key,
    required this.onSignedIn,
    required this.onError,
    required this.fallback, // unused on web
  });

  final void Function(AppUser user) onSignedIn;
  final void Function(Object error) onError;
  final Widget fallback;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  // Client id comes from the <meta name="google-signin-client_id"> tag in
  // web/index.html (passing clientId here is unsupported on web).
  final GoogleSignIn _gsi = GoogleSignIn(scopes: const ['email', 'profile']);
  final AuthApi _api = AuthApi();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _gsi.onCurrentUserChanged.listen(_handleAccount);
    // Initializes the GIS client (and restores an existing session if present).
    _gsi.signInSilently();
  }

  Future<void> _handleAccount(GoogleSignInAccount? account) async {
    if (account == null || _loading) return;
    setState(() => _loading = true);
    try {
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw Exception('Google did not return an ID token.');
      }
      final user = await _api.google(idToken: idToken);
      if (mounted) widget.onSignedIn(user);
    } catch (e) {
      if (mounted) widget.onError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(child: gsi_web.renderButton()),
          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0xCCFFFFFF),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
