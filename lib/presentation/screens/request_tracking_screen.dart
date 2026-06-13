import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../data/api/discovery_api.dart';
import '../../data/api/request_api.dart';
import '../../data/models/marketplace_helper.dart';
import '../../data/models/service_request.dart';
import '../widgets/app_map.dart';
import '../widgets/rating_stars.dart';
import '../widgets/status_timeline.dart';

/// Seeker view: polls the active request for status + live helper position
/// (FR-016/017) and presents the SOS status timeline.
class RequestTrackingScreen extends StatefulWidget {
  final String requestId;
  const RequestTrackingScreen({super.key, required this.requestId});

  @override
  State<RequestTrackingScreen> createState() => _RequestTrackingScreenState();
}

class _RequestTrackingScreenState extends State<RequestTrackingScreen> {
  final _api = RequestApi();
  final _discovery = DiscoveryApi();
  Timer? _poll;
  ServiceRequest? _req;
  bool _reviewed = false;
  String? _categoryName;
  MarketplaceHelper? _helper;
  bool _loadingHelper = false;

  // Design tokens (consistent with the app's blue + a status green).
  static const _bg = Color(0xFFF7F8FA);
  static const _blue = Color(0xFF2563EB);
  static const _green = Color(0xFF1A9E5C);
  static const _ink = Color(0xFF14181F);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE6E8EC);

  @override
  void initState() {
    super.initState();
    _refresh();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final r = await _api.get(widget.requestId);
      if (!mounted) return;
      setState(() => _req = r);
      _loadAux(r);
      if (r.status.isTerminal) _poll?.cancel();
    } catch (_) {/* keep last known (offline tolerant) */}
  }

  /// Lazily resolve the category name (header) and the assigned helper (contact
  /// bar + timeline detail) once they're known.
  Future<void> _loadAux(ServiceRequest r) async {
    if (_categoryName == null) {
      try {
        final cats = await _discovery.categories();
        final match = cats.where((c) => c.id == r.categoryId);
        if (match.isNotEmpty && mounted) setState(() => _categoryName = match.first.name);
      } catch (_) {}
    }
    if (r.helperId != null && _helper == null && !_loadingHelper) {
      _loadingHelper = true;
      try {
        final h = await _discovery.getById(r.helperId!);
        if (mounted) setState(() => _helper = h);
      } catch (_) {
      } finally {
        _loadingHelper = false;
      }
    }
  }

  Future<void> _cancel() async {
    try {
      await _api.cancel(widget.requestId);
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _call() async {
    final phone = _helper?.phone;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _review() async {
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReviewSheet(),
    );
    if (result == null) return;
    try {
      await _api.review(requestId: widget.requestId, rating: result);
      setState(() => _reviewed = true);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Thanks for your rating!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _req;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _ink,
        title: Text(context.tr('request_help')),
      ),
      body: r == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(
                  height: 200,
                  child: AppMap(
                    centerLat: r.helperLocation?.latitude ?? r.pickupLat,
                    centerLng: r.helperLocation?.longitude ?? r.pickupLng,
                    markers: [
                      MapMarker(r.pickupLat, r.pickupLng,
                          icon: Icons.my_location,
                          color: Theme.of(context).colorScheme.primary),
                      if (r.helperLocation != null)
                        MapMarker(r.helperLocation!.latitude, r.helperLocation!.longitude,
                            icon: Icons.local_shipping,
                            color: Theme.of(context).brightness == Brightness.light
                                ? const Color(0xFF555555)
                                : const Color(0xFFCCCCCC)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _header(r),
                      const SizedBox(height: 18),
                      if (!r.status.isTerminal) ...[
                        _statusBanner(r),
                        const SizedBox(height: 18),
                      ],
                      if (r.status == RequestStatus.completed) ...[
                        _completionBanner(),
                        const SizedBox(height: 18),
                      ],
                      StatusTimeline(
                        current: r.status,
                        helperName: _helper?.name,
                        categoryName: _categoryName,
                      ),
                      if (r.helperLocation != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Helper location updated '
                            '${TimeOfDay.fromDateTime(r.helperLocation!.recordedAt.toLocal()).format(context)}',
                            style: const TextStyle(fontSize: 12, color: _muted),
                          ),
                        ),
                      if (_showContact(r)) ...[
                        const SizedBox(height: 16),
                        _contactBar(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: r == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: r.status == RequestStatus.completed
                    ? (_reviewed
                        ? const SizedBox.shrink()
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary),
                            onPressed: _review,
                            icon: const Icon(Icons.star),
                            label: Text(context.tr('rate_helper')),
                          ))
                    : r.status.isTerminal
                        ? const SizedBox.shrink()
                        : OutlinedButton.icon(
                            onPressed: _cancel,
                            icon: Icon(Icons.close, color: Theme.of(context).colorScheme.error),
                            label: Text(context.tr('cancel'),
                                style: TextStyle(color: Theme.of(context).colorScheme.error)),
                          ),
              ),
            ),
    );
  }

  bool _showContact(ServiceRequest r) =>
      _helper != null &&
      r.status != RequestStatus.requested &&
      !r.status.isTerminal;

  // ── Header ──
  Widget _header(ServiceRequest r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ACTIVE REQUEST',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: Color(0xFFE5484D))),
        const SizedBox(height: 2),
        Text(_categoryName ?? 'Roadside help',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 21, color: _ink)),
        const SizedBox(height: 4),
        Text(
          'Pickup · ${r.pickupLat.toStringAsFixed(4)}, ${r.pickupLng.toStringAsFixed(4)}',
          style: const TextStyle(fontSize: 13, color: _muted),
        ),
      ],
    );
  }

  // ── Current-status banner ──
  IconData _statusIcon(RequestStatus s) {
    switch (s) {
      case RequestStatus.requested:
        return Icons.campaign_rounded;
      case RequestStatus.accepted:
        return Icons.how_to_reg_rounded;
      case RequestStatus.onTheWay:
        return Icons.navigation_rounded;
      case RequestStatus.arrived:
        return Icons.place_rounded;
      default:
        return Icons.bolt_rounded;
    }
  }

  Widget _statusBanner(ServiceRequest r) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(color: const Color(0xFFEAF1FE), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current status',
                    style: TextStyle(fontSize: 12, color: _blue, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(r.status.label,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: _ink)),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(12)),
            child: Icon(_statusIcon(r.status), size: 20, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ── Completion banner ──
  Widget _completionBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFEAFBF1), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.celebration_rounded, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('All sorted',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _ink)),
                Text('Rate ${_helper?.name ?? 'your helper'} to help others find good help.',
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF3B7A57))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Contact bar ──
  Widget _contactBar() {
    final h = _helper!;
    final initial = h.name.trim().isNotEmpty ? h.name.trim()[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: _line, shape: BoxShape.circle),
            child: Text(initial,
                style: const TextStyle(fontWeight: FontWeight.w700, color: _muted)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: _ink),
                    overflow: TextOverflow.ellipsis),
                Text('★ ${h.ratingAvg.toStringAsFixed(1)} · ${h.typeLabel}',
                    style: const TextStyle(fontSize: 12, color: _muted)),
              ],
            ),
          ),
          if (h.phone != null && h.phone!.isNotEmpty)
            GestureDetector(
              onTap: _call,
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                child: const Icon(Icons.phone, size: 16, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewSheet extends StatefulWidget {
  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _rating = 5;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.tr('rate_helper'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          RatingInput(value: _rating, onChanged: (v) => setState(() => _rating = v)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary),
              onPressed: () => Navigator.of(context).pop(_rating),
              child: Text(context.tr('submit')),
            ),
          ),
        ],
      ),
    );
  }
}
