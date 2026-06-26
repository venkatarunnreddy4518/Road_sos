// Situation-specific animated loading screens for Roadside SOS.
// Flutter ports of the RoadAid loader set — each maps to a real app state.
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Design tokens (mirrors the original loader palette).
class LoaderTokens {
  static const green = Color(0xFF22C55E);
  static const greenDim = Color(0xFF16A34A);
  static const blue = Color(0xFF2563EB);
  static const red = Color(0xFFEF4444);
  static const bg = Color(0xFF080D10);
  static const text = Colors.white;
}

Color _muted([double a = 0.38]) => Colors.white.withValues(alpha: a);

/// Shared dark shell with an optional title + subtitle.
class LoaderShell extends StatelessWidget {
  final Color bg;
  final Widget child;
  final String? title;
  final String? sub;
  final Color titleColor;
  const LoaderShell({
    super.key,
    required this.child,
    this.bg = LoaderTokens.bg,
    this.title,
    this.sub,
    this.titleColor = LoaderTokens.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: bg,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(title!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: titleColor)),
            ),
          if (sub != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(sub!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: _muted())),
            ),
        ],
      ),
    );
  }
}

/// Base mixin: one repeating controller.
mixin _Loop<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  AnimationController loop(int ms) =>
      AnimationController(vsync: this, duration: Duration(milliseconds: ms))..repeat();
}

/* ─── 1. PULSE SOS — SOS button pressed / emergency dispatch ─── */
class PulseSOS extends StatefulWidget {
  final String message;
  final String sub;
  const PulseSOS(
      {super.key,
      this.message = 'Calling for help',
      this.sub = 'Locating nearest helpers…'});
  @override
  State<PulseSOS> createState() => _PulseSOSState();
}

class _PulseSOSState extends State<PulseSOS>
    with TickerProviderStateMixin, _Loop {
  late final AnimationController _c = loop(1800);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoaderShell(
      title: widget.message,
      sub: widget.sub,
      child: SizedBox(
        width: 88,
        height: 88,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final pulse = (math.sin(_c.value * 2 * math.pi) + 1) / 2;
            return Stack(alignment: Alignment.center, children: [
              for (int i = 0; i < 3; i++) _ring((_c.value + i / 3) % 1.0),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LoaderTokens.green,
                  boxShadow: [
                    BoxShadow(
                        color: LoaderTokens.green.withValues(alpha: 0.5 * (1 - pulse)),
                        blurRadius: 6,
                        spreadRadius: 8 * pulse),
                  ],
                ),
                child: const Center(
                  child: Text('SOS',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1)),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _ring(double phase) {
    final scale = 0.85 + phase * (2.4 - 0.85);
    return Opacity(
      opacity: (1 - phase).clamp(0.0, 1.0),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: LoaderTokens.green, width: 2),
          ),
        ),
      ),
    );
  }
}

/* ─── 2. ROAD SCANNER — AI Mechanic analyzing ─── */
class RoadScanner extends StatefulWidget {
  final String message;
  final String sub;
  const RoadScanner(
      {super.key,
      this.message = 'Scanning road ahead',
      this.sub = 'AI analyzing your location…'});
  @override
  State<RoadScanner> createState() => _RoadScannerState();
}

class _RoadScannerState extends State<RoadScanner>
    with TickerProviderStateMixin, _Loop {
  late final AnimationController _c = loop(1400);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoaderShell(
      bg: const Color(0xFF0A0F0A),
      title: widget.message,
      titleColor: LoaderTokens.green,
      sub: widget.sub,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 160,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF131F17),
            border: Border.all(color: const Color(0xFF1F3626)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) =>
                CustomPaint(painter: _RoadPainter(_c.value), size: const Size(160, 80)),
          ),
        ),
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  final double t;
  _RoadPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final edge = Paint()..color = Colors.white.withValues(alpha: 0.07);
    canvas.drawLine(const Offset(0, 12), Offset(size.width, 12), edge);
    canvas.drawLine(
        Offset(0, size.height - 12), Offset(size.width, size.height - 12), edge);
    // scrolling dashed centre line
    final dash = Paint()
      ..color = LoaderTokens.green
      ..strokeWidth = 2;
    const seg = 18.0, gap = 18.0;
    double off = -(t * (seg + gap)) - (seg + gap);
    final y = size.height / 2;
    for (double x = off; x < size.width; x += seg + gap) {
      canvas.drawLine(Offset(x, y), Offset(x + seg, y), dash);
    }
    // scan beam ping-pong
    final tt = t < 0.5 ? t * 2 : (1 - t) * 2;
    final bx = tt * (size.width - 3);
    final beam = Paint()..color = LoaderTokens.green;
    canvas.drawRect(Rect.fromLTWH(bx, 0, 3, size.height), beam);
    canvas.drawRect(
        Rect.fromLTWH(bx - 6, 0, 15, size.height),
        Paint()..color = LoaderTokens.green.withValues(alpha: 0.18));
  }

  @override
  bool shouldRepaint(_RoadPainter o) => o.t != t;
}

