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
    final rect = ui.Rect.fromLTWH(0, 0, size.x, size.y);
    if (_program == null) {
      canvas.drawRect(rect, ui.Paint()..color = const ui.Color(0xFF02030F));
      return;
    }

    final controller = gameRef.shaderUniformController;
    final texture = controller.entityTexture;
    if (texture == null) {
      canvas.drawRect(rect, ui.Paint()..color = const ui.Color(0xFF02030F));
      return;
    }

    final shader = _program!.fragmentShader();
    final uniforms = _buildUniforms(
      towerCount: controller.towerCount,
      enemyCount: controller.enemyCount,
    );
    for (var i = 0; i < uniforms.length; i++) {
      shader.setFloat(i, uniforms[i]);
    }
    shader.setImageSampler(0, texture);

    final paint = ui.Paint()..shader = shader;
    canvas.drawRect(rect, paint);
    shader.dispose();
  }

  Float32List _buildUniforms({
    required int towerCount,
    required int enemyCount,
  }) {
    final pointer = gameRef.lastPointer ?? Vector2.zero();
    final waveIntensity = gameRef.enemyManager.waveIntensity;
    return Float32List.fromList([
      size.x,
      size.y,
      _time,
      pointer.x,
      pointer.y,
      waveIntensity,
      towerCount.toDouble(),
      enemyCount.toDouble(),
    ]);
  }
}
