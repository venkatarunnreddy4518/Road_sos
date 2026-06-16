import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/location_service.dart';
import '../../../data/api/discovery_api.dart';
import '../../../data/api/profile_api.dart';
import '../../../data/api/request_api.dart';
import '../../../data/models/category.dart';
import '../../state/auth_state.dart';
import '../../utils/helper_actions.dart';
import '../../utils/incoming_request_alert.dart';
import 'provider_job_screen.dart';

/// Provider mode: register as a helper (if needed), then see + accept open requests.
class ProviderInboxScreen extends StatefulWidget {
  const ProviderInboxScreen({super.key});

  @override
  State<ProviderInboxScreen> createState() => _ProviderInboxScreenState();
}

class _ProviderInboxScreenState extends State<ProviderInboxScreen> {
  final _requests = RequestApi();
  Timer? _poll;
  List<Map<String, dynamic>> _open = [];
  List<ServiceCategory> _categories = [];
  bool _loading = true;
  double _lat = 17.4239;
  double _lng = 78.4738;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final pos = await LocationService.current();
    if (pos != null) {
      _lat = pos.latitude;
      _lng = pos.longitude;
    }
    try {
      _categories = await DiscoveryApi().categories();
    } catch (_) {}
    if (!mounted) return;
    if (context.read<AuthState>().user?.isHelper ?? false) {
      _startPolling();
    } else {
      setState(() => _loading = false);
    }
  }

  void _startPolling() {
    _refresh();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final res = await _requests.open(lat: _lat, lng: _lng);
      if (mounted) {
        final oldIds = _open.map((r) => r['id'] as String).toSet();
        final newRequests = res.where((r) => !oldIds.contains(r['id'] as String)).toList();
        final wasLoading = _loading;

        setState(() {
          _open = res;
          _loading = false;
        });

        if (!wasLoading && newRequests.isNotEmpty) {
          for (final req in newRequests) {
            _showIncomingRequestAlert(req);
          }
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showIncomingRequestAlert(Map<String, dynamic> req) {
    final id = req['id'] as String;
    showIncomingRequestAlert(
      context: context,
      req: req,
      categories: _categories,
      onAccept: () => _accept(id),
      onReject: () => _decline(id),
    );
  }

  Future<void> _accept(String id) async {
    try {
      await _requests.accept(id);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProviderJobScreen(requestId: id)));
      _refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  /// Reject: decline so the request reopens to the next nearest helper, and drop
  /// it from this inbox immediately.
  Future<void> _decline(String id) async {
    setState(() => _open.removeWhere((r) => r['id'] == id));
    try {
      await _requests.decline(id);
    } catch (_) {
      // Non-fatal: the next poll will reconcile the list.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHelper = context.watch<AuthState>().user?.isHelper ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('provider_mode'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !isHelper
              ? _RegisterHelper(lat: _lat, lng: _lng, onRegistered: () {
                  setState(() => _loading = true);
                  _startPolling();
                })
              : _open.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(children: [
                        const SizedBox(height: 120),
                        Center(child: Text(context.tr('no_incoming_requests'))),
                      ]),
                    )
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: _open.map((r) {
                          final dist = (r['distance_km'] as num?)?.toDouble();
                          final seeker = (r['seeker_name'] as String?)?.trim();
                          final note = (r['note'] as String?)?.trim();
                          final lat = (r['pickup_lat'] as num?)?.toDouble();
                          final lng = (r['pickup_lng'] as num?)?.toDouble();

                          final catId = r['category_id'] as String?;
                          final cat = _categories.firstWhere(
                            (c) => c.id == catId,
                            orElse: () => ServiceCategory(
                              id: '',
                              key: '',
                              name: 'Emergency Request',
                              icon: 'build',
                              sortOrder: 0,
                              helperTypes: [],
                            ),
                          );

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                        child: Text(
                                          cat.icon == 'tire_repair'
                                              ? '🛞'
                                              : cat.icon == 'local_gas_station'
                                                  ? '⛽'
                                                  : cat.icon == 'battery_charging_full'
                                                      ? '🔋'
                                                      : cat.icon == 'fire_truck'
                                                          ? '🚒'
                                                          : '🔧',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    seeker?.isNotEmpty == true ? seeker! : context.tr('someone_nearby'),
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.w800, fontSize: 15),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    cat.name,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w800,
                                                      color: Theme.of(context).colorScheme.primary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (dist != null)
                                              Text(
                                                '${dist.toStringAsFixed(1)} ${context.tr('km_away_suffix')}',
                                                style: const TextStyle(
                                                    color: Color(0xFF7C887F),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (note?.isNotEmpty == true) ...[
                                    const SizedBox(height: 10),
                                    Text(note!, style: const TextStyle(fontSize: 13.5)),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      if (lat != null && lng != null)
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => HelperActions.directions(
                                                lat, lng,
                                                label: seeker ?? context.tr('someone_nearby')),
                                            icon: const Icon(Icons.directions, size: 18),
                                            label: Text(context.tr('navigate')),
                                          ),
                                        ),
                                      if (lat != null && lng != null) const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _decline(r['id']),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Theme.of(context).colorScheme.error,
                                            side: BorderSide(
                                                color: Theme.of(context).colorScheme.error),
                                          ),
                                          child: Text(context.tr('reject')),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: () => _accept(r['id']),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Theme.of(context).colorScheme.primary,
                                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                          ),
                                          child: Text(context.tr('accept')),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
    );
  }
}

class _RegisterHelper extends StatefulWidget {
  final double lat;
  final double lng;
  final VoidCallback onRegistered;
  const _RegisterHelper({required this.lat, required this.lng, required this.onRegistered});

  @override
  State<_RegisterHelper> createState() => _RegisterHelperState();
}

class _RegisterHelperState extends State<_RegisterHelper> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String _type = 'mechanic';
  bool _busy = false;

  static const _types = {
    'mechanic': 'Mechanic',
    'puncture_shop': 'Puncture Shop',
    'petrol_pump': 'Petrol Pump',
    'towing': 'Towing',
    'battery': 'Battery',
  };

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final helper = await ProfileApi().upsertHelper(
        name: _name.text.trim(),
        helperType: _type,
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        latitude: widget.lat,
        longitude: widget.lng,
      );
      if (!mounted) return;
      // Refresh user (now is_helper=true).
      final auth = context.read<AuthState>();
      if (auth.user != null && helper.id.isNotEmpty) {
        // Lightweight: re-fetch profile to update is_helper flag.
        final me = await ProfileApi().get();
        auth.setUser(me);
      }
      widget.onRegistered();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 4),
        Text(context.tr('register_desc'),
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
        const SizedBox(height: 20),
        TextField(
          controller: _name,
          decoration: InputDecoration(labelText: context.tr('service_name'), border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _type,
          decoration: InputDecoration(labelText: context.tr('service_type'), border: const OutlineInputBorder()),
          items: _types.entries
              .map((e) {
                final label = switch (e.key) {
                  'mechanic' => context.tr('type_mechanic'),
                  'puncture_shop' => context.tr('type_tyre_repair'),
                  'petrol_pump' => context.tr('type_fuel_delivery'),
                  'towing' => context.tr('cat_towing'),
                  'battery' => context.tr('cat_battery'),
                  _ => e.value,
                };
                return DropdownMenuItem(value: e.key, child: Text(label));
              })
              .toList(),
          onChanged: (v) => setState(() => _type = v ?? 'mechanic'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(labelText: context.tr('contact_phone'), border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary),
          onPressed: _busy ? null : _register,
          child: _busy
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary))
              : Text(context.tr('register_go_online')),
        ),
      ],
    );
  }
}
