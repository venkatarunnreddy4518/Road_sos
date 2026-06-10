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
      // Offline fallback: nearest cached helpers for this category's helper types.
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
    // The cache stores all helper types; filter to those serving this category.
    final all = await _cache.load(lat: widget.lat, lng: widget.lng);
    final types = widget.category.helperTypes.toSet();
    final filtered = all.where((h) => types.contains(h.helperType)).toList();
    return (filtered.isEmpty ? all : filtered).take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _helpers.isEmpty
                  ? Center(child: Text(context.tr('no_results')))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        children: [
                          if (_offline)
                            Container(
                              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F0),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Row(children: [
                                const Icon(Icons.wifi_off, size: 18, color: Color(0xFFB3261E)),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(context.tr('offline_banner'),
                                        style: const TextStyle(fontSize: 12))),
                              ]),
                            ),
                          ..._helpers.map((h) => MarketplaceHelperCard(
                                helper: h,
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => HelperDetailScreen(
                                      helperId: h.id, categoryId: widget.category.id),
                                )),
                              )),
                        ],
                      ),
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
            const Icon(Icons.cloud_off, size: 48, color: Colors.black38),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: Text(context.tr('retry'))),
          ],
        ),
      ),
    );
  }
}
