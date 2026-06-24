// lib/domain/usecases/find_nearest_helpers.dart
import 'package:roadside_help/domain/entities/helper.dart';
import 'package:roadside_help/data/repositories/helper_repository.dart';
import 'package:roadside_help/core/utils/distance_calculator.dart';

class FindNearestHelpers {
  final HelperRepository _repository;

  FindNearestHelpers(this._repository);

  Future<List<Helper>> execute(double userLat, double userLng, HelperType type) async {
    final helpers = await _repository.getHelpersByType(type);

    // Calculate distances and store in a temporary map
    final helperDistances = helpers.map((helper) {
      return MapEntry(
        helper,
        DistanceCalculator.calculateDistance(userLat, userLng, helper.latitude, helper.longitude),
      );
    }).toList();

    // Sort by distance ascending
    helperDistances.sort((a, b) => a.value.compareTo(b.value));

    // Take top 3 and return the helper entities
    return helperDistances.take(3).map((e) => e.key).toList();
  }
}
