// lib/presentation/widgets/location_permission_sheet.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../core/utils/location_service.dart';
import '../../core/utils/web_support.dart';

/// Shows the beautiful "Enable location" bottom sheet and returns the resulting
/// [LocationResult] once the user grants access (or null if they dismiss/skip).
///
/// Real-world pattern: a friendly explainer + a single primary CTA, with clear
/// recovery states when the OS denies or location services are off.
Future<LocationResult?> showLocationPermissionSheet(BuildContext context) {
  return showModalBottomSheet<LocationResult>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _LocationPermissionSheet(),
  );
}

enum _Phase { intro, loading, denied, blocked, serviceOff, failed, webHelp, insecure }

class _LocationPermissionSheet extends StatefulWidget {
  const _LocationPermissionSheet();

  @override
  State<_LocationPermissionSheet> createState() => _LocationPermissionSheetState();
}

class _LocationPermissionSheetState extends State<_LocationPermissionSheet> {
  _Phase _phase = _Phase.intro;

  static const _green = Color(0xFF0E7C52);
  static const _greenBright = Color(0xFF18B26B);
  static const _ink = Color(0xFF14201B);
  static const _muted = Color(0xFF7C887F);

  @override
  void initState() {
    super.initState();
    // On the web, location needs a secure context (https or localhost). If the
    // app was opened via a plain http IP, no prompt can ever succeed — say so.
    if (kIsWeb && !isSecureContextForGeo()) {
      _phase = _Phase.insecure;
    }
  }

  Future<void> _request() async {
    setState(() => _phase = _Phase.loading);
    final res = await LocationService.determinePosition(request: true);
    if (!mounted) return;
    switch (res.status) {
      case LocationStatus.granted:
        Navigator.of(context).pop(res);
        return;
      case LocationStatus.denied:
        // On web a denial is sticky — guide the user to the address-bar setting.
        setState(() => _phase = kIsWeb ? _Phase.webHelp : _Phase.denied);
        break;
      case LocationStatus.deniedForever:
        setState(() => _phase = kIsWeb ? _Phase.webHelp : _Phase.blocked);
        break;
      case LocationStatus.serviceDisabled:
        setState(() => _phase = _Phase.serviceOff);
        break;
      case LocationStatus.timeout:
      case LocationStatus.error:
        setState(() => _phase = _Phase.failed);
        break;
    }
  }

  // ── Per-phase copy ──
  ({String emoji, String title, String body, String cta}) get _content {
    switch (_phase) {
      case _Phase.intro:
      case _Phase.loading:
        return (
          emoji: '📍',
          title: 'Find help around you',
          body: 'Share your location so we can show the nearest verified helpers '
              'and accurate distances. We only use it while you need help.',
          cta: 'Allow location access',
        );
      case _Phase.denied:
        return (
          emoji: '🙈',
          title: 'Location permission needed',
          body: "We couldn't access your location. Tap below to try again — it "
              'helps us find helpers closest to you.',
          cta: 'Try again',
        );
      case _Phase.blocked:
        return (
          emoji: '🔒',
          title: 'Enable location in Settings',
          body: 'Location is turned off for this app. Open Settings and allow '
              'location access, then come back.',
          cta: 'Open settings',
        );
      case _Phase.serviceOff:
        return (
          emoji: '🛰️',
          title: 'Turn on location services',
          body: 'Your device location (GPS) is switched off. Turn it on to find '
              'helpers near you.',
          cta: 'Open location settings',
        );
      case _Phase.failed:
        return (
          emoji: '😕',
          title: "Couldn't get your location",
          body: 'Something went wrong while locating you. Please try again.',
          cta: 'Try again',
        );
      case _Phase.webHelp:
        return (
          emoji: '🔒',
          title: 'Allow location for this site',
          body: 'Your browser is blocking location. Click the lock (or ⓘ) icon at '
              'the left of the address bar → Location → Allow, then reload.',
          cta: 'Reload page',
        );
      case _Phase.insecure:
        return (
          emoji: '🌐',
          title: 'Open over a secure address',
          body: 'Browser location only works on a secure address. Open the app at '
              'http://localhost (not an IP), or over https, then allow location.',
          cta: 'Reload page',
        );
    }
  }

  Future<void> _onCta() async {
    switch (_phase) {
      case _Phase.intro:
      case _Phase.denied:
      case _Phase.failed:
        await _request();
        break;
      case _Phase.blocked:
        await LocationService.openAppSettings();
        break;
      case _Phase.serviceOff:
        await LocationService.openLocationSettings();
        break;
      case _Phase.webHelp:
      case _Phase.insecure:
        // Reload so a just-changed site permission / corrected URL takes effect.
        reloadPage();
        break;
      case _Phase.loading:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _content;
    final loading = _phase == _Phase.loading;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(color: Color(0x2614281E), blurRadius: 30, offset: Offset(0, 12)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab handle
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 22),
              decoration: BoxDecoration(
                color: const Color(0xFFE7ECEA),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),

            // Animated location badge
            _PulsingBadge(emoji: c.emoji, loading: loading),
            const SizedBox(height: 22),

            Text(
              c.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: _ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              c.body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: _muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            // Primary CTA
            GestureDetector(
              onTap: loading ? null : _onCta,
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_greenBright, _green],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: _green.withValues(alpha: 0.32),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.my_location, color: Colors.white, size: 19),
                          const SizedBox(width: 9),
                          Text(
                            c.cta,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 6),

            // Secondary "Not now"
            TextButton(
              onPressed: loading ? null : () => Navigator.of(context).pop(),
              child: const Text(
                'Not now',
                style: TextStyle(
                  color: _muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A soft pulsing circular badge that holds the phase emoji (or a glow while loading).
class _PulsingBadge extends StatefulWidget {
  final String emoji;
  final bool loading;
  const _PulsingBadge({required this.emoji, required this.loading});

  @override
  State<_PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<_PulsingBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Expanding pulse ring
              Container(
                width: 56 + 40 * _c.value,
                height: 56 + 40 * _c.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF18B26B).withValues(alpha: 0.18 * (1 - _c.value)),
                ),
              ),
              child!,
            ],
          );
        },
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF18B26B), Color(0xFF0E7C52)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0E7C52).withValues(alpha: 0.30),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(widget.emoji, style: const TextStyle(fontSize: 28)),
        ),
      ),
    );
  }
}
