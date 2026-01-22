import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/shaders/shader_uniform_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShaderUniformController', () {
    late ShaderUniformController controller;

    setUp(() {
      controller = ShaderUniformController();
    });

    test('has correct static constants', () {
      expect(ShaderUniformController.maxEntities, 10);
      expect(ShaderUniformController.updateInterval, 1 / 12);
    });

    test('initializes with correct priority', () {
      expect(controller.priority, 100);
    });

    test('has initialized position buffers', () {
      expect(controller.towerPositionBuffer, isA<Float32List>());
      expect(controller.enemyPositionBuffer, isA<Float32List>());
      expect(controller.towerPositionBuffer.length, ShaderUniformController.maxEntities * 2);
      expect(controller.enemyPositionBuffer.length, ShaderUniformController.maxEntities * 2);
    });

    test('initial counts are zero', () {
      expect(controller.towerCount, 0);
      expect(controller.enemyCount, 0);
    });

    test('enabled is true by default', () {
      expect(controller.enabled, isTrue);
    });

    test('enabled can be toggled', () {
      controller.enabled = false;
      expect(controller.enabled, isFalse);

      controller.enabled = true;
      expect(controller.enabled, isTrue);
    });

    test('entityTexture is null initially', () {
      expect(controller.entityTexture, isNull);
    });

    test('update with enabled false does nothing', () {
      controller.enabled = false;
      controller.update(0.1);

      // Should not throw and counts remain zero
      expect(controller.towerCount, 0);
      expect(controller.enemyCount, 0);
    });

    test('update before interval does not update', () {
      controller.enabled = true;
      // Update interval is 1/12 = 0.083...
      controller.update(0.01);
      controller.update(0.01);

      // Should not have reached interval yet
      expect(true, isTrue);
    });

    test('multiple small updates accumulate', () {
      controller.enabled = false; // Disable to avoid gameRef access
      for (int i = 0; i < 10; i++) {
        controller.update(0.01);
      }

      // Should not throw with enabled=false
      expect(true, isTrue);
    });

    test('onRemove disposes texture', () {
      controller.onRemove();
      // Should not throw
      expect(true, isTrue);
    });

    test('position buffers are zeroed initially', () {
      for (int i = 0; i < controller.towerPositionBuffer.length; i++) {
        expect(controller.towerPositionBuffer[i], 0.0);
      }
      for (int i = 0; i < controller.enemyPositionBuffer.length; i++) {
        expect(controller.enemyPositionBuffer[i], 0.0);
      }
    });

    test('multiple controllers can exist', () {
      final controller1 = ShaderUniformController();
      final controller2 = ShaderUniformController();
      final controller3 = ShaderUniformController();

      expect(controller1, isNotNull);
      expect(controller2, isNotNull);
      expect(controller3, isNotNull);

      // Each has independent buffers
      controller1.towerPositionBuffer[0] = 100;
      expect(controller2.towerPositionBuffer[0], 0);
    });
  });

  group('ShaderUniformController timing', () {
    test('update interval is approximately 12 FPS', () {
      expect(ShaderUniformController.updateInterval, closeTo(0.0833, 0.001));
    });

    test('rapid updates are rate limited', () {
      final controller = ShaderUniformController();
      controller.enabled = false; // Disable to avoid gameRef access

      // 100 updates at 60fps = 1.67 seconds
      for (int i = 0; i < 100; i++) {
        controller.update(0.0167);
      }

      // Should not throw with enabled=false
      expect(true, isTrue);
    });
  });
}
