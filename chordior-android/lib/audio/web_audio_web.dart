import 'dart:js_interop';

@JS('chordiorPlayChord')
external void _jsChordiorPlayChord(
  JSArray<JSNumber> freqs,
  JSNumber volume,
  JSString timbre,
  JSString mode,
  JSNumber speedMs,
  JSNumber sustainSec,
  JSBoolean dampPrevious,
);

@JS('chordiorSetTimbre')
external void _jsChordiorSetTimbre(
  JSString timbre,
);

void playWebChord(
  List<double> frequencies,
  double volume,
  String timbre, {
  String mode = 'Simultaneous',
  int speedMs = 120,
  double sustainSec = 2.0,
  bool dampPrevious = true,
}) {
  try {
    final jsList = frequencies.map((f) => f.toJS).toList().toJS;
    _jsChordiorPlayChord(
      jsList,
      volume.toJS,
      timbre.toJS,
      mode.toJS,
      speedMs.toJS,
      sustainSec.toJS,
      dampPrevious.toJS,
    );
  } catch (_) {}
}

void setWebTimbre(String timbre) {
  try {
    _jsChordiorSetTimbre(timbre.toJS);
  } catch (_) {}
}

