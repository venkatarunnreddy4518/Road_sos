// lib/presentation/screens/ai_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/l10n_ext.dart';
import '../state/ai_config_state.dart';

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _aiEnabled = true;
  AiProvider _provider = AiProvider.ollama;
  late TextEditingController _endpointController;
  late TextEditingController _modelController;
  late TextEditingController _apiKeyController;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    final config = context.read<AiConfigState>();
    _aiEnabled = config.aiEnabled;
    _provider = config.provider;
    _endpointController = TextEditingController(text: config.endpoint);
    _modelController = TextEditingController(text: config.model);
    _apiKeyController = TextEditingController(text: config.apiKey);
  }

  @override
  void dispose() {
    _endpointController.dispose();
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _onProviderChanged(AiProvider? value) {
    if (value == null) return;
    setState(() {
      _provider = value;
      // Pre-fill defaults for the selected provider
      _endpointController.text = _getDefaultEndpoint(value);
      _modelController.text = _getDefaultModel(value);
    });
  }

  String _getDefaultEndpoint(AiProvider provider) {
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

  String _getDefaultModel(AiProvider provider) {
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

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    await context.read<AiConfigState>().saveSettings(
      aiEnabled: _aiEnabled,
      provider: _provider,
      endpoint: _endpointController.text.trim(),
      model: _modelController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI Settings saved successfully!'),
          backgroundColor: Color(0xFF0E7C52),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('ai_settings')),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF0E7C52)),
            onPressed: _save,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Enable/Disable Card
            Card(
              elevation: 0,
              color: isDark ? Colors.grey[900] : Colors.white,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outline, width: 1.5),
              ),
              child: SwitchListTile(
                title: Text(
                  context.tr('ai_enabled'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                subtitle: const Text('Ask the AI assistant for immediate vehicle issue diagnosis.'),
                value: _aiEnabled,
                activeColor: const Color(0xFF0E7C52),
                onChanged: (val) => setState(() => _aiEnabled = val),
              ),
            ),
            const SizedBox(height: 20),

            if (_aiEnabled) ...[
              // Configuration settings
              const Text(
                'PROVIDER CONFIGURATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Color(0xFF7C887F),
                ),
              ),
              const SizedBox(height: 8),

              // Dropdown
              DropdownButtonFormField<AiProvider>(
                value: _provider,
                decoration: InputDecoration(
                  labelText: context.tr('ai_provider'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[900] : Colors.white,
                ),
                items: AiProvider.values.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text(p.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: _onProviderChanged,
              ),
              const SizedBox(height: 16),

              // Endpoint
              TextFormField(
                controller: _endpointController,
                decoration: InputDecoration(
                  labelText: context.tr('ai_endpoint'),
                  hintText: 'e.g. http://localhost:11434',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[900] : Colors.white,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a valid base URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Model
              TextFormField(
                controller: _modelController,
                decoration: InputDecoration(
                  labelText: context.tr('ai_model'),
                  hintText: 'e.g. llama3.2',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[900] : Colors.white,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a model name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // API Key (For BYOK)
              if (_provider != AiProvider.ollama) ...[
                TextFormField(
                  controller: _apiKeyController,
                  obscureText: _obscureApiKey,
                  decoration: InputDecoration(
                    labelText: context.tr('ai_api_key'),
                    hintText: 'Enter API Key (BYOK)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[900] : Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFF7C887F),
                      ),
                      onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                    ),
                  ),
                  validator: (val) {
                    if (_provider != AiProvider.ollama && (val == null || val.trim().isEmpty)) {
                      return 'API key is required for cloud providers';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Tokens are stored locally on your device and are sent directly to the AI provider.',
                    style: TextStyle(color: theme.colorScheme.tertiary, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Setup Guide Card based on selected provider
              if (_provider == AiProvider.ollama)
                _buildOllamaGuide(theme, isDark)
              else if (_provider == AiProvider.gemini)
                _buildBYOKGuide('Google Gemini', 'https://aistudio.google.com/', theme, isDark)
              else if (_provider == AiProvider.openai)
                _buildBYOKGuide('OpenAI', 'https://platform.openai.com/api-keys', theme, isDark)
              else if (_provider == AiProvider.anthropic)
                _buildBYOKGuide('Anthropic Claude', 'https://console.anthropic.com/', theme, isDark),
            ],
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E7C52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Save Settings',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOllamaGuide(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : const Color(0xFFE7F6EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFCDECE0), width: 1.5),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🐳', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'Ollama Local AI Setup Guide',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Color(0xFF0E7C52),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '1. Install Ollama from ollama.com.\n'
            '2. Run `ollama run llama3.2` (or your preferred model).\n'
            '3. Set environment variable `OLLAMA_ORIGINS=*` to allow web/app connections (restart Ollama afterwards).\n'
            '4. If using an Android Emulator, set Endpoint to `http://10.0.2.2:11434` instead of localhost.',
            style: TextStyle(fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBYOKGuide(String providerName, String url, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : const Color(0xFFF7F8F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E4DA), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔑', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Bring Your Own Token (BYOK)',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'To use $providerName, generate an API Key from their developer dashboard:\n'
            '$url\n\n'
            'Your key is saved directly on this phone and is sent only to $providerName for authentication.',
            style: const TextStyle(fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }
}
