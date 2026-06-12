import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../core/i18n/l10n_ext.dart';
import '../../core/utils/location_service.dart';
import '../../data/api/discovery_api.dart';
import '../../data/models/category.dart';
import '../../data/models/marketplace_helper.dart';
import '../../data/repositories/helper_cache.dart';
import '../widgets/category_grid.dart';
import '../widgets/horizontal_helper_card.dart';
import '../widgets/location_permission_sheet.dart';
import '../widgets/map_markers.dart';
import 'helper_detail_screen.dart';
import 'helper_results_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'ai_assistant_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  Widget _buildNavItem(int index, String icon, String label) {
    final isActive = _tab == index;
    final theme = Theme.of(context);
    final color = isActive ? theme.colorScheme.primary : theme.colorScheme.tertiary;

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
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
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
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1.5)),
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 18),
        child: Row(
          children: [
            _buildNavItem(0, '🏠', context.tr('nav_home')),
            _buildNavItem(1, '🕐', context.tr('history')),
            _buildNavItem(2, '📡', context.tr('nav_nearby')),
            _buildNavItem(3, '🚗', context.tr('nav_travel')),
            _buildNavItem(4, '👤', context.tr('profile')),
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
  final ScrollController _scrollController = ScrollController();
  List<ServiceCategory> _categories = [];
  List<MarketplaceHelper> _nearby = [];
  Position? _pos;
  bool _loading = true;
  bool _offline = false;
  DateTime? _cacheAge;
  bool _showPromo = true;
  double _scrollOffset = 0.0;

  /// True once we know we don't have a real fix (denied/skipped) — the map then
  /// shows an approximate area and the location pill invites the user to enable.
  bool _locationDenied = false;

  double get _lat => _pos?.latitude ?? 17.4239;
  double get _lng => _pos?.longitude ?? 78.4738;
  bool get _hasRealLocation => _pos != null;
  String _addressLine1 = 'Locating you…';
  String _addressLine2 = '';

  Future<void> _fetchAddress(double lat, double lng) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18');
      final res = await http.get(url, headers: {'User-Agent': 'roadside_help_app/1.0'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          final road = addr['road'] ?? addr['suburb'] ?? addr['neighbourhood'] ?? addr['amenity'] ?? '';
          final city = addr['city'] ?? addr['town'] ?? addr['county'] ?? 'Hyderabad';
          final state = addr['state'] ?? '';
          if (mounted) {
            setState(() {
              _addressLine1 = road.toString().isNotEmpty ? road.toString() : 'Current Location';
              _addressLine2 = '$city, $state'.trim();
            });
          }
        } else {
          final displayName = data['display_name'] as String?;
          if (displayName != null) {
            final parts = displayName.split(',');
            if (mounted) {
              setState(() {
                _addressLine1 = parts.first.trim();
                _addressLine2 = parts.skip(1).take(2).join(',').trim();
              });
            }
          }
        }
      }
    } catch (_) {
      // Keep existing default values
    }
  }

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
    // Resolve location (prompting via the popup on first entry) before loading.
    WidgetsBinding.instance.addPostFrameCallback((_) => _useMyLocation());
    _scrollController.addListener(() {
      if (mounted) {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _moveMap() {
    try {
      _mapController.move(LatLng(_lat, _lng), 14.5);
    } catch (_) {}
  }

  /// Resolves the user's position, showing the beautiful permission popup the
  /// first time (or whenever permission isn't granted), then loads helpers.
  Future<void> _useMyLocation() async {
    await _resolveLocation(prompt: true);
    await _load();
  }

  Future<void> _resolveLocation({required bool prompt}) async {
    // Already granted → fetch silently, no popup.
    if (await LocationService.hasPermission()) {
      final res = await LocationService.determinePosition(request: false);
      if (!mounted) return;
      if (res.ok) {
        setState(() {
          _pos = res.position;
          _locationDenied = false;
        });
        _moveMap();
      }
      return;
    }
    if (!prompt || !mounted) return;
    // Not granted → show the friendly explainer popup.
    final res = await showLocationPermissionSheet(context);
    if (!mounted) return;
    if (res != null && res.ok) {
      setState(() {
        _pos = res.position;
        _locationDenied = false;
      });
      _moveMap();
    } else {
      setState(() => _locationDenied = true);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    if (_hasRealLocation) _fetchAddress(_lat, _lng);
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

  Widget _buildContentList({ScrollController? controller, required bool isDesktop}) {
    return ListView(
      controller: controller,
      shrinkWrap: isDesktop,
      physics: isDesktop ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.zero,
      children: [
        // Location Row: tappable pill that resolves / re-requests location.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GestureDetector(
            onTap: _useMyLocation,
            child: Builder(
              builder: (context) {
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;
                final chipBg = _locationDenied
                    ? (isDark ? const Color(0xFF2E250A) : const Color(0xFFFFF7E0))
                    : (isDark ? const Color(0xFF112E20) : const Color(0xFFE7F6EE));
                final chipText = _locationDenied
                    ? (isDark ? const Color(0xFFFFC107) : const Color(0xFF8A6D00))
                    : (isDark ? const Color(0xFF22C7A9) : const Color(0xFF0E7C52));
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _locationDenied
                          ? const Color(0xFFF5C518)
                          : theme.colorScheme.outline,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(_locationDenied ? '📍 ' : '🧭 ',
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _locationDenied
                                  ? context.tr('location_off')
                                  : _hasRealLocation
                                      ? _addressLine1
                                      : context.tr('locating'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _locationDenied
                                  ? context.tr('location_off_sub')
                                  : _addressLine2,
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.tertiary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: chipBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _locationDenied
                                  ? Icons.location_off
                                  : Icons.my_location,
                              size: 11,
                              color: chipText,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _locationDenied ? context.tr('enable') : context.tr('gps'),
                              style: TextStyle(
                                color: chipText,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
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
          Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final offlineBg = isDark ? const Color(0xFF2D1211) : const Color(0xFFFFF1F0);
              final offlineText = isDark ? const Color(0xFFFF6B6B) : const Color(0xFFB3261E);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: offlineBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, size: 18, color: offlineText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _cacheAge != null
                            ? '${context.tr('offline_banner')} · ${context.tr('last_updated')} ${_fmtAge(_cacheAge!)}'
                            : context.tr('offline_banner'),
                        style: TextStyle(fontSize: 12, color: offlineText),
                      ),
                    ),
                  ],
                ),
              );
            }
          ),

        // Promo Banner
        if (_showPromo)
          Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final promoBg = isDark ? const Color(0xFF112E20) : const Color(0xFFE7F6EE);
              final promoBorder = isDark ? const Color(0xFF194D36) : const Color(0xFFCDECE0);
              final promoText = isDark ? const Color(0xFF22C7A9) : const Color(0xFF0E7C52);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: promoBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: promoBorder, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Text('🛡️', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('promo_title'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: promoText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr('promo_sub'),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF7C887F),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 16, color: promoText),
                        onPressed: () {
                          setState(() {
                            _showPromo = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            }
          ),

        // AI Mechanic Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: const Icon(Icons.psychology, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      context.tr('ai_mechanic_title'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: const BoxDecoration(
                                        color: Colors.white24,
                                        borderRadius: BorderRadius.all(Radius.circular(6)),
                                      ),
                                      child: Text(
                                        context.tr('new_badge'),
                                        style: const TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.tr('ai_mechanic_sub'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
          ),
        ),

        // Emergency Services Label
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(
            context.tr('emergency_services'),
            style: const TextStyle(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              context.tr('open_near_you'),
              style: const TextStyle(
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
                ? Center(
                    child: Builder(
                      builder: (context) {
                        return Text(
                          context.tr('no_helpers_nearby'),
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.tertiary),
                        );
                      }
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              context.tr('safety_advice'),
              style: const TextStyle(
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
              children: [
                _SafetyAdviceCard(
                  emoji: '💡',
                  title: context.tr('safety1_title'),
                  desc: context.tr('safety1_desc'),
                ),
                _SafetyAdviceCard(
                  emoji: '🚗',
                  title: context.tr('safety2_title'),
                  desc: context.tr('safety2_desc'),
                ),
                _SafetyAdviceCard(
                  emoji: '📍',
                  title: context.tr('safety3_title'),
                  desc: context.tr('safety3_desc'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    final userMarker = Marker(
      point: LatLng(_lat, _lng),
      width: 230,
      height: 230,
      child: const PulsingUserMarker(),
    );

    final markers = [
      userMarker,
      ..._nearby.map((h) {
        final isEmergency = h.helperType.contains('puncture') || h.helperType.contains('battery');
        return Marker(
          point: LatLng(h.latitude, h.longitude),
          width: 30,
          height: 30,
          child: PingingHelperMarker(isEmergency: isEmergency),
        );
      }),
    ];

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 440,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Color(0xFFE7ECEA), width: 1.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Theme.of(context).colorScheme.secondary, Theme.of(context).colorScheme.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Text('🛟', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Roadside SOS',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            context.tr('app_subtitle'),
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.tertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildContentList(isDesktop: true),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
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
                Positioned(
                  top: 24,
                  left: 24,
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
                          '${_nearby.length} ${context.tr('helpers_nearby_suffix')}',
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
                Positioned(
                  right: 24,
                  top: 24,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _useMyLocation,
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
              ],
            ),
          ),
        ],
      );
    } else {
      const double mapHeight = 440.0;
      final double mapOffset = -_scrollOffset * 0.18;
      final double scrimOpacity = (_scrollOffset / 260.0).clamp(0.0, 0.7);

      return Stack(
        children: [
          Positioned(
            top: mapOffset,
            left: 0,
            right: 0,
            height: mapHeight,
            child: Stack(
              children: [
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
                          '${_nearby.length} ${context.tr('helpers_nearby_suffix')}',
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
                Positioned(
                  right: 16,
                  top: 48,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _useMyLocation,
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
                Positioned(
                  top: 180,
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📍 ', style: TextStyle(fontSize: 12)),
                          Text(
                            context.tr('pickup_point'),
                            style: const TextStyle(
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
              ],
            ),
          ),
          Positioned(
            top: mapOffset,
            left: 0,
            right: 0,
            height: mapHeight,
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: Duration.zero,
                color: Colors.black.withValues(alpha: scrimOpacity),
              ),
            ),
          ),
          NotificationListener<ScrollNotification>(
            onNotification: (n) {
              setState(() => _scrollOffset = n.metrics.pixels);
              return true;
            },
            child: ListView(
              padding: const EdgeInsets.only(top: mapHeight - 32),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: _buildContentList(isDesktop: true),
                ),
              ],
            ),
          ),
        ],
      );
    }
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
                color: const Color(0xFF18B26B).withValues(alpha: 0.5 * (1.0 - _controller.value)),
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
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  context.tr('where_help'),
                  style: const TextStyle(
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
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📡', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 10),
            Text(context.tr('nearby_placeholder'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🚗', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 10),
            Text(context.tr('travel_placeholder'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
