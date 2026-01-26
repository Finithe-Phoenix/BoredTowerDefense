import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../bored_games_game.dart';
import 'shader_manager.dart';

/// Full-screen post-process shader overlay (vignette + chromatic pulse).
class ScreenPostProcessComponent extends PositionComponent with HasGameRef<BoredGamesGame> {
  ScreenPostProcessComponent({
    this.opacity = 0.35,
    this.enabled = true,
  }) {
    priority = 1200;
  }

  final double opacity;
  bool enabled;
  ui.FragmentProgram? _program;
  double _time = 0;

  // Static cached paint to avoid per-frame allocations
  static final ui.Paint _shaderPaint = ui.Paint();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = gameRef.size;
    anchor = Anchor.topLeft;
    position = Vector2.zero();

    await ShaderManager.instance.loadShaderFromAsset(
      name: 'post_process',
      assetPath: 'assets/shaders/post_process_master.frag',
    );
    _program = ShaderManager.instance.program('post_process');
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!enabled) return;
    _time += dt;
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    if (!enabled) return;
    if (_program == null) return;
    final scale = gameRef.shaderScale;
    final renderWidth = size.x * scale;
    final renderHeight = size.y * scale;
    final rect = ui.Rect.fromLTWH(0, 0, renderWidth, renderHeight);
    final shader = _program!.fragmentShader();
    final uniforms = _buildUniforms(renderWidth, renderHeight);
    for (var i = 0; i < uniforms.length; i++) {
      shader.setFloat(i, uniforms[i]);
    }
    _shaderPaint.shader = shader;
    canvas.save();
    if (scale != 1.0) {
      canvas.scale(1 / scale);
    }
    canvas.drawRect(rect, _shaderPaint);
    canvas.restore();
    shader.dispose();
  }

  Float32List _buildUniforms(double width, double height) {
    return Float32List.fromList([
      width,
      height,
      _time,
      gameRef.screenEffects.trauma,
      gameRef.enemyManager.waveIntensity,
      opacity,
    ]);
  }
}
