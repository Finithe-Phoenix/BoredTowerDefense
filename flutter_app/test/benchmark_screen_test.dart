import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/bloc/settings/settings_cubit.dart';
import 'package:bored_games/src/game/bored_games_game.dart';
import 'package:bored_games/src/game/entities/tower.dart';
import 'package:bored_games/src/game/managers/bullet_manager.dart';
import 'package:bored_games/src/game/managers/enemy_manager.dart';
import 'package:bored_games/src/game/managers/tower_manager.dart';
import 'package:bored_games/src/game/world/game_world.dart';
import 'package:bored_games/src/ui/screens/benchmark_screen.dart';
import 'package:bored_games/src/ui/widgets/tron_button.dart';

class _FakeWorld extends GameWorld {
  _FakeWorld({
    required double tileSize,
    this.singleBuildableCell = false,
  }) : super(
          tileSize: tileSize,
          mapFile: 'assets/tiles/maps/level_01.tmx',
        ) {
    waypoints = <Vector2>[
      Vector2(tileSize * 2, tileSize * 2),
      Vector2(tileSize * 8, tileSize * 2),
      Vector2(tileSize * 8, tileSize * 8),
    ];
    if (singleBuildableCell) {
      isBuildable = List<List<bool>>.generate(
        20,
        (_) => List<bool>.filled(20, false),
      );
      isBuildable[2][2] = true;
    } else {
      isBuildable = List<List<bool>>.generate(
        20,
        (_) => List<bool>.filled(20, true),
      );
    }
  }

  final bool singleBuildableCell;

  @override
  Future<void> onLoad() async {}
}

class _FakeTowerManager extends TowerManager {
  _FakeTowerManager({required super.tileSize, required super.world});

  int placementsAttempted = 0;
  int failBeforeSuccess = 0;

  @override
  bool placeTower(Vector2 worldPos) {
    placementsAttempted++;
    return placementsAttempted > failBeforeSuccess;
  }
}

class _FakeEnemyManager extends EnemyManager {
  _FakeEnemyManager({required super.tileSize, required super.world});

  int aliveValue = 0;
  int waveValue = 1;
  bool spawningValue = false;

  @override
  int get aliveCount => aliveValue;

  @override
  int get currentWave => waveValue;

  @override
  bool get spawning => spawningValue;

  @override
  set spawning(bool value) => spawningValue = value;
}

class _FakeBulletManager extends BulletManager {
  int activeCountValue = 0;

  @override
  int get activeCount => activeCountValue;
}

class _FakeBenchmarkGame extends BoredGamesGame {
  _FakeBenchmarkGame({
    required this.fakeWorld,
    required this.fakeEnemyManager,
    required this.fakeTowerManager,
    required this.fakeBulletManager,
  }) : super(tileSize: 32);

  final _FakeWorld fakeWorld;
  final _FakeEnemyManager fakeEnemyManager;
  final _FakeTowerManager fakeTowerManager;
  final _FakeBulletManager fakeBulletManager;

  bool loadedValue = true;
  int startWaveCalls = 0;
  int lastStartWaveCount = 0;
  int towerCostValue = 50;
  double dtValue = 0.016;
  int _goldValue = 999999;
  int _scoreValue = 0;
  double _timeScaleValue = 1.0;
  final List<String> qualityCalls = <String>[];
  final List<double> particleCalls = <double>[];

  @override
  bool get isLoaded => loadedValue;

  @override
  GameWorld get worldLayer => fakeWorld;

  @override
  EnemyManager get enemyManager => fakeEnemyManager;

  @override
  TowerManager get towerManager => fakeTowerManager;

  @override
  BulletManager get bulletManager => fakeBulletManager;

  @override
  int get gold => _goldValue;

  @override
  set gold(int value) => _goldValue = value;

  @override
  int get score => _scoreValue;

  @override
  set score(int value) => _scoreValue = value;

  @override
  double get dt => dtValue;

  @override
  int towerCost(TowerType type) => towerCostValue;

  @override
  double get timeScale => _timeScaleValue;

  @override
  set timeScale(double value) => _timeScaleValue = value;

  @override
  void setGraphicsQualityFromSettings(String quality) {
    qualityCalls.add(quality);
  }

  @override
  void setParticleIntensityFromSettings(double intensity) {
    particleCalls.add(intensity);
  }

  @override
  void startWave({int count = 10}) {
    startWaveCalls++;
    lastStartWaveCount = count;
    fakeEnemyManager.waveValue += 1;
    fakeEnemyManager.aliveValue += count;
    _scoreValue += count * 10;
    fakeBulletManager.activeCountValue = count;
  }

  @override
  Future<void> onLoad() async {}

  @override
  void update(double dt) {
    dtValue = dt;
  }
}

