// lib/presentation/widgets/horizontal_helper_card.dart
import 'package:flutter/material.dart';

import '../../data/models/marketplace_helper.dart';

class HorizontalHelperCard extends StatelessWidget {
  final MarketplaceHelper helper;
  final VoidCallback onTap;

  const HorizontalHelperCard({
    super.key,
    required this.helper,
    required this.onTap,
  });

  static List<Color> _getCategoryColors(String type) {
    switch (type) {
      case 'puncture_shop':
        return const [Color(0xFF5B8DEF), Color(0xFF3B5BDB)];
      case 'petrol_pump':
        return const [Color(0xFFFFA94D), Color(0xFFF76707)];
      case 'battery':
        return const [Color(0xFF22C7A9), Color(0xFF0CA678)];
      case 'mechanic':
        return const [Color(0xFF9775FA), Color(0xFF7048E8)];
      case 'towing':
        return const [Color(0xFFFF8787), Color(0xFFF03E3E)];
      default:
        return const [Color(0xFF0E7C52), Color(0xFF18B26B)];
    }
  }

  static String _getCategoryEmoji(String type) {
    switch (type) {
      case 'puncture_shop':
        return '🛞';
      case 'petrol_pump':
        return '⛽';
      case 'battery':
        return '🔋';
      case 'mechanic':
        return '🛠️';
      case 'towing':
        return '🚛';
      default:
        return '🔧';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.colorScheme.outline;
    final cardColor = theme.colorScheme.surface;
    final mutedText = theme.colorScheme.tertiary;

    final colors = _getCategoryColors(helper.helperType);
    final emoji = _getCategoryEmoji(helper.helperType);

    return Container(
      width: 158,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C14281E),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.5),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top category header matching gradient
              Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glass-morphic circle for category emoji
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.85),
                            Colors.white.withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 18, height: 1.0),
                      ),
                    ),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      helper.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          '★',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFF5A623), // Star color
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          helper.ratingAvg.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '(${helper.ratingCount})',
                          style: TextStyle(
                            fontSize: 10,
                            color: mutedText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (helper.distanceKm != null)
                          Text(
                            '${helper.distanceKm!.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0E7C52), // green distance text
                            ),
                          ),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: helper.openNow == true
                                ? const Color(0xFF18B26B)
                                : const Color(0xFF7C887F),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
