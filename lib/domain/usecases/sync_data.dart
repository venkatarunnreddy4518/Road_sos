// lib/domain/usecases/sync_data.dart
import 'package:roadside_help/domain/entities/helper.dart';
import 'package:roadside_help/data/providers/api_client.dart';
import 'package:roadside_help/data/repositories/helper_repository.dart';
import 'dart:convert';

class SyncData {
  final ApiClient _apiClient;
  final HelperRepository _repository;

  SyncData(this._apiClient, this._repository);

  Future<DateTime?> execute() async {
    try {
      final response = await _apiClient.get('/v1/helpers/sync');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> helperList = data['helpers'];

        final helpers = helperList.map((json) => Helper.fromMap(json)).toList();
        await _repository.bulkInsertHelpers(helpers);

        return DateTime.parse(data['metadata']['sync_timestamp']);
      }
    } catch (e) {
      // Log error via AppLogger
    }
    return null;
  }
}
