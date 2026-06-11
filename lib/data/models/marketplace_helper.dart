// lib/data/models/marketplace_helper.dart
/// Helper as served by the marketplace backend (distinct from the legacy
/// offline-only entity in domain/entities/helper.dart).
class MarketplaceHelper {
  final String id;
  final String name;
  final String helperType;
  final String? phone;
  final bool smsCapable;
  final double latitude;
  final double longitude;
  final String? address;
  final Map<String, dynamic>? openingHours;
  final String dataSource;
  final bool isVerified;
  final double ratingAvg;
  final int ratingCount;

  // Present only on discovery responses (nearby/search).
  final double? distanceKm;
  final bool isFar;
  final bool? openNow; // null => hours unknown

  MarketplaceHelper({
    required this.id,
    required this.name,
    required this.helperType,
    this.phone,
    required this.smsCapable,
    required this.latitude,
    required this.longitude,
    this.address,
    this.openingHours,
    required this.dataSource,
    required this.isVerified,
    required this.ratingAvg,
    required this.ratingCount,
    this.distanceKm,
    this.isFar = false,
    this.openNow,
  });

  factory MarketplaceHelper.fromJson(Map<String, dynamic> j) => MarketplaceHelper(
        id: j['id'],
        name: j['name'],
        helperType: j['helper_type'],
        phone: j['phone'],
        smsCapable: j['sms_capable'] ?? false,
        latitude: (j['latitude'] as num).toDouble(),
        longitude: (j['longitude'] as num).toDouble(),
        address: j['address'],
        openingHours: j['opening_hours'] == null
            ? null
            : Map<String, dynamic>.from(j['opening_hours']),
        dataSource: j['data_source'] ?? 'curated',
        isVerified: j['is_verified'] ?? false,
        ratingAvg: (j['rating_avg'] as num?)?.toDouble() ?? 0,
        ratingCount: j['rating_count'] ?? 0,
        distanceKm: (j['distance_km'] as num?)?.toDouble(),
        isFar: j['is_far'] ?? false,
        openNow: j['open_now'],
      );

  /// Serialize persistable fields for the offline cache.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'helper_type': helperType,
        'phone': phone,
        'sms_capable': smsCapable,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'opening_hours': openingHours,
        'data_source': dataSource,
        'is_verified': isVerified,
        'rating_avg': ratingAvg,
        'rating_count': ratingCount,
      };

  /// Copy with distance fields recomputed (used when reading the offline cache
  /// against the user's current position).
  MarketplaceHelper withDistance(double distanceKm, bool far) => MarketplaceHelper(
        id: id,
        name: name,
        helperType: helperType,
        phone: phone,
        smsCapable: smsCapable,
        latitude: latitude,
        longitude: longitude,
        address: address,
        openingHours: openingHours,
        dataSource: dataSource,
        isVerified: isVerified,
        ratingAvg: ratingAvg,
        ratingCount: ratingCount,
        distanceKm: distanceKm,
        isFar: far,
        openNow: openNow,
      );

  String get typeLabel {
    switch (helperType) {
      case 'puncture_shop':
        return 'Puncture Shop';
      case 'petrol_pump':
        return 'Petrol Pump';
      case 'mechanic':
        return 'Mechanic';
      case 'towing':
        return 'Towing';
      case 'battery':
        return 'Battery';
      default:
        return helperType;
    }
  }
}
