// lib/presentation/widgets/google_sign_in_button.dart
//
// Cross-platform "Continue with Google" button. The web build renders Google's
// official GIS button (the only supported web flow in google_sign_in 6.x and the
// branding Google requires); other platforms fall back to the native flow.
export 'google_sign_in_button_io.dart'
    if (dart.library.js_interop) 'google_sign_in_button_web.dart';
