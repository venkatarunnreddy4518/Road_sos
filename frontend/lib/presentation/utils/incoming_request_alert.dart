import 'package:flutter/material.dart';

import '../../data/models/category.dart';

String _emojiFor(String icon) {
  switch (icon) {
    case 'tire_repair':
      return '🛞';
    case 'local_gas_station':
      return '⛽';
    case 'battery_charging_full':
      return '🔋';
    case 'fire_truck':
      return '🚒';
    default:
      return '🔧';
  }
}

/// Flashes the "SOS incoming" dialog on whichever screen is showing (home or the
/// provider inbox) when a new request is routed to this helper. Offers Accept and
/// Reject — Accept assigns the helper; Reject declines so the request reopens to
/// the next nearest helper.
Future<void> showIncomingRequestAlert({
  required BuildContext context,
  required Map<String, dynamic> req,
  required List<ServiceCategory> categories,
  required Future<void> Function() onAccept,
  required Future<void> Function() onReject,
}) {
  final seeker = (req['seeker_name'] as String?)?.trim();
  final note = (req['note'] as String?)?.trim();
  final dist = (req['distance_km'] as num?)?.toDouble();
  final catId = req['category_id'] as String?;
  final cat = categories.firstWhere(
    (c) => c.id == catId,
    orElse: () => ServiceCategory(
      id: '',
      key: '',
      name: 'Emergency Request',
      icon: 'build',
      sortOrder: 0,
      helperTypes: [],
    ),
  );

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Row(
          children: [
            const Text('🚨 ', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'SOS Incoming Alert!',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w900,
                  color: Theme.of(dialogContext).colorScheme.error,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A motorist nearby requested your help:',
              style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(_emojiFor(cat.icon), style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cat.name,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Seeker: ${seeker?.isNotEmpty == true ? seeker! : 'Someone Nearby'}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                  if (dist != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Distance: ${dist.toStringAsFixed(1)} km away',
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Colors.grey),
                    ),
                  ],
                  if (note?.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Text(
                      'Note: "$note"',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onReject();
            },
            child: Text(
              'Reject',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.bold,
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onAccept();
            },
            child: const Text(
              'Accept SOS',
              style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w900),
            ),
          ),
        ],
      );
    },
  );
}
