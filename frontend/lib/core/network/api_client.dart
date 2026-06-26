// lib/core/network/api_client.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'token_store.dart';

/// Thrown on non-2xx responses, carrying the backend error envelope.
class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  ApiException(this.statusCode, this.code, this.message);
  @override
  String toString() => message;
}

/// Thin REST client: base URL resolved dynamically, bearer auth,
/// JSON encode/decode, transparent access-token refresh on 401.
class ApiClient {
  ApiClient({TokenStore? tokenStore})
      : _tokens = tokenStore ?? TokenStore();

  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host != 'localhost' && host != '127.0.0.1' && host.isNotEmpty) {
        return 'https://roadside-help-api.onrender.com';
      }
    }
    return 'http://localhost:8000';
  }

  final TokenStore _tokens;
  final http.Client _http = http.Client();

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = query?.map((k, v) => MapEntry(k, v?.toString()))
      ?..removeWhere((_, v) => v == null);
    return Uri.parse('$baseUrl/api/v1$path').replace(
      queryParameters: q?.isEmpty ?? true ? null : q!.cast<String, String>(),
    );
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _tokens.accessToken;
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) =>
      _send(() async => _http.get(_uri(path, query), headers: await _headers(auth: auth)), path, query, auth, 'GET', null);

  Future<dynamic> post(String path, {Object? body, bool auth = true}) =>
      _send(() async => _http.post(_uri(path), headers: await _headers(auth: auth), body: jsonEncode(body ?? {})), path, null, auth, 'POST', body);

  Future<dynamic> patch(String path, {Object? body, bool auth = true}) =>
      _send(() async => _http.patch(_uri(path), headers: await _headers(auth: auth), body: jsonEncode(body ?? {})), path, null, auth, 'PATCH', body);

  Future<dynamic> _send(
    Future<http.Response> Function() call,
    String path,
    Map<String, dynamic>? query,
    bool auth,
    String method,
    Object? body, {
    bool retried = false,
  }) async {
    final res = await call();
    if (res.statusCode == 401 && auth && !retried) {
      if (await _tryRefresh()) {
        return _send(call, path, query, auth, method, body, retried: true);
      }
    }
    return _decode(res);
  }

  Future<bool> _tryRefresh() async {
    final refresh = await _tokens.refreshToken;
    if (refresh == null) return false;
    final res = await _http.post(_uri('/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refresh}));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body);
      await _tokens.save(access: data['access_token'], refresh: data['refresh_token']);
      return true;
    }
    await _tokens.clear();
    return false;
  }

  dynamic _decode(http.Response res) {
    final hasBody = res.body.isNotEmpty;
    final data = hasBody ? jsonDecode(res.body) : null;
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    final err = (data is Map && data['error'] is Map) ? data['error'] as Map : null;
    throw ApiException(
      res.statusCode,
      err?['code']?.toString() ?? 'error',
      err?['message']?.toString() ?? 'Request failed (${res.statusCode}).',
    );
  }
}
