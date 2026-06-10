// test/domain/usecases/find_nearest_test.dart
import 'package:test/test.dart';
import 'package:roadside_help/domain/entities/helper.dart';
import 'package:roadside_help/domain/usecases/find_nearest_helpers.dart';
import 'package:roadside_help/data/repositories/helper_repository.dart';
import 'package:mockito/mockito.dart';

class MockHelperRepository extends Mock implements HelperRepository {}

void main() {
  late MockHelperRepository mockRepo;
  late FindNearestHelpers findNearest;

  setUp(() {
    mockRepo = MockHelperRepository();
    findNearest = FindNearestHelpers(mockRepo);
  });

  test('should return 3 nearest helpers sorted by distance', () async {
    final userLat = 12.9716;
    final userLng = 77.5946;

    final helpers = [
      Helper(id: '1', name: 'A', type: HelperType.PUNCTURE_SHOP, latitude: 12.9720, longitude: 77.5950, phoneNumber: '1', smsCapable: true, source: HelperSource.CURATED, lastUpdated: DateTime.now()),
      Helper(id: '2', name: 'B', type: HelperType.PUNCTURE_SHOP, latitude: 12.9800, longitude: 77.6000, phoneNumber: '2', smsCapable: true, source: HelperSource.CURATED, lastUpdated: DateTime.now()),
      Helper(id: '3', name: 'C', type: HelperType.PUNCTURE_SHOP, latitude: 12.9710, longitude: 77.5940, phoneNumber: '3', smsCapable: true, source: HelperSource.CURATED, lastUpdated: DateTime.now()),
      Helper(id: '4', name: 'D', type: HelperType.PUNCTURE_SHOP, latitude: 13.0000, longitude: 77.7000, phoneNumber: '4', smsCapable: true, source: HelperSource.CURATED, lastUpdated: DateTime.now()),
    ];

    when(mockRepo.getHelpersByType(HelperType.PUNCTURE_SHOP)).thenAnswer((_) async => helpers);

    final result = await findNearest.execute(userLat, userLng, HelperType.PUNCTURE_SHOP);

    expect(result.length, 3);
    expect(result[0].id, '3'); // Closest
    expect(result[1].id, '1');
    expect(result[2].id, '2');
  });
}
