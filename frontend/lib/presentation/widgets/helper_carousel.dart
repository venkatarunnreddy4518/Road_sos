// lib/presentation/widgets/helper_carousel.dart
import 'package:flutter/material.dart';

import '../../data/models/marketplace_helper.dart';

/// Horizontal, selectable carousel of nearby helpers with a "selected helper"
/// action bar (call / request). A richer, more interactive replacement for the
/// plain nearby-helper rail.
class HelperCarousel extends StatefulWidget {
  final List<MarketplaceHelper> helpers;
  final void Function(MarketplaceHelper helper) onCall;
  final void Function(MarketplaceHelper helper) onRequest;
  final VoidCallback? onViewAll;

  const HelperCarousel({
    super.key,
    required this.helpers,
    required this.onCall,
    required this.onRequest,
    this.onViewAll,
  });

  @override
  State<HelperCarousel> createState() => _HelperCarouselState();
}

class _HelperCarouselState extends State<HelperCarousel> {
  String? _selectedId;

  // Design tokens.
  static const _ink = Color(0xFF14181F);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE6E8EC);
  static const _green = Color(0xFF1A9E5C);
  static const _blue = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _selectedId = widget.helpers.isNotEmpty ? widget.helpers.first.id : null;
  }

  @override
  void didUpdateWidget(covariant HelperCarousel old) {
    super.didUpdateWidget(old);
    // Keep the selection valid as the nearby list refreshes.
    final ids = widget.helpers.map((h) => h.id).toSet();
    if (_selectedId == null || !ids.contains(_selectedId)) {
      _selectedId = widget.helpers.isNotEmpty ? widget.helpers.first.id : null;
    }
  }

  static Color _colorFor(String type) {
    switch (type) {
      case 'mechanic':
        return _blue;
      case 'puncture_shop':
        return const Color(0xFF7C5CFC);
      case 'petrol_pump':
        return const Color(0xFFF5A623);
      case 'towing':
        return const Color(0xFFE5484D);
      case 'battery':
      default:
        return _green;
    }
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final p = parts.first;
      return p.substring(0, p.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Rough urban ETA from distance (~20 km/h). An estimate, not a live route.
  static String _eta(double? km) {
    if (km == null) return '';
    final mins = (km * 3).ceil().clamp(1, 99);
    return '$mins min';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.helpers.isEmpty) return const SizedBox.shrink();
    final selected = widget.helpers.firstWhere(
      (h) => h.id == _selectedId,
      orElse: () => widget.helpers.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.helpers.length} HELPERS NEARBY',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: _green),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Helpers near you',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: _ink)),
                  if (widget.onViewAll != null)
                    GestureDetector(
                      onTap: widget.onViewAll,
                      behavior: HitTestBehavior.opaque,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('View all',
                              style: TextStyle(color: _blue, fontWeight: FontWeight.w600, fontSize: 13)),
                          Icon(Icons.chevron_right_rounded, size: 18, color: _blue),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Carousel
        SizedBox(
          height: 186,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
            itemCount: widget.helpers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _card(widget.helpers[i]),
          ),
        ),

        // Selected-helper action bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: _actionBar(selected),
        ),
      ],
    );
  }

  Widget _card(MarketplaceHelper h) {
    final color = _colorFor(h.helperType);
    final isSel = h.id == _selectedId;
    return GestureDetector(
      onTap: () => setState(() => _selectedId = h.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 192,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSel ? color : _line, width: isSel ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: isSel ? color.withValues(alpha: 0.13) : const Color(0x0A101828),
              blurRadius: isSel ? 16 : 4,
              offset: Offset(0, isSel ? 6 : 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
                  child: Text(_initials(h.name),
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color)),
                ),
                if (h.isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                        color: const Color(0xFFEAFBF1), borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_rounded, size: 12, color: _green),
                        SizedBox(width: 3),
                        Text('Verified',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _green)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(h.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: _ink)),
            const SizedBox(height: 2),
            Text(h.typeLabel, style: const TextStyle(fontSize: 12, color: _muted)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 15, color: Color(0xFFF5A623)),
                const SizedBox(width: 3),
                Text(h.ratingAvg.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _ink)),
                const SizedBox(width: 3),
                Text('(${h.ratingCount})',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFF0F1F3)))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 14, color: _muted),
                      const SizedBox(width: 3),
                      Text(h.distanceKm != null ? '${h.distanceKm!.toStringAsFixed(1)} km' : '—',
                          style: const TextStyle(fontSize: 12, color: _muted)),
                    ],
                  ),
                  if (_eta(h.distanceKm).isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                      child: Text(_eta(h.distanceKm),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBar(MarketplaceHelper h) {
    final color = _colorFor(h.helperType);
    final eta = _eta(h.distanceKm);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selected helper', style: TextStyle(fontSize: 12, color: _muted)),
                const SizedBox(height: 2),
                Text(
                  eta.isNotEmpty ? '${h.name} · $eta away' : h.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _ink),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (h.phone != null && h.phone!.isNotEmpty)
            GestureDetector(
              onTap: () => widget.onCall(h),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _line),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.phone, size: 16, color: _muted),
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => widget.onRequest(h),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
              child: const Text('Request',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
            ),
          ),
        ],
      ),
    );
  }
}
