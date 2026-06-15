// lib/presentation/widgets/status_timeline.dart
import 'package:flutter/material.dart';

import '../../data/models/service_request.dart';

/// Per-step metadata for the SOS request timeline.
class _StepMeta {
  final IconData icon;
  final String label;
  final String detail;
  const _StepMeta(this.icon, this.label, this.detail);
}

/// Vertical SOS status timeline: each lifecycle step shows an icon, label and
/// detail, with the active step pulsing, completed steps in green with a check,
/// and pending steps muted. Mirrors the request_status lifecycle on the backend.
class StatusTimeline extends StatelessWidget {
  final RequestStatus current;
  final String? helperName;
  final String? categoryName;
  final int? etaMinutes;

  const StatusTimeline({
    super.key,
    required this.current,
    this.helperName,
    this.categoryName,
    this.etaMinutes,
  });

  static const _order = [
    RequestStatus.requested,
    RequestStatus.accepted,
    RequestStatus.onTheWay,
    RequestStatus.arrived,
    RequestStatus.completed,
  ];

  // Design tokens (kept consistent with the app's blue + a status green).
  static const _green = Color(0xFF1A9E5C);
  static const _blue = Color(0xFF2563EB);
  static const _idleBg = Color(0xFFE6E8EC);
  static const _idleFg = Color(0xFF9CA3AF);
  static const _ink = Color(0xFF14181F);
  static const _muted = Color(0xFF6B7280);

  List<_StepMeta> _steps() {
    final helper = (helperName != null && helperName!.trim().isNotEmpty)
        ? helperName!.trim()
        : 'Your helper';
    final cat = (categoryName != null && categoryName!.trim().isNotEmpty)
        ? categoryName!.trim()
        : 'Your request';
    final eta = (etaMinutes != null && etaMinutes! > 0) ? ' · ETA ~$etaMinutes min' : '';
    return [
      const _StepMeta(Icons.campaign_rounded, 'Request sent', 'Sent to the nearest helper'),
      _StepMeta(Icons.how_to_reg_rounded, 'Helper assigned', '$helper accepted your request$eta'),
      _StepMeta(Icons.navigation_rounded, 'On the way', '$helper is heading to your location$eta'),
      const _StepMeta(Icons.place_rounded, 'Arrived', 'Your helper is at your location'),
      _StepMeta(Icons.celebration_rounded, 'Help completed', '$cat resolved'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (current == RequestStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: Color(0xFFE5484D), size: 20),
            SizedBox(width: 10),
            Text('Request cancelled',
                style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFE5484D))),
          ],
        ),
      );
    }

    final steps = _steps();
    final activeIndex = _order.indexOf(current).clamp(0, _order.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_order.length, (i) {
        final meta = steps[i];
        final isDone = i < activeIndex;
        final isActive = i == activeIndex;
        final isLast = i == _order.length - 1;
        final showText = isDone || isActive;

        Color nodeBg = _idleBg, nodeFg = _idleFg;
        if (isDone) {
          nodeBg = _green;
          nodeFg = Colors.white;
        } else if (isActive) {
          nodeBg = _blue;
          nodeFg = Colors.white;
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  _Node(
                    bg: nodeBg,
                    fg: nodeFg,
                    icon: isDone ? Icons.check_rounded : meta.icon,
                    active: isActive,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: isDone ? _green : _idleBg,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 4, bottom: isLast ? 0 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meta.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: showText ? _ink : _idleFg,
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (showText)
                        Text(meta.detail,
                            style: const TextStyle(fontSize: 12.5, color: _muted)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// A timeline node — a colored circle holding the step icon (or a check when
/// done). When [active] it shows an expanding, fading pulse ring.
class _Node extends StatefulWidget {
  final Color bg;
  final Color fg;
  final IconData icon;
  final bool active;
  const _Node({required this.bg, required this.fg, required this.icon, required this.active});

  @override
  State<_Node> createState() => _NodeState();
}

class _NodeState extends State<_Node> with SingleTickerProviderStateMixin {
  AnimationController? _c;

  void _sync() {
    if (widget.active && _c == null) {
      _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    } else if (!widget.active && _c != null) {
      _c!.dispose();
      _c = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _Node old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: widget.bg, shape: BoxShape.circle),
      child: Icon(widget.icon, size: 17, color: widget.fg),
    );
    final controller = _c;
    if (controller == null) return dot;
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) {
              final v = controller.value;
              return Container(
                width: 36 + 18 * v,
                height: 36 + 18 * v,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2563EB).withValues(alpha: 0.30 * (1 - v)),
                ),
              );
            },
          ),
          dot,
        ],
      ),
    );
  }
}
