// lib/core/utils/location_service.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Outcome of a location attempt — lets the UI react precisely instead of
/// silently falling back to a hardcoded city (FR-025).
enum LocationStatus {
  granted, // got a real fix
  serviceDisabled, // device location/GPS turned off
  denied, // permission denied (can ask again)
  deniedForever, // permission permanently denied — needs app settings
  timeout, // permission ok but no fix in time
  error, // anything unexpected
}

class LocationResult {
  final LocationStatus status;
  final Position? position;
  const LocationResult(this.status, [this.position]);

  bool get ok => position != null;
}

/// Wraps GPS access with a graceful, real-world permission flow.
class LocationService {
  /// True when permission is already granted (no prompt shown).
  static Future<bool> hasPermission() async {
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.whileInUse || p == LocationPermission.always;
  }

  /// Full flow: checks the service, (optionally) requests permission, then
  /// returns the most accurate fix it can — warm-starting from the last known
  /// position so the map snaps to roughly the right place immediately.
  static Future<LocationResult> determinePosition({bool request = true}) async {
    try {
      // Native platforms can report the OS location toggle; web cannot.
      if (!kIsWeb && !await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult(LocationStatus.serviceDisabled);
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied && request) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        return const LocationResult(LocationStatus.denied);
      }
      if (perm == LocationPermission.deniedForever) {
        return const LocationResult(LocationStatus.deniedForever);
      }

      // Permission granted — try for a fix.
      Position? warm;
      if (!kIsWeb) {
        try {
          warm = await Geolocator.getLastKnownPosition();
        } catch (_) {
          // Not all platforms support this; ignore.
        }
      }

      try {
        final fresh = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 12),
        );
        return LocationResult(LocationStatus.granted, fresh);
      } on TimeoutException {
        // Fall back to the warm fix if we have one, else report the timeout.
        return warm != null
            ? LocationResult(LocationStatus.granted, warm)
            : const LocationResult(LocationStatus.timeout);
      } catch (_) {
        return warm != null
            ? LocationResult(LocationStatus.granted, warm)
            : const LocationResult(LocationStatus.error);
      }
    } catch (_) {
      return const LocationResult(LocationStatus.error);
    }
  }

  /// Backward-compatible helper: just the position, or null.
  static Future<Position?> current() async =>
      (await determinePosition()).position;

  /// Open the OS location-services screen (native only).
  static Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  /// Open this app's settings page so the user can flip permission back on.
  static Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }
}
