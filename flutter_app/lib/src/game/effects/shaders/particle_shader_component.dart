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
    if (_program == null) return;
    final rect = ui.Rect.fromLTWH(0, 0, size.x, size.y);
    final shader = _program!.fragmentShader();
    final uniforms = Float32List.fromList([
      size.x,
      size.y,
      _time,
    ]);
    for (var i = 0; i < uniforms.length; i++) {
      shader.setFloat(i, uniforms[i]);
    }
    final paint = ui.Paint()..shader = shader;
    canvas.drawRect(rect, paint);
    shader.dispose();
  }
}
