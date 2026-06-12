import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/location_service.dart';
import '../../../data/api/request_api.dart';
import '../../../data/models/service_request.dart';
import '../../utils/helper_actions.dart';
import '../../widgets/status_timeline.dart';

/// Helper's active job: advance status and stream location while active (Story 3).
class ProviderJobScreen extends StatefulWidget {
  final String requestId;
  const ProviderJobScreen({super.key, required this.requestId});

  @override
  State<ProviderJobScreen> createState() => _ProviderJobScreenState();
}

class _ProviderJobScreenState extends State<ProviderJobScreen> {
  final _api = RequestApi();
  Timer? _locationTimer;
  ServiceRequest? _req;
  bool _busy = false;

  static const _next = {
    RequestStatus.accepted: RequestStatus.onTheWay,
    RequestStatus.onTheWay: RequestStatus.arrived,
    RequestStatus.arrived: RequestStatus.completed,
  };

  @override
  void initState() {
    super.initState();
    _load();
    // Periodically share location with the seeker while the job is active.
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pushLocation());
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await _api.get(widget.requestId);
      if (mounted) setState(() => _req = r);
    } catch (_) {}
  }

  Future<void> _pushLocation() async {
    final r = _req;
    if (r == null || r.status.isTerminal) return;
    final pos = await LocationService.current();
    final lat = pos?.latitude ?? r.pickupLat + 0.01;
    final lng = pos?.longitude ?? r.pickupLng + 0.01;
    try {
      await _api.postLocation(widget.requestId, lat, lng);
    } catch (_) {}
  }

  Future<void> _advance(RequestStatus next) async {
    setState(() => _busy = true);
    try {
      final r = await _api.updateStatus(widget.requestId, _statusToApi(next));
      if (mounted) setState(() => _req = r);
      if (next.isTerminal) _locationTimer?.cancel();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _statusToApi(RequestStatus s) {
    switch (s) {
      case RequestStatus.onTheWay:
        return 'on_the_way';
      case RequestStatus.arrived:
        return 'arrived';
      case RequestStatus.completed:
        return 'completed';
      default:
        return 'on_the_way';
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _req;
    final next = r == null ? null : _next[r.status];
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('active_job'))),
      body: r == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Who needs help + how to reach them.
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F6EE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, color: Color(0xFF0E7C52)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Text(
                                r.seekerName?.isNotEmpty == true ? r.seekerName! : context.tr('someone_nearby'),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(context.tr('needs_your_help'),
                                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF5B6B62))),
                            ],
                          ),
                        ),
                        IconButton.filled(
                          onPressed: () => HelperActions.directions(
                              r.pickupLat, r.pickupLng,
                              label: r.seekerName ?? context.tr('someone_nearby')),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF0E7C52),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.directions),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (r.note?.isNotEmpty == true)
                    Text(r.note!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  StatusTimeline(current: r.status),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => HelperActions.directions(
                        r.pickupLat, r.pickupLng,
                        label: r.seekerName ?? context.tr('someone_nearby')),
                    icon: const Icon(Icons.navigation_outlined),
                    label: Text(context.tr('directions_to_seeker')),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: r == null || next == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary),
                  onPressed: _busy ? null : () => _advance(next),
                  child: Text(switch (next) {
                    RequestStatus.onTheWay => context.tr('mark_on_the_way'),
                    RequestStatus.arrived => context.tr('mark_arrived'),
                    RequestStatus.completed => context.tr('mark_completed'),
                    _ => 'Mark as ${next.label}',
                  }),
                ),
              ),
            ),
    );
  }
}
