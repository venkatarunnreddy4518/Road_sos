// lib/presentation/widgets/marketplace_helper_card.dart
import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../data/models/marketplace_helper.dart';
import '../utils/helper_actions.dart';
import 'rating_stars.dart';

class MarketplaceHelperCard extends StatelessWidget {
  final MarketplaceHelper helper;
  final VoidCallback onTap;  const MarketplaceHelperCard({super.key, required this.helper, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.colorScheme.outline;
    final cardColor = theme.colorScheme.surface;
    final mutedText = theme.colorScheme.tertiary;

    final dist = helper.distanceKm;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0814281E),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.5),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                helper.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (helper.isVerified)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(Icons.verified, size: 15, color: Color(0xFF18B26B)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          helper.typeLabel,
                          style: TextStyle(
                            color: mutedText,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Rating & Open badges
                        Row(
                          children: [
                            const Text(
                              '★',
                              style: TextStyle(fontSize: 14, color: Color(0xFFF5A623)),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              helper.ratingAvg.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '(${helper.ratingCount})',
                              style: TextStyle(
                                fontSize: 11,
                                color: mutedText,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _buildOpenBadge(context),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (dist != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          dist.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0E7C52), // large green distance
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'km away',
                          style: TextStyle(
                            fontSize: 10,
                            color: mutedText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Actions row
              Row(
                children: [
                  if (helper.phone != null)
                    Expanded(
                      child: InkWell(
                        onTap: () => HelperActions.call(helper.phone!),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF18B26B), Color(0xFF0E7C52)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x240E7C52),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('📞 ', style: TextStyle(fontSize: 10, color: Colors.white)),
                              Text(
                                'Call',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (helper.phone != null) const SizedBox(width: 8),
                  if (helper.smsCapable && helper.phone != null) ...[
                    Expanded(
                      child: InkWell(
                        onTap: () => HelperActions.sms(helper.phone!),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(color: border, width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                            color: cardColor,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('💬 ', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface)),
                              Text(
                                'SMS',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: InkWell(
                      onTap: () => HelperActions.directions(
                        helper.latitude,
                        helper.longitude,
                        label: helper.name,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: border, width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                          color: cardColor,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🧭 ', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface)),
                            Text(
                              'Directions',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpenBadge(BuildContext context) {
    if (helper.openNow == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB), // soft yellow/amber
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Hours Unknown',
          style: TextStyle(
            color: Color(0xFFD97706),
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    return helper.openNow!
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F6EE), // soft green
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Open Now',
              style: TextStyle(
                color: Color(0xFF0E7C52),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF2F2), // soft red
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Closed',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
  }


}
