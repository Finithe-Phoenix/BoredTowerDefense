import 'dart:ui' show Canvas, Offset, PictureRecorder, PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bored_games/src/services/level_service.dart';
import 'package:bored_games/src/services/storage_service.dart';
import 'package:bored_games/src/ui/screens/level_select_screen.dart';
import 'package:bored_games/src/ui/widgets/tron_button.dart';
import 'package:bored_games/src/ui/widgets/universe_graph_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void useLargeViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1920, 1080);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    StorageService.instance.resetForTesting();
    await StorageService.instance.initialize();
    LevelService.overrideUnlockAllLevels = false;
    LevelService.instance.resetForTesting();
  });

  tearDown(() {
    LevelService.overrideUnlockAllLevels = null;
    LevelService.instance.resetForTesting();
    StorageService.instance.resetForTesting();
  });

  Future<void> openWorldGrid(WidgetTester tester, {int worldId = 1}) async {
    final graphFinder = find.byType(UniverseGraphWidget);
    expect(graphFinder, findsOneWidget);
    final graph = tester.widget<UniverseGraphWidget>(graphFinder);
    graph.onWorldSelected(worldId);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  Finder levelCards() {
    return find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_TronLevelCard',
    );
  }

  Future<void> setViewport(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('LevelSelectScreen switches to level grid after selection',
      (tester) async {
    useLargeViewport(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: LevelSelectScreen(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    await openWorldGrid(tester);

    expect(find.byKey(const ValueKey('level_grid')), findsOneWidget);
  });

  testWidgets('LevelSelectScreen BACK returns to world selection',
      (tester) async {
    useLargeViewport(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: LevelSelectScreen(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await openWorldGrid(tester);

    expect(find.byKey(const ValueKey('level_grid')), findsOneWidget);

    final backButton = find.text('BACK');
    await tester.ensureVisible(backButton);
    await tester.tap(backButton, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(UniverseGraphWidget), findsWidgets);
  });

  testWidgets('LevelSelectScreen BACK callback returns to world selection',
      (tester) async {
    useLargeViewport(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: LevelSelectScreen(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await openWorldGrid(tester);
    expect(find.byKey(const ValueKey('level_grid')), findsOneWidget);

    final backButton =
        tester.widget<TronButton>(find.widgetWithText(TronButton, 'BACK'));
    backButton.onPressed();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(UniverseGraphWidget), findsWidgets);
  });

  testWidgets('LevelSelectScreen shows locked snackbar for unavailable level',
      (tester) async {
    useLargeViewport(tester);
    expect(LevelService.instance.isLevelUnlocked(2), isFalse);

    await tester.pumpWidget(
      const MaterialApp(
        home: LevelSelectScreen(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await openWorldGrid(tester);

    final cards = levelCards();
    expect(cards.evaluate().length, greaterThanOrEqualTo(2));

    await tester.ensureVisible(cards.at(1));
    await tester.tap(cards.at(1), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Level 2 is locked'), findsOneWidget);
  });

  testWidgets('LevelSelectScreen navigates to game for unlocked level',
      (tester) async {
    useLargeViewport(tester);
    int? capturedLevelId;

    await tester.pumpWidget(
      MaterialApp(
        home: const LevelSelectScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == '/game') {
            capturedLevelId = settings.arguments as int?;
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('GAME_SCREEN')),
            );
          }
          return null;
        },
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await openWorldGrid(tester);

    final cards = levelCards();
    expect(cards, findsWidgets);

    await tester.ensureVisible(cards.first);
    await tester.tap(cards.first, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('GAME_SCREEN'), findsOneWidget);
    expect(capturedLevelId, 1);
  });

  testWidgets('LevelSelectScreen RETURN button pops route from world view',
      (tester) async {
    useLargeViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LevelSelectScreen(),
                    ),
                  );
                },
                child: const Text('OPEN LEVELS'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN LEVELS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(LevelSelectScreen), findsOneWidget);

    final returnButton =
        tester.widget<TronButton>(find.widgetWithText(TronButton, 'RETURN'));
    expect(() => returnButton.onPressed(), returnsNormally);
    await tester.pump();
  });

  testWidgets('LevelSelectScreen responsive grid columns by viewport width',
      (tester) async {
    Future<int> extractColumns(Size size) async {
      await setViewport(tester, size);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpWidget(
        MaterialApp(
          home: LevelSelectScreen(key: ValueKey('screen-${size.width}')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await openWorldGrid(tester);
      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      return delegate.crossAxisCount;
    }

    expect(await extractColumns(const Size(1500, 900)), 5);
    expect(await extractColumns(const Size(1200, 900)), 4);
    expect(await extractColumns(const Size(850, 900)), 3);
    expect(await extractColumns(const Size(650, 900)), 2);
  });

  testWidgets('Level cards animate hover, click, completed and locked states',
      (tester) async {
    useLargeViewport(tester);
    await LevelService.instance.updateProgress(
      levelId: 1,
      completed: true,
      score: 9000,
      wavesCleared: 5,
      livesRemaining: 25,
      maxLives: 25,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: const LevelSelectScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == '/game') {
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('GAME_FALLBACK')),
            );
          }
          return null;
        },
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await openWorldGrid(tester);
    await tester.pump(const Duration(milliseconds: 1300));

    final cards = levelCards();
    expect(cards.evaluate().length, greaterThanOrEqualTo(3));

    final unlockedCompleted = cards.at(0);
    final locked = cards.at(2);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(0, 0));
    await mouse.moveTo(tester.getCenter(unlockedCompleted));
    await tester.pump(const Duration(milliseconds: 200));

    final click =
        await tester.startGesture(tester.getCenter(unlockedCompleted));
    await tester.pump(const Duration(milliseconds: 120));
    await click.cancel();
    await tester.pump(const Duration(milliseconds: 250));

    await mouse.moveTo(const Offset(5, 5));
    await tester.pump(const Duration(milliseconds: 120));

    await tester.tap(locked, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Level 3 is locked'), findsOneWidget);
  });

  testWidgets(
      'Level card painter covers wireframe and particle branches during construction',
      (tester) async {
    useLargeViewport(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: LevelSelectScreen(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await openWorldGrid(tester);

    Future<void> paintFirstCardPainter() async {
      final cardPaint = find
          .descendant(
            of: levelCards().first,
            matching: find.byType(CustomPaint),
          )
          .first;
      final customPaint = tester.widget<CustomPaint>(cardPaint);
      final painter = customPaint.painter!;
      final size = tester.renderObject<RenderBox>(cardPaint).size;
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, size);
      recorder.endRecording();
    }

    // Progress <= 0.6 branch in wireframe fade + trail + particles.
    await tester.pump(const Duration(milliseconds: 220));
    await paintFirstCardPainter();

    // 0.6 < progress < 0.9 branch in wireframe fade interpolation.
    await tester.pump(const Duration(milliseconds: 260));
    await paintFirstCardPainter();
  });

  testWidgets('Level card painter covers text cache and empty star outlines',
      (tester) async {
    useLargeViewport(tester);
    await LevelService.instance.updateProgress(
      levelId: 1,
      completed: true,
      score: 5000,
      wavesCleared: 5,
      livesRemaining: 10,
      maxLives: 25,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: LevelSelectScreen(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await openWorldGrid(tester);
    await tester.pump(const Duration(milliseconds: 1300));

    final cardPaint = find
        .descendant(
          of: levelCards().first,
          matching: find.byType(CustomPaint),
        )
        .first;
    final customPaint = tester.widget<CustomPaint>(cardPaint);
    final painter = customPaint.painter!;
    final size = tester.renderObject<RenderBox>(cardPaint).size;

    // Paint twice using same painter instance to hit text cache comparison
    // branches (_levelNumberColorValue/_levelNumberFontSize checks).
    final recorderA = PictureRecorder();
    painter.paint(Canvas(recorderA), size);
    recorderA.endRecording();

    final recorderB = PictureRecorder();
    painter.paint(Canvas(recorderB), size);
    recorderB.endRecording();
  });

  test('EpicLevelCardPainter covers wireframe and particle branches directly',
      () {
    final constructionPainter = EpicLevelCardPainter(
      progress: 0.35,
      pulseValue: 0.62,
      primaryColor: Colors.cyan,
      isHovered: true,
      isCompleted: false,
      isLocked: false,
      levelNumber: 3,
      stars: 0,
      hoverProgress: 0.7,
      clickProgress: 0.4,
    );

    final recorderA = PictureRecorder();
    constructionPainter.paint(Canvas(recorderA), const Size(140, 140));
    recorderA.endRecording();

    final interpolationPainter = EpicLevelCardPainter(
      progress: 0.75,
      pulseValue: 0.25,
      primaryColor: Colors.cyan,
      isHovered: true,
      isCompleted: false,
      isLocked: false,
      levelNumber: 3,
      stars: 0,
      hoverProgress: 0.5,
      clickProgress: 0.2,
    );

    final recorderB = PictureRecorder();
    interpolationPainter.paint(Canvas(recorderB), const Size(140, 140));
    recorderB.endRecording();
  });

  test('EpicLevelCardPainter reuses level text cache and draws empty stars',
      () {
    final completedPainter = EpicLevelCardPainter(
      progress: 0.95,
      pulseValue: 0.4,
      primaryColor: Colors.cyan,
      isHovered: false,
      isCompleted: true,
      isLocked: false,
      levelNumber: 7,
      stars: 1,
      hoverProgress: 0.3,
      clickProgress: 0.1,
    );

    final recorderA = PictureRecorder();
    completedPainter.paint(Canvas(recorderA), const Size(140, 140));
    recorderA.endRecording();

    // Paint again with same painter instance to exercise cached comparison
    // branches for color/font-size checks.
    final recorderB = PictureRecorder();
    completedPainter.paint(Canvas(recorderB), const Size(140, 140));
    recorderB.endRecording();
  });

  test('WorldProgress stores constructor values', () {
    const progress = WorldProgress(total: 10, completed: 4, stars: 7);
    expect(progress.total, 10);
    expect(progress.completed, 4);
    expect(progress.stars, 7);
  });
}
