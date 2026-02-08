import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../bored_games_game.dart';
import 'shader_manager.dart';

/// Lightweight GPU-driven particle trail layer (full-screen) to offload CPU paint work.
class ParticleShaderComponent extends PositionComponent with HasGameRef<BoredGamesGame> {
  ParticleShaderComponent() {
    priority = -15;
  }

  ui.FragmentProgram? _program;
  double _time = 0;
  bool enabled = true;

  // Static cached paint to avoid per-frame allocations
  static final ui.Paint _shaderPaint = ui.Paint();
  final Float32List _uniforms = Float32List(3);
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
      name: 'particle_trails',
      assetPath: 'assets/shaders/particle_trail_shader.frag',
    );
    _program = ShaderManager.instance.program('particle_trails');
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
    if (_program == null) return;
    final scale = gameRef.shaderScale;
    _ensureRenderMetrics(scale);
    final shader = _program!.fragmentShader();
    _uniforms[0] = _renderWidth;
    _uniforms[1] = _renderHeight;
    _uniforms[2] = _time;
    for (var i = 0; i < _uniforms.length; i++) {
      shader.setFloat(i, _uniforms[i]);
    }
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
