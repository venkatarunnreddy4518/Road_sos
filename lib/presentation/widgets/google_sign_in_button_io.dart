// lib/presentation/widgets/google_sign_in_button_io.dart
//
// Non-web implementation: just shows [fallback], whose onTap drives the native
// google_sign_in flow (wired in the welcome screen). The web build swaps this
// file out via the conditional export in google_sign_in_button.dart.
import 'package:flutter/material.dart';

import '../../data/models/app_user.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onSignedIn,
    required this.onError,
    required this.fallback,
  });

  /// Called with the signed-in user (used by the web build; the fallback handles
  /// this itself on native platforms).
  final void Function(AppUser user) onSignedIn;
  final void Function(Object error) onError;

  /// The styled button to display on native platforms.
  final Widget fallback;

  @override
  Widget build(BuildContext context) => fallback;
}
