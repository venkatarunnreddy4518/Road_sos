import 'package:flutter/material.dart';
import 'package:roadside_help/core/i18n/l10n_ext.dart';
import 'package:roadside_help/data/repositories/helper_repository.dart';
import 'package:roadside_help/domain/entities/helper.dart';
import 'package:roadside_help/domain/usecases/find_nearest_helpers.dart';
import 'package:roadside_help/presentation/demo/demo_helpers.dart';
import 'package:roadside_help/presentation/utils/helper_type_ui.dart';

import '../widgets/helper_card.dart';
import '../widgets/loaders.dart';

class HelperListScreen extends StatefulWidget {
  final HelperType type;

  const HelperListScreen({super.key, required this.type});

  @override
  State<HelperListScreen> createState() => _HelperListScreenState();
}

class _HelperListScreenState extends State<HelperListScreen> {
  static const double _userLat = 12.9716;
  static const double _userLng = 77.5946;

  late Future<List<Helper>> _helpersFuture;

  @override
  void initState() {
    super.initState();
    final useCase = FindNearestHelpers(HelperRepository());
    _helpersFuture = useCase.execute(_userLat, _userLng, widget.type);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Helper>>(
        future: _helpersFuture,
        builder: (context, snapshot) {
          final dbHelpers = snapshot.data ?? [];
          final helpers = dbHelpers.isEmpty ? demoHelpersForType(widget.type) : dbHelpers;
          final loading = snapshot.connectionState == ConnectionState.waiting;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 280,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF111111),
                title: Text(helperTypeTitle(context, widget.type)),
                flexibleSpace: FlexibleSpaceBar(
                  background: _HelperMapHeader(
                    type: widget.type,
                    helperCount: helpers.length,
                    loading: loading,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('choose_partner'),
                              style: const TextStyle(
                                color: Color(0xFF111111),
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              loading ? context.tr('finding_partners') : context.tr('sorted_arrival'),
                              style: const TextStyle(
                                color: Color(0xFF6E7168),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.swap_vert, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              context.tr('filter_nearest'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: HelperRadar(),
                )
              else
                SliverList.builder(
                  itemCount: helpers.length,
                  itemBuilder: (context, index) {
                    return HelperCard(helper: helpers[index]);
                  },
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}

class _HelperMapHeader extends StatelessWidget {
  final HelperType type;
  final int helperCount;
  final bool loading;

  const _HelperMapHeader({
    required this.type,
    required this.helperCount,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _ListMap()),
        const Positioned(
          left: 24,
          top: 118,
          child: _MapPin(
            icon: Icons.navigation,
            color: Color(0xFF111111),
            size: 42,
          ),
        ),
        Positioned(
          right: 42,
          top: 112,
          child: _MapPin(
            icon: helperTypeIcon(type),
            color: helperTypeColor(type),
            size: 44,
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: helperTypeColor(type).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(helperTypeIcon(type), color: helperTypeColor(type)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        helperTypeTitle(context, type),
                        style: const TextStyle(
                          color: Color(0xFF111111),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loading ? context.tr('checking_availability') : '$helperCount ${context.tr('partners_near')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF6E7168),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF111111)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MapPin extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _MapPin({
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.44),
    );
  }
}

class _ListMap extends StatelessWidget {
  const _ListMap();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ListMapPainter());
  }
}

class _ListMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEFF1E8),
    );

    final road = Paint()
      ..color = const Color(0xFFD4D8C9)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roadPath = Path()
      ..moveTo(-20, size.height * 0.6)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.4,
        size.width * 0.52,
        size.height * 0.72,
        size.width + 30,
        size.height * 0.32,
      );
    canvas.drawPath(roadPath, road);

    final crossRoad = Paint()
      ..color = const Color(0xFFE1C46C)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final crossPath = Path()
      ..moveTo(size.width * 0.28, -20)
      ..cubicTo(
        size.width * 0.36,
        size.height * 0.32,
        size.width * 0.62,
        size.height * 0.48,
        size.width * 0.76,
        size.height + 30,
      );
    canvas.drawPath(crossPath, crossRoad);

    final block = Paint()..color = Colors.white.withValues(alpha: 0.56);
    for (var i = 0; i < 6; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(30 + (i * 74) % size.width, 70 + (i * 47) % 160, 58, 42),
          const Radius.circular(8),
        ),
        block,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
