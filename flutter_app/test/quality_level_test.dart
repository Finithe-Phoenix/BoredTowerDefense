import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/models/quality_level.dart';

void main() {
  group('QualityLevel enum', () {
    test('quality level enum contains expected values', () {
      expect(QualityLevel.values.length, 4);
      expect(QualityLevel.values.first, QualityLevel.low);
      expect(QualityLevel.values.last, QualityLevel.extreme);
    });

    test('all quality levels exist', () {
      expect(QualityLevel.values, contains(QualityLevel.low));
      expect(QualityLevel.values, contains(QualityLevel.medium));
      expect(QualityLevel.values, contains(QualityLevel.high));
      expect(QualityLevel.values, contains(QualityLevel.extreme));
    });

    test('quality levels have correct index', () {
      expect(QualityLevel.low.index, 0);
      expect(QualityLevel.medium.index, 1);
      expect(QualityLevel.high.index, 2);
      expect(QualityLevel.extreme.index, 3);
    });

    test('quality levels have correct name', () {
      expect(QualityLevel.low.name, 'low');
      expect(QualityLevel.medium.name, 'medium');
      expect(QualityLevel.high.name, 'high');
      expect(QualityLevel.extreme.name, 'extreme');
    });

    test('quality levels are ordered correctly', () {
      expect(QualityLevel.low.index, lessThan(QualityLevel.medium.index));
      expect(QualityLevel.medium.index, lessThan(QualityLevel.high.index));
      expect(QualityLevel.high.index, lessThan(QualityLevel.extreme.index));
    });

    test('quality levels can be compared by index', () {
      final low = QualityLevel.low;
      final medium = QualityLevel.medium;
      final high = QualityLevel.high;
      final extreme = QualityLevel.extreme;

      expect(low.index < medium.index, isTrue);
      expect(medium.index < high.index, isTrue);
      expect(low.index < high.index, isTrue);
      expect(high.index < extreme.index, isTrue);
    });

    test('quality levels toString returns enum name', () {
      expect(QualityLevel.low.toString(), 'QualityLevel.low');
      expect(QualityLevel.medium.toString(), 'QualityLevel.medium');
      expect(QualityLevel.high.toString(), 'QualityLevel.high');
      expect(QualityLevel.extreme.toString(), 'QualityLevel.extreme');
    });

    test('quality levels can be accessed by index', () {
      expect(QualityLevel.values[0], QualityLevel.low);
      expect(QualityLevel.values[1], QualityLevel.medium);
      expect(QualityLevel.values[2], QualityLevel.high);
      expect(QualityLevel.values[3], QualityLevel.extreme);
    });
  });
}
