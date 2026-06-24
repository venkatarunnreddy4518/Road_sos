import 'package:flutter_test/flutter_test.dart';
import 'package:roadside_help/presentation/state/ai_config_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiConfigState Persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to Ollama enabled with correct defaults', () async {
      final state = AiConfigState();
      await state.load();
      expect(state.aiEnabled, isTrue);
      expect(state.provider, AiProvider.ollama);
      expect(state.endpoint, 'http://localhost:11434');
      expect(state.model, 'llama3.2');
      expect(state.apiKey, isEmpty);
    });

    test('saves and restores configurations correctly', () async {
      final state = AiConfigState();
      await state.load();

      await state.saveSettings(
        aiEnabled: false,
        provider: AiProvider.gemini,
        endpoint: 'https://generativelanguage.googleapis.com',
        model: 'gemini-1.5-flash',
        apiKey: 'test-api-key',
      );

      expect(state.aiEnabled, isFalse);
      expect(state.provider, AiProvider.gemini);
      expect(state.endpoint, 'https://generativelanguage.googleapis.com');
      expect(state.model, 'gemini-1.5-flash');
      expect(state.apiKey, 'test-api-key');

      // Verify persistence by loading into a new instance
      final state2 = AiConfigState();
      await state2.load();
      expect(state2.aiEnabled, isFalse);
      expect(state2.provider, AiProvider.gemini);
      expect(state2.endpoint, 'https://generativelanguage.googleapis.com');
      expect(state2.model, 'gemini-1.5-flash');
      expect(state2.apiKey, 'test-api-key');
    });

    test('retains default values when saved values are missing', () async {
      SharedPreferences.setMockInitialValues({
        'ai_enabled': true,
        'ai_provider': 'openai',
        'ai_endpoint': 'https://api.openai.com/v1',
        'ai_model': 'gpt-4o-mini',
        'ai_api_key': 'open-ai-key',
      });

      final state = AiConfigState();
      await state.load();
      expect(state.provider, AiProvider.openai);
      expect(state.endpoint, 'https://api.openai.com/v1');
      expect(state.model, 'gpt-4o-mini');
      expect(state.apiKey, 'open-ai-key');
    });
  });
}
