// lib/core/utils/location_store.dart
import 'package:shared_preferences/shared_preferences.dart';

/// A location the user deliberately chose (via address search or by dragging the
/// map). On web/desktop there is no GPS, so a saved place — not the browser's
/// coarse Wi-Fi/IP guess — is the accurate source of truth.
class SavedLocation {
  final double lat;
  final double lng;
  final String label1;
  final String label2;
  const SavedLocation(this.lat, this.lng, this.label1, this.label2);
}

/// Persists the user's chosen location across reloads/sessions so the app stops
/// reverting to an inaccurate network estimate every time it opens.
class LocationStore {
  static const _kLat = 'loc_lat';
  static const _kLng = 'loc_lng';
  static const _kL1 = 'loc_label1';
  static const _kL2 = 'loc_label2';

  static Future<void> save(
    double lat,
    double lng, {
    String label1 = '',
    String label2 = '',
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kLat, lat);
    await p.setDouble(_kLng, lng);
    await p.setString(_kL1, label1);
    await p.setString(_kL2, label2);
  }

  static Future<SavedLocation?> load() async {
    final p = await SharedPreferences.getInstance();
    final lat = p.getDouble(_kLat);
    final lng = p.getDouble(_kLng);
    if (lat == null || lng == null) return null;
    return SavedLocation(lat, lng, p.getString(_kL1) ?? '', p.getString(_kL2) ?? '');
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kLat);
    await p.remove(_kLng);
    await p.remove(_kL1);
    await p.remove(_kL2);
  }
}