/* ─── 3. HELPER RADAR — matching helpers ─── */
class HelperRadar extends StatefulWidget {
  final String message;
  final String sub;
  const HelperRadar(
      {super.key, this.message = 'Finding helpers', this.sub = '5 verified nearby'});
  @override
  State<HelperRadar> createState() => _HelperRadarState();
}

class _HelperRadarState extends State<HelperRadar>
    with TickerProviderStateMixin, _Loop {
  late final AnimationController _c = loop(2000);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoaderShell(
      bg: const Color(0xFF06090F),
      title: widget.message,
      sub: widget.sub,
      child: SizedBox(
        width: 96,
        height: 96,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) =>
              CustomPaint(painter: _RadarPainter(_c.value), size: const Size(96, 96)),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double t;
  _RadarPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    // backdrop
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF0C1A12));
    canvas.drawCircle(
        c, r, Paint()..style = PaintingStyle.stroke..color = const Color(0xFF1A3020));
    // rings + crosshairs
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = LoaderTokens.green.withValues(alpha: 0.18);
    for (final rr in [r * 0.85, r * 0.55, r * 0.25]) {
      canvas.drawCircle(c, rr, ring);
    }
    final cross = Paint()..color = LoaderTokens.green.withValues(alpha: 0.12)..strokeWidth = 0.6;
    canvas.drawLine(Offset(0, c.dy), Offset(size.width, c.dy), cross);
    canvas.drawLine(Offset(c.dx, 0), Offset(c.dx, size.height), cross);
    // sweep
    final sweep = SweepGradient(
      startAngle: 0,
      endAngle: 2 * math.pi,
      colors: [Colors.transparent, LoaderTokens.green.withValues(alpha: 0.45)],
      stops: const [0.6, 1.0],
      transform: GradientRotation(t * 2 * math.pi),
    );
    canvas.drawCircle(
        c, r, Paint()..shader = sweep.createShader(Rect.fromCircle(center: c, radius: r)));
    // center
    canvas.drawCircle(c, 3, Paint()..color = LoaderTokens.green);
    // helper blips
    const blips = [Offset(28, 16), Offset(68, 52), Offset(18, 68)];
    for (int i = 0; i < blips.length; i++) {
      final ph = ((t + i * 0.3) % 1.0);
      final a = ph < 0.6 ? (ph / 0.6) : (1 - (ph - 0.6) / 0.4);
      canvas.drawCircle(blips[i], 3,
          Paint()..color = LoaderTokens.green.withValues(alpha: a.clamp(0.0, 1.0)));
    }
  }

  @override
  bool shouldRepaint(_RadarPainter o) => o.t != t;
}

/* ─── 4. WRENCH + GEAR — mechanic dispatched ─── */
class WrenchGear extends StatefulWidget {
  final String message;
  final String sub;
  const WrenchGear(
      {super.key, this.message = 'Mechanic on the way', this.sub = 'ETA: 12 minutes'});
  @override
  State<WrenchGear> createState() => _WrenchGearState();
}

class _WrenchGearState extends State<WrenchGear>
    with TickerProviderStateMixin, _Loop {
  late final AnimationController _gear = loop(2400);
  late final AnimationController _wr = loop(1000);
  @override
  void dispose() {
    _gear.dispose();
    _wr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoaderShell(
      bg: const Color(0xFF0C0C12),
      title: widget.message,
      sub: widget.sub,
      child: SizedBox(
        width: 90,
        height: 90,
        child: Stack(alignment: Alignment.center, children: [
          RotationTransition(
            turns: _gear,
            child: Icon(Icons.settings,
                size: 84, color: LoaderTokens.blue.withValues(alpha: 0.5)),
          ),
          AnimatedBuilder(
            animation: _wr,
            builder: (_, child) => Transform.rotate(
                angle: math.sin(_wr.value * 2 * math.pi) * 0.5, child: child),
            child: const Icon(Icons.build, size: 38, color: LoaderTokens.green),
          ),
        ]),
      ),
    );
  }
}

