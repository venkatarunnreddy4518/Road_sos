// lib/core/utils/geo_distance.dart
import 'dart:math' as math;

/// Pure-Dart straight-line distance, used to recompute distances for the
/// offline cache without any platform plugin (works on web + mobile).
class GeoDistance {
  static const double earthRadiusKm = 6371.0088;
  static const double farThresholdKm = 15.0;

  static double haversineKm(double lat1, double lng1, double lat2, double lng2) {
    final p1 = _rad(lat1);
    final p2 = _rad(lat2);
    final dPhi = _rad(lat2 - lat1);
    final dLambda = _rad(lng2 - lng1);
    final a = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
        math.cos(p1) * math.cos(p2) * math.sin(dLambda / 2) * math.sin(dLambda / 2);
    return 2 * earthRadiusKm * math.asin(math.min(1, math.sqrt(a)));
  }

  static bool isFar(double distanceKm) => distanceKm > farThresholdKm;

  static double _rad(double deg) => deg * math.pi / 180.0;
}
