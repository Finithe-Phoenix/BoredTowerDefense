import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/boss_entrance_effect.dart';

void main() {
  group('BossEntranceEffect', () {
    test('can be created with required parameters', () {
      final effect = BossEntranceEffect(
        bossPosition: Vector2(100, 100),
        bossColor: Colors.red,
      );

      expect(effect, isNotNull);
    });

    test('has priority of 50', () {
      final effect = BossEntranceEffect(
        bossPosition: Vector2(100, 100),
        bossColor: Colors.cyan,
      );

      expect(effect.priority, 50);
    });

    test('position is set to boss position', () {
      final bossPos = Vector2(200, 300);
      final effect = BossEntranceEffect(
        bossPosition: bossPos,
        bossColor: Colors.green,
      );

      expect(effect.position.x, bossPos.x);
      expect(effect.position.y, bossPos.y);
    });

    test('getShakeIntensity returns 0 when elapsed >= duration', () {
      final effect = BossEntranceEffect(
        bossPosition: Vector2(0, 0),
        bossColor: Colors.blue,
      );

      // Simulate completing the effect (duration is 2.5 seconds)
      for (int i = 0; i < 30; i++) {
        effect.update(0.1);
      }

      expect(effect.getShakeIntensity(), 0.0);
    });

    test('getShakeIntensity returns positive value at start', () {
      final effect = BossEntranceEffect(
        bossPosition: Vector2(0, 0),
        bossColor: Colors.blue,
      );

      // Small update to start
      effect.update(0.01);

      expect(effect.getShakeIntensity(), greaterThan(0.0));
    });

    test('getShakeIntensity decreases over time', () {
      final effect = BossEntranceEffect(
        bossPosition: Vector2(0, 0),
        bossColor: Colors.blue,
      );

      effect.update(0.1);
      final intensity1 = effect.getShakeIntensity();

      effect.update(0.5);
      final intensity2 = effect.getShakeIntensity();

      expect(intensity2, lessThan(intensity1));
    });

    test('update method progresses elapsed time', () {
      final effect = BossEntranceEffect(
        bossPosition: Vector2(0, 0),
        bossColor: Colors.purple,
      );

      // Initial shake intensity should be high
      effect.update(0.01);
      final initialIntensity = effect.getShakeIntensity();
      expect(initialIntensity, greaterThan(0));

      // After significant time, intensity should decrease
      effect.update(1.0);
      final laterIntensity = effect.getShakeIntensity();
      expect(laterIntensity, lessThanOrEqualTo(initialIntensity));
    });

    test('uses bossColor for visual effects', () {
      final effect1 = BossEntranceEffect(
        bossPosition: Vector2(0, 0),
        bossColor: Colors.red,
      );

      final effect2 = BossEntranceEffect(
        bossPosition: Vector2(0, 0),
        bossColor: Colors.blue,
      );

      // Both effects should be created successfully with different colors
      expect(effect1, isNotNull);
      expect(effect2, isNotNull);
    });

    test('handles different boss positions', () {
      final positions = [
        Vector2(0, 0),
        Vector2(100, 200),
        Vector2(-50, -50),
        Vector2(1000, 500),
      ];

      for (final pos in positions) {
        final effect = BossEntranceEffect(
          bossPosition: pos,
          bossColor: Colors.cyan,
        );
        expect(effect.position, pos);
      }
    });
  });
}
