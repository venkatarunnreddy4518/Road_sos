// lib/presentation/widgets/marketplace_helper_card.dart
import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../data/models/marketplace_helper.dart';
import '../utils/helper_actions.dart';
import 'rating_stars.dart';

class MarketplaceHelperCard extends StatelessWidget {
  final MarketplaceHelper helper;
  final VoidCallback onTap;
  const MarketplaceHelperCard({super.key, required this.helper, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dist = helper.distanceKm;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                    child: Icon(Icons.handyman, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(helper.name,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            if (helper.isVerified)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(Icons.verified, size: 16, color: Theme.of(context).colorScheme.primary),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(helper.typeLabel,
                            style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (dist != null)
                    Text('${dist.toStringAsFixed(1)} km',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  RatingStars(rating: helper.ratingAvg, count: helper.ratingCount),
                  _statusChip(context),
                  if (helper.isFar)
                    _chip(
                      context.tr('far_away'),
                      isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                      Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (helper.phone != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => HelperActions.call(helper.phone!),
                        icon: const Icon(Icons.call, size: 18),
                        label: Text(context.tr('call')),
                      ),
                    ),
                  if (helper.phone != null && helper.smsCapable) const SizedBox(width: 8),
                  if (helper.smsCapable && helper.phone != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => HelperActions.sms(helper.phone!),
                        icon: const Icon(Icons.sms, size: 18),
                        label: Text(context.tr('sms')),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          HelperActions.directions(helper.latitude, helper.longitude, label: helper.name),
                      icon: const Icon(Icons.directions, size: 18),
                      label: Text(context.tr('directions')),
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

  Widget _statusChip(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final grayBg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
    final grayFg = Theme.of(context).colorScheme.tertiary;

    if (helper.openNow == null) {
      return _chip(context.tr('hours_unknown'), grayBg, grayFg);
    }
    return helper.openNow!
        ? _chip(context.tr('open_now'), primaryColor, onPrimaryColor)
        : _chip(context.tr('closed'), grayBg, grayFg);
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
