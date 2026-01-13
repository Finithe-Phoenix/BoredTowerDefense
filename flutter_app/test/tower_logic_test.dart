import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/entities/enemy.dart';
import 'package:bored_games/src/game/entities/tower.dart';
import 'package:bored_games/src/game/managers/enemy_manager.dart';
import 'package:bored_games/src/game/world/game_world.dart';
import 'package:bored_games/src/models/upgrade_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('applyUpgradeStats updates tower multipliers', () {
    final tower = Tower(
      position: Vector2.zero(),
      size: 32,
      type: TowerType.phaseMage,
    );

    tower.applyUpgradeStats(const UpgradeStats(
      towerDamageMult: 2.0,
      towerRangeMult: 1.5,
      towerFireRateMult: 0.5,
      projectileSpeedMult: 1.2,
      slowMult: 1.4,
    ));

    expect(tower.damage, closeTo(TowerType.phaseMage.damage * 2.0, 0.001));
    expect(tower.range, closeTo(TowerType.phaseMage.range * 1.5, 0.001));
    expect(tower.fireRate, closeTo(TowerType.phaseMage.fireRate * 0.5, 0.001));
    expect(tower.projectileSpeed,
        closeTo(TowerType.phaseMage.projectileSpeed * 1.2, 0.001));
    expect(
      tower.slowAmount,
      closeTo(TowerType.phaseMage.slowAmount * 1.4, 0.001),
    );
  });

  test('manual target fires when in range', () {
    final world = GameWorld(tileSize: 32, mapFile: 'maps/level1.tmx');
    final manager = EnemyManager(tileSize: 32, world: world);
    final tower = Tower(
      position: Vector2.zero(),
      size: 32,
      type: TowerType.pulseArcher,
    );
    var fired = false;
    tower.onFire = (_, __, ___) => fired = true;

    final enemy = Enemy(path: const []);
    enemy.position = tower.centerPosition.clone();

    tower.setManualMode(true);
    tower.setManualTarget(enemy);
    tower.updateTargeting(manager);

    expect(fired, isTrue);
  });

  test('manual target out of range does not fire', () {
    final world = GameWorld(tileSize: 32, mapFile: 'maps/level1.tmx');
    final manager = EnemyManager(tileSize: 32, world: world);
    final tower = Tower(
      position: Vector2.zero(),
      size: 32,
      type: TowerType.pulseArcher,
    );
    var fired = false;
    tower.onFire = (_, __, ___) => fired = true;

    final enemy = Enemy(path: const []);
    enemy.position = Vector2(1000, 1000);

    tower.setManualMode(true);
    tower.setManualTarget(enemy);
    tower.updateTargeting(manager);

    expect(fired, isFalse);
  });
}
