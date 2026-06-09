// lib/core/utils/distance_calculator.dart
import 'package:geolocator/geolocator.dart';

class DistanceCalculator {
  /// Computes the straight-line distance between two coordinates in meters.
  /// Uses the Haversine formula via the geolocator package.
  static double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Checks if a distance is beyond the "far away" threshold (e.g., 15km).
  static bool isFarAway(double distanceInMeters) {
    const double thresholdMeters = 15000.0;
    return distanceInMeters > thresholdMeters;
  }
}
