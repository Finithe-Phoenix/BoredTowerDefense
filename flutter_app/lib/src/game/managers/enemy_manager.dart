import 'package:flame/components.dart';

class EnemyManager extends Component {
  EnemyManager({required this.tileSize});

  final double tileSize;

  // TODO: add enemy pool/list, wave scheduling, and path references.

  @override
  void update(double dt) {
    super.update(dt);
    // Future: handle spawning cadence and cleanup.
  }
}
