// lib/data/api/discovery_api.dart
import '../../core/network/api_client.dart';
import '../models/category.dart';
import '../models/marketplace_helper.dart';

/// Categories, helper discovery/search, and helper reviews (public endpoints).
class DiscoveryApi {
  DiscoveryApi({ApiClient? client}) : _client = client ?? ApiClient();
  final ApiClient _client;

  Future<List<ServiceCategory>> categories() async {
    final d = await _client.get('/categories', auth: false);
    return (d as List).map((e) => ServiceCategory.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<MarketplaceHelper>> nearby({
    required double lat,
    required double lng,
    String? category,
    String? helperType,
    int limit = 3,
  }) async {
    final d = await _client.get('/helpers/nearby', auth: false, query: {
      'lat': lat,
      'lng': lng,
      'category': category,
      'helper_type': helperType,
      'limit': limit,
    });
    return (d as List).map((e) => MarketplaceHelper.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<MarketplaceHelper>> search({required String q, double? lat, double? lng}) async {
    final d = await _client.get('/helpers/search', auth: false, query: {'q': q, 'lat': lat, 'lng': lng});
    return (d as List).map((e) => MarketplaceHelper.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<MarketplaceHelper>> syncFeed() async {
    final d = await _client.get('/helpers', auth: false);
    return (d['helpers'] as List)
        .map((e) => MarketplaceHelper.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<MarketplaceHelper> getById(String id) async {
    final d = await _client.get('/helpers/$id', auth: false);
    return MarketplaceHelper.fromJson(Map<String, dynamic>.from(d));
  }

  Future<Map<String, dynamic>> reviews(String helperId) async {
    final d = await _client.get('/helpers/$helperId/reviews', auth: false);
    return Map<String, dynamic>.from(d);
  }
}
