import 'dart:js_interop';

// Minimal Web Audio API bindings — just enough to synthesise a short chime,
// so we avoid bundling an audio asset or adding a package dependency.

@JS('AudioContext')
extension type _AudioContext._(JSObject _) implements JSObject {
  external factory _AudioContext();
  external _OscillatorNode createOscillator();
  external _GainNode createGain();
  external JSObject get destination;
  external double get currentTime;
  external JSPromise<JSAny?> resume();
}

extension type _OscillatorNode._(JSObject _) implements JSObject {
  external _AudioParam get frequency;
  external set type(String value);
  external void connect(JSObject node);
  external void start([double when]);
  external void stop([double when]);
}

extension type _GainNode._(JSObject _) implements JSObject {
  external _AudioParam get gain;
  external void connect(JSObject node);
}

extension type _AudioParam._(JSObject _) implements JSObject {
  external set value(double v);
  external void setValueAtTime(double value, double time);
  external void exponentialRampToValueAtTime(double value, double time);
}

// One reused context: it's first created during the toggle tap (a user
// gesture), which unlocks audio under the browser autoplay policy; later
// poll-driven chimes reuse and resume it.
_AudioContext? _ctx;

/// Create + resume the shared AudioContext ahead of time. Called on screen
/// load (just after a navigation gesture, so sticky activation is present) so
/// the context is already "running" when the first poll-driven chime fires —
/// otherwise a context created at that instant can be suspended and drop the
/// first tone.
void warmUpAudio() {
  try {
    (_ctx ??= _AudioContext()).resume();
  } catch (_) {/* audio unavailable */}
}

/// Web implementation: a pleasant two-note "ding-ding" via Web Audio.
void playAlertChime() {
  try {
    final ctx = _ctx ??= _AudioContext();
    ctx.resume();
    final t = ctx.currentTime;
    _tone(ctx, t, 880); // A5
    _tone(ctx, t + 0.16, 1320); // ~E6
  } catch (_) {
    // Audio unavailable (no Web Audio support / blocked) — fail silently;
    // the snackbar + screen-reader announcement still convey the update.
  }
}

void _tone(_AudioContext ctx, double start, double freq) {
  const dur = 0.13;
  final osc = ctx.createOscillator();
  final gain = ctx.createGain();
  osc.type = 'sine';
  osc.frequency.value = freq;
  // Quick attack, exponential decay (can't ramp to exactly 0, so use ~0).
  gain.gain.setValueAtTime(0.0001, start);
  gain.gain.exponentialRampToValueAtTime(0.3, start + 0.015);
  gain.gain.exponentialRampToValueAtTime(0.0001, start + dur);
  osc.connect(gain);
  gain.connect(ctx.destination);
  osc.start(start);
  osc.stop(start + dur + 0.02);
}
