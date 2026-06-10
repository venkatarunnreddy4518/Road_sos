// lib/data/repositories/helper_cache.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/geo_distance.dart';
import '../models/marketplace_helper.dart';

/// Offline-first cache of the last successfully fetched helpers (FR-026/FR-027).
///
/// Uses shared_preferences (works on web + mobile) rather than SQLite, which has
/// no web support. Distances are not stored — they are recomputed from cached
/// coordinates against the user's current position so they stay correct offline.
class HelperCache {
  static const _helpersKey = 'cached_helpers';
  static const _syncedAtKey = 'cached_helpers_synced_at';

  Future<void> save(List<MarketplaceHelper> helpers) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(helpers.map((h) => h.toJson()).toList());
    await prefs.setString(_helpersKey, payload);
    await prefs.setString(_syncedAtKey, DateTime.now().toIso8601String());
  }

  /// Returns cached helpers sorted by distance from (lat,lng), nearest first,
  /// with the far-away flag set; empty if nothing cached.
  Future<List<MarketplaceHelper>> load({
    required double lat,
    required double lng,
    String? helperType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_helpersKey);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List)
        .map((e) => MarketplaceHelper.fromJson(Map<String, dynamic>.from(e)))
        .where((h) => helperType == null || h.helperType == helperType)
        .map((h) {
      final d = GeoDistance.haversineKm(lat, lng, h.latitude, h.longitude);
      return h.withDistance(double.parse(d.toStringAsFixed(2)), GeoDistance.isFar(d));
    }).toList()
      ..sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
    return list;
  }

  Future<DateTime?> lastSyncedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_syncedAtKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }
}
