import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../bored_games_game.dart';
import 'shader_manager.dart';
import 'shader_uniform_controller.dart';

class WorldUberShaderComponent extends PositionComponent with HasGameRef<BoredGamesGame> {
  WorldUberShaderComponent() {
    priority = -20;
  }

  ui.FragmentProgram? _program;
  double _time = 0;
  bool enabled = true;

  // Static cached paints to avoid per-frame allocations
  static final ui.Paint _fallbackPaint = ui.Paint()..color = const ui.Color(0xFF02030F);
  static final ui.Paint _shaderPaint = ui.Paint();
  final Float32List _uniforms = Float32List(8);
  ui.Rect _renderRect = ui.Rect.zero;
  double _renderWidth = 0;
  double _renderHeight = 0;
  double _lastScale = -1;
  double _lastWidth = -1;
  double _lastHeight = -1;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = gameRef.size;
    anchor = Anchor.topLeft;
    position = Vector2.zero();

    await ShaderManager.instance.loadShaderFromAsset(
      name: 'world_uber',
      assetPath: 'assets/shaders/world_uber_shader.frag',
    );
    _program = ShaderManager.instance.program('world_uber');
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    if (!enabled) return;
    final scale = gameRef.shaderScale;
    _ensureRenderMetrics(scale);
    if (_program == null) {
      if (scale != 1.0) {
        canvas.save();
        canvas.scale(1 / scale);
        canvas.drawRect(_renderRect, _fallbackPaint);
        canvas.restore();
      } else {
        canvas.drawRect(_renderRect, _fallbackPaint);
      }
      return;
    }

    final controller = gameRef.shaderUniformController;
    final texture = controller.entityTexture;
    if (texture == null) {
      if (scale != 1.0) {
        canvas.save();
        canvas.scale(1 / scale);
        canvas.drawRect(_renderRect, _fallbackPaint);
        canvas.restore();
      } else {
        canvas.drawRect(_renderRect, _fallbackPaint);
      }
      return;
    }

    final shader = _program!.fragmentShader();
    _writeUniforms(
      scale: scale,
      towerCount: controller.towerCount,
      enemyCount: controller.enemyCount,
    );
    for (var i = 0; i < _uniforms.length; i++) {
      shader.setFloat(i, _uniforms[i]);
    }
    shader.setImageSampler(0, texture);

    _shaderPaint.shader = shader;
    if (scale != 1.0) {
      canvas.save();
      canvas.scale(1 / scale);
      canvas.drawRect(_renderRect, _shaderPaint);
      canvas.restore();
    } else {
      canvas.drawRect(_renderRect, _shaderPaint);
    }
    shader.dispose();
  }

  void _writeUniforms({
    required double scale,
    required int towerCount,
    required int enemyCount,
  }) {
    final pointer = gameRef.lastPointer;
    final pointerX = (pointer?.x ?? 0) * scale;
    final pointerY = (pointer?.y ?? 0) * scale;
    final waveIntensity = gameRef.enemyManager.waveIntensity;
    _uniforms[0] = _renderWidth;
    _uniforms[1] = _renderHeight;
    _uniforms[2] = _time;
    _uniforms[3] = pointerX;
    _uniforms[4] = pointerY;
    _uniforms[5] = waveIntensity;
    _uniforms[6] = towerCount.toDouble();
    _uniforms[7] = enemyCount.toDouble();
  }

  void _ensureRenderMetrics(double scale) {
    final width = size.x;
    final height = size.y;
    if (scale == _lastScale && width == _lastWidth && height == _lastHeight) return;
    _lastScale = scale;
    _lastWidth = width;
    _lastHeight = height;
    _renderWidth = width * scale;
    _renderHeight = height * scale;
    _renderRect = ui.Rect.fromLTWH(0, 0, _renderWidth, _renderHeight);
  }
}
