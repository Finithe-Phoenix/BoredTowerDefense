import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

class GameWorld extends Component {
  GameWorld({required this.tileSize});

  final double tileSize;

  List<Vector2> waypoints = [];
  late List<List<bool>> isBuildable;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadMap();
  }

  Future<void> _loadMap() async {
    final String raw = await rootBundle.loadString('assets/maps/level1.json');
    final Map<String, dynamic> data = json.decode(raw);

    final int width = data['width'] as int;
    final int height = data['height'] as int;
    isBuildable = List.generate(height, (_) => List<bool>.filled(width, true));

    for (final layer in data['layers'] as List<dynamic>) {
      if (layer['name'] == 'Path' && layer['type'] == 'objectgroup') {
        final objects = layer['objects'] as List<dynamic>;
        waypoints = objects
            .map((obj) => Vector2(
                  (obj['x'] as num).toDouble(),
                  (obj['y'] as num).toDouble(),
                ))
            .toList();
      }
      if (layer['name'] == 'Collision' && layer['type'] == 'tilelayer') {
        final List<dynamic> dataList = layer['data'] as List<dynamic>;
        for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
            final int index = y * width + x;
            final int val = dataList[index] as int;
            // 0 = buildable, >0 = blocked
            if (val > 0) {
              isBuildable[y][x] = false;
            }
          }
        }
      }
    }
  }
}