/* ─── 5. PIN DROP — GPS lock / getting location ─── */
class PinDrop extends StatefulWidget {
  final String message;
  final String sub;
  const PinDrop(
      {super.key,
      this.message = 'Getting your location',
      this.sub = 'GPS locking in…'});
  @override
  State<PinDrop> createState() => _PinDropState();
}

class _PinDropState extends State<PinDrop> with TickerProviderStateMixin, _Loop {
  late final AnimationController _c = loop(1200);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoaderShell(
      bg: const Color(0xFF06080F),
      title: widget.message,
      sub: widget.sub,
      child: SizedBox(
        width: 70,
        height: 100,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final up = math.sin(_c.value * 2 * math.pi).clamp(0.0, 1.0);
            final ring = (_c.value);
            return Stack(alignment: Alignment.bottomCenter, children: [
              // expanding ring
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Opacity(
                  opacity: (1 - ring).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.5 + ring * 2,
                    child: Container(
                      width: 30,
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: LoaderTokens.blue.withValues(alpha: 0.45)),
                      ),
                    ),
                  ),
                ),
              ),
              // shadow
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Transform.scale(
                  scale: 1 - up * 0.45,
                  child: Container(
                    width: 22,
                    height: 7,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55 * (1 - up * 0.6)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              // pin
              Padding(
                padding: EdgeInsets.only(bottom: 22 + up * 14),
                child: Transform.rotate(
                  angle: -math.pi / 4,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: LoaderTokens.blue,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Center(
                      child: Transform.rotate(
                        angle: math.pi / 4,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

/* ─── 6. PROGRESS STEPS — request booking flow ─── */
class ProgressStepsLoader extends StatefulWidget {
  final List<String> steps;
  final int activeIndex;
  const ProgressStepsLoader({
    super.key,
    this.steps = const [
      'Location found',
      'Helpers matched',
      'Confirming ETA…',
      'Helper dispatched',
    ],
    this.activeIndex = 2,
  });
  @override
  State<ProgressStepsLoader> createState() => _ProgressStepsLoaderState();
}

class _ProgressStepsLoaderState extends State<ProgressStepsLoader>
    with TickerProviderStateMixin, _Loop {
  late final AnimationController _c = loop(1400);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoaderShell(
      child: SizedBox(
        width: 220,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < widget.steps.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (_, __) {
                    final done = i < widget.activeIndex;
                    final active = i == widget.activeIndex;
                    final frac = active
                        ? 0.45 + 0.45 * ((math.sin(_c.value * 2 * math.pi) + 1) / 2)
                        : (done ? 1.0 : 0.0);
                    return Row(children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (done || active)
                              ? LoaderTokens.green
                              : Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: frac,
                            minHeight: 3,
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            valueColor: const AlwaysStoppedAnimation(LoaderTokens.green),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      SizedBox(
                        width: 100,
                        child: Text(widget.steps[i],
                            style: TextStyle(
                                fontSize: 11,
                                color: active
                                    ? LoaderTokens.green
                                    : done
                                        ? Colors.white.withValues(alpha: 0.55)
                                        : Colors.white.withValues(alpha: 0.2))),
                      ),
                    ]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/* ─── 7. CAR ON ROUTE — live helper tracking ─── */
class CarOnRoute extends StatefulWidget {
  final String message;
  final String sub;
  const CarOnRoute(
      {super.key,
      this.message = 'Helper is on the way',
      this.sub = 'Live tracking active'});
  @override
  State<CarOnRoute> createState() => _CarOnRouteState();
}

class _CarOnRouteState extends State<CarOnRoute>
    with TickerProviderStateMixin, _Loop {
  late final AnimationController _c = loop(3000);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoaderShell(
      bg: const Color(0xFF080C10),
      title: widget.message,
      sub: widget.sub,
      child: SizedBox(
        width: 200,
        height: 56,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final p = _c.value;
            return LayoutBuilder(builder: (_, cs) {
              final w = cs.maxWidth;
              return Stack(alignment: Alignment.centerLeft, children: [
                // track
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: p,
                      minHeight: 3,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation(LoaderTokens.green),
                    ),
                  ),
                ),
                _dot(10, Colors.white.withValues(alpha: 0.2)),
                Align(
                  alignment: Alignment.centerRight,
                  child: _dotRaw(p >= 0.98
                      ? LoaderTokens.green
                      : Colors.white.withValues(alpha: 0.2)),
                ),
                Positioned(
                  left: (10 + p * (w - 20)) - 11,
                  child: const Text('🚗', style: TextStyle(fontSize: 22)),
                ),
              ]);
            });
          },
        ),
      ),
    );
  }

  Widget _dot(double left, Color c) =>
      Positioned(left: left, child: _dotRaw(c));
  Widget _dotRaw(Color c) => Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(shape: BoxShape.circle, color: c));
}

/* ─── 8. SOS SIGNAL — emergency broadcast ─── */
class SOSSignal extends StatefulWidget {
  final String message;
  final String sub;
  const SOSSignal(
      {super.key,
      this.message = 'Emergency signal sent',
      this.sub = 'Broadcasting location…'});
  @override
  State<SOSSignal> createState() => _SOSSignalState();
}

class _SOSSignalState extends State<SOSSignal>
    with TickerProviderStateMixin, _Loop {
  late final AnimationController _c = loop(1000);
  static const _bars = [0.3, 0.55, 0.8, 1.0, 0.7];
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoaderShell(
      bg: const Color(0xFF0D0505),
      title: widget.message,
      sub: widget.sub,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final blink = 0.35 + 0.65 * ((math.sin(_c.value * 2 * math.pi) + 1) / 2);
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Opacity(
              opacity: blink,
              child: const Text('SOS',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: LoaderTokens.red,
                      letterSpacing: 6)),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 46,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 0; i < _bars.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: _bar(i, _c.value),
                    ),
                ],
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _bar(int i, double t) {
    final ph = (math.sin((t + i * 0.12) * 2 * math.pi) + 1) / 2;
    final h = (_bars[i] * 46) * (0.6 + 0.4 * ph);
    return Opacity(
      opacity: 0.25 + 0.75 * ph,
      child: Container(
        width: 10,
        height: h,
        decoration: const BoxDecoration(
          color: LoaderTokens.red,
          borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
        ),
      ),
    );
  }
}

/* ─── 9. VERIFIED BADGE — helper verification ─── */
class VerifiedBadge extends StatefulWidget {
  final String message;
  final String sub;
  const VerifiedBadge(
      {super.key,
      this.message = 'Verifying helper',
      this.sub = 'Background check complete'});
  @override
  State<VerifiedBadge> createState() => _VerifiedBadgeState();
}

class _VerifiedBadgeState extends State<VerifiedBadge>
    with TickerProviderStateMixin, _Loop {
  late final AnimationController _c = loop(1200);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoaderShell(
      bg: const Color(0xFF080F14),
      title: widget.message,
      sub: widget.sub,
      child: SizedBox(
        width: 90,
        height: 90,
        child: Stack(alignment: Alignment.center, children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: LoaderTokens.green.withValues(alpha: 0.12), width: 2.5),
            ),
          ),
          RotationTransition(
            turns: _c,
            child: CustomPaint(painter: _ArcPainter(), size: const Size(90, 90)),
          ),
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Color(0xFF0E2018)),
            child: const Icon(Icons.check_rounded, color: LoaderTokens.green, size: 34),
          ),
        ]),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = LoaderTokens.green;
    canvas.drawArc(Offset.zero & size, -math.pi / 2, math.pi, false, p);
  }

  @override
  bool shouldRepaint(_ArcPainter o) => false;
}

