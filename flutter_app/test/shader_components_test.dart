import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/shaders/particle_shader_component.dart';
import 'package:bored_games/src/game/effects/shaders/screen_post_process_component.dart';
import 'package:bored_games/src/game/effects/shaders/world_uber_shader_component.dart';

void main() {
  group('ParticleShaderComponent', () {
    test('can be created', () {
      final component = ParticleShaderComponent();
      expect(component, isNotNull);
    });

    test('has priority of -15', () {
      final component = ParticleShaderComponent();
      expect(component.priority, -15);
    });

    test('is enabled by default', () {
      final component = ParticleShaderComponent();
      expect(component.enabled, isTrue);
    });

    test('can be disabled', () {
      final component = ParticleShaderComponent();
      component.enabled = false;
      expect(component.enabled, isFalse);
    });
  });

  group('ScreenPostProcessComponent', () {
    test('can be created with default values', () {
      final component = ScreenPostProcessComponent();
      expect(component, isNotNull);
    });

    test('has priority of 1200', () {
      final component = ScreenPostProcessComponent();
      expect(component.priority, 1200);
    });

    test('is enabled by default', () {
      final component = ScreenPostProcessComponent();
      expect(component.enabled, isTrue);
    });

    test('has default opacity of 0.35', () {
      final component = ScreenPostProcessComponent();
      expect(component.opacity, 0.35);
    });

    test('can be created with custom opacity', () {
      final component = ScreenPostProcessComponent(opacity: 0.5);
      expect(component.opacity, 0.5);
    });

    test('can be created with enabled false', () {
      final component = ScreenPostProcessComponent(enabled: false);
      expect(component.enabled, isFalse);
    });

    test('can be disabled after creation', () {
      final component = ScreenPostProcessComponent();
      component.enabled = false;
      expect(component.enabled, isFalse);
    });

    test('opacity is immutable', () {
      final component = ScreenPostProcessComponent(opacity: 0.8);
      // opacity is final, so we can only verify it was set correctly
      expect(component.opacity, 0.8);
    });
  });

  group('WorldUberShaderComponent', () {
    test('can be created', () {
      final component = WorldUberShaderComponent();
      expect(component, isNotNull);
    });

    test('has priority of -20', () {
      final component = WorldUberShaderComponent();
      expect(component.priority, -20);
    });

    test('is enabled by default', () {
      final component = WorldUberShaderComponent();
      expect(component.enabled, isTrue);
    });

    test('can be disabled', () {
      final component = WorldUberShaderComponent();
      component.enabled = false;
      expect(component.enabled, isFalse);
    });
  });
}
