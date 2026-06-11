// lib/presentation/screens/helper_results_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../data/api/discovery_api.dart';
import '../../data/models/category.dart';
import '../../data/models/marketplace_helper.dart';
import '../../data/repositories/helper_cache.dart';
import '../widgets/marketplace_helper_card.dart';
import '../widgets/map_markers.dart';
import 'helper_detail_screen.dart';

/// Nearest helpers for a chosen category (FR-010/FR-011).
class HelperResultsScreen extends StatefulWidget {
  final ServiceCategory category;
  final double lat;
  final double lng;
  const HelperResultsScreen({super.key, required this.category, required this.lat, required this.lng});

  @override
  State<HelperResultsScreen> createState() => _HelperResultsScreenState();
}

class _HelperResultsScreenState extends State<HelperResultsScreen> {
  final _api = DiscoveryApi();
  final _cache = HelperCache();
  final MapController _mapController = MapController();
  List<MarketplaceHelper> _helpers = [];
  bool _loading = true;
  bool _offline = false;
  String? _error;

  String _activeFilter = 'Nearest';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.nearby(
          lat: widget.lat, lng: widget.lng, category: widget.category.key, limit: 10);
      if (!mounted) return;
      setState(() {
        _helpers = res;
        _error = null;
        _offline = false;
      });
    } catch (_) {
      final cached = await _cacheForCategory();
      if (!mounted) return;
      setState(() {
        _helpers = cached;
        _offline = true;
        _error = cached.isEmpty ? context.tr('needs_connection') : null;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<MarketplaceHelper>> _cacheForCategory() async {
    final all = await _cache.load(lat: widget.lat, lng: widget.lng);
    final types = widget.category.helperTypes.toSet();
    final filtered = all.where((h) => types.contains(h.helperType)).toList();
    return (filtered.isEmpty ? all : filtered).take(10).toList();
  }

  List<MarketplaceHelper> get _filteredHelpers {
    List<MarketplaceHelper> list = List.from(_helpers);

    if (_activeFilter == 'Nearest') {
      list.sort((a, b) => (a.distanceKm ?? 999.0).compareTo(b.distanceKm ?? 999.0));
    } else if (_activeFilter == 'Top Rated') {
      list.sort((a, b) => b.ratingAvg.compareTo(a.ratingAvg));
    } else if (_activeFilter == 'Open Now') {
      list = list.where((h) => h.openNow == true).toList();
    } else if (_activeFilter == 'With SMS') {
      list = list.where((h) => h.smsCapable == true).toList();
    }

    return list;
  }

  Widget _buildFilterChip(String label) {
    final isActive = _activeFilter == label;
    final theme = Theme.of(context);
    final border = theme.colorScheme.outline;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _activeFilter = label;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0E7C52) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? const Color(0xFF0E7C52) : border,
              width: 1.5,
            ),
            gradient: isActive
                ? const LinearGradient(
                    colors: [Color(0xFF18B26B), Color(0xFF0E7C52)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            boxShadow: isActive
                ? const [
                    BoxShadow(
                      color: Color(0x1F0E7C52),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    )
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x05000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    )
                  ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFF7C887F),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finalHelpers = _filteredHelpers;

    // Create markers for map
    final userMarker = Marker(
      point: LatLng(widget.lat, widget.lng),
      width: 230,
      height: 230,
      child: const PulsingUserMarker(),
    );

    final helperMarkers = finalHelpers.map((h) {
      final isEmergency = h.helperType.contains('puncture') || h.helperType.contains('battery');
      return Marker(
        point: LatLng(h.latitude, h.longitude),
        width: 30,
        height: 30,
        child: GestureDetector(
          onTap: () {
            _mapController.move(LatLng(h.latitude, h.longitude), 15.5);
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => HelperDetailScreen(
                helperId: h.id,
                categoryId: widget.category.id,
              ),
            ));
          },
          child: PingingHelperMarker(isEmergency: isEmergency),
        ),
      );
    }).toList();

    final markers = [userMarker, ...helperMarkers];

    return Scaffold(
      body: Stack(
        children: [
          // 1. BACKGROUND INTERACTIVE MAP
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(widget.lat, widget.lng),
                initialZoom: 14.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: Theme.of(context).brightness == Brightness.dark
                      ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                      : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.roadsidehelp.app',
                  maxZoom: 19,
                ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),

          // 2. TRANSLUCENT GLASSMORPHIC HEADER
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0E7C52).withOpacity(0.85),
                        const Color(0xFF18B26B).withOpacity(0.75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.category.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _loading
                                  ? 'Locating verified helpers...'
                                  : '${finalHelpers.length} helpers available nearby',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.85),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _load,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.refresh, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. FLOATING MAP CONTROL (RECENTER)
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 92,
            child: GestureDetector(
              onTap: () {
                _mapController.move(LatLng(widget.lat, widget.lng), 14.5);
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Color(0x1C14281E), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                  border: Border.all(color: const Color(0xFFE7ECEA), width: 1.5),
                ),
                alignment: Alignment.center,
                child: const Text('🎯', style: TextStyle(fontSize: 18)),
              ),
            ),
          ),

          // 4. DRAGGABLE SCROLLABLE SLIDING PANEL
          DraggableScrollableSheet(
            initialChildSize: 0.42,
            minChildSize: 0.20,
            maxChildSize: 0.88,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1614281E),
                      blurRadius: 24,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Drag Handle
                    Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(top: 12, bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7ECEA),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),

                    // Filter chips row (Sticky)
                    Container(
                      height: 38,
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFilterChip('Nearest'),
                          _buildFilterChip('Top Rated'),
                          _buildFilterChip('Open Now'),
                          _buildFilterChip('With SMS'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Helpers list
                    Expanded(
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : _error != null
                              ? _ErrorView(message: _error!, onRetry: _load)
                              : finalHelpers.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Text('🤷‍♂️', style: TextStyle(fontSize: 32)),
                                            const SizedBox(height: 8),
                                            Text(
                                              context.tr('no_results'),
                                              style: const TextStyle(
                                                color: Color(0xFF7C887F),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      controller: scrollController, // Vital for sheet drag capability
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                      itemCount: finalHelpers.length + (_offline ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        if (_offline && index == 0) {
                                          return Container(
                                            margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFF1F0),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.wifi_off, size: 18, color: Color(0xFFB3261E)),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    context.tr('offline_banner'),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFFB3261E),
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        final h = finalHelpers[index - (_offline ? 1 : 0)];
                                        return MarketplaceHelperCard(
                                          helper: h,
                                          onTap: () {
                                            _mapController.move(LatLng(h.latitude, h.longitude), 15.5);
                                            Navigator.of(context).push(MaterialPageRoute(
                                              builder: (_) => HelperDetailScreen(
                                                helperId: h.id,
                                                categoryId: widget.category.id,
                                              ),
                                            ));
                                          },
                                        );
                                      },
                                    ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Color(0xFF7C887F)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF7C887F))),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: Text(context.tr('retry'))),
          ],
        ),
      ),
    );
  }
}
