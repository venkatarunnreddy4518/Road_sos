// lib/core/utils/location_service.dart
import 'package:geolocator/geolocator.dart';

/// Wraps GPS access with a graceful permission flow (FR-025).
class LocationService {
  /// Returns the current position, or null if unavailable/denied.
  static Future<Position?> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }
}
