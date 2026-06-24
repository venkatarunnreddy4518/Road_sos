import 'package:flutter/services.dart';

/// Native implementation: the platform alert sound (works on Android/iOS and
/// desktop). Web overrides this with a synthesised tone in [alert_sound_web].
void playAlertChime() => SystemSound.play(SystemSoundType.alert);

/// No-op on native — only the web AudioContext needs priming. Kept so callers
/// can warm up audio uniformly across platforms.
void warmUpAudio() {}
