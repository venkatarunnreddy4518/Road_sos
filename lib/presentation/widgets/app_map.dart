// lib/presentation/widgets/app_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapMarker {
  final double lat;
  final double lng;
  final IconData icon;
  final Color color;
  MapMarker(this.lat, this.lng, {this.icon = Icons.location_on, this.color = const Color(0xFF111111)});
}

/// OpenStreetMap-based map (no API key) showing the user + helper markers.
class AppMap extends StatelessWidget {
  final double centerLat;
  final double centerLng;
  final List<MapMarker> markers;
  final double zoom;
  const AppMap({
    super.key,
    required this.centerLat,
    required this.centerLng,
    this.markers = const [],
    this.zoom = 13,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileUrl = isDark
        ? 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
        : 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';

    return FlutterMap(
      options: MapOptions(initialCenter: LatLng(centerLat, centerLng), initialZoom: zoom),
      children: [
        TileLayer(
          urlTemplate: tileUrl,
          userAgentPackageName: 'com.roadsidehelp.app',
        ),
        MarkerLayer(
          markers: markers
              .map((m) => Marker(
                    point: LatLng(m.lat, m.lng),
                    width: 44,
                    height: 44,
                    child: Icon(m.icon, color: m.color, size: 36),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
