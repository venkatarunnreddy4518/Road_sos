// test/domain/usecases/location_test.dart
import 'package:test/test.dart';
import 'package:roadside_help/domain/entities/helper.dart'; // Not really needed but for context
import 'package:roadside_help/core/utils/distance_calculator.dart';

void main() {
  test('should update distance when user location changes offline', () {
    final helperLat = 12.9720;
    final helperLng = 77.5950;

    final dist1 = DistanceCalculator.calculateDistance(12.9716, 77.5946, helperLat, helperLng);
    final dist2 = DistanceCalculator.calculateDistance(12.9800, 77.6000, helperLat, helperLng);

    expect(dist1 != dist2, true);
  });
}
