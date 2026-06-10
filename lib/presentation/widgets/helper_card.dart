import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:roadside_help/core/utils/distance_calculator.dart';
import 'package:roadside_help/domain/entities/helper.dart';
import 'package:roadside_help/presentation/utils/helper_type_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class HelperCard extends StatelessWidget {
  static const double _userLat = 12.9716;
  static const double _userLng = 77.5946;

  final Helper helper;

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
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${helper.latitude},${helper.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final distance = DistanceCalculator.calculateDistance(
      _userLat,
      _userLng,
      helper.latitude,
      helper.longitude,
    );
    final etaMinutes = math.max(4, (distance / 420).round());
    final isFar = DistanceCalculator.isFarAway(distance);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final tertiaryColor = Theme.of(context).colorScheme.tertiary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: helperTypeColor(helper.type).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    helperTypeIcon(helper.type),
                    color: helperTypeColor(helper.type),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        helper.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        helperTypeTitle(helper.type),
                        style: TextStyle(
                          color: tertiaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _InfoChip(
                            icon: Icons.access_time,
                            label: '$etaMinutes min',
                            color: primaryColor,
                          ),
                          _InfoChip(
                            icon: Icons.route,
                            label: '${(distance / 1000).toStringAsFixed(1)} km',
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          if (isFar)
                            _InfoChip(
                              icon: Icons.warning_amber_rounded,
                              label: 'Far away',
                              color: tertiaryColor,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              helper.openingHours ?? 'Hours unknown',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tertiaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openMaps,
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('Directions'),
                  ),
                ),
                if (helper.smsCapable) ...[
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    onPressed: _makeSMS,
                    icon: const Icon(Icons.message),
                    tooltip: 'SMS',
                    style: IconButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: Theme.of(context).colorScheme.outline),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _makeCall,
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Call'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
