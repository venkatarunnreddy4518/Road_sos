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
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFFDF6E3),
                    child: Icon(Icons.handyman, color: Color(0xFF111111)),
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
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(Icons.verified, size: 16, color: Color(0xFF18A957)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(helper.typeLabel, style: const TextStyle(color: Colors.black54, fontSize: 12)),
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
                  if (helper.isFar) _chip(context.tr('far_away'), const Color(0xFFFDECEC), const Color(0xFFB3261E)),
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
    if (helper.openNow == null) {
      return _chip(context.tr('hours_unknown'), const Color(0xFFF2F2F2), Colors.black54);
    }
    return helper.openNow!
        ? _chip(context.tr('open_now'), const Color(0xFFE7F6EE), const Color(0xFF18A957))
        : _chip(context.tr('closed'), const Color(0xFFF2F2F2), Colors.black54);
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
