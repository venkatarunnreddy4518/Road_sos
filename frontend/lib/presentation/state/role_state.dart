// lib/presentation/state/role_state.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which "version" of the app the user is currently using.
enum AppRole { seeker, helper }

/// App-wide role: seeker (request help) vs helper (accept nearby requests).
/// Persisted so the choice survives restarts. Toggled from the home header.
class RoleState extends ChangeNotifier {
  static const _prefKey = 'app_role';

  AppRole _role = AppRole.seeker;
  AppRole get role => _role;
  bool get isHelper => _role == AppRole.helper;

  Future<void> restore() async {
    final p = await SharedPreferences.getInstance();
    if (p.getString(_prefKey) == AppRole.helper.name) {
      _role = AppRole.helper;
      notifyListeners();
    }
  }

  Future<void> setRole(AppRole r) async {
    if (_role == r) return;
    _role = r;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefKey, r.name);
  }

  void toggle() =>
      setRole(_role == AppRole.seeker ? AppRole.helper : AppRole.seeker);
}
