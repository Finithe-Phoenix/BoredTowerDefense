import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/models/quality_level.dart';

void main() {
  test('quality level enum contains expected values', () {
    expect(QualityLevel.values.length, 3);
    expect(QualityLevel.values.first, QualityLevel.low);
    expect(QualityLevel.values.last, QualityLevel.high);
  });
}
