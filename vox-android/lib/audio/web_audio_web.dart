import 'dart:js_interop';

@JS('vocalMasterPlayNote')
external void _jsVocalMasterPlayNote(JSNumber midi, JSNumber volume, JSString timbre, JSNumber sustainSec, JSBoolean dampPrevious);

@JS('vocalMasterStopNote')
external void _jsVocalMasterStopNote(JSNumber midi);

@JS('vocalMasterSetTimbre')
external void _jsVocalMasterSetTimbre(JSString timbre);

@JS('vocalMasterStopAll')
external void _jsVocalMasterStopAll();

void webPlayNote(int midi, double volume, String timbre, double sustainSec, [bool dampPrevious = false]) {
  try {
    _jsVocalMasterPlayNote(midi.toJS, volume.toJS, timbre.toJS, sustainSec.toJS, dampPrevious.toJS);
  } catch (_) {}
}

void webStopNote(int midi) {
  try {
    _jsVocalMasterStopNote(midi.toJS);
  } catch (_) {}
}

void webSetTimbre(String timbre) {
  try {
    _jsVocalMasterSetTimbre(timbre.toJS);
  } catch (_) {}
}

void webStopAll() {
  try {
    _jsVocalMasterStopAll();
  } catch (_) {}
}
