import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../data/api/discovery_api.dart';
import '../../data/models/marketplace_helper.dart';
import '../widgets/marketplace_helper_card.dart';
import 'helper_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final double lat;
  final double lng;
  const SearchScreen({super.key, required this.lat, required this.lng});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _api = DiscoveryApi();
  final _controller = TextEditingController();
  List<MarketplaceHelper> _results = [];
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await _api.search(q: q.trim(), lat: widget.lat, lng: widget.lng);
      setState(() => _results = res);
    } catch (_) {
      setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: _search,
          onChanged: (v) {
            if (v.length >= 3) _search(v);
          },
          decoration: InputDecoration(
            hintText: context.tr('search_hint'),
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => _search(_controller.text)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: _results
                  .map((h) => MarketplaceHelperCard(
                        helper: h,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => HelperDetailScreen(helperId: h.id, categoryId: null),
                        )),
                      ))
                  .toList(),
            ),
    );
  }
}