void main() {
  void useLargeViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1920, 1080);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<void> pumpBenchmarkScreen(WidgetTester tester) async {
    useLargeViewport(tester);
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => SettingsCubit(),
        child: const MaterialApp(
          home: BenchmarkScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
  }

  Future<void> disposeScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
  }

  Future<_FakeBenchmarkGame> pumpFakeBenchmarkScreen(
    WidgetTester tester, {
    int failBeforeSuccess = 0,
    int initialEnemies = 0,
    bool spawning = false,
    int towerCost = 50,
    int startingGold = 999999,
    bool singleBuildableCell = false,
  }) async {
    useLargeViewport(tester);
    final fakeWorld = _FakeWorld(
      tileSize: 32,
      singleBuildableCell: singleBuildableCell,
    );
    final fakeEnemyManager = _FakeEnemyManager(tileSize: 32, world: fakeWorld)
      ..aliveValue = initialEnemies
      ..spawningValue = spawning;
    final fakeTowerManager = _FakeTowerManager(tileSize: 32, world: fakeWorld)
      ..failBeforeSuccess = failBeforeSuccess;
    final fakeBulletManager = _FakeBulletManager();
    final fakeGame = _FakeBenchmarkGame(
      fakeWorld: fakeWorld,
      fakeEnemyManager: fakeEnemyManager,
      fakeTowerManager: fakeTowerManager,
      fakeBulletManager: fakeBulletManager,
    )
      ..towerCostValue = towerCost
      ..gold = startingGold;

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => SettingsCubit(),
        child: MaterialApp(
          home: BenchmarkScreen(
            gameFactory: (_, __) => fakeGame,
            settingsApplyDelay: const Duration(milliseconds: 1),
            gameReadyDelay: const Duration(milliseconds: 1),
            benchmarkStartDelay: const Duration(milliseconds: 50),
            autoPlayInterval: const Duration(milliseconds: 20),
            statsInterval: const Duration(milliseconds: 10),
            uiUpdateInterval: const Duration(milliseconds: 50),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    return fakeGame;
  }

  testWidgets('BenchmarkScreen renders start state', (tester) async {
    await pumpBenchmarkScreen(tester);

    expect(find.text('BENCHMARK MODE'), findsOneWidget);
    expect(
        find.widgetWithText(TronButton, 'INICIAR BENCHMARK'), findsOneWidget);

    await disposeScreen(tester);
  });

  testWidgets('BenchmarkScreen shows benchmark feature summary',
      (tester) async {
    await pumpBenchmarkScreen(tester);

    expect(find.text('Sistema de prueba de rendimiento'), findsOneWidget);
    expect(find.text('Torres automáticas'), findsOneWidget);
    expect(find.text('Oleadas progresivas'), findsOneWidget);
    expect(find.text('Estadísticas en tiempo real'), findsOneWidget);
    expect(find.text('Test de estrés del dispositivo'), findsOneWidget);
    expect(find.widgetWithText(TronButton, 'VOLVER'), findsOneWidget);

    await disposeScreen(tester);
  });

  testWidgets('BenchmarkScreen can start and stop to show results overlay',
      (tester) async {
    await pumpBenchmarkScreen(tester);

    await tester.tap(find.widgetWithText(TronButton, 'INICIAR BENCHMARK'));
    await tester.pump();

    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.stop_rounded));
    await tester.pump();

    expect(find.text('BENCHMARK COMPLETO'), findsOneWidget);
    expect(find.textContaining('GRADO:'), findsOneWidget);
    expect(find.widgetWithText(TronButton, 'REINTENTAR'), findsOneWidget);
    expect(find.widgetWithText(TronButton, 'SALIR'), findsOneWidget);

    // Drain delayed startup timer scheduled by _startBenchmark.
    await tester.pump(const Duration(milliseconds: 1600));

    await disposeScreen(tester);
  });

  testWidgets('BenchmarkScreen VOLVER button pops route', (tester) async {
    useLargeViewport(tester);
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => SettingsCubit(),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BenchmarkScreen(),
                      ),
                    );
                  },
                  child: const Text('OPEN BENCHMARK'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN BENCHMARK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(BenchmarkScreen), findsOneWidget);

    final backButton = find.widgetWithText(TronButton, 'VOLVER');
    await tester.ensureVisible(backButton);
    await tester.tap(backButton, warnIfMissed: false);
    await tester.pump();

    var popped = false;
    for (int i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(BenchmarkScreen).evaluate().isEmpty) {
        popped = true;
        break;
      }
    }

    expect(popped, isTrue);
    expect(find.text('OPEN BENCHMARK'), findsOneWidget);
  });

  testWidgets('BenchmarkScreen top-right back icon pops route', (tester) async {
    useLargeViewport(tester);
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => SettingsCubit(),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BenchmarkScreen(),
                      ),
                    );
                  },
                  child: const Text('OPEN BENCHMARK'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN BENCHMARK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(BenchmarkScreen), findsOneWidget);

    final iconBack = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.arrow_back_rounded));
    iconBack.onPressed?.call();
    await tester.pump();
    for (int i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(BenchmarkScreen).evaluate().isEmpty) break;
    }

    expect(find.byType(BenchmarkScreen), findsNothing);
    expect(find.text('OPEN BENCHMARK'), findsOneWidget);
  });

  testWidgets(
      'BenchmarkScreen running overlay supports speed controls and stop flow',
      (tester) async {
    await pumpBenchmarkScreen(tester);

    await tester.tap(find.widgetWithText(TronButton, 'INICIAR BENCHMARK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1800));

    expect(find.text('BENCHMARK'), findsOneWidget);
    expect(find.text('x1'), findsOneWidget);
    expect(find.text('x2'), findsOneWidget);
    expect(find.text('x5'), findsOneWidget);

    await tester.tap(find.text('x2'));
    await tester.pump();
    await tester.tap(find.text('x5'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('TIME'), findsOneWidget);
    expect(find.text('FPS'), findsOneWidget);
    expect(find.text('WAVE'), findsOneWidget);
    expect(find.text('TWR'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.stop_rounded));
    await tester.pump();
    expect(find.text('BENCHMARK COMPLETO'), findsOneWidget);

    // Drain delayed timers safely before teardown.
    await tester.pump(const Duration(milliseconds: 2000));
    await disposeScreen(tester);
  });

  testWidgets('BenchmarkScreen REINTENTAR returns to start screen',
      (tester) async {
    await pumpBenchmarkScreen(tester);

    await tester.tap(find.widgetWithText(TronButton, 'INICIAR BENCHMARK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.tap(find.byIcon(Icons.stop_rounded));
    await tester.pump();

    expect(find.text('BENCHMARK COMPLETO'), findsOneWidget);
    final retryButton = tester
        .widget<TronButton>(find.widgetWithText(TronButton, 'REINTENTAR'));
    retryButton.onPressed();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('BENCHMARK MODE'), findsOneWidget);
    expect(
        find.widgetWithText(TronButton, 'INICIAR BENCHMARK'), findsOneWidget);
    await disposeScreen(tester);
  });

  testWidgets('BenchmarkScreen SALIR button pops route from results',
      (tester) async {
    useLargeViewport(tester);
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => SettingsCubit(),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BenchmarkScreen(),
                      ),
                    );
                  },
                  child: const Text('OPEN BENCHMARK'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN BENCHMARK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.tap(find.widgetWithText(TronButton, 'INICIAR BENCHMARK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.tap(find.byIcon(Icons.stop_rounded));
    await tester.pump();
    expect(find.text('BENCHMARK COMPLETO'), findsOneWidget);

    final exitButton =
        tester.widget<TronButton>(find.widgetWithText(TronButton, 'SALIR'));
    exitButton.onPressed();
    await tester.pump();
    for (int i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(BenchmarkScreen).evaluate().isEmpty) break;
    }

    expect(find.byType(BenchmarkScreen), findsNothing);
    expect(find.text('OPEN BENCHMARK'), findsOneWidget);
  });

  testWidgets(
      'BenchmarkScreen fake game drives autoplay, wave spawn, and stats updates',
      (tester) async {
    final fakeGame = await pumpFakeBenchmarkScreen(
      tester,
      initialEnemies: 0,
      spawning: false,
    );

    final startButton = tester.widget<TronButton>(
        find.widgetWithText(TronButton, 'INICIAR BENCHMARK'));
    startButton.onPressed();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1400));

    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
    expect(fakeGame.qualityCalls, isNotEmpty);
    expect(fakeGame.particleCalls, isNotEmpty);
    expect(fakeGame.fakeTowerManager.placementsAttempted, greaterThan(0));
    expect(fakeGame.startWaveCalls, greaterThan(0));
    expect(fakeGame.lastStartWaveCount, lessThanOrEqualTo(40));
    expect(find.text('TIME'), findsOneWidget);
    expect(find.text('FPS'), findsOneWidget);

    final stopButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.stop_rounded));
    stopButton.onPressed?.call();
    await tester.pump();
    expect(find.text('BENCHMARK COMPLETO'), findsOneWidget);
    await disposeScreen(tester);
  });

  testWidgets('BenchmarkScreen fake game exercises random fallback placement',
      (tester) async {
    final fakeGame = await pumpFakeBenchmarkScreen(
      tester,
      failBeforeSuccess: 1,
      initialEnemies: 0,
      spawning: false,
      singleBuildableCell: true,
    );

    final startButton = tester.widget<TronButton>(
        find.widgetWithText(TronButton, 'INICIAR BENCHMARK'));
    startButton.onPressed();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(fakeGame.fakeTowerManager.placementsAttempted, greaterThan(1));
    final stopButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.stop_rounded));
    stopButton.onPressed?.call();
    await tester.pump();
    await disposeScreen(tester);
  });

  testWidgets('BenchmarkScreen fake game covers insufficient-gold tower skip',
      (tester) async {
    final fakeGame = await pumpFakeBenchmarkScreen(
      tester,
      towerCost: 100,
      startingGold: 50,
      initialEnemies: 0,
      spawning: false,
    );

    final startButton = tester.widget<TronButton>(
        find.widgetWithText(TronButton, 'INICIAR BENCHMARK'));
    startButton.onPressed();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(fakeGame.fakeTowerManager.placementsAttempted, 0);
    expect(fakeGame.startWaveCalls, greaterThan(0));
    final stopButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.stop_rounded));
    stopButton.onPressed?.call();
    await tester.pump();
    await disposeScreen(tester);
  });
}