/* ─── 10. MAP TILES — map / tile loading ─── */
class MapTiles extends StatefulWidget {
  final String message;
  final String sub;
  const MapTiles(
      {super.key, this.message = 'Loading map', this.sub = 'Fetching tiles…'});
  @override
  State<MapTiles> createState() => _MapTilesState();
}

class _MapTilesState extends State<MapTiles> with TickerProviderStateMixin, _Loop {
  late final AnimationController _c = loop(2000);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoaderShell(
      bg: const Color(0xFF09100E),
      title: widget.message,
      sub: widget.sub,
      child: SizedBox(
        width: 96,
        height: 96,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            return Stack(children: [
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, mainAxisSpacing: 4, crossAxisSpacing: 4),
                itemCount: 9,
                itemBuilder: (_, i) {
                  final ph = ((_c.value + i * 0.13) % 1.0);
                  final lit = ph < 0.6 ? (ph / 0.6) : (1 - (ph - 0.6) / 0.4);
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Color.lerp(const Color(0xFF1A2A22),
                          const Color(0xFF1A3A25), lit.clamp(0.0, 1.0)),
                    ),
                  );
                },
              ),
              Positioned(
                top: 30,
                left: 0,
                right: 0,
                child: Container(
                    height: 2, color: LoaderTokens.green.withValues(alpha: 0.15)),
              ),
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Container(
                    height: 2, color: LoaderTokens.green.withValues(alpha: 0.1)),
              ),
            ]);
          },
        ),
      ),
    );
  }
}
