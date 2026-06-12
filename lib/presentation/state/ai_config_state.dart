// lib/presentation/state/ai_config_state.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AiProvider {
  ollama,
  gemini,
  openai,
  anthropic,
  custom,
}

class AiConfigState extends ChangeNotifier {
  bool _aiEnabled = true;
  AiProvider _provider = AiProvider.ollama;
  String _endpoint = 'http://localhost:11434';
  String _model = 'llama3.2';
  String _apiKey = '';

  bool get aiEnabled => _aiEnabled;
  AiProvider get provider => _provider;
  String get endpoint => _endpoint;
  String get model => _model;
  String get apiKey => _apiKey;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _aiEnabled = prefs.getBool('ai_enabled') ?? true;
    final providerStr = prefs.getString('ai_provider') ?? 'ollama';
    _provider = AiProvider.values.firstWhere(
      (e) => e.name == providerStr,
      orElse: () => AiProvider.ollama,
    );
    _endpoint = prefs.getString('ai_endpoint') ?? _defaultEndpoint(_provider);
    _model = prefs.getString('ai_model') ?? _defaultModel(_provider);
    _apiKey = prefs.getString('ai_api_key') ?? '';
    notifyListeners();
  }

  Future<void> saveSettings({
    required bool aiEnabled,
    required AiProvider provider,
    required String endpoint,
    required String model,
    required String apiKey,
  }) async {
    _aiEnabled = aiEnabled;
    _provider = provider;
    _endpoint = endpoint;
    _model = model;
    _apiKey = apiKey;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ai_enabled', aiEnabled);
    await prefs.setString('ai_provider', provider.name);
    await prefs.setString('ai_endpoint', endpoint);
    await prefs.setString('ai_model', model);
    await prefs.setString('ai_api_key', apiKey);
  }

  static String _defaultEndpoint(AiProvider provider) {
    switch (provider) {
      case AiProvider.ollama:
        return 'http://localhost:11434';
      case AiProvider.openai:
        return 'https://api.openai.com/v1';
      case AiProvider.gemini:
        return 'https://generativelanguage.googleapis.com';
      case AiProvider.anthropic:
        return 'https://api.anthropic.com';
      case AiProvider.custom:
        return '';
    }
  }

  static String _defaultModel(AiProvider provider) {
    switch (provider) {
      case AiProvider.ollama:
        return 'llama3.2';
      case AiProvider.openai:
        return 'gpt-4o-mini';
      case AiProvider.gemini:
        return 'gemini-1.5-flash';
      case AiProvider.anthropic:
        return 'claude-3-5-sonnet';
      case AiProvider.custom:
        return '';
    }
  }
}
