// lib/data/api/profile_api.dart
import '../../core/network/api_client.dart';
import '../models/app_user.dart';
import '../models/marketplace_helper.dart';

class ProfileApi {
  ProfileApi({ApiClient? client}) : _client = client ?? ApiClient();
  final ApiClient _client;

  Future<AppUser> get() async {
    final d = await _client.get('/profile');
    return AppUser.fromJson(Map<String, dynamic>.from(d));
  }

  Future<AppUser> update({
    String? displayName,
    String? phone,
    String? vehicleInfo,
    String? preferredLanguage,
  }) async {
    final d = await _client.patch('/profile', body: {
      if (displayName != null) 'display_name': displayName,
      if (phone != null) 'phone': phone,
      if (vehicleInfo != null) 'vehicle_info': vehicleInfo,
      if (preferredLanguage != null) 'preferred_language': preferredLanguage,
    });
    return AppUser.fromJson(Map<String, dynamic>.from(d));
  }

  /// Register/update the caller's helper profile (enables provider mode).
  Future<MarketplaceHelper> upsertHelper({
    required String name,
    required String helperType,
    String? phone,
    bool smsCapable = false,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    final d = await _client.post('/helpers', body: {
      'name': name,
      'helper_type': helperType,
      'phone': phone,
      'sms_capable': smsCapable,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    });
    return MarketplaceHelper.fromJson(Map<String, dynamic>.from(d));
  }
}
