// test/integration/offline_data_test.dart
import 'package:test/test.dart';
import 'package:roadside_help/data/repositories/helper_repository.dart';
import 'package:roadside_help/domain/entities/helper.dart';

void main() {
  test('should retrieve helpers from local SQLite when offline', () async {
    final repo = HelperRepository();

    final mockHelper = Helper(
      id: 'offline-1',
      name: 'Offline Shop',
      type: HelperType.PUNCTURE_SHOP,
      latitude: 12.9716,
      longitude: 77.5946,
      phoneNumber: '123',
      smsCapable: true,
      source: HelperSource.CURATED,
      lastUpdated: DateTime.now(),
    );

    await repo.upsertHelper(mockHelper);
    final helpers = await repo.getHelpersByType(HelperType.PUNCTURE_SHOP);

    expect(helpers.any((h) => h.id == 'offline-1'), true);
  });
}
