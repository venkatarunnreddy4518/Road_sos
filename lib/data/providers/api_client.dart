// lib/data/providers/api_client.dart
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl = 'https://api.roadsidehelp.in'; // Example base URL
  final String apiKey = 'YOUR_API_KEY'; // Should be moved to env in real app

  Future<http.Response> get(String endpoint, {Map<String, String>? params}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final requestUri = uri.replace(queryParameters: params);

    return await http.get(
      requestUri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    );
  }
}
