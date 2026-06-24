// lib/domain/entities/helper.dart
enum HelperType {
  PUNCTURE_SHOP,
  PETROL_PUMP,
  MECHANIC,
}

enum HelperSource {
  CURATED,
  THIRD_PARTY,
}

class Helper {
  final String id;
  final String name;
  final HelperType type;
  final double latitude;
  final double longitude;
  final String phoneNumber;
  final bool smsCapable;
  final String? openingHours;
  final HelperSource source;
  final DateTime lastUpdated;

  Helper({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.phoneNumber,
    required this.smsCapable,
    this.openingHours,
    required this.source,
    required this.lastUpdated,
  });

  // Factory for SQLite
  factory Helper.fromMap(Map<String, dynamic> map) {
    return Helper(
      id: map['id'],
      name: map['name'],
      type: HelperType.values.firstWhere((e) => e.toString().split('.').last == map['type']),
      latitude: map['latitude'],
      longitude: map['longitude'],
      phoneNumber: map['phoneNumber'],
      smsCapable: map['sms_capable'] == 1,
      openingHours: map['opening_hours'],
      source: HelperSource.values.firstWhere((e) => e.toString().split('.').last == map['source']),
      lastUpdated: DateTime.parse(map['last_updated']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'sms_capable': smsCapable ? 1 : 0,
      'opening_hours': openingHours,
      'source': source.toString().split('.').last,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}
