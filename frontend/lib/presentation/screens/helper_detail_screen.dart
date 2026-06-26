import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../data/api/discovery_api.dart';
import '../../data/api/request_api.dart';
import '../../data/models/marketplace_helper.dart';
import '../state/auth_state.dart';
import '../utils/helper_actions.dart';
import '../widgets/app_map.dart';
import '../widgets/rating_stars.dart';
import '../widgets/loaders.dart';
import 'auth/email_auth_screen.dart';
import 'request_tracking_screen.dart';

class HelperDetailScreen extends StatefulWidget {
  final String helperId;
  final String? categoryId;
  const HelperDetailScreen({super.key, required this.helperId, required this.categoryId});

  @override
  State<HelperDetailScreen> createState() => _HelperDetailScreenState();
}

class _HelperDetailScreenState extends State<HelperDetailScreen> {
  final _discovery = DiscoveryApi();
  final _requests = RequestApi();
  MarketplaceHelper? _helper;
  List<dynamic> _reviews = [];
  bool _loading = true;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final h = await _discovery.getById(widget.helperId);
      final r = await _discovery.reviews(widget.helperId);
      setState(() {
        _helper = h;
        _reviews = r['reviews'] ?? [];
      });
    } catch (_) {
      // leave _helper null -> show error state
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestHelp() async {
    final auth = context.read<AuthState>();
    if (!auth.isAuthenticated) {
      // Guest gate (FR-005): prompt sign-in, then return.
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmailAuthScreen()));
      if (!mounted || !auth.isAuthenticated) return;
    }
    if (widget.categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('pick_category_prompt'))),
      );
      return;
    }
    setState(() => _requesting = true);
    try {
      final req = await _requests.create(
        categoryId: widget.categoryId!,
        lat: _helper!.latitude,
        lng: _helper!.longitude,
        targetHelperId: _helper!.id,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => RequestTrackingScreen(requestId: req.id)),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = _helper;
    return Scaffold(
      appBar: AppBar(title: Text(h?.name ?? '...')),
      body: (_loading || _requesting)
          ? (_requesting
              ? const PulseSOS()
              : const VerifiedBadge(message: 'Loading helper', sub: 'Fetching profile…'))
          : h == null
              ? Center(child: Text(context.tr('needs_connection')))
              : Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: AppMap(
                        centerLat: h.latitude,
                        centerLng: h.longitude,
                        markers: [MapMarker(h.latitude, h.longitude, icon: Icons.location_on, color: const Color(0xFF18A957))],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(h.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(h.typeLabel, style: const TextStyle(color: Colors.black54)),
                          const SizedBox(height: 8),
                          RatingStars(rating: h.ratingAvg, count: h.ratingCount, size: 18),
                          if (h.address != null) ...[
                            const SizedBox(height: 8),
                            Row(children: [
                              const Icon(Icons.place, size: 16, color: Colors.black45),
                              const SizedBox(width: 6),
                              Expanded(child: Text(h.address!)),
                            ]),
                          ],
                          const SizedBox(height: 16),
                          Row(children: [
                            if (h.phone != null)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => HelperActions.call(h.phone!),
                                  icon: const Icon(Icons.call),
                                  label: Text(context.tr('call')),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => HelperActions.directions(h.latitude, h.longitude, label: h.name),
                                icon: const Icon(Icons.directions),
                                label: Text(context.tr('directions')),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 20),
                          if (_reviews.isNotEmpty)
                            Text(context.tr('reviews'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          ..._reviews.map((rv) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.account_circle, size: 36, color: Colors.black26),
                                title: RatingStars(rating: (rv['rating'] as num).toDouble()),
                                subtitle: rv['comment'] != null ? Text(rv['comment']) : null,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: h == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF18A957), foregroundColor: Colors.white),
                  onPressed: _requesting ? null : _requestHelp,
                  child: _requesting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(context.tr('request_help'), style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
    );
  }
}
