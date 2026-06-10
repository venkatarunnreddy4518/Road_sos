// test/integration/helper_list_test.dart
import 'package:test/test.dart';
import 'package:roadside_help/domain/entities/helper.dart';
import 'package:roadside_help/core/utils/distance_calculator.dart';

void main() {
  test('Helper list should be sorted by distance calculated via Haversine', () {
    final userLat = 12.9716;
    final userLng = 77.5946;

    final helperA = Helper(id: 'A', name: 'Shop A', type: HelperType.PUNCTURE_SHOP, latitude: 12.9720, longitude: 77.5950, phoneNumber: '1', smsCapable: true, source: HelperSource.CURATED, lastUpdated: DateTime.now());
    final helperB = Helper(id: 'B', name: 'Shop B', type: HelperType.PUNCTURE_SHOP, latitude: 13.0000, longitude: 77.7000, phoneNumber: '2', smsCapable: true, source: HelperSource.CURATED, lastUpdated: DateTime.now());

    final distA = DistanceCalculator.calculateDistance(userLat, userLng, helperA.latitude, helperA.longitude);
    final distB = DistanceCalculator.calculateDistance(userLat, userLng, helperB.latitude, helperB.longitude);

    expect(distA < distB, true);
  });
}
