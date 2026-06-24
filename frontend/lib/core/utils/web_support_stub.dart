// Non-web stub for web-only helpers. Native builds get these no-ops.

/// Reloads the page (web only). No-op on native.
void reloadPage() {}

/// Whether the current context can use the browser Geolocation API.
/// Always true on native (handled by OS permissions).
bool isSecureContextForGeo() => true;

/// The current origin (web only); empty on native.
String currentOrigin() => '';
