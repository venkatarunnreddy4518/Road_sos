// lib/presentation/widgets/helper_card.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:roadside_help/domain/entities/helper.dart';
import 'package:roadside_help/core/utils/distance_calculator.dart';
import 'package:roadside_help/core/i18n/app_localization.dart';

class HelperCard extends StatelessWidget {
  final Helper helper;
  final String locale = 'en'; // Mock locale

  const HelperCard({super.key, required this.helper});

  Future<void> _makeCall() async {
    final url = Uri.parse('tel:${helper.phoneNumber}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _makeSMS() async {
    final url = Uri.parse('sms:${helper.phoneNumber}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _openMaps() async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${helper.latitude},${helper.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final distance = DistanceCalculator.calculateDistance(12.9716, 77.5946, helper.latitude, helper.longitude);
    final isFar = DistanceCalculator.isFarAway(distance);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(helper.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${(distance / 1000).toStringAsFixed(2)} km ${isFar ? " - ${AppLocalization.translate('far_away', locale)}" : ""}',
            ),
            if (helper.openingHours == null || helper.openingHours!.isEmpty)
              Text(
                AppLocalization.translate('hours_unknown', locale),
                style: const TextStyle(fontSize: 12, color: Colors.orange),
              ),
            if (helper.openingHours != null && helper.openingHours!.isNotEmpty)
              Text(
                'Hours: ${helper.openingHours}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (helper.smsCapable)
              IconButton(
                icon: const Icon(Icons.message, color: Colors.blueGrey),
                onPressed: _makeSMS,
                tooltip: 'Send SMS',
              ),
            IconButton(
              icon: const Icon(Icons.phone, color: Colors.green),
              onPressed: _makeCall,
              tooltip: AppLocalization.translate('call_now', locale),
            ),
            IconButton(
              icon: const Icon(Icons.directions, color: Colors.blue),
              onPressed: _openMaps,
              tooltip: AppLocalization.translate('directions', locale),
            ),
          ],
        ),
      ),
    );
  }
}
