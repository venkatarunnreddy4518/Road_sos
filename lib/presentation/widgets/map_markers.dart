import 'package:flutter/material.dart';

/// Pulsing user location marker with a sweeping conic radar animation.
class PulsingUserMarker extends StatefulWidget {
  const PulsingUserMarker({super.key});

  @override
  State<PulsingUserMarker> createState() => _PulsingUserMarkerState();
}

class _PulsingUserMarkerState extends State<PulsingUserMarker> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true, // Let taps pass through the radar sweep area to pan/zoom the map
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Conic Sweeping Radar background
          RotationTransition(
            turns: _radarController,
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    const Color(0xFF18B26B).withOpacity(0.0),
                    const Color(0xFF18B26B).withOpacity(0.0),
                    const Color(0xFF18B26B).withOpacity(0.28),
                    const Color(0xFF18B26B).withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.83, 0.97, 1.0],
                ),
              ),
            ),
          ),
          // Pulsing user ring
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 14 + (24 * _pulseController.value),
                height: 14 + (24 * _pulseController.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF18B26B).withOpacity(1.0 - _pulseController.value),
                    width: 2,
                  ),
                ),
              );
            },
          ),
          // Inner user marker dot
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF0E7C52), width: 3.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0E7C52).withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF0E7C52),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper marker showing a pinging/rippling radar effect.
class PingingHelperMarker extends StatefulWidget {
  final bool isEmergency;
  const PingingHelperMarker({super.key, required this.isEmergency});

  @override
  State<PingingHelperMarker> createState() => _PingingHelperMarkerState();
}

class _PingingHelperMarkerState extends State<PingingHelperMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isEmergency ? const Color(0xFFF5A623) : const Color(0xFF0E7C52);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Ripple ping
            Container(
              width: 10 + (20 * _controller.value),
              height: 10 + (20 * _controller.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.3 * (1.0 - _controller.value)),
              ),
            ),
            // Dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ],
        );
      },
    );
  }
}
