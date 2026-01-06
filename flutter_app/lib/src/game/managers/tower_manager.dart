import 'package:flame/components.dart';

class TowerManager extends Component {
  TowerManager({required this.tileSize});

  final double tileSize;

  // TODO: manage tower grid, placement validation, and ghost previews.

  @override
  void update(double dt) {
    super.update(dt);
    // Future: handle targeting logic coordination with BulletManager.
  }
}
