import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:roadside_help/core/utils/distance_calculator.dart';
import 'package:roadside_help/domain/entities/helper.dart';
import 'package:roadside_help/presentation/demo/demo_helpers.dart';
import 'package:roadside_help/presentation/utils/helper_type_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'helper_list_screen.dart';

class ProblemSelectionScreen extends StatefulWidget {
  const ProblemSelectionScreen({super.key});

  @override
  State<ProblemSelectionScreen> createState() => _ProblemSelectionScreenState();
}

class _ProblemSelectionScreenState extends State<ProblemSelectionScreen> {
  static const double _userLat = 12.9716;
  static const double _userLng = 77.5946;

  HelperType _selectedType = HelperType.PUNCTURE_SHOP;

  @override
  Widget build(BuildContext context) {
    final helpers = demoHelpersForType(_selectedType);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 720;
          final sheetHeight = constraints.maxHeight * (compact ? 0.58 : 0.5);

          return Stack(
            children: [
              Positioned.fill(
                child: _MapBackdrop(
                  helpers: helpers,
                  selectedType: _selectedType,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _TopPanel(selectedType: _selectedType),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: sheetHeight.clamp(360, 470).toDouble(),
                child: _RideHelpSheet(
                  helpers: helpers,
                  selectedType: _selectedType,
                  userLat: _userLat,
                  userLng: _userLng,
                  onTypeChanged: (type) => setState(() => _selectedType = type),
                  onViewAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HelperListScreen(type: _selectedType),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopPanel extends StatelessWidget {
  final HelperType selectedType;

  const _TopPanel({required this.selectedType});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.menu),
                tooltip: 'Menu',
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'Roadside Help',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none),
                tooltip: 'Notifications',
              ),
            ],
          ),
          const SizedBox(height: 8),
          _RouteInput(
            icon: Icons.my_location,
            color: const Color(0xFF18A957),
            label: 'Pickup',
            value: 'MG Road, Bengaluru',
          ),
          const Divider(height: 16),
          _RouteInput(
            icon: helperTypeIcon(selectedType),
            color: helperTypeColor(selectedType),
            label: 'Need help with',
            value: helperTypeTitle(selectedType),
          ),
        ],
      ),
    );
  }
}

