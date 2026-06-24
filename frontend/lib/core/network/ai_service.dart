// lib/core/network/ai_service.dart
import '../../presentation/state/ai_config_state.dart';
import 'api_client.dart';

class ChatMessage {
  final String role;
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class AiService {
  final ApiClient _client = ApiClient();

  Future<String> chat(List<ChatMessage> messages, AiConfigState config) async {
    if (!config.aiEnabled) {
      throw Exception('AI is currently disabled in settings.');
    }

    final payload = {
      'messages': messages.map((m) => m.toJson()).toList(),
      'provider': config.provider.name,
      'endpoint': config.endpoint,
      'model': config.model,
      'api_key': config.apiKey,
    };

    try {
      final data = await _client.post('/ai/chat', body: payload, auth: false);
      if (data is Map && data.containsKey('response')) {
        return data['response'] ?? '';
      }
      throw Exception('Invalid response format from server');
    } catch (e) {
      throw Exception('Backend AI request failed: $e');
    }
  }
}
