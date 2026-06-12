// lib/presentation/widgets/app_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapMarker {
  final double lat;
  final double lng;
  final IconData icon;
  final Color color;
  final double size;
  MapMarker(this.lat, this.lng, {this.icon = Icons.location_on, this.color = const Color(0xFF111111), this.size = 36});
}

/// OpenStreetMap-based map (no API key) showing the user + helper markers.
class AppMap extends StatelessWidget {
  final double centerLat;
  final double centerLng;
  final List<MapMarker> markers;
  final double zoom;
  final MapController? mapController;
  final bool interactive;

  const AppMap({
    super.key,
    required this.centerLat,
    required this.centerLng,
    this.markers = const [],
    this.zoom = 13,
    this.mapController,
    this.interactive = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use standard OpenStreetMap tiles — reliable and free for all usage.
    final tileUrl = isDark
        ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: LatLng(centerLat, centerLng),
        initialZoom: zoom,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: tileUrl,
          userAgentPackageName: 'com.roadsidehelp.app',
          maxZoom: 19,
          tileBuilder: isDark ? _darkTileBuilder : null,
        ),
        MarkerLayer(
          markers: markers
              .map((m) => Marker(
                    point: LatLng(m.lat, m.lng),
                    width: m.size + 8,
                    height: m.size + 8,
                    child: _StyledMarker(icon: m.icon, color: m.color, size: m.size),
                  ))
              .toList(),
        ),
      ],
    );
  }

  /// Apply a dark filter to standard OSM tiles via ColorFiltered.
  static Widget _darkTileBuilder(BuildContext context, Widget tileWidget, TileImage tile) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        -0.6, 0, 0, 0, 180,
        0, -0.6, 0, 0, 180,
        0, 0, -0.6, 0, 180,
        0, 0, 0, 1, 0,
      ]),
      child: tileWidget,
    );
  }
}

class _StyledMarker extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _StyledMarker({required this.icon, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size),
    );
  }
}