class _RouteInput extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _RouteInput({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF74766F),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RideHelpSheet extends StatelessWidget {
  final List<Helper> helpers;
  final HelperType selectedType;
  final double userLat;
  final double userLng;
  final ValueChanged<HelperType> onTypeChanged;
  final VoidCallback onViewAll;

  const _RideHelpSheet({
    required this.helpers,
    required this.selectedType,
    required this.userLat,
    required this.userLng,
    required this.onTypeChanged,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final nearest = helpers.isNotEmpty ? helpers.first : null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8DAD2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Book roadside help',
                        style: TextStyle(
                          color: Color(0xFF111111),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${helpers.length} nearby partners available',
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
                    color: const Color(0xFFF4C430).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.flash_on, color: Color(0xFFE0A500), size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Fast',
                        style: TextStyle(
                          color: Color(0xFF111111),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ServiceSelector(
              selectedType: selectedType,
              onTypeChanged: onTypeChanged,
            ),
            const SizedBox(height: 18),
            if (nearest != null)
              _NearestHelperCard(
                helper: nearest,
                userLat: userLat,
                userLng: userLng,
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onViewAll,
                icon: const Icon(Icons.arrow_forward),
                label: Text('View ${helperTypeTitle(selectedType).toLowerCase()} options'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF111111),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceSelector extends StatelessWidget {
  final HelperType selectedType;
  final ValueChanged<HelperType> onTypeChanged;

  const _ServiceSelector({
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _serviceOptions.map((option) {
        final selected = option.type == selectedType;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: option == _serviceOptions.last ? 0 : 8,
            ),
            child: InkWell(
              onTap: () => onTypeChanged(option.type),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(minHeight: 88),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF111111) : const Color(0xFFF7F8F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? const Color(0xFF111111) : const Color(0xFFE2E4DA),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: selected ? option.color : option.color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        option.icon,
                        size: 18,
                        color: selected ? const Color(0xFF111111) : option.color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      option.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : const Color(0xFF111111),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NearestHelperCard extends StatelessWidget {
  final Helper helper;
  final double userLat;
  final double userLng;

  const _NearestHelperCard({
    required this.helper,
    required this.userLat,
    required this.userLng,
  });

  Future<void> _makeCall() async {
    final url = Uri.parse('tel:${helper.phoneNumber}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final distance = DistanceCalculator.calculateDistance(
      userLat,
      userLng,
      helper.latitude,
      helper.longitude,
    );
    final etaMinutes = math.max(4, (distance / 420).round());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E4DA)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: helperTypeColor(helper.type).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              helperTypeIcon(helper.type),
              color: helperTypeColor(helper.type),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  helper.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111111),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(distance / 1000).toStringAsFixed(1)} km away',
                  style: const TextStyle(
                    color: Color(0xFF6E7168),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Color(0xFF18A957)),
                    const SizedBox(width: 4),
                    Text(
                      '$etaMinutes min',
                      style: const TextStyle(
                        color: Color(0xFF18A957),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        helper.openingHours ?? 'Hours unknown',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF6E7168),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _makeCall,
            icon: const Icon(Icons.phone),
            tooltip: 'Call',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF18A957),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapBackdrop extends StatelessWidget {
  final List<Helper> helpers;
  final HelperType selectedType;

  const _MapBackdrop({
    required this.helpers,
    required this.selectedType,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final markerSpots = [
          const Offset(0.68, 0.34),
          const Offset(0.32, 0.47),
          const Offset(0.76, 0.58),
        ];

        return Stack(
          children: [
            CustomPaint(
              size: constraints.biggest,
              painter: _MapPainter(),
            ),
            Positioned(
              left: constraints.maxWidth * 0.47,
              top: constraints.maxHeight * 0.36,
              child: const _UserMarker(),
            ),
            for (var i = 0; i < helpers.length && i < markerSpots.length; i++)
              Positioned(
                left: constraints.maxWidth * markerSpots[i].dx,
                top: constraints.maxHeight * markerSpots[i].dy,
                child: _HelperMarker(
                  color: helperTypeColor(selectedType),
                  icon: helperTypeIcon(selectedType),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _UserMarker extends StatelessWidget {
  const _UserMarker();

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(-18, -18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.navigation, color: Colors.white, size: 18),
      ),
    );
  }
}

class _HelperMarker extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _HelperMarker({
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(-17, -34),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          Container(
            width: 2,
            height: 10,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFEFF1E8);
    canvas.drawRect(Offset.zero & size, background);

    final blockPaint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    for (var i = 0; i < 7; i++) {
      final left = (i * 92.0) % size.width;
      final top = (i * 73.0) % size.height;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left - 40, top + 70, 86, 54),
          const Radius.circular(8),
        ),
        blockPaint,
      );
    }

    final roadPaint = Paint()
      ..color = const Color(0xFFD5D9CA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    final mainRoad = Path()
      ..moveTo(-20, size.height * 0.34)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.22,
        size.width * 0.56,
        size.height * 0.58,
        size.width + 30,
        size.height * 0.42,
      );
    canvas.drawPath(mainRoad, roadPaint);

    final roadPaintSecondary = Paint()
      ..color = const Color(0xFFE0C06F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final serviceRoad = Path()
      ..moveTo(size.width * 0.18, -20)
      ..cubicTo(
        size.width * 0.42,
        size.height * 0.28,
        size.width * 0.28,
        size.height * 0.64,
        size.width * 0.68,
        size.height + 40,
      );
    canvas.drawPath(serviceRoad, roadPaintSecondary);

    final lanePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(mainRoad, lanePaint);

    final waterPaint = Paint()..color = const Color(0xFFBFD9D2).withValues(alpha: 0.5);
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.72, size.height * 0.12, 150, 90),
      waterPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ServiceOption {
  final HelperType type;
  final String title;
  final IconData icon;
  final Color color;

  const _ServiceOption({
    required this.type,
    required this.title,
    required this.icon,
    required this.color,
  });
}

const _serviceOptions = [
  _ServiceOption(
    type: HelperType.PUNCTURE_SHOP,
    title: 'Tyre',
    icon: Icons.tire_repair,
    color: Color(0xFFF4C430),
  ),
  _ServiceOption(
    type: HelperType.PETROL_PUMP,
    title: 'Fuel',
    icon: Icons.local_gas_station,
    color: Color(0xFF18A957),
  ),
  _ServiceOption(
    type: HelperType.MECHANIC,
    title: 'Mechanic',
    icon: Icons.build,
    color: Color(0xFF2C6BED),
  ),
];
