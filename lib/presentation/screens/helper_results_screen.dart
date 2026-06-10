import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/network/api_client.dart';
import '../../data/api/discovery_api.dart';
import '../../data/models/category.dart';
import '../../data/models/marketplace_helper.dart';
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
  List<MarketplaceHelper> _helpers = [];
  bool _loading = true;
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
      setState(() {
        _helpers = res;
        _error = null;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = context.tr('needs_connection'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                  ? Center(child: Text(context.tr('nearby_helpers')))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        children: _helpers
                            .map((h) => MarketplaceHelperCard(
                                  helper: h,
                                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => HelperDetailScreen(
                                        helperId: h.id, categoryId: widget.category.id),
                                  )),
                                ))
                            .toList(),
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
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
