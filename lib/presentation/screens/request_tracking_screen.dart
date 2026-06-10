import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../data/api/request_api.dart';
import '../../data/models/service_request.dart';
import '../widgets/app_map.dart';
import '../widgets/rating_stars.dart';
import '../widgets/status_timeline.dart';

/// Seeker view: polls the active request for status + live helper position (FR-016/017).
class RequestTrackingScreen extends StatefulWidget {
  final String requestId;
  const RequestTrackingScreen({super.key, required this.requestId});

  @override
  State<RequestTrackingScreen> createState() => _RequestTrackingScreenState();
}

class _RequestTrackingScreenState extends State<RequestTrackingScreen> {
  final _api = RequestApi();
  Timer? _poll;
  ServiceRequest? _req;
  bool _reviewed = false;

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
      if (r.status.isTerminal) _poll?.cancel();
    } catch (_) {/* keep last known (offline tolerant) */}
  }

  Future<void> _cancel() async {
    try {
      await _api.cancel(widget.requestId);
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanks for your rating!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _req;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('request_help'))),
      body: r == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(
                  height: 220,
                  child: AppMap(
                    centerLat: r.helperLocation?.latitude ?? r.pickupLat,
                    centerLng: r.helperLocation?.longitude ?? r.pickupLng,
                    markers: [
                      MapMarker(r.pickupLat, r.pickupLng, icon: Icons.my_location, color: const Color(0xFF111111)),
                      if (r.helperLocation != null)
                        MapMarker(r.helperLocation!.latitude, r.helperLocation!.longitude,
                            icon: Icons.local_shipping, color: const Color(0xFF18A957)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      StatusTimeline(current: r.status),
                      if (r.helperLocation != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Helper location updated ${TimeOfDay.fromDateTime(r.helperLocation!.recordedAt.toLocal()).format(context)}',
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ),
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
                                backgroundColor: const Color(0xFFF4C430), foregroundColor: Colors.black),
                            onPressed: _review,
                            icon: const Icon(Icons.star),
                            label: Text(context.tr('rate_helper')),
                          ))
                    : r.status.isTerminal
                        ? const SizedBox.shrink()
                        : OutlinedButton.icon(
                            onPressed: _cancel,
                            icon: const Icon(Icons.close, color: Color(0xFFB3261E)),
                            label: Text(context.tr('cancel'), style: const TextStyle(color: Color(0xFFB3261E))),
                          ),
              ),
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
                  backgroundColor: const Color(0xFF111111), foregroundColor: Colors.white),
              onPressed: () => Navigator.of(context).pop(_rating),
              child: Text(context.tr('submit')),
            ),
          ),
        ],
      ),
    );
  }
}
