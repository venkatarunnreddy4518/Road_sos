// lib/presentation/screens/problem_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:roadside_help/core/i18n/app_localization.dart';
import 'helper_list_screen.dart';
import '../../domain/entities/helper.dart';

class ProblemSelectionScreen extends StatelessWidget {
  const ProblemSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = 'en'; // Mock locale, would come from state management

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalization.translate('nearest_helpers', locale)),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        children: [
          _ProblemCard(
            label: AppLocalization.translate('problem_puncture', locale),
            type: HelperType.PUNCTURE_SHOP,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HelperListScreen(type: HelperType.PUNCTURE_SHOP)),
            ),
          ),
          _ProblemCard(
            label: AppLocalization.translate('problem_fuel', locale),
            type: HelperType.PETROL_PUMP,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HelperListScreen(type: HelperType.PETROL_PUMP)),
            ),
          ),
          _ProblemCard(
            label: AppLocalization.translate('problem_breakdown', locale),
            type: HelperType.MECHANIC,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HelperListScreen(type: HelperType.MECHANIC)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProblemCard extends StatelessWidget {
  final String label;
  final HelperType type;
  final VoidCallback onTap;

  const _ProblemCard({required this.label, required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
