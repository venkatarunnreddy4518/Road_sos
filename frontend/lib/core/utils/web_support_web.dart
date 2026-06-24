// Web implementation of the web-only helpers.
import 'dart:html' as html;

/// Reloads the page so a just-changed site permission takes effect.
void reloadPage() => html.window.location.reload();

/// Browser geolocation requires a secure context: https:// or localhost/127.0.0.1.
/// Accessing via a plain http LAN IP silently blocks location.
bool isSecureContextForGeo() => html.window.isSecureContext ?? true;

String currentOrigin() => html.window.location.origin;
