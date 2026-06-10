// lib/presentation/utils/helper_actions.dart
import 'package:url_launcher/url_launcher.dart';

/// Native device actions delegated via url_launcher (FR-012).
class HelperActions {
  static Future<void> call(String phone) async {
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  static Future<void> sms(String phone) async {
    await launchUrl(Uri(scheme: 'sms', path: phone));
  }

  static Future<void> directions(double lat, double lng, {String? label}) async {
    // geo: works on Android; falls back to Google Maps URL (web/iOS).
    final geo = Uri.parse('geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(label ?? 'Helper')})');
    if (await canLaunchUrl(geo)) {
      await launchUrl(geo);
      return;
    }
    await launchUrl(
      Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'),
      mode: LaunchMode.externalApplication,
    );
  }
}
