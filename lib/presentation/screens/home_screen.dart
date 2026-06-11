import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/utils/location_service.dart';
import '../../data/api/discovery_api.dart';
import '../../data/models/category.dart';
import '../../data/models/marketplace_helper.dart';
import '../../data/repositories/helper_cache.dart';
import '../state/auth_state.dart';
import '../widgets/category_grid.dart';
import '../widgets/horizontal_helper_card.dart';
import 'helper_detail_screen.dart';
import 'helper_results_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  Widget _buildNavItem(int index, String icon, String label) {
    final isActive = _tab == index;
    final color = isActive ? const Color(0xFF0E7C52) : const Color(0xFF7C887F);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: TextStyle(fontSize: 20, color: color)),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 3),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF0E7C52),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _DiscoverTab(),
      const HistoryScreen(),
      const _NearbyPlaceholderTab(),
      const _TravelPlaceholderTab(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_tab],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE7ECEA), width: 1.5)),
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 18),
        child: Row(
          children: [
            _buildNavItem(0, '🏠', 'Home'),
            _buildNavItem(1, '🕐', 'History'),
            _buildNavItem(2, '📡', 'Nearby'),
            _buildNavItem(3, '🚗', 'Travel'),
            _buildNavItem(4, '👤', 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _DiscoverTab extends StatefulWidget {
  const _DiscoverTab();
  @override
  State<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<_DiscoverTab> {
  final _api = DiscoveryApi();
  final _cache = HelperCache();
  final MapController _mapController = MapController();
  List<ServiceCategory> _categories = [];
  List<MarketplaceHelper> _nearby = [];
  Position? _pos;
  bool _loading = true;
  bool _offline = false;
  DateTime? _cacheAge;
  bool _showPromo = true;

  double get _lat => _pos?.latitude ?? 17.4239;
  double get _lng => _pos?.longitude ?? 78.4738;

  String _fmtAge(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _pos = await LocationService.current();
    try {
      final cats = await _api.categories();
      final near = await _api.nearby(lat: _lat, lng: _lng, limit: 5);
      try {
        await _cache.save(await _api.syncFeed());
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _nearby = near;
        _offline = false;
        _cacheAge = null;
      });
      try {
        _mapController.move(LatLng(_lat, _lng), 14.5);
      } catch (_) {}
    } catch (_) {
      final cached = await _cache.load(lat: _lat, lng: _lng);
      final age = await _cache.lastSyncedAt();
      if (!mounted) return;
      setState(() {
        _offline = true;
        _nearby = cached.take(5).toList();
        _cacheAge = age;
      });
      try {
        _mapController.move(LatLng(_lat, _lng), 14.5);
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Create map markers
    final userMarker = Marker(
      point: LatLng(_lat, _lng),
      width: 44,
      height: 44,
      child: const _PulsingUserMarker(),
    );

    final markers = [
      userMarker,
      ..._nearby.map((h) {
        final isEmergency = h.helperType.contains('puncture') || h.helperType.contains('battery');
        return Marker(
          point: LatLng(h.latitude, h.longitude),
          width: 30,
          height: 30,
          child: _PingingHelperMarker(isEmergency: isEmergency),
        );
      }),
    ];

    return Stack(
      children: [
        // 1. MAP AREA (background)
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(_lat, _lng),
              initialZoom: 14.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.roadsidehelp.app',
                maxZoom: 19,
              ),
              MarkerLayer(markers: markers),
            ],
          ),
        ),

        // 2. FLOATING LIVE CHIP (Top overlays)
        Positioned(
          top: 48,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Color(0x1A14281E), blurRadius: 10, offset: Offset(0, 4)),
              ],
              border: Border.all(color: const Color(0xFFE7ECEA), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _PulsingGreenDot(),
                const SizedBox(width: 6),
                Text(
                  '${_nearby.length} helpers nearby',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF14201B),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. MAP FAB BUTTONS
        Positioned(
          right: 16,
          top: 48,
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  _mapController.move(LatLng(_lat, _lng), 14.5);
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(color: Color(0x1414281E), blurRadius: 8, offset: Offset(0, 3)),
                    ],
                    border: Border.all(color: const Color(0xFFE7ECEA), width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🎯', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _load,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(color: Color(0x1414281E), blurRadius: 8, offset: Offset(0, 3)),
                    ],
                    border: Border.all(color: const Color(0xFFE7ECEA), width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: const Text('📡', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),

        // 4. MAP CENTER PIN LABEL
        Positioned(
          top: MediaQuery.of(context).size.height * 0.22,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0E7C52),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x330E7C52), blurRadius: 12, offset: Offset(0, 2)),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('📍 ', style: TextStyle(fontSize: 12)),
                  Text(
                    'Pickup Point',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 5. BOTTOM SHEET PANEL (DraggableScrollableSheet)
        DraggableScrollableSheet(
          initialChildSize: 0.56,
          minChildSize: 0.56,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1214281E),
                    blurRadius: 24,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7ECEA),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.zero,
                      children: [
                        // Location Row: Bordered pill style with locator arrow
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: const Color(0xFFE7ECEA), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const Text('🧭 ', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sai Satya Narayan Nivas, Mathrusree Naga...',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF14201B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Kukatpally, Hyderabad',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF7C887F),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE7F6EE),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'మీది మంట లేక్',
                                    style: TextStyle(
                                      color: Color(0xFF0E7C52),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Shimmer Search Bar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: _ShimmerSearchBar(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => SearchScreen(lat: _lat, lng: _lng)),
                            ),
                          ),
                        ),

                        if (_offline)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.wifi_off, size: 18, color: Color(0xFFB3261E)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _cacheAge != null
                                        ? '${context.tr('offline_banner')} · ${context.tr('last_updated')} ${_fmtAge(_cacheAge!)}'
                                        : context.tr('offline_banner'),
                                    style: const TextStyle(fontSize: 12, color: Color(0xFFB3261E)),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Promo Banner
                        if (_showPromo)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE7F6EE),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFCDECE0), width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  const Text('🛡️', style: TextStyle(fontSize: 24)),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'More verified helpers online now',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0E7C52),
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'All helpers are background checked.',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF7C887F),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16, color: Color(0xFF0E7C52)),
                                    onPressed: () {
                                      setState(() {
                                        _showPromo = false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Emergency Services Label
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                          child: Text(
                            'EMERGENCY SERVICES',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: Color(0xFF7C887F),
                            ),
                          ),
                        ),

                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else ...[
                          CategoryGrid(
                            categories: _categories,
                            onTap: (c) => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => HelperResultsScreen(category: c, lat: _lat, lng: _lng),
                            )),
                          ),

                          // Open Near You Rail
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                            child: Text(
                              'OPEN NEAR YOU',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: Color(0xFF7C887F),
                              ),
                            ),
                          ),

                          Container(
                            height: 136,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: _nearby.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No helpers nearby',
                                      style: TextStyle(fontSize: 12, color: Color(0xFF7C887F)),
                                    ),
                                  )
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: _nearby.length,
                                    itemBuilder: (context, index) {
                                      final helper = _nearby[index];
                                      return HorizontalHelperCard(
                                        helper: helper,
                                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                          builder: (_) => HelperDetailScreen(helperId: helper.id, categoryId: null),
                                        )),
                                      );
                                    },
                                  ),
                          ),

                          // Safety Advice Rail
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: Text(
                              'SAFETY ADVICE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: Color(0xFF7C887F),
                              ),
                            ),
                          ),

                          Container(
                            height: 96,
                            margin: const EdgeInsets.only(bottom: 24),
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              children: const [
                                _SafetyAdviceCard(
                                  emoji: '💡',
                                  title: 'Turn on Hazards',
                                  desc: 'Switch on hazard lights immediately to warn passing traffic.',
                                ),
                                _SafetyAdviceCard(
                                  emoji: '🚗',
                                  title: 'Move Off Road',
                                  desc: 'Pull safely onto the shoulder or a safe spot away from lanes.',
                                ),
                                _SafetyAdviceCard(
                                  emoji: '📍',
                                  title: 'Share Location',
                                  desc: 'Send your GPS coordinates to family or emergency contacts.',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SafetyAdviceCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;
  const _SafetyAdviceCard({required this.emoji, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECEA), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0614281E),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF14201B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF7C887F),
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingUserMarker extends StatefulWidget {
  const _PulsingUserMarker();
  @override
  State<_PulsingUserMarker> createState() => _PulsingUserMarkerState();
}

class _PulsingUserMarkerState extends State<_PulsingUserMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Ripple ring
            Container(
              width: 14 + (24 * _controller.value),
              height: 14 + (24 * _controller.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF18B26B).withOpacity(1.0 - _controller.value),
                  width: 2,
                ),
              ),
            ),
            // Inner marker
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0E7C52), width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x380E7C52),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF0E7C52),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PingingHelperMarker extends StatefulWidget {
  final bool isEmergency;
  const _PingingHelperMarker({required this.isEmergency});
  @override
  State<_PingingHelperMarker> createState() => _PingingHelperMarkerState();
}

