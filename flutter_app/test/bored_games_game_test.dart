import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/bored_games_game.dart';
import 'package:bored_games/src/models/quality_level.dart';

void main() {
  group('PendingAbility', () {
    test('has all expected values', () {
      expect(PendingAbility.values, contains(PendingAbility.none));
      expect(PendingAbility.values, contains(PendingAbility.pulse));
      expect(PendingAbility.values, contains(PendingAbility.mine));
    });

    test('has exactly 3 values', () {
      expect(PendingAbility.values.length, 3);
    });
  });

  group('BoredGamesGame quality profiles', () {
    test('low profile applies expected flags', () {
      final game = BoredGamesGame();
      game.enableWorldShader = true;
      game.enableBackgroundParticles = true;

      game.setGraphicsQualityFromSettings('low');

      expect(game.quality, QualityLevel.low);
      expect(game.autoQuality, isFalse);
      expect(game.reduceFx, isTrue);
      expect(game.allowBlur, isFalse);
      expect(game.shaderScale, 0.5);
      expect(game.worldShaderEnabled, isFalse);
      expect(game.particleShaderEnabled, isFalse);
      expect(game.postProcessEnabled, isFalse);
    });

    test('medium profile applies expected flags', () {
      final game = BoredGamesGame();
      game.enableWorldShader = true;
      game.enableBackgroundParticles = true;

      game.setGraphicsQualityFromSettings('medium');

      expect(game.quality, QualityLevel.medium);
      expect(game.autoQuality, isFalse);
      expect(game.reduceFx, isFalse);
      expect(game.allowBlur, isFalse);
      expect(game.shaderScale, 0.8);
      expect(game.worldShaderEnabled, isTrue);
      expect(game.particleShaderEnabled, isFalse);
      expect(game.postProcessEnabled, isFalse);
    });

    test('high profile applies expected flags', () {
      final game = BoredGamesGame();
      game.enableWorldShader = true;
      game.enableBackgroundParticles = true;

      game.setGraphicsQualityFromSettings('high');

      expect(game.quality, QualityLevel.high);
      expect(game.autoQuality, isFalse);
      expect(game.reduceFx, isFalse);
      expect(game.allowBlur, isTrue);
      expect(game.shaderScale, 1.0);
      expect(game.worldShaderEnabled, isTrue);
      expect(game.particleShaderEnabled, isTrue);
      expect(game.postProcessEnabled, isTrue);
    });

    test('extreme profile applies expected flags', () {
      final game = BoredGamesGame();
      game.enableWorldShader = true;
      game.enableBackgroundParticles = true;

      game.setGraphicsQualityFromSettings('extreme');

      expect(game.quality, QualityLevel.extreme);
      expect(game.autoQuality, isFalse);
      expect(game.reduceFx, isFalse);
      expect(game.allowBlur, isTrue);
      expect(game.shaderScale, 1.15);
      expect(game.worldShaderEnabled, isTrue);
      expect(game.particleShaderEnabled, isTrue);
      expect(game.postProcessEnabled, isTrue);
    });

    test('legacy auto and invalid values normalize to high', () {
      final game = BoredGamesGame();

      game.setGraphicsQualityFromSettings('auto');
      expect(game.quality, QualityLevel.high);

      game.setGraphicsQualityFromSettings('unknown-profile');
      expect(game.quality, QualityLevel.high);
    });
  });
}
