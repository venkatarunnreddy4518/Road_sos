// lib/data/api/apple_auth_service.dart
import 'auth_api.dart';
import '../models/app_user.dart';

/// Bridges Apple Sign-In to the backend.
///
/// Real Apple Sign In requires Apple Developer setup — a Service ID + return URL on web,
/// or the "Sign in with Apple" capability on iOS — plus the `sign_in_with_apple` package,
/// and APPLE_CLIENT_ID set on the backend to that same Service/bundle id (the token
/// audience). Configure the client via --dart-define at build/run time (no secrets in
/// source):
///   APPLE_CLIENT_ID   Apple Service ID (web) / app bundle id used as the token audience.
///
/// When unset, this uses the prototype dev fallback (backend in Apple mock mode), mirroring
/// [GoogleAuthService].
class AppleAuthService {
  AppleAuthService({AuthApi? api}) : _api = api ?? AuthApi();
  final AuthApi _api;

  static const String clientId =
      String.fromEnvironment('APPLE_CLIENT_ID', defaultValue: '');

  bool get isConfigured => clientId.isNotEmpty;

  /// Returns the signed-in user, or null if the user cancelled.
  Future<AppUser?> signIn() async {
    if (!isConfigured) {
      // Prototype dev fallback — backend is in Apple mock mode.
      return _api.apple(devEmail: 'demo.user@icloud.com', devName: 'Demo User');
    }

    // Real Apple Sign-In goes here once `sign_in_with_apple` is added, forwarding the
    // identity token (and the name, which Apple returns only on first authorization):
    //   final cred = await SignInWithApple.getAppleIDCredential(
    //     scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    //   );
    //   return _api.apple(idToken: cred.identityToken, devName: cred.givenName);
    throw UnimplementedError(
      'APPLE_CLIENT_ID is set but the native Apple flow is not wired yet. '
      'Add the sign_in_with_apple package to enable real Apple Sign-In.',
    );
  }
}
