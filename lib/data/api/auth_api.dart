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
    if (data['access_token'] == null || data['refresh_token'] == null || data['user'] == null) {
      throw ArgumentError('Invalid auth response: missing required fields');
    }
    await _tokens.save(access: data['access_token'], refresh: data['refresh_token']);
    return AppUser.fromJson(Map<String, dynamic>.from(data['user']));
  }

  Future<AppUser> registerEmail(String name, String email, String password) async {
    if (name.trim().isEmpty) throw ArgumentError('Name cannot be empty');
    if (!email.contains('@')) throw ArgumentError('Invalid email format');
    if (password.length < 6) throw ArgumentError('Password must be at least 6 characters');

    final d = await _client.post('/auth/email/register',
        auth: false, body: {'display_name': name.trim(), 'email': email.toLowerCase().trim(), 'password': password});
    return _consume(Map<String, dynamic>.from(d));
  }

  Future<AppUser> loginEmail(String email, String password) async {
    if (!email.contains('@')) throw ArgumentError('Invalid email format');
    if (password.isEmpty) throw ArgumentError('Password cannot be empty');

    final d = await _client.post('/auth/email/login',
        auth: false, body: {'email': email.toLowerCase().trim(), 'password': password});
    return _consume(Map<String, dynamic>.from(d));
  }

  /// Returns the dev code when the backend is in SMS mock mode (null otherwise).
  Future<String?> requestOtp(String phone) async {
    if (phone.trim().length < 6) throw ArgumentError('Enter a valid phone number');

    final d = await _client.post('/auth/phone/request-otp', auth: false, body: {'phone': phone.trim()});
    return d['dev_code'];
  }

  Future<AppUser> verifyOtp(String phone, String code, {String? name}) async {
    if (phone.trim().length < 6) throw ArgumentError('Invalid phone number');
    if (code.trim().length < 4 || code.trim().length > 8) throw ArgumentError('Invalid verification code');

    final d = await _client.post('/auth/phone/verify-otp',
        auth: false, body: {'phone': phone.trim(), 'code': code.trim(), 'display_name': name?.trim()});
    return _consume(Map<String, dynamic>.from(d));
  }

  /// Google sign-in. Web passes accessToken (OAuth2 popup); mobile passes idToken;
  /// prototype mock mode passes devEmail/devName.
  Future<AppUser> google({String? idToken, String? accessToken, String? devEmail, String? devName}) async {
    final d = await _client.post('/auth/google', auth: false, body: {
      'id_token': idToken,
      'access_token': accessToken,
      'dev_email': devEmail,
      'dev_name': devName,
    });
    return _consume(Map<String, dynamic>.from(d));
  }

  /// Apple sign-in. In prototype mock mode, pass devEmail/devName.
  Future<AppUser> apple({String? idToken, String? devEmail, String? devName}) async {
    final d = await _client.post('/auth/apple', auth: false, body: {
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
