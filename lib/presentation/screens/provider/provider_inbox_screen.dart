import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/location_service.dart';
import '../../../data/api/profile_api.dart';
import '../../../data/api/request_api.dart';
import '../../state/auth_state.dart';
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
        setState(() {
          _open = res;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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
                        Center(child: Text('No ${context.tr('incoming_requests').toLowerCase()}')),
                      ]),
                    )
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        children: _open.map((r) {
                          final dist = (r['distance_km'] as num?)?.toDouble();
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.notifications_active, color: Color(0xFFF4C430)),
                              title: Text(r['note'] ?? 'Roadside request'),
                              subtitle: Text(dist != null ? '${dist.toStringAsFixed(1)} km away' : ''),
                              trailing: FilledButton(
                                onPressed: () => _accept(r['id']),
                                child: Text(context.tr('accept')),
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
        const Text('Become a helper', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Register your service to receive nearby roadside requests.',
            style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 20),
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Service name', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _type,
          decoration: const InputDecoration(labelText: 'Service type', border: OutlineInputBorder()),
          items: _types.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) => setState(() => _type = v ?? 'mechanic'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Contact phone', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF18A957), foregroundColor: Colors.white),
          onPressed: _busy ? null : _register,
          child: _busy
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Register & go online'),
        ),
      ],
    );
  }
}
