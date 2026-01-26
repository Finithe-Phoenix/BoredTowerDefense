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
    final renderWidth = size.x * scale;
    final renderHeight = size.y * scale;
    final rect = ui.Rect.fromLTWH(0, 0, renderWidth, renderHeight);
    if (_program == null) {
      canvas.save();
      if (scale != 1.0) {
        canvas.scale(1 / scale);
      }
      canvas.drawRect(rect, _fallbackPaint);
      canvas.restore();
      return;
    }

    final controller = gameRef.shaderUniformController;
    final texture = controller.entityTexture;
    if (texture == null) {
      canvas.save();
      if (scale != 1.0) {
        canvas.scale(1 / scale);
      }
      canvas.drawRect(rect, _fallbackPaint);
      canvas.restore();
      return;
    }

    final shader = _program!.fragmentShader();
    final uniforms = _buildUniforms(
      renderSize: Vector2(renderWidth, renderHeight),
      scale: scale,
      towerCount: controller.towerCount,
      enemyCount: controller.enemyCount,
    );
    for (var i = 0; i < uniforms.length; i++) {
      shader.setFloat(i, uniforms[i]);
    }
    shader.setImageSampler(0, texture);

    _shaderPaint.shader = shader;
    canvas.save();
    if (scale != 1.0) {
      canvas.scale(1 / scale);
    }
    canvas.drawRect(rect, _shaderPaint);
    canvas.restore();
    shader.dispose();
  }

  Float32List _buildUniforms({
    required Vector2 renderSize,
    required double scale,
    required int towerCount,
    required int enemyCount,
  }) {
    final pointer = (gameRef.lastPointer ?? Vector2.zero()) * scale;
    final waveIntensity = gameRef.enemyManager.waveIntensity;
    return Float32List.fromList([
      renderSize.x,
      renderSize.y,
      _time,
      pointer.x,
      pointer.y,
      waveIntensity,
      towerCount.toDouble(),
      enemyCount.toDouble(),
    ]);
  }
}
