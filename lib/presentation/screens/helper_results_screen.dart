import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../data/api/discovery_api.dart';
import '../../data/models/category.dart';
import '../../data/models/marketplace_helper.dart';
import '../../data/repositories/helper_cache.dart';
import '../widgets/marketplace_helper_card.dart';
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

  Widget _buildBottomNav() {
    Widget buildItem(String icon, String label) {
      return Expanded(
        child: InkWell(
          onTap: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF7C887F),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE7ECEA), width: 1.5)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 18),
      child: Row(
        children: [
          buildItem('🏠', 'Home'),
          buildItem('🕐', 'History'),
          buildItem('📡', 'Nearby'),
          buildItem('🚗', 'Travel'),
          buildItem('👤', 'Profile'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finalHelpers = _filteredHelpers;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Green Gradient Header with translucent back button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF18B26B), Color(0xFF0E7C52)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.category.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Filters Row
          const SizedBox(height: 14),
          Container(
            height: 36,
            padding: const EdgeInsets.only(left: 16),
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
          const SizedBox(height: 12),

          // Results List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorView(message: _error!, onRetry: _load)
                    : finalHelpers.isEmpty
                        ? Center(
                            child: Text(
                              context.tr('no_results'),
                              style: const TextStyle(color: Color(0xFF7C887F)),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView(
                              padding: EdgeInsets.zero,
                              children: [
                                if (_offline)
                                  Container(
                                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                                            context.tr('offline_banner'),
                                            style: const TextStyle(fontSize: 12, color: Color(0xFFB3261E)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ...finalHelpers.map((h) => MarketplaceHelperCard(
                                      helper: h,
                                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                        builder: (_) => HelperDetailScreen(
                                            helperId: h.id, categoryId: widget.category.id),
                                      )),
                                    )),
                              ],
                            ),
                          ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
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
