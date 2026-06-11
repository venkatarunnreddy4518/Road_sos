// lib/presentation/widgets/category_grid.dart
import 'package:flutter/material.dart';

import '../../data/models/category.dart';

/// Bento category grid matching the requested bento mockup layout.
class CategoryGrid extends StatelessWidget {
  final List<ServiceCategory> categories;
  final void Function(ServiceCategory) onTap;

  const CategoryGrid({super.key, required this.categories, required this.onTap});

  @override
  Widget build(BuildContext context) {
    ServiceCategory? findCat(String key) {
      for (final c in categories) {
        if (c.key == key) return c;
      }
      return null;
    }

    final puncture = findCat('puncture');
    final fuel = findCat('fuel');
    final breakdown = findCat('breakdown');
    final battery = findCat('battery');
    final towing = findCat('towing');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Row 1: Tall Puncture Fix (left) & stacked Out of Fuel + Jump Start (right)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tall card: Puncture Fix
                Expanded(
                  child: puncture != null
                      ? _buildBentoCard(
                          context,
                          category: puncture,
                          label: 'ROADSIDE',
                          name: 'Puncture\nFix',
                          emoji: '🛞',
                          isTall: true,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF5B8DEF), Color(0xFF3B5BDB)],
                          ),
                          isFast: true,
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 11),
                // Stacked cards: Out of Fuel & Jump Start
                Expanded(
                  child: Column(
                    children: [
                      // Out of Fuel
                      Expanded(
                        child: fuel != null
                            ? _buildBentoCard(
                                context,
                                category: fuel,
                                label: 'EMERGENCY',
                                name: 'Out of Fuel',
                                emoji: '⛽',
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFFFFA94D), Color(0xFFF76707)],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 11),
                      // Jump Start
                      Expanded(
                        child: battery != null
                            ? _buildBentoCard(
                                context,
                                category: battery,
                                label: 'BATTERY',
                                name: 'Jump Start',
                                emoji: '🔋',
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF22C7A9), Color(0xFF0CA678)],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          // Wide card: Mechanic / Breakdown
          breakdown != null
              ? _buildBentoCard(
                  context,
                  category: breakdown,
                  name: 'Mechanic / Breakdown',
                  emoji: '🛠️',
                  isWide: true,
                  badgeText: '⚙️ On-site repair',
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF9775FA), Color(0xFF7048E8)],
                  ),
                )
              : const SizedBox.shrink(),
          const SizedBox(height: 11),
          // Wide card: Towing Service
          towing != null
              ? _buildBentoCard(
                  context,
                  category: towing,
                  name: 'Towing Service',
                  label: 'Tow to a workshop or your destination',
                  emoji: '🚛',
                  isWide: true,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF8787), Color(0xFFF03E3E)],
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildBentoCard(
    BuildContext context, {
    required ServiceCategory category,
    required String name,
    required String emoji,
    required Gradient gradient,
    String? label,
    String? badgeText,
    bool isTall = false,
    bool isWide = false,
    bool isFast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2814281E),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(category),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(15),
            height: isWide ? 86 : (isTall ? 211 : 100),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Text layouts
                if (isWide)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (badgeText != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  badgeText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                            ],
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.15,
                              ),
                            ),
                            if (label != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.85),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildBentoIco(emoji, isWide: true),
                    ],
                  )
                else ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (label != null)
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.82),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _buildBentoIco(emoji),
                  ),
                ],
                // FAST badge on top right for tall card
                if (isFast)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Text(
                        'FAST',
                        style: TextStyle(
                          color: Color(0xFFF76707),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBentoIco(String emoji, {bool isWide = false}) {
    final size = isWide ? 52.0 : 56.0;
    final emojiSize = isWide ? 28.0 : 31.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.55),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x38000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white60,
            blurRadius: 2,
            offset: Offset(0, 1.5),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        emoji,
        style: TextStyle(
          fontSize: emojiSize,
          height: 1.0,
        ),
      ),
    );
  }
}