class _PingingHelperMarkerState extends State<_PingingHelperMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final color = widget.isEmergency ? const Color(0xFFF5A623) : const Color(0xFF0E7C52);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Ripple ping
            Container(
              width: 10 + (20 * _controller.value),
              height: 10 + (20 * _controller.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.3 * (1.0 - _controller.value)),
              ),
            ),
            // Dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PulsingGreenDot extends StatefulWidget {
  const _PulsingGreenDot();
  @override
  State<_PulsingGreenDot> createState() => _PulsingGreenDotState();
}

class _PulsingGreenDotState extends State<_PulsingGreenDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 8 + (10 * _controller.value),
              height: 8 + (10 * _controller.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF18B26B).withOpacity(0.5 * (1.0 - _controller.value)),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF18B26B),
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ShimmerSearchBar extends StatefulWidget {
  final VoidCallback onTap;
  const _ShimmerSearchBar({required this.onTap});
  @override
  State<_ShimmerSearchBar> createState() => _ShimmerSearchBarState();
}

class _ShimmerSearchBarState extends State<_ShimmerSearchBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: const [
                  Color(0xFF18B26B),
                  Color(0xFF2AE08E),
                  Color(0xFF18B26B),
                  Color(0xFF0E7C52),
                ],
                stops: const [0.0, 0.35, 0.5, 1.0],
                begin: Alignment(-1.0 - _controller.value, -1.0),
                end: Alignment(1.0 - _controller.value, 1.0),
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x240E7C52),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'Where do you need help?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NearbyPlaceholderTab extends StatelessWidget {
  const _NearbyPlaceholderTab();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📡', style: TextStyle(fontSize: 40)),
            SizedBox(height: 10),
            Text('Nearby Helpers Map & List', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _TravelPlaceholderTab extends StatelessWidget {
  const _TravelPlaceholderTab();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🚗', style: TextStyle(fontSize: 40)),
            SizedBox(height: 10),
            Text('Travel Mode & Route Support', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
