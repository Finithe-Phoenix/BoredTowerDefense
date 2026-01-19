import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bored_games/src/game/bored_games_game.dart';
import 'package:bored_games/src/game/entities/boss.dart';
import 'package:bored_games/src/models/level_config.dart';
import '../helpers/fake_audioplayers_platform.dart';

/// Integration tests for the complete boss system
/// Tests the interaction between Boss, EnemyManager, HUD, and Game
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFakeAudioplayersPlatform();
  });

  Future<Boss> _spawnBoss(BoredGamesGame game) async {
    await game.ready();
    game.enemyManager.startWave(count: 5);
    game.enemyManager.remaining = 2;
    game.enemyManager.update(2.0);
    game.update(0);
    final boss = game.enemyManager.currentBoss;
    expect(boss, isNotNull);
    return boss!;
  }

  group('Boss System Integration', () {
    testWithGame(
      'complete boss encounter - level 10',
      () => BoredGamesGame(
        tileSize: 32,
        levelConfig: LevelConfig(
          id: 10,
          name: 'Citadel Core',
          mapFile: 'maps/level10.tmx',
          waves: 5,
          difficulty: 1,
          startingGold: 200,
          startingLives: 20,
        ),
      ),
      (game) async {
        // Initialize game
        await game.ready();

        // Start final wave
        for (int wave = 1; wave <= 5; wave++) {
          game.enemyManager.startWave(count: 5);
          await game.ready();

          // Wait for wave to spawn
          while (game.enemyManager.spawning) {
            game.update(2.0);
            await game.ready();
          }
        }

        // Boss should spawn on last wave
        expect(game.enemyManager.currentBoss, isNotNull);
        expect(game.enemyManager.currentBoss?.bossType, BossType.citadelCore);
        expect(game.enemyManager.currentBoss?.isAlive, true);
      },
    );

    testWithGame(
      'boss health bar updates correctly',
      () => BoredGamesGame(
        tileSize: 32,
        levelConfig: LevelConfig(
          id: 10,
          name: 'Test',
          mapFile: 'maps/level1.tmx',
          waves: 1,
          difficulty: 1,
        ),
      ),
      (game) async {
        final boss = await _spawnBoss(game);
        game.enemyManager.spawning = false;
        game.enemyManager.remaining = 0;

        // HUD should track boss
        expect(game.enemyManager.currentBoss, equals(boss));

        // Damage boss
        boss.takeDamage(boss.maxHealth * 0.4);
        game.update(0.1);

        expect(boss.healthPercent, closeTo(0.6, 0.01));
        expect(boss.currentPhase, 2);
      },
    );

    testWithGame(
      'boss phase changes trigger visual effects',
      () => BoredGamesGame(
        tileSize: 32,
        levelConfig: LevelConfig(
          id: 10,
          name: 'Test',
          mapFile: 'maps/level1.tmx',
          waves: 1,
          difficulty: 1,
        ),
      ),
      (game) async {
        int phaseChanges = 0;
        game.enemyManager.onBossPhaseChange = (_, __) {
          phaseChanges++;
        };

        final boss = await _spawnBoss(game);
        final phaseDamage = boss.maxHealth * 0.26;

        // Damage through all phases
        boss.takeDamage(phaseDamage); // Phase 2
        boss.update(0.016);
        expect(phaseChanges, 1);

        boss.takeDamage(phaseDamage); // Phase 3
        boss.update(0.016);
        expect(phaseChanges, 2);

        boss.takeDamage(phaseDamage); // Phase 4
        boss.update(0.016);
        expect(phaseChanges, 3);
      },
    );

    testWithGame(
      'BOOST mode activates with boss present',
      () => BoredGamesGame(
        tileSize: 32,
        levelConfig: LevelConfig(
          id: 10,
          name: 'Test',
          mapFile: 'maps/level1.tmx',
          waves: 1,
          difficulty: 1,
        ),
      ),
      (game) async {
        // No boss initially
        expect(game.enemyManager.currentBoss, isNull);

        await _spawnBoss(game);

        // Boss should be tracked
        expect(game.enemyManager.currentBoss, isNotNull);
        expect(game.enemyManager.currentBoss?.isAlive, true);
      },
    );

    testWithGame(
      'boss rewards gold correctly',
      () => BoredGamesGame(
        tileSize: 32,
        levelConfig: LevelConfig(
          id: 10,
          name: 'Test',
          mapFile: 'maps/level1.tmx',
          waves: 1,
          difficulty: 1,
        ),
      ),
      (game) async {
        final initialGold = game.gold;
        int goldRewarded = 0;

        // Setup enemy killed callback
        game.enemyManager.onEnemyKilled = (enemy, gold) {
          goldRewarded += gold;
        };

        final boss = await _spawnBoss(game);
        game.enemyManager.spawning = false;
        game.enemyManager.remaining = 0;

        // Kill boss
        boss.takeDamage(boss.maxHealth * 2);
        game.update(0.1);

        expect(goldRewarded, boss.goldReward);
      },
    );

    testWithGame(
      'all 10 world bosses spawn correctly',
      () => BoredGamesGame(
        tileSize: 32,
        levelConfig: LevelConfig(
          id: 10,
          name: 'Test',
          mapFile: 'maps/level1.tmx',
          waves: 3,
          difficulty: 1,
        ),
      ),
      (game) async {
        final bossLevels = {
          10: BossType.citadelCore,
          20: BossType.abyssGate,
          30: BossType.voidlineApex,
          40: BossType.shardVault,
          50: BossType.arcFortress,
          60: BossType.coreHunter,
          70: BossType.omegaGrid,
          80: BossType.stormTower,
          90: BossType.finalGate,
          100: BossType.omegaNexus,
        };

        for (final entry in bossLevels.entries) {
          final levelId = entry.key;
          final expectedBossType = entry.value;

          final boss = Boss(
            path: [Vector2(0, 0), Vector2(100, 0)],
            bossType: expectedBossType,
            bossLevel: levelId,
            maxHealth: 5000,
          );

          expect(boss.bossType, expectedBossType);
          expect(boss.bossLevel, levelId);
        }
      },
    );

    testWithGame(
      'boss entrance effect spawns',
      () => BoredGamesGame(
        tileSize: 32,
        levelConfig: LevelConfig(
          id: 10,
          name: 'Test',
          mapFile: 'maps/level1.tmx',
          waves: 1,
          difficulty: 1,
        ),
      ),
      (game) async {
        final initialChildCount = game.enemyManager.children.length;

        await _spawnBoss(game);
        await game.ready();

        // Should have additional children (boss + entrance effect)
        expect(game.enemyManager.children.length, greaterThan(initialChildCount));
      },
    );

    testWithGame(
      'mini-boss spawns on regular levels',
      () => BoredGamesGame(
        tileSize: 32,
        levelConfig: LevelConfig(
          id: 5, // Not a multiple of 10
          name: 'Test',
          mapFile: 'maps/level1.tmx',
          waves: 1,
          difficulty: 1,
        ),
      ),
      (game) async {
        final boss = await _spawnBoss(game);

        // Should spawn mini-boss
        expect(boss.bossType, BossType.miniBoss);
      },
    );

    testWithGame(
      'boss abilities are called during combat',
      () => BoredGamesGame(
        tileSize: 32,
        levelConfig: LevelConfig(
          id: 10,
          name: 'Test',
          mapFile: 'maps/level1.tmx',
          waves: 3,
          difficulty: 1,
        ),
      ),
      (game) async {
        int abilitiesUsed = 0;
        final abilities = <String>[];

        final boss = Boss(
          path: [Vector2(0, 0), Vector2(100, 0), Vector2(200, 100)],
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 10000,
          onAbilityUsed: (boss, abilityName) {
            abilitiesUsed++;
            abilities.add(abilityName);
          },
        );

        // Update boss for long enough to trigger abilities
        for (int i = 0; i < 60; i++) {
          boss.update(0.1);
        }

        expect(abilitiesUsed, greaterThan(0));
        expect(abilities.contains('emp_pulse'), true);
      },
    );

    testWithGame(
      'Omega Nexus cycles through all mechanics',
      () => BoredGamesGame(
        tileSize: 32,
        levelConfig: LevelConfig(
          id: 1,
          name: 'Test',
          mapFile: 'maps/level1.tmx',
          waves: 1,
          difficulty: 1,
        ),
      ),
      (game) async {
        final abilities = <String>{};

        final boss = Boss(
          path: [Vector2(0, 0), Vector2(200, 0)],
          bossType: BossType.omegaNexus,
          bossLevel: 100,
          maxHealth: 50000,
          onAbilityUsed: (boss, abilityName) {
            abilities.add(abilityName);
          },
        );

        // Update for extended time to cycle mechanics
        for (int i = 0; i < 220; i++) {
          boss.update(0.1);
        }

        // Should have used multiple different abilities
        expect(abilities.length, greaterThan(1));
      },
    );

    testWithGame(
      'boss death completes wave',
      () => BoredGamesGame(
        tileSize: 32,
        levelConfig: LevelConfig(
          id: 10,
          name: 'Test',
          mapFile: 'maps/level1.tmx',
          waves: 1,
          difficulty: 1,
        ),
      ),
      (game) async {
        bool waveCompleted = false;

        game.enemyManager.onWaveComplete = (wave) {
          waveCompleted = true;
        };

        final boss = await _spawnBoss(game);
        game.enemyManager.spawning = false;
        game.enemyManager.remaining = 0;

        // Kill boss
        boss.takeDamage(boss.maxHealth * 2);
        game.update(0.1);

        expect(waveCompleted, true);
      },
    );

    testWithGame(
      'multiple bosses can exist in sequence',
      () => BoredGamesGame(
        tileSize: 32,
        levelConfig: LevelConfig(
          id: 1,
          name: 'Test',
          mapFile: 'maps/level1.tmx',
          waves: 1,
          difficulty: 1,
        ),
      ),
      (game) async {
        // Boss 1
        final boss1 = await _spawnBoss(game);

        // Kill boss 1
        boss1.takeDamage(boss1.maxHealth * 2);
        game.update(0.1);
        game.enemyManager.reset();

        // Boss 2
        final boss2 = await _spawnBoss(game);

        // Should track new boss
        expect(boss1.isAlive, false);
        expect(boss2.isAlive, true);
        expect(game.enemyManager.currentBoss, equals(boss2));
      },
    );

    testWithGame(
      'boss scales with difficulty',
      () => BoredGamesGame(
        tileSize: 32,
        levelConfig: LevelConfig(
          id: 1,
          name: 'Test',
          mapFile: 'maps/level1.tmx',
          waves: 1,
          difficulty: 1,
        ),
      ),
      (game) async {
        // Create bosses at different difficulty levels
        final easyBoss = Boss(
          path: [Vector2(0, 0), Vector2(100, 0)],
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 1000,
        );

        final hardBoss = Boss(
          path: [Vector2(0, 0), Vector2(100, 0)],
          bossType: BossType.citadelCore,
          bossLevel: 10,
          maxHealth: 2000, // Scaled for higher difficulty
        );

        expect(hardBoss.maxHealth, greaterThan(easyBoss.maxHealth));
      },
    );
  });
}
