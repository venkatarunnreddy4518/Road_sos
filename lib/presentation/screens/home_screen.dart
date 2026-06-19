import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:async';

import '../../core/i18n/l10n_ext.dart';
import '../../core/i18n/strings.dart';
import '../../core/utils/location_service.dart';
import '../../core/utils/location_store.dart';
import '../../data/api/discovery_api.dart';
import '../../data/api/request_api.dart';
import '../../data/models/category.dart';
import '../../data/models/marketplace_helper.dart';
import '../../data/repositories/helper_cache.dart';
import '../state/auth_state.dart';
import '../state/role_state.dart';
import '../state/theme_state.dart';
import '../utils/helper_actions.dart';
import '../utils/incoming_request_alert.dart';
import '../widgets/category_grid.dart';
import '../widgets/helper_carousel.dart';
import '../widgets/location_permission_sheet.dart';
import '../widgets/map_markers.dart';
import 'helper_detail_screen.dart';
import 'helper_results_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'provider/provider_inbox_screen.dart';
import 'provider/provider_job_screen.dart';
import 'search_screen.dart';
import 'ai_assistant_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  // ── Design tokens from HTML ──
  static const Color _border = Color(0xFFECEEF4);
  static const Color _primary = Color(0xFF2563EB);

  // ── Helper incoming-request watcher ──
  // While the helper is anywhere in the app, poll for SOS requests routed to them
  // and flash an Accept/Reject alert (the request is targeted to the nearest helper).
  final RequestApi _requests = RequestApi();
  Timer? _helperPoll;
  List<ServiceCategory> _helperCats = [];
  final Set<String> _seenRequestIds = {};
  bool _alertOpen = false;
  bool _watchReady = false;
  double _helperLat = 17.4239;
  double _helperLng = 78.4738;

  @override
  void initState() {
    super.initState();
    _helperPoll = Timer.periodic(const Duration(seconds: 5), (_) => _pollIncoming());
  }

  @override
  void dispose() {
    _helperPoll?.cancel();
    super.dispose();
  }

  Future<void> _pollIncoming() async {
    if (!mounted || _alertOpen) return;
    if (!(context.read<AuthState>().user?.isHelper ?? false)) return;
    if (!_watchReady) {
      _watchReady = true;
      final pos = await LocationService.current();
      if (pos != null) {
        _helperLat = pos.latitude;
        _helperLng = pos.longitude;
      }
      try {
        _helperCats = await DiscoveryApi().categories();
      } catch (_) {}
      // First pass primes the seen-set so we don't flash a backlog on launch.
      try {
        final initial = await _requests.open(lat: _helperLat, lng: _helperLng);
        for (final r in initial) {
          _seenRequestIds.add(r['id'] as String);
        }
      } catch (_) {}
      return;
    }
    try {
      final open = await _requests.open(lat: _helperLat, lng: _helperLng);
      final fresh = open.where((r) => !_seenRequestIds.contains(r['id'] as String)).toList();
      for (final r in open) {
        _seenRequestIds.add(r['id'] as String);
      }
      if (fresh.isNotEmpty && mounted && !_alertOpen) {
        _alertOpen = true;
        await showIncomingRequestAlert(
          context: context,
          req: fresh.first,
          categories: _helperCats,
          onAccept: () => _acceptIncoming(fresh.first['id'] as String),
          onReject: () => _requests.decline(fresh.first['id'] as String),
        );
        _alertOpen = false;
      }
    } catch (_) {/* offline-tolerant; retry next tick */}
  }

  Future<void> _acceptIncoming(String id) async {
    try {
      await _requests.accept(id);
      if (!mounted) return;
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => ProviderJobScreen(requestId: id)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Widget _buildNavItem(int index, String icon, String label) {
    final isActive = _tab == index;
    final theme = Theme.of(context);
    final color = isActive ? _primary : theme.colorScheme.tertiary;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: TextStyle(fontSize: 20, color: color)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleState>().role;

    // Home tab carries the mode bar (Seeker/Helper + theme) and swaps its body
    // to the helper inbox when in Helper mode.
    final Widget homeTab = Column(
      children: [
        const _HomeModeBar(),
        Expanded(
          child: role == AppRole.helper
              ? const ProviderInboxScreen(embedded: true)
              : const _DiscoverTab(),
        ),
      ],
    );

    final pages = [
      homeTab,
      const HistoryScreen(),
      const _NearbyPlaceholderTab(),
      const _TravelPlaceholderTab(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_tab],
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Main navigation bar background & border
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.outline
                      : _border,
                  width: 1.5,
                ),
              ),
            ),
            padding: EdgeInsets.only(
              top: 10,
              bottom: 18 + MediaQuery.of(context).padding.bottom,
              left: 6,
              right: 6,
            ),
            child: Row(
              children: [
                _buildNavItem(0, '🏠', context.tr('nav_home')),
                _buildNavItem(1, '🕐', context.tr('history')),
                const SizedBox(width: 64), // Spacer for notch cutout
                _buildNavItem(3, '🚗', context.tr('nav_travel')),
                _buildNavItem(4, '👤', context.tr('profile')),
              ],
            ),
          ),
          // 2. Notch cutout background circle
          Positioned(
            top: -22,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  children: [
                    // Bottom mask to blend notch with the white bar below
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 32,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 3. Circular gradient FAB inside the notch
          Positioned(
            top: -16, // centered inside the 64px notch (-22 + (64-52)/2)
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => setState(() => _tab = 2),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [_primary, Color(0xFF60A5FA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
  bool _showNearbyList = false; // expands the helpers-nearby pill into a list

  /// True once we know we don't have a real fix (denied/skipped) — the map then
  /// shows an approximate area and the location pill invites the user to enable.
  bool _locationDenied = false;

  double get _lat => _pos?.latitude ?? 17.4239;
  double get _lng => _pos?.longitude ?? 78.4738;
  bool get _hasRealLocation => _pos != null;
  String _addressLine1 = 'Locating you…';
  String _addressLine2 = '';

  Timer? _debounceTimer;

  void _onMapMove(LatLng center) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _updateLocationFromMapCenter(center.latitude, center.longitude);
    });
  }

  void _updateLocationFromMapCenter(double latitude, double longitude) {
    setState(() {
      _pos = _posFrom(latitude, longitude);
      _addressLine1 = 'Locating...';
      _addressLine2 = '';
    });
    // Dragging the map is a deliberate choice → persist it so it sticks.
    _fetchAddress(latitude, longitude, persist: true);
    _loadHelpersOnly(latitude, longitude);
  }

  /// A synthetic high-confidence fix for a manually chosen point.
  Position _posFrom(double lat, double lng) => Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

  /// Sets the visible address and, when the location was user-chosen, saves it.
  void _applyAddress(double lat, double lng, String l1, String l2, bool persist) {
    if (!mounted) return;
    setState(() {
      _addressLine1 = l1;
      _addressLine2 = l2;
    });
    if (persist) LocationStore.save(lat, lng, label1: l1, label2: l2);
  }

  Future<void> _loadHelpersOnly(double latitude, double longitude) async {
    try {
      final near = await _api.nearby(lat: latitude, lng: longitude, limit: 5);
      if (!mounted) return;
      setState(() {
        _nearby = near;
      });
    } catch (_) {
      final cached = await _cache.load(lat: latitude, lng: longitude);
      if (!mounted) return;
      setState(() {
        _nearby = cached.take(5).toList();
      });
    }
  }

  Future<void> _fetchAddress(double lat, double lng, {bool persist = false}) async {
    // Ask the geocoder for names in the app's active language so the pill matches
    // the UI (otherwise Nominatim returns local-script names, e.g. Telugu, in an
    // English UI). Falls back to English-first when the script isn't available.
    final lang = '${context.read<LocaleController>().code},en';
    final fallback1 = 'Location near (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18');
      final res = await http.get(url,
          headers: {'User-Agent': 'roadside_help_app/1.0', 'Accept-Language': lang});
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          // Prefer a recognizable street/locality over GHMC-style "Ward N" names.
          String pick(List<String> keys) {
            for (final k in keys) {
              final v = addr[k];
              if (v != null && v.toString().trim().isNotEmpty) {
                return v.toString().replaceFirst(RegExp(r'^Ward\s*\d+\s*'), '').trim();
              }
            }
            return '';
          }

          final line1 = pick(['road', 'neighbourhood', 'quarter', 'residential',
              'suburb', 'village', 'hamlet', 'city_district']);
          final city = pick(['city', 'town', 'municipality', 'county']);
          final state = pick(['state']);
          final parts = <String>[
            city.isNotEmpty ? city : 'Hyderabad',
            if (state.isNotEmpty) state,
          ];
          _applyAddress(lat, lng, line1.isNotEmpty ? line1 : 'Current location',
              parts.join(', '), persist);
          return;
        }
        final displayName = data['display_name'] as String?;
        if (displayName != null) {
          final parts = displayName.split(',');
          _applyAddress(lat, lng, parts.first.trim(),
              parts.skip(1).take(2).join(',').trim(), persist);
          return;
        }
      }
      _applyAddress(lat, lng, fallback1, 'Hyderabad, Telangana', persist);
    } catch (_) {
      _applyAddress(lat, lng, fallback1, 'Hyderabad, Telangana', persist);
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
    // Restore a previously chosen location (accurate on web); otherwise resolve
    // device/network location, prompting via the popup on first entry.
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapLocation());
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _moveMap() {
    try {
      _mapController.move(LatLng(_lat, _lng), 14.5);
    } catch (_) {}
  }

  /// First entry: prefer the user's saved/chosen location (the accurate source
  /// of truth on web, where there is no GPS). Only fall back to device/network
  /// location when nothing has been saved yet.
  Future<void> _bootstrapLocation() async {
    final saved = await LocationStore.load();
    if (saved != null && mounted) {
      setState(() {
        _pos = _posFrom(saved.lat, saved.lng);
        _locationDenied = false;
        _addressLine1 = saved.label1.isNotEmpty ? saved.label1 : 'Saved location';
        _addressLine2 = saved.label2;
      });
      _moveMap();
      await _load();
      return;
    }
    await _useMyLocation();
  }

  /// Deliberate "use my current location": forget any saved pin and re-read the
  /// device/network position, showing the permission popup if needed.
  Future<void> _useMyLocation() async {
    await LocationStore.clear();
    LocationService.clearSessionFix();
    await _resolveLocation(prompt: true);
    await _load();
  }

  /// Opens a location picker so the user can set an exact place by address
  /// (essential on web/desktop, where there is no GPS and the browser only
  /// returns a coarse Wi-Fi/IP estimate). Also offers a "use my GPS" shortcut.
  Future<void> _openLocationPicker() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _LocationSearchSheet(),
    );
    if (result == null || !mounted) return;

    if (result['useGps'] == true) {
      LocationService.clearSessionFix(); // deliberate re-read
      await _useMyLocation();
      return;
    }

    final lat = result['lat'] as double;
    final lng = result['lng'] as double;
    setState(() {
      _pos = _posFrom(lat, lng);
      _locationDenied = false;
      _addressLine1 = 'Locating...';
      _addressLine2 = '';
    });
    _moveMap();
    // Searched + picked → persist so it survives reloads.
    _fetchAddress(lat, lng, persist: true);
    _loadHelpersOnly(lat, lng);
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
            onTap: _openLocationPicker,
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

          // Nearby helpers carousel
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 12),
            child: _nearby.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      context.tr('no_helpers_nearby'),
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.tertiary),
                    ),
                  )
                : HelperCarousel(
                    helpers: _nearby,
                    onCall: (h) {
                      if (h.phone != null && h.phone!.isNotEmpty) {
                        HelperActions.call(h.phone!);
                      }
                    },
                    onRequest: (h) {
                      String? catId;
                      for (final c in _categories) {
                        if (c.helperTypes.contains(h.helperType)) {
                          catId = c.id;
                          break;
                        }
                      }
                      catId ??= _categories.isNotEmpty ? _categories.first.id : null;
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => HelperDetailScreen(helperId: h.id, categoryId: catId),
                      ));
                    },
                    onViewAll: _categories.isEmpty
                        ? null
                        : () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => HelperResultsScreen(
                                  category: _categories.first, lat: _lat, lng: _lng),
                            )),
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

  // ── Helpers-nearby pill (tap to expand a one-line list) ──
  Widget _helpersNearbyOverlay() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _helpersNearbyPill(),
        if (_showNearbyList) ...[
          const SizedBox(height: 8),
          _nearbyListPanel(),
        ],
      ],
    );
  }

  Widget _helpersNearbyPill() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _showNearbyList = !_showNearbyList),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : const Color(0x1A14281E),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark ? theme.colorScheme.outline : const Color(0xFFE7ECEA),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _PulsingGreenDot(),
            const SizedBox(width: 6),
            Text(
              '${_nearby.length} ${context.tr('helpers_nearby_suffix')}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              _showNearbyList ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              size: 15,
              color: theme.colorScheme.tertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _nearbyListPanel() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: 264,
      constraints: const BoxConstraints(maxHeight: 248),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : const Color(0x1F14281E),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark ? theme.colorScheme.outline : const Color(0xFFE7ECEA),
          width: 1,
        ),
      ),
      child: _nearby.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                context.tr('no_helpers_nearby'),
                style: TextStyle(fontSize: 12.5, color: theme.colorScheme.tertiary),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: Text(
                    '${_nearby.length} ${context.tr('helpers_nearby_suffix')}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _nearby.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 1,
                      color: (isDark ? theme.colorScheme.outline : const Color(0xFFEFF1F5)),
                    ),
                    itemBuilder: (_, i) => _nearbyRow(_nearby[i]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _nearbyRow(MarketplaceHelper h) {
    final theme = Theme.of(context);
    final dist = h.distanceKm != null ? '${h.distanceKm!.toStringAsFixed(1)} km' : '';
    return InkWell(
      onTap: () {
        setState(() => _showNearbyList = false);
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => HelperDetailScreen(helperId: h.id, categoryId: null),
        ));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Text(_typeEmoji(h.helperType), style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${h.name} · ${h.typeLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (dist.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                dist,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _typeEmoji(String t) {
    if (t.contains('puncture')) return '🛞';
    if (t.contains('petrol') || t.contains('fuel')) return '⛽';
    if (t.contains('tow')) return '🚒';
    if (t.contains('battery')) return '🔋';
    return '🔧';
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
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: const Border(right: BorderSide(color: Color(0xFFE7ECEA), width: 1.5)),
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
                      onPositionChanged: (camera, hasGesture) {
                        if (hasGesture && camera.center != null) {
                          _onMapMove(camera.center!);
                        }
                      },
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
                // Fixed crosshair pin: whatever sits under it is the chosen
                // location. Lets the user drag the map to fine-tune the pickup.
                const _MapCenterPin(),
                Positioned(
                  top: 24,
                  left: 24,
                  child: _helpersNearbyOverlay(),
                ),
                Positioned(
                  right: 24,
                  top: 24,
                  child: Builder(
                    builder: (context) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      final boxDecoration = BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black26 : const Color(0x1414281E),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: isDark ? Theme.of(context).colorScheme.outline : const Color(0xFFE7ECEA),
                          width: 1.5,
                        ),
                      );
                      return Column(
                        children: [
                          GestureDetector(
                            onTap: _useMyLocation,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: boxDecoration,
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
                              decoration: boxDecoration,
                              alignment: Alignment.center,
                              child: const Text('📡', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ],
                      );
                    }
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // Full-bleed interactive map with a draggable content sheet on top (the
      // standard maps UX). The map fills the screen so pinch-zoom & pan work in
      // the visible area; the sheet scrolls/drag-expands independently instead of
      // stealing the map's multi-touch gestures.
      final double screenH = MediaQuery.of(context).size.height;
      return Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(_lat, _lng),
                initialZoom: 14.5,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                onPositionChanged: (camera, hasGesture) {
                  if (hasGesture && camera.center != null) {
                    _onMapMove(camera.center!);
                  }
                },
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
          // Helpers-nearby pill (top-left) — tap to expand a one-line list
          Positioned(
            top: 48,
            left: 16,
            child: _helpersNearbyOverlay(),
          ),
          // Locate / refresh buttons (top-right)
          Positioned(
            right: 16,
            top: 48,
            child: Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final boxDecoration = BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black26 : const Color(0x1414281E),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(
                    color: isDark ? Theme.of(context).colorScheme.outline : const Color(0xFFE7ECEA),
                    width: 1.5,
                  ),
                );
                return Column(
                  children: [
                    GestureDetector(
                      onTap: _useMyLocation,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: boxDecoration,
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
                        decoration: boxDecoration,
                        alignment: Alignment.center,
                        child: const Text('📡', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                );
              }
            ),
          ),
          // Pickup-point label, anchored in the visible map area above the sheet.
          Positioned(
            top: screenH * 0.22,
            left: 0,
            right: 0,
            child: IgnorePointer(
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
          ),
          // Draggable content sheet over the map.
          DraggableScrollableSheet(
            initialChildSize: 0.46,
            minChildSize: 0.30,
            maxChildSize: 0.92,
            snap: true,
            snapSizes: const [0.46, 0.92],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Grab handle
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 2),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outline,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildContentList(
                        controller: scrollController,
                        isDesktop: false,
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
}

class _SafetyAdviceCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;
  const _SafetyAdviceCard({required this.emoji, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? theme.colorScheme.outline : const Color(0xFFE7ECEA),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black12 : const Color(0x0614281E),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
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
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.tertiary,
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

/// Address search for setting an exact location on web/desktop (no GPS). Geocodes
/// the typed query via OpenStreetMap (Nominatim) and returns the chosen point as
/// `{lat, lng, label}`, or `{useGps: true}` to fall back to device location.
class _LocationSearchSheet extends StatefulWidget {
  const _LocationSearchSheet();

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<dynamic> _results = [];
  bool _loading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    final query = q.trim();
    if (query.length < 3) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(query));
  }

  Future<void> _search(String q) async {
    final lang = '${context.read<LocaleController>().code},en';
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?format=json&limit=6&addressdetails=1&q=${Uri.encodeQueryComponent(q)}',
      );
      final res = await http.get(url,
          headers: {'User-Agent': 'roadside_help_app/1.0', 'Accept-Language': lang});
      if (!mounted) return;
      setState(() {
        _results = res.statusCode == 200 ? (json.decode(res.body) as List) : [];
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _results = [];
          _loading = false;
        });
      }
    }
  }

  void _pick(dynamic r) {
    Navigator.of(context).pop({
      'lat': double.parse(r['lat'].toString()),
      'lng': double.parse(r['lon'].toString()),
      'label': r['display_name']?.toString() ?? '',
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Set your location',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search area, street or landmark',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop({'useGps': true}),
            icon: const Icon(Icons.my_location, size: 18),
            label: const Text('Use my current location'),
          ),
          if (_results.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _results.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: theme.colorScheme.outline),
                itemBuilder: (_, i) {
                  final r = _results[i];
                  final name = r['display_name']?.toString() ?? '';
                  final first = name.split(',').first;
                  final rest = name.split(',').skip(1).join(',').trim();
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_outlined, size: 20),
                    title: Text(first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    subtitle: rest.isEmpty
                        ? null
                        : Text(rest, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => _pick(r),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// A fixed crosshair pin centered over the map. Its tip marks the exact point
/// that becomes the user's location when the map is dragged. Non-interactive so
/// it never swallows the map's pan gestures.
class _MapCenterPin extends StatelessWidget {
  const _MapCenterPin();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Offset up by half the icon so the pin's tip rests on dead-center.
            Transform.translate(
              offset: const Offset(0, -14),
              child: Icon(
                Icons.location_pin,
                size: 40,
                color: const Color(0xFF2563EB),
                shadows: [
                  Shadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Home header: the Seeker/Helper role switch plus a light/dark slide toggle.
/// Persists both choices (RoleState / ThemeState) and flips the whole home.
class _HomeModeBar extends StatelessWidget {
  const _HomeModeBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final roleState = context.watch<RoleState>();
    final themeState = context.watch<ThemeState>();
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? theme.colorScheme.outline : const Color(0xFFECEEF4),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: _RoleSegment(
                  role: roleState.role,
                  onChanged: roleState.setRole,
                ),
              ),
              const SizedBox(width: 12),
              _ThemeSlideToggle(
                isDark: isDark,
                onChanged: (dark) => themeState.setThemeMode(
                    dark ? ThemeMode.dark : ThemeMode.light),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-segment Seeker | Helper switch with an animated sliding highlight.
class _RoleSegment extends StatelessWidget {
  final AppRole role;
  final ValueChanged<AppRole> onChanged;
  const _RoleSegment({required this.role, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final seeker = role == AppRole.seeker;
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFEFF1F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: seeker ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              _seg(context, '🆘  Seeker', seeker, () => onChanged(AppRole.seeker)),
              _seg(context, '🛠  Helper', !seeker, () => onChanged(AppRole.helper)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _seg(BuildContext context, String label, bool active, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: active ? theme.colorScheme.onPrimary : theme.colorScheme.tertiary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Light/dark slide toggle (sun ↔ moon) driving ThemeState.
class _ThemeSlideToggle extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onChanged;
  const _ThemeSlideToggle({required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!isDark),
      child: Container(
        width: 66,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2530) : const Color(0xFFEFF1F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            const Positioned(
              left: 9, top: 0, bottom: 0,
              child: Center(child: Text('☀️', style: TextStyle(fontSize: 13))),
            ),
            const Positioned(
              right: 9, top: 0, bottom: 0,
              child: Center(child: Text('🌙', style: TextStyle(fontSize: 12))),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3B82F6) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
