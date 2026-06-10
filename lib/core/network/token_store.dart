// lib/core/network/token_store.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Securely persists auth tokens across launches (Constitution II).
class TokenStore {
  static const _access = 'access_token';
  static const _refresh = 'refresh_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> save({required String access, required String refresh}) async {
    await _storage.write(key: _access, value: access);
    await _storage.write(key: _refresh, value: refresh);
  }

  Future<String?> get accessToken => _storage.read(key: _access);
  Future<String?> get refreshToken => _storage.read(key: _refresh);

  Future<void> updateAccess(String access) => _storage.write(key: _access, value: access);

  Future<void> clear() async {
    await _storage.delete(key: _access);
    await _storage.delete(key: _refresh);
  }
}
