// lib/data/api/google_auth_service.dart
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_api.dart';
import '../models/app_user.dart';

/// Bridges native Google Sign-In to the backend.
///
/// When a real OAuth client id is supplied via --dart-define=GOOGLE_CLIENT_ID,
/// it performs the real native flow, obtains a Google ID token, and exchanges it
/// at the backend. Otherwise it uses the prototype dev fallback (labelled in the UI).
class GoogleAuthService {
  GoogleAuthService({AuthApi? api}) : _api = api ?? AuthApi();
  final AuthApi _api;

  static const String clientId = String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');

  bool get isConfigured => clientId.isNotEmpty;

  /// Returns the signed-in user, or null if the user cancelled.
  Future<AppUser?> signIn() async {
    if (!isConfigured) {
      // Prototype dev fallback — backend is in Google mock mode.
      return _api.google(devEmail: 'demo.user@gmail.com', devName: 'Demo User');
    }

    final google = GoogleSignIn(
      clientId: clientId,
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
