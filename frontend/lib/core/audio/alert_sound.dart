// Cross-platform alert chime used by the request-tracking audio alerts.
//
// On native platforms (Android/iOS/desktop) this plays the OS alert sound;
// on web — where `SystemSound` is a no-op — it synthesises a short two-note
// tone via the Web Audio API, so the toggle is audible everywhere.
//
// The right implementation is picked at compile time: the web file when
// `dart:js_interop` is available, the native stub otherwise.
export 'alert_sound_stub.dart' if (dart.library.js_interop) 'alert_sound_web.dart';
