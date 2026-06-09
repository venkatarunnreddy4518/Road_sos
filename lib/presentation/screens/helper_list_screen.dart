// lib/presentation/screens/helper_list_screen.dart
import 'package:flutter/material.dart';
import 'package:roadside_help/domain/entities/helper.dart';
import 'package:roadside_help/domain/usecases/find_nearest_helpers.dart';
import 'package:roadside_help/data/repositories/helper_repository.dart';
import 'package:roadside_help/core/i18n/app_localization.dart';
import '../widgets/helper_card.dart';

class HelperListScreen extends StatefulWidget {
  final HelperType type;
  const HelperListScreen({super.key, required this.type});

  @override
  State<HelperListScreen> createState() => _HelperListScreenState();
}

class _HelperListScreenState extends State<HelperListScreen> {
  late Future<List<Helper>> _helpersFuture;
  final String locale = 'en'; // Mock locale

  @override
  void initState() {
    super.initState();
    final useCase = FindNearestHelpers(HelperRepository());
    // Mocking user location (Bangalore)
    _helpersFuture = useCase.execute(12.9716, 77.5946, widget.type);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalization.translate('nearest_helpers', locale)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Last updated: 2 mins ago', // Mock: would be fetched from AppConfig.lastSyncTime
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Helper>>(
        future: _helpersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading helpers'));
          }
          final helpers = snapshot.data ?? [];
          if (helpers.isEmpty) {
            return const Center(child: Text('No helpers found'));
          }

          return ListView.builder(
            itemCount: helpers.length,
            itemBuilder: (context, index) {
              return HelperCard(helper: helpers[index]);
            },
          );
        },
      ),
    );
  }
}
