import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/audio/alert_sound.dart';
import '../widgets/loaders.dart';
import '../../core/i18n/l10n_ext.dart';
import '../../data/api/discovery_api.dart';
import '../../data/api/request_api.dart';
import '../../data/models/category.dart';
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
  ServiceCategory? _category;
  MarketplaceHelper? _helper;
  bool _loadingHelper = false;

  // Audio-alert toggle: when on, each status advance plays a sound + haptic +
  // screen-reader announcement so the seeker doesn't have to watch the screen.
  // Defaults ON for everyone; a user who turns it off has that choice remembered.
  static const _prefAudioAlerts = 'rt_audio_alerts';
  bool _audioAlerts = true;
  RequestStatus? _lastStatus;

  // Design tokens (consistent with the app's blue + a status green).
  static const _bg = Color(0xFFF7F8FA);
  static const _blue = Color(0xFF2563EB);
  static const _green = Color(0xFF1A9E5C);
  static const _ink = Color(0xFF14181F);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE6E8EC);
  static const _danger = Color(0xFFE5484D);

  /// Per-service brand colour (the header service tile). Applies to every
  /// category, with a neutral blue fallback for anything unmapped.
  static const _serviceColors = <String, Color>{
    'puncture': Color(0xFF6E56CF),
    'fuel': Color(0xFFF5A623),
    'breakdown': Color(0xFF2563EB),
    'towing': Color(0xFFE5484D),
    'battery': Color(0xFF1A9E5C),
  };

  Color get _serviceAccent => _serviceColors[_category?.key] ?? _blue;
  IconData get _serviceIcon => _category?.materialIcon ?? Icons.build_rounded;

  /// Accent for the current lifecycle step (shared with [StatusTimeline]).
  Color _stepColor(RequestStatus s) => StatusTimeline.colorFor(s);

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    warmUpAudio(); // prime web audio so the first default-on chime is audible
    _refresh();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _refresh());
  }

  Future<void> _loadPrefs() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (mounted) setState(() => _audioAlerts = p.getBool(_prefAudioAlerts) ?? true);
    } catch (_) {}
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
      final prev = _lastStatus;
      _lastStatus = r.status;
      setState(() => _req = r);
      // Skip the very first poll (prev == null) so we only alert on transitions.
      if (prev != null && prev != r.status) _onStatusChanged(r.status);
      _loadAux(r);
      if (r.status.isTerminal) _poll?.cancel();
    } catch (_) {/* keep last known (offline tolerant) */}
  }

  /// Fires when the request advances to a new lifecycle state. When the user has
  /// enabled audio alerts we play a sound + haptic and announce it for screen
  /// readers, plus a floating snackbar so the cue is visible too.
  void _onStatusChanged(RequestStatus s) {
    if (!_audioAlerts || !mounted) return;
    final msg = _statusMessage(s);
    playAlertChime();
    HapticFeedback.mediumImpact();
    SemanticsService.sendAnnouncement(View.of(context), msg, Directionality.of(context));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _stepColor(s),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Icon(_statusIcon(s), color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
                child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      ));
  }

  String _statusMessage(RequestStatus s) {
    switch (s) {
      case RequestStatus.accepted:
        return 'A helper accepted your request';
      case RequestStatus.onTheWay:
        return 'Your helper is on the way';
      case RequestStatus.arrived:
        return 'Your helper has arrived';
      case RequestStatus.completed:
        return 'Your request is complete';
      case RequestStatus.cancelled:
        return 'Your request was cancelled';
      case RequestStatus.requested:
        return 'Looking for a nearby helper';
    }
  }

  Future<void> _toggleAudioAlerts() async {
    final next = !_audioAlerts;
    setState(() => _audioAlerts = next);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_prefAudioAlerts, next);
    } catch (_) {}
    if (next) {
      // Immediate confirmation that sound/haptics actually work on this device.
      playAlertChime();
      HapticFeedback.selectionClick();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(next
            ? "Audio alerts on — you'll be alerted when your request updates"
            : 'Audio alerts off'),
      ));
  }

  /// Lazily resolve the category name (header) and the assigned helper (contact
  /// bar + timeline detail) once they're known.
  Future<void> _loadAux(ServiceRequest r) async {
    if (_category == null) {
      try {
        final cats = await _discovery.categories();
        final match = cats.where((c) => c.id == r.categoryId);
        if (match.isNotEmpty && mounted) setState(() => _category = match.first);
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

  /// Confirm before cancelling — once a helper is assigned the cancellation has
  /// real-world consequences, so we ask first (mirrors the marketplace flow).
  Future<void> _confirmCancel(ServiceRequest r) async {
    final assigned = r.helperId != null && r.status != RequestStatus.requested;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CancelSheet(assigned: assigned),
    );
    if (confirmed == true) _cancel();
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
      body: r == null || _loadingHelper
          ? (r == null
              ? const CarOnRoute(message: 'Loading your request', sub: 'Fetching live status…')
              : const WrenchGear(
                  message: 'Connecting your mechanic', sub: 'Helper assigned — preparing route…'))
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
                        const SizedBox(height: 16),
                      ],
                      if (r.status == RequestStatus.onTheWay &&
                          r.etaMinutes != null &&
                          r.etaMinutes! > 0) ...[
                        _etaCard(r),
                        const SizedBox(height: 16),
                      ],
                      if (_showContact(r)) ...[
                        _contactBar(),
                        const SizedBox(height: 16),
                      ],
                      _timelineCard(r),
                      if (r.status == RequestStatus.completed) ...[
                        const SizedBox(height: 16),
                        _completionBanner(),
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
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _danger,
                              side: const BorderSide(color: _line, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => _confirmCancel(r),
                            icon: const Icon(Icons.close, size: 18),
                            label: Text(context.tr('cancel')),
                          ),
              ),
            ),
    );
  }

  bool _showContact(ServiceRequest r) =>
      _helper != null &&
      r.status != RequestStatus.requested &&
      !r.status.isTerminal;

  // ── Header (service tile + accent eyebrow, themed per category) ──
  Widget _header(ServiceRequest r) {
    final accent = _serviceAccent;
    final eyebrow = r.status == RequestStatus.cancelled
        ? ('CANCELLED', _danger)
        : r.status == RequestStatus.completed
            ? ('COMPLETED', _green)
            : ('ACTIVE REQUEST', _stepColor(r.status));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(_serviceIcon, size: 22, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow.$1,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                      color: eyebrow.$2)),
              const SizedBox(height: 2),
              Text(_category?.name ?? 'Roadside help',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 21, color: _ink)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.place_rounded, size: 13, color: _muted),
                  const SizedBox(width: 4),
                  Text(
                    'Pickup · ${r.pickupLat.toStringAsFixed(4)}, ${r.pickupLng.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 13, color: _muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── ETA card (shown while the helper is en route) ──
  Widget _etaCard(ServiceRequest r) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
          color: const Color(0xFFEAF1FE), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Estimated arrival',
                    style: TextStyle(fontSize: 11.5, color: _blue, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '~${r.etaMinutes} min'
                  '${r.distanceKm != null ? ' · ${r.distanceKm!.toStringAsFixed(1)} km' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24, color: _ink),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.navigation_rounded, size: 20, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ── Timeline wrapped in a titled "PROGRESS" card ──
  Widget _timelineCard(ServiceRequest r) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEEF0F3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PROGRESS',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  color: Color(0xFF9CA3AF))),
          const SizedBox(height: 14),
          StatusTimeline(
            current: r.status,
            helperName: _helper?.name ?? r.helperName,
            categoryName: _category?.name,
            etaMinutes: r.etaMinutes,
          ),
          if (r.helperLocation != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                'Helper location updated '
                '${TimeOfDay.fromDateTime(r.helperLocation!.recordedAt.toLocal()).format(context)}',
                style: const TextStyle(fontSize: 12, color: _muted),
              ),
            ),
        ],
      ),
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
    final accent = _stepColor(r.status);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CURRENT STATUS',
                    style: TextStyle(
                        fontSize: 11,
                        color: accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6)),
                const SizedBox(height: 3),
                Text(r.status.label,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: _ink)),
                if (r.etaMinutes != null &&
                    r.etaMinutes! > 0 &&
                    r.status == RequestStatus.accepted) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 15, color: accent),
                      const SizedBox(width: 5),
                      Text(
                        'Arriving in ~${r.etaMinutes} min'
                        '${r.distanceKm != null ? ' · ${r.distanceKm!.toStringAsFixed(1)} km' : ''}',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600, color: accent),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          _audioToggle(accent),
        ],
      ),
    );
  }

  // ── Audio-alert toggle (lives in the status banner) ──
  Widget _audioToggle(Color accent) {
    final on = _audioAlerts;
    return Tooltip(
      message: on ? 'Mute request alerts' : 'Alert me on updates',
      child: Semantics(
        button: true,
        toggled: on,
        label: 'Audio alerts',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggleAudioAlerts,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: on ? accent : Colors.white,
                border: Border.all(color: on ? accent : _line, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                on ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                size: 20,
                color: on ? Colors.white : _muted,
              ),
            ),
          ),
        ),
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
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _serviceAccent.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Text(initial,
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15, color: _serviceAccent)),
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

/// Confirmation sheet shown before cancelling an active request.
class _CancelSheet extends StatelessWidget {
  final bool assigned;
  const _CancelSheet({required this.assigned});

  static const _ink = Color(0xFF14181F);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE6E8EC);
  static const _danger = Color(0xFFE5484D);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 18, right: 18, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const Text('Cancel this request?',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _ink)),
          const SizedBox(height: 6),
          Text(
            assigned
                ? 'Your helper is already on their way. Cancelling now may inconvenience them.'
                : 'You can start a new request anytime.',
            style: const TextStyle(fontSize: 13.5, color: _muted, height: 1.5),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ink,
                    side: const BorderSide(color: _line, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Keep request',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _danger,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes, cancel',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
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
