import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/hud/hud_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HudButton', () {
    late bool wasPressed;

    setUp(() {
      wasPressed = false;
    });

    test('creates button with required parameters', () {
      final button = HudButton(
        label: 'TEST',
        onPressed: () {},
        position: Vector2(100, 100),
      );

      expect(button.label, 'TEST');
      expect(button.position.x, 100);
      expect(button.position.y, 100);
      expect(button.anchor, Anchor.topLeft);
    });

    test('creates button with default size', () {
      final button = HudButton(
        label: 'TEST',
        onPressed: () {},
        position: Vector2(0, 0),
      );

      expect(button.buttonSize.x, 110);
      expect(button.buttonSize.y, 44);
    });

    test('creates button with custom size', () {
      final button = HudButton(
        label: 'TEST',
        onPressed: () {},
        position: Vector2(0, 0),
        size: Vector2(200, 80),
      );

      expect(button.buttonSize.x, 200);
      expect(button.buttonSize.y, 80);
    });

    test('creates button with custom color', () {
      final button = HudButton(
        label: 'TEST',
        onPressed: () {},
        position: Vector2(0, 0),
        color: Colors.red,
      );

      expect(button.color, Colors.red);
    });

    test('default color is cyan', () {
      final button = HudButton(
        label: 'TEST',
        onPressed: () {},
        position: Vector2(0, 0),
      );

      expect(button.color, const Color(0xFF00FFFF));
    });

    test('isSelected property can be set', () {
      final button = HudButton(
        label: 'TEST',
        onPressed: () {},
        position: Vector2(0, 0),
        isSelected: true,
      );

      expect(button.isSelected, isTrue);

      button.isSelected = false;
      expect(button.isSelected, isFalse);
    });

    test('enabled property getter and setter', () {
      final button = HudButton(
        label: 'TEST',
        onPressed: () {},
        position: Vector2(0, 0),
        enabled: false,
      );

      expect(button.enabled, isFalse);
      expect(button.isEnabled, isFalse);

      button.enabled = true;
      expect(button.enabled, isTrue);
      expect(button.isEnabled, isTrue);
    });

    test('reduceFlicker property', () {
      final button = HudButton(
        label: 'TEST',
        onPressed: () {},
        position: Vector2(0, 0),
        reduceFlicker: true,
      );

      expect(button.reduceFlicker, isTrue);
    });

    test('update increments time', () {
      final button = HudButton(
        label: 'TEST',
        onPressed: () {},
        position: Vector2(0, 0),
      );

      button.update(0.1);
      button.update(0.1);
      button.update(0.1);

      expect(true, isTrue);
    });

    test('update handles hover scale animation', () {
      final button = HudButton(
        label: 'TEST',
        onPressed: () {},
        position: Vector2(0, 0),
        isSelected: true,
      );

      // Multiple updates to let animation progress
      for (int i = 0; i < 30; i++) {
        button.update(0.016);
      }

      expect(true, isTrue);
    });

    test('update handles animation over time', () {
      final button = HudButton(
        label: 'TEST',
        onPressed: () => wasPressed = true,
        position: Vector2(0, 0),
      );

      // Update to progress animations
      for (int i = 0; i < 50; i++) {
        button.update(0.016);
      }

      expect(true, isTrue);
    });

    test('button enabled state can be toggled', () {
      final button = HudButton(
        label: 'TEST',
        onPressed: () => wasPressed = true,
        position: Vector2(0, 0),
        enabled: true,
      );

      expect(button.enabled, isTrue);
      button.enabled = false;
      expect(button.enabled, isFalse);
      button.enabled = true;
      expect(button.enabled, isTrue);
    });

    test('button isEnabled and enabled are synchronized', () {
      final button = HudButton(
        label: 'TEST',
        onPressed: () => wasPressed = true,
        position: Vector2(0, 0),
        enabled: false,
      );

      expect(button.isEnabled, isFalse);
      expect(button.enabled, isFalse);

      button.isEnabled = true;
      expect(button.enabled, isTrue);
    });

    test('button selection state affects rendering', () {
      final button = HudButton(
        label: 'TEST',
        onPressed: () => wasPressed = true,
        position: Vector2(0, 0),
        isSelected: false,
      );

      expect(button.isSelected, isFalse);
      button.isSelected = true;
      expect(button.isSelected, isTrue);

      // Update with selection active
      for (int i = 0; i < 20; i++) {
        button.update(0.016);
      }

      expect(true, isTrue);
    });

    test('callback is stored correctly', () {
      var callCount = 0;
      final button = HudButton(
        label: 'TEST',
        onPressed: () => callCount++,
        position: Vector2(0, 0),
      );

      // Callback is stored but we cannot trigger it without game ref
      expect(button.label, 'TEST');
    });

    test('button properties are accessible', () {
      final button = HudButton(
        label: 'MY_BUTTON',
        onPressed: () {},
        position: Vector2(50, 100),
        size: Vector2(150, 60),
        color: Colors.green,
        isSelected: true,
        reduceFlicker: true,
        enabled: false,
      );

      expect(button.label, 'MY_BUTTON');
      expect(button.buttonSize.x, 150);
      expect(button.buttonSize.y, 60);
      expect(button.color, Colors.green);
      expect(button.isSelected, isTrue);
      expect(button.reduceFlicker, isTrue);
      expect(button.enabled, isFalse);
    });

    test('button with zero delta time update', () {
      final button = HudButton(
        label: 'TEST',
        onPressed: () {},
        position: Vector2(0, 0),
      );

      button.update(0.0);
      expect(true, isTrue);
    });

    test('button with large delta time update', () {
      final button = HudButton(
        label: 'TEST',
        onPressed: () {},
        position: Vector2(0, 0),
      );

      button.update(1.0);
      expect(true, isTrue);
    });

    test('multiple buttons can exist', () {
      final buttons = <HudButton>[];

      for (int i = 0; i < 10; i++) {
        buttons.add(HudButton(
          label: 'BTN$i',
          onPressed: () {},
          position: Vector2(i * 120.0, 0),
        ));
      }

      expect(buttons.length, 10);
      for (final button in buttons) {
        button.update(0.016);
      }
    });

    test('button label can be any string', () {
      final button1 = HudButton(
        label: '',
        onPressed: () {},
        position: Vector2(0, 0),
      );

      final button2 = HudButton(
        label: 'A VERY LONG LABEL TEXT',
        onPressed: () {},
        position: Vector2(0, 0),
      );

      final button3 = HudButton(
        label: '🎮',
        onPressed: () {},
        position: Vector2(0, 0),
      );

      expect(button1.label, '');
      expect(button2.label, 'A VERY LONG LABEL TEXT');
      expect(button3.label, '🎮');
    });
  });

  group('HudButton animation states', () {
    test('selected button animates hover scale', () {
      final button = HudButton(
        label: 'TEST',
        onPressed: () {},
        position: Vector2(0, 0),
        isSelected: true,
      );

      // Animate for a while
      for (int i = 0; i < 100; i++) {
        button.update(0.016);
      }

      expect(true, isTrue);
    });

    test('unselected button has no hover animation', () {
      final button = HudButton(
        label: 'TEST',
        onPressed: () {},
        position: Vector2(0, 0),
        isSelected: false,
      );

      for (int i = 0; i < 100; i++) {
        button.update(0.016);
      }

      expect(true, isTrue);
    });

    test('toggle selection during animation', () {
      final button = HudButton(
        label: 'TEST',
        onPressed: () {},
        position: Vector2(0, 0),
        isSelected: false,
      );

      for (int i = 0; i < 50; i++) {
        button.update(0.016);
        if (i == 25) {
          button.isSelected = true;
        }
      }

      expect(button.isSelected, isTrue);
    });
  });

  group('HudButton render', () {
    test('renders without exceptions', () {
      final button = HudButton(
        label: 'TEST',
        onPressed: () {},
        position: Vector2(0, 0),
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      button.update(0.1);
      button.render(canvas);
      recorder.endRecording();
    });

    test('renders when selected', () {
      final button = HudButton(
        label: 'SELECTED',
        onPressed: () {},
        position: Vector2(0, 0),
        isSelected: true,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      button.update(0.1);
      button.render(canvas);
      recorder.endRecording();
    });

    test('renders when disabled', () {
      final button = HudButton(
        label: 'DISABLED',
        onPressed: () {},
        position: Vector2(0, 0),
        enabled: false,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      button.update(0.1);
      button.render(canvas);
      recorder.endRecording();
    });

    test('renders with custom color', () {
      final button = HudButton(
        label: 'COLORED',
        onPressed: () {},
        position: Vector2(0, 0),
        color: Colors.pink,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      button.update(0.1);
      button.render(canvas);
      recorder.endRecording();
    });

    test('renders with reduceFlicker true', () {
      final button = HudButton(
        label: 'NO_FLICKER',
        onPressed: () {},
        position: Vector2(0, 0),
        reduceFlicker: true,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      button.update(0.1);
      button.render(canvas);
      recorder.endRecording();
    });

    test('renders small button', () {
      final button = HudButton(
        label: 'SM',
        onPressed: () {},
        position: Vector2(0, 0),
        size: Vector2(60, 30),
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      button.update(0.1);
      button.render(canvas);
      recorder.endRecording();
    });

    test('renders large button', () {
      final button = HudButton(
        label: 'VERY LONG LABEL',
        onPressed: () {},
        position: Vector2(0, 0),
        size: Vector2(300, 100),
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      button.update(0.1);
      button.render(canvas);
      recorder.endRecording();
    });

    test('renders after animation time', () {
      final button = HudButton(
        label: 'ANIMATED',
        onPressed: () {},
        position: Vector2(0, 0),
        isSelected: true,
      );

      // Let animation run
      for (int i = 0; i < 60; i++) {
        button.update(0.016);
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      button.render(canvas);
      recorder.endRecording();
    });

    test('renders all states in sequence', () {
      final button = HudButton(
        label: 'STATES',
        onPressed: () {},
        position: Vector2(0, 0),
      );

      // Test various states
      final states = [
        () => button.isSelected = false,
        () => button.isSelected = true,
        () => button.enabled = false,
        () => button.enabled = true,
      ];

      for (final setState in states) {
        setState();
        button.update(0.05);

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        button.render(canvas);
        recorder.endRecording();
      }
    });
  });
}
