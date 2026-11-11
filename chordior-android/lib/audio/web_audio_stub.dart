// 非 Web 平台的空实现桩
void playWebChord(
  List<double> frequencies,
  double volume,
  String timbre, {
  String mode = 'Simultaneous',
  int speedMs = 120,
  double sustainSec = 2.0,
  bool dampPrevious = true,
}) {}

void setWebTimbre(String timbre) {}
