// Gallery of all situation-specific loading screens (RoadAid loaders).
import 'package:flutter/material.dart';

import '../widgets/loaders.dart';

class _Item {
  final String label;
  final String use;
  final Widget loader;
  const _Item(this.label, this.use, this.loader);
}

const _items = <_Item>[
  _Item('Pulse SOS', 'SOS button pressed', PulseSOS()),
  _Item('Road Scanner', 'AI Mechanic analyzing', RoadScanner()),
  _Item('Helper Radar', 'Matching nearby helpers', HelperRadar()),
  _Item('Wrench + Gear', 'Mechanic dispatched', WrenchGear()),
  _Item('Pin Drop', 'GPS lock / getting location', PinDrop()),
  _Item('Progress Steps', 'Request booking flow', ProgressStepsLoader()),
  _Item('Car on Route', 'Live helper tracking', CarOnRoute()),
  _Item('SOS Signal', 'Emergency broadcast', SOSSignal()),
  _Item('Verified Badge', 'Helper verification', VerifiedBadge()),
  _Item('Map Tiles', 'Map / tile loading', MapTiles()),
];

class LoaderGalleryScreen extends StatelessWidget {
  const LoaderGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050709),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050709),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Loading Screens'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, i) {
          final it = _items[i];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(height: 200, child: it.loader),
              ),
              const SizedBox(height: 8),
              Text('${i + 1}. ${it.label}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              Text(it.use,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
            ],
          );
        },
      ),
    );
  }
}
