// lib/data/api/request_api.dart
import '../../core/network/api_client.dart';
import '../models/service_request.dart';

/// Service-request lifecycle, provider inbox, live location, and reviews.
class RequestApi {
  RequestApi({ApiClient? client}) : _client = client ?? ApiClient();
  final ApiClient _client;

  ServiceRequest _req(dynamic d) => ServiceRequest.fromJson(Map<String, dynamic>.from(d));

  Future<ServiceRequest> create({
    required String categoryId,
    required double lat,
    required double lng,
    String? targetHelperId,
    String? note,
  }) async {
    final d = await _client.post('/requests', body: {
      'category_id': categoryId,
      'pickup_lat': lat,
      'pickup_lng': lng,
      'target_helper_id': targetHelperId,
      'note': note,
    });
    return _req(d);
  }

  Future<List<ServiceRequest>> mine({String role = 'seeker', bool activeOnly = false}) async {
    final d = await _client.get('/requests/mine', query: {'role': role, 'active_only': activeOnly});
    return (d as List).map(_req).toList();
  }

  Future<List<Map<String, dynamic>>> open({required double lat, required double lng}) async {
    final d = await _client.get('/requests/open', query: {'lat': lat, 'lng': lng});
    return (d as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<ServiceRequest> get(String id) async => _req(await _client.get('/requests/$id'));

  Future<ServiceRequest> accept(String id) async => _req(await _client.post('/requests/$id/accept'));

  Future<ServiceRequest> decline(String id) async => _req(await _client.post('/requests/$id/decline'));

  Future<ServiceRequest> updateStatus(String id, String status) async =>
      _req(await _client.post('/requests/$id/status', body: {'status': status}));

  Future<ServiceRequest> cancel(String id) async => _req(await _client.post('/requests/$id/cancel'));

  Future<void> postLocation(String id, double lat, double lng) async {
    await _client.post('/requests/$id/location', body: {'latitude': lat, 'longitude': lng});
  }

  Future<void> review({required String requestId, required int rating, String? comment}) async {
    await _client.post('/reviews', body: {'request_id': requestId, 'rating': rating, 'comment': comment});
  }
}
