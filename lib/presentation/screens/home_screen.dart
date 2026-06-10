import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/location_service.dart';
import '../../data/api/discovery_api.dart';
import '../../data/models/category.dart';
import '../../data/models/marketplace_helper.dart';
import '../state/auth_state.dart';
import '../widgets/category_grid.dart';
import '../widgets/marketplace_helper_card.dart';
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

  @override
  Widget build(BuildContext context) {
    final pages = [const _DiscoverTab(), const HistoryScreen(), const ProfileScreen()];
    return Scaffold(
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: context.tr('app_title')),
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long), label: context.tr('history')),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: context.tr('profile')),
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
  List<ServiceCategory> _categories = [];
  List<MarketplaceHelper> _nearby = [];
  Position? _pos;
  bool _loading = true;
  bool _offline = false;

  // Fallback to the seed center so the prototype is demoable without GPS.
  double get _lat => _pos?.latitude ?? 17.4239;
  double get _lng => _pos?.longitude ?? 78.4738;

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
      setState(() {
        _categories = cats;
        _nearby = near;
        _offline = false;
      });
    } on ApiException {
      setState(() => _offline = true);
    } catch (_) {
      setState(() => _offline = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      user != null ? 'Hi, ${user.displayName} 👋' : context.tr('whats_problem'),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SearchScreen(lat: _lat, lng: _lng)),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE6E6E6)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.black54),
                      const SizedBox(width: 10),
                      Text(context.tr('search_hint'), style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              ),
            ),
            if (_offline)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F0), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.wifi_off, size: 18, color: Color(0xFFB3261E)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(context.tr('offline_banner'), style: const TextStyle(fontSize: 12))),
                ]),
              ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              CategoryGrid(
                categories: _categories,
                onTap: (c) => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => HelperResultsScreen(category: c, lat: _lat, lng: _lng),
                )),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(context.tr('nearby_helpers'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 4),
              ..._nearby.map((h) => MarketplaceHelperCard(
                    helper: h,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => HelperDetailScreen(helperId: h.id, categoryId: null),
                    )),
                  )),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
