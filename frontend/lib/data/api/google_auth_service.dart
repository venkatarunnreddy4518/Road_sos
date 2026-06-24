// lib/data/api/google_auth_service.dart
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_api.dart';
import '../models/app_user.dart';

/// Bridges native Google Sign-In to the backend.
///
/// Configure via --dart-define at build/run time (no secrets in source):
///   GOOGLE_CLIENT_ID         iOS/Web OAuth client id (also the token audience there)
///   GOOGLE_SERVER_CLIENT_ID  Web OAuth client id; on Android this becomes the ID token's
///                            audience so the backend can verify it (set GOOGLE_CLIENT_ID on
///                            the backend to the same Web client id).
///
/// When neither is supplied, it uses the prototype dev fallback (backend in Google mock mode).
class GoogleAuthService {
  GoogleAuthService({AuthApi? api}) : _api = api ?? AuthApi();
  final AuthApi _api;

  static const String clientId = String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');
  static const String serverClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: '');

  bool get isConfigured => clientId.isNotEmpty || serverClientId.isNotEmpty;

  /// Returns the signed-in user, or null if the user cancelled.
  Future<AppUser?> signIn() async {
    if (!isConfigured) {
      // Prototype dev fallback — backend is in Google mock mode.
      return _api.google(devEmail: 'demo.user@gmail.com', devName: 'Demo User');
    }

    final google = GoogleSignIn(
      clientId: clientId.isEmpty ? null : clientId,
      serverClientId: serverClientId.isEmpty ? null : serverClientId,
      scopes: const ['email', 'profile'],
    );
    final account = await google.signIn();
    if (account == null) return null; // user cancelled
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw Exception('Google did not return an ID token.');
    }
    return _api.google(idToken: idToken);
  }
}
