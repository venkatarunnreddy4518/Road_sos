// lib/presentation/state/auth_state.dart
import 'package:flutter/material.dart';

import '../../core/network/token_store.dart';
import '../../data/api/auth_api.dart';
import '../../data/models/app_user.dart';

enum AuthStatus { unknown, authenticated, guest, unauthenticated }

/// Holds the current session. Restores it on launch from the stored token.
class AuthState extends ChangeNotifier {
  AuthState({AuthApi? api, TokenStore? tokens})
      : _api = api ?? AuthApi(),
        _tokens = tokens ?? TokenStore();

  final AuthApi _api;
  final TokenStore _tokens;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isGuest => _status == AuthStatus.guest;

  Future<void> restore() async {
    final token = await _tokens.accessToken;
    if (token == null) {
      _set(AuthStatus.unauthenticated, null);
      return;
    }
    try {
      _user = await _api.me();
      _set(AuthStatus.authenticated, _user);
    } catch (_) {
      await _tokens.clear();
      _set(AuthStatus.unauthenticated, null);
    }
  }

  void continueAsGuest() => _set(AuthStatus.guest, null);

  void onSignedIn(AppUser user) => _set(AuthStatus.authenticated, user);

  void setUser(AppUser user) {
    _user = user;
    notifyListeners();
  }

  Future<void> logout() async {
    await _api.logout();
    _set(AuthStatus.unauthenticated, null);
  }

  void _set(AuthStatus s, AppUser? u) {
    _status = s;
    _user = u;
    notifyListeners();
  }
}
