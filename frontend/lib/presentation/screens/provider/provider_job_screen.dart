import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/geo_distance.dart';
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

  // Autopilot simulation state
  double? _simStartLat;
  double? _simStartLng;
  double _simProgress = 0.0;
  bool _autopilot = false;

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

    double lat;
    double lng;

    if (_autopilot) {
      // Simulate movement towards pickup coordinates
      if (_simStartLat == null || _simStartLng == null) {
        final pos = await LocationService.current();
        _simStartLat = pos?.latitude ?? (r.pickupLat + 0.005);
        _simStartLng = pos?.longitude ?? (r.pickupLng + 0.005);
        _simProgress = 0.0;
      }

      if (_simProgress < 1.0) {
        _simProgress = double.parse((_simProgress + 0.25).toStringAsFixed(2));
        if (_simProgress > 1.0) _simProgress = 1.0;
      }

      lat = _simStartLat! + (r.pickupLat - _simStartLat!) * _simProgress;
      lng = _simStartLng! + (r.pickupLng - _simStartLng!) * _simProgress;
    } else {
      final pos = await LocationService.current();
      lat = pos?.latitude ?? (r.pickupLat + 0.01);
      lng = pos?.longitude ?? (r.pickupLng + 0.01);
    }

    try {
      await _api.postLocation(widget.requestId, lat, lng);
      // Reload request to pick up backend auto-transition
      await _load();
    } catch (_) {}

    // Client-side geofencing backup in case backend didn't auto-transition
    if (_req != null && _req!.status == RequestStatus.onTheWay) {
      final dist = GeoDistance.haversineKm(lat, lng, _req!.pickupLat, _req!.pickupLng);
      if (dist <= 0.1) {
        await _advance(RequestStatus.arrived);
      }
    }

    // Auto-advance logic for autopilot
    if (_autopilot && _req != null) {
      final currentStatus = _req!.status;
      if (currentStatus == RequestStatus.accepted) {
        await _advance(RequestStatus.onTheWay);
      } else if (currentStatus == RequestStatus.arrived) {
        // Wait a short duration and automatically mark as completed
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted && _autopilot && _req?.status == RequestStatus.arrived) {
            _advance(RequestStatus.completed);
          }
        });
      }
    }
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
                  const SizedBox(height: 12),
                  // Autopilot Mode Toggle card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _autopilot 
                          ? const Color(0xFFE3F2FD)
                          : Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.05)
                              : const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _autopilot ? const Color(0xFF90CAF9) : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _autopilot ? Icons.auto_mode : Icons.person_pin_circle_outlined,
                              color: _autopilot ? const Color(0xFF1976D2) : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Autopilot Mode',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  _autopilot ? 'Simulating trip to seeker...' : 'Manual workflow tracking',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _autopilot ? const Color(0xFF1565C0) : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: _autopilot,
                          activeThumbColor: const Color(0xFF1976D2),
                          onChanged: (val) {
                            setState(() {
                              _autopilot = val;
                              if (val) {
                                _simStartLat = null;
                                _simStartLng = null;
                                _simProgress = 0.0;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (r.note?.isNotEmpty == true)
                    Text(r.note!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  // Distance to seeker info
                  Builder(
                    builder: (context) {
                      double? currentLat;
                      double? currentLng;
                      if (_autopilot && _simStartLat != null && _simStartLng != null) {
                        currentLat = _simStartLat! + (r.pickupLat - _simStartLat!) * _simProgress;
                        currentLng = _simStartLng! + (r.pickupLng - _simStartLng!) * _simProgress;
                      }
                      
                      if (currentLat != null && currentLng != null) {
                        final dist = GeoDistance.haversineKm(currentLat, currentLng, r.pickupLat, r.pickupLng);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.navigation, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                'Distance to Seeker: ${dist.toStringAsFixed(2)} km (${(_simProgress * 100).round()}% progressed)',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }
                  ),
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
