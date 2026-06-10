// lib/data/api/auth_api.dart
import '../../core/network/api_client.dart';
import '../../core/network/token_store.dart';
import '../models/app_user.dart';

/// Auth endpoints. Persists the returned token pair on success.
class AuthApi {
  AuthApi({ApiClient? client, TokenStore? tokens})
      : _client = client ?? ApiClient(),
        _tokens = tokens ?? TokenStore();

  final ApiClient _client;
  final TokenStore _tokens;

  Future<AppUser> _consume(Map<String, dynamic> data) async {
    await _tokens.save(access: data['access_token'], refresh: data['refresh_token']);
    return AppUser.fromJson(Map<String, dynamic>.from(data['user']));
  }

  Future<AppUser> registerEmail(String name, String email, String password) async {
    final d = await _client.post('/auth/email/register',
        auth: false, body: {'display_name': name, 'email': email, 'password': password});
    return _consume(Map<String, dynamic>.from(d));
  }

  Future<AppUser> loginEmail(String email, String password) async {
    final d = await _client.post('/auth/email/login',
        auth: false, body: {'email': email, 'password': password});
    return _consume(Map<String, dynamic>.from(d));
  }

  /// Returns the dev code when the backend is in SMS mock mode (null otherwise).
  Future<String?> requestOtp(String phone) async {
    final d = await _client.post('/auth/phone/request-otp', auth: false, body: {'phone': phone});
    return d['dev_code'];
  }

  Future<AppUser> verifyOtp(String phone, String code, {String? name}) async {
    final d = await _client.post('/auth/phone/verify-otp',
        auth: false, body: {'phone': phone, 'code': code, 'display_name': name});
    return _consume(Map<String, dynamic>.from(d));
  }

  /// Google sign-in. In prototype mock mode, pass devEmail/devName.
  Future<AppUser> google({String? idToken, String? devEmail, String? devName}) async {
    final d = await _client.post('/auth/google', auth: false, body: {
      'id_token': idToken,
      'dev_email': devEmail,
      'dev_name': devName,
    });
    return _consume(Map<String, dynamic>.from(d));
  }

  Future<AppUser> me() async {
    final d = await _client.get('/auth/me');
    return AppUser.fromJson(Map<String, dynamic>.from(d));
  }

  Future<void> logout() async {
    final refresh = await _tokens.refreshToken;
    if (refresh != null) {
      try {
        await _client.post('/auth/logout', body: {'refresh_token': refresh});
      } catch (_) {/* best effort */}
    }
    await _tokens.clear();
  }
}
