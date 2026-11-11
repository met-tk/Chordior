import 'package:flutter_test/flutter_test.dart';
import 'package:chordior_flutter/core/theory_engine.dart';

void main() {
  group('Chordior Theory Engine Tests', () {
    test('01: 和弦构成音测试', () {
      final cMaj = getChordNotes('C', 'Maj');
      expect(cMaj, equals(['C', 'E', 'G']));

      final aM7 = getChordNotes('A', 'm7');
      expect(aM7, equals(['A', 'C', 'E', 'G']));

      final g7 = getChordNotes('G', '7');
      expect(g7, equals(['G', 'B', 'D', 'F']));

      final dM7b5 = getChordNotes('D', 'm7b5');
      expect(dM7b5, equals(['D', 'F', 'G#/Ab', 'C']));
    });

    test('02: 和弦反向识别与转位分析', () {
      final name1 = identifyChordName([12, 16, 19]); // C3, E3, G3
      expect(name1.contains('C Maj'), isTrue);

      final name2 = identifyChordName([16, 19, 24]); // E3, G3, C4
      expect(name2.contains('1转位') || name2.contains('E'), isTrue);

      final name3 = identifyChordName([9, 12, 16]); // A2, C3, E3
      expect(name3.contains('A min'), isTrue);
    });

    test('03: 调式音阶生成与顺阶和弦级数', () {
      final scales = getAllScales();
      expect(scales.containsKey('C Ionian (自然大调 Major)'), isTrue);
      expect(scales['C Ionian (自然大调 Major)']!.length, equals(7));

      final harmonics = getModeHarmonics('C', 'Ionian (自然大调 Major)', depth: 'Triad');
      expect(harmonics.length, equals(7));
      expect(harmonics[0].roman, equals('I'));
      expect(harmonics[0].name.contains('C Maj'), isTrue);
      expect(harmonics[4].roman, equals('V'));
      expect(harmonics[4].name.contains('G Maj'), isTrue);
    });

    test('04: 智能声部诱导排列 (Voice-Leading Compact)', () {
      final cMajIndices = notesToPianoIndices(['C', 'E', 'G']);
      expect(cMajIndices.length, equals(3));
      // 根音为 C (即 index % 12 == 0)
      expect(cMajIndices.first % 12, equals(0));

      final aMinIndices = notesToPianoIndices(
        ['A', 'C', 'E'],
        previousIndices: cMajIndices,
      );
      expect(aMinIndices.length, equals(3));
      expect(aMinIndices.first % 12, equals(9));
    });
  });
}
