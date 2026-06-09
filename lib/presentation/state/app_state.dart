// lib/presentation/state/app_state.dart
import 'package:flutter/material.dart';
import '../../data/repositories/local_db.dart';

enum ConnectivityStatus { online, offline, initializing }

class AppState extends ChangeNotifier {
  ConnectivityStatus _status = ConnectivityStatus.initializing;
  String _currentLanguage = 'en';
  final LocalDb _db = LocalDb();

  ConnectivityStatus get status => _status;
  String get currentLanguage => _currentLanguage;

  void setConnectivity(ConnectivityStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    await _db.setConfig('language_preference', languageCode);
    notifyListeners();
  }

  Future<void> loadLanguagePreference() async {
    final saved = await _db.getConfig('language_preference');
    if (saved != null) {
      _currentLanguage = saved;
      notifyListeners();
    }
  }

  String get networkMessage {

    switch (_status) {
      case ConnectivityStatus.offline:
        return 'You are offline. Showing cached helpers.';
      case ConnectivityStatus.initializing:
        return 'Checking connection...';
      default:
        return '';
    }
  }
}
