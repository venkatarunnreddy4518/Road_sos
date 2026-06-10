import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../data/api/request_api.dart';
import '../../data/models/service_request.dart';
import '../state/auth_state.dart';
import 'request_tracking_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _api = RequestApi();
  List<ServiceRequest> _items = [];
  bool _loading = true;
  String _role = 'seeker';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _api.mine(role: _role);
    } catch (_) {
      _items = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('history'))),
        body: Center(child: Text(context.tr('login'))),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('history')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'seeker', label: Text('As seeker')),
                ButtonSegment(value: 'helper', label: Text('As helper')),
              ],
              selected: {_role},
              onSelectionChanged: (s) {
                setState(() => _role = s.first);
                _load();
              },
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No requests yet'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    children: _items.map((r) {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(r.status.label),
                          subtitle: Text(r.note ?? 'Request ${r.id.substring(0, 8)}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => RequestTrackingScreen(requestId: r.id),
                          )),
                        ),
                      );
                    }).toList(),
                  ),
                ),
    );
  }
}
