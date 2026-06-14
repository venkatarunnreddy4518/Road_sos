import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../data/api/discovery_api.dart';
import '../../data/api/request_api.dart';
import '../../data/models/category.dart';
import '../../data/models/service_request.dart';
import '../state/auth_state.dart';
import 'provider/provider_register_screen.dart';
import 'request_tracking_screen.dart';

/// "My SOS Requests" — seeker/helper request history.
/// Visual port of the React SosRequests screen, backed by real /requests/mine data.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _api = RequestApi();
  final _discovery = DiscoveryApi();

  List<ServiceRequest> _items = [];
  Map<String, ServiceCategory> _catById = {};
  bool _loading = true;
  String _role = 'seeker';

  // ── palette ──
  static const _bg = Color(0xFFF7F8FA);
  static const _ink = Color(0xFF14181F);
  static const _muted = Color(0xFF9CA3AF);
  static const _line = Color(0xFFEEF0F3);
  static const _blue = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _load();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _discovery.categories();
      if (mounted) setState(() => _catById = {for (final c in cats) c.id: c});
    } catch (_) {/* labels fall back to a generic title */}
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
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _ink,
        title: Text(context.tr('my_sos'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, fontFamily: 'Outfit')),
      ),
      body: !auth.isAuthenticated
          ? _empty(Icons.lock_outline_rounded, context.tr('login'),
              'Sign in to view your roadside request history.')
          : Column(
              children: [
                // ── Tabs ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                  child: Row(
                    children: [
                      _tab('seeker', context.tr('as_seeker')),
                      const SizedBox(width: 8),
                      _tab('helper', context.tr('as_helper')),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(onRefresh: _load, child: _body()),
                ),
              ],
            ),
    );
  }

  Widget _tab(String value, String label) {
    final active = _role == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_role == value) return;
          setState(() => _role = value);
          _load();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? _blue : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: active ? null : Border.all(color: const Color(0xFFE6E8EC)),
          ),
          child: Text(label,
              style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: active ? Colors.white : const Color(0xFF6B7280))),
        ),
      ),
    );
  }

  Widget _body() {
    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          _role == 'helper'
              ? _helperEmpty()
              : _empty(Icons.inbox_rounded, 'No SOS requests yet',
                  'Your roadside requests will appear here once you book a helper.'),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(18),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _requestCard(_items[i]),
    );
  }

  Widget _requestCard(ServiceRequest r) {
    final cat = _catById[r.categoryId];
    final tile = _tileColor(cat);
    final st = _statusStyle(r.status);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RequestTrackingScreen(requestId: r.id))),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _line)),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: tile.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
              child: Icon(cat?.materialIcon ?? Icons.build_rounded, size: 20, color: tile),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat?.name ?? 'Roadside help',
                      style: const TextStyle(
                          fontFamily: 'Outfit', fontWeight: FontWeight.w700, fontSize: 14, color: _ink)),
                  const SizedBox(height: 3),
                  Text(_formatDate(r.requestedAt),
                      style: const TextStyle(fontSize: 11.5, color: _muted)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: st.bg, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(st.icon, size: 11, color: st.color),
                        const SizedBox(width: 4),
                        Text(st.label,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: st.color)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (r.fareAmount != null) ...[
                  Text(_formatMoney(r.fareAmount!),
                      style: const TextStyle(
                          fontFamily: 'Outfit', fontWeight: FontWeight.w700, fontSize: 14, color: _ink)),
                  const SizedBox(height: 4),
                ],
                const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFC0C4CC)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _helperEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.build_rounded, size: 24, color: Color(0xFFC0C4CC)),
          ),
          const SizedBox(height: 10),
          const Text('No helper activity yet',
              style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700, fontSize: 14, color: _ink)),
          const SizedBox(height: 6),
          const Text(
            'Turn on Provider Mode to start receiving and responding to nearby roadside requests.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: _muted, height: 1.5),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProviderRegisterScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(12)),
              child: const Text('Turn on Provider Mode',
                  style: TextStyle(
                      fontFamily: 'Outfit', fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(IconData icon, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, size: 24, color: const Color(0xFFC0C4CC)),
          ),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Outfit', fontWeight: FontWeight.w700, fontSize: 14, color: _ink)),
          const SizedBox(height: 6),
          Text(sub,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: _muted, height: 1.5)),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('dd MMM yyyy, h:mm a').format(dt.toLocal());
  }

  String _formatMoney(double amount) =>
      '₹${NumberFormat('#,##0.00', 'en_IN').format(amount)}';

  Color _tileColor(ServiceCategory? cat) {
    final key = (cat?.key ?? cat?.icon ?? '').toLowerCase();
    if (key.contains('mechanic') || key.contains('build')) return const Color(0xFF7C5CFC);
    if (key.contains('puncture') || key.contains('tyre') || key.contains('tire')) return _blue;
    if (key.contains('fuel') || key.contains('petrol') || key.contains('gas')) return const Color(0xFFF5A623);
    if (key.contains('tow')) return const Color(0xFFE5484D);
    if (key.contains('battery') || key.contains('jump')) return const Color(0xFF1A9E5C);
    return _blue;
  }

  _StatusStyle _statusStyle(RequestStatus s) {
    switch (s) {
      case RequestStatus.completed:
        return const _StatusStyle(
            Color(0xFFEAFBF1), Color(0xFF1A9E5C), 'Completed', Icons.check_circle_rounded);
      case RequestStatus.cancelled:
        return const _StatusStyle(
            Color(0xFFF3F4F6), Color(0xFF9CA3AF), 'Cancelled', Icons.cancel_rounded);
      default:
        return const _StatusStyle(
            Color(0xFFEAF1FE), Color(0xFF2563EB), 'In progress', Icons.schedule_rounded);
    }
  }
}

class _StatusStyle {
  final Color bg;
  final Color color;
  final String label;
  final IconData icon;
  const _StatusStyle(this.bg, this.color, this.label, this.icon);
}
