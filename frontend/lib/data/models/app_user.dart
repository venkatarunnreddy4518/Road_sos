// lib/data/models/app_user.dart
class AppUser {
  final String id;
  final String displayName;
  final String? email;
  final String? phone;
  final String? vehicleInfo;
  final bool isHelper;
  final String preferredLanguage;

  AppUser({
    required this.id,
    required this.displayName,
    this.email,
    this.phone,
    this.vehicleInfo,
    required this.isHelper,
    required this.preferredLanguage,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'],
        displayName: j['display_name'] ?? '',
        email: j['email'],
        phone: j['phone'],
        vehicleInfo: j['vehicle_info'],
        isHelper: j['is_helper'] ?? false,
        preferredLanguage: j['preferred_language'] ?? 'en',
      );
}
