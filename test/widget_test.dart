import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upwiq/exercises/place_trade_exercise.dart';
import 'package:upwiq/game/game_store.dart';
import 'package:upwiq/main.dart';
import 'package:upwiq/progress/progress_store.dart';
import 'package:upwiq/settings/settings_store.dart';

void main() {
  testWidgets('levels start folded, open on tap, and tabs navigate', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    ProgressStore.reset();
    GameStore.reset();
    final progress = await ProgressStore.load();
    final game = await GameStore.load(clock: () => DateTime(2026, 9, 30, 10));
    SettingsStore.reset();
    final settings = await SettingsStore.load();
    await tester.pumpWidget(
      UpwiqApp(progress: progress, game: game, settings: settings),
    );
    expect(find.text('0 XP'), findsOneWidget);
    expect(find.text('Market Foundations'), findsOneWidget);

    // Lessons are hidden until the level is opened.
    final lesson = find.text('Support and resistance are zones');
    expect(lesson, findsNothing);
    await tester.scrollUntilVisible(find.text('Market Structure'), 300);
    await tester.tap(find.text('Market Structure'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(lesson, 200);
    expect(lesson, findsOneWidget);

    // Level 7 exists and shows its free lessons badge.
    await tester.scrollUntilVisible(find.text('Trading Psychology'), 300);
    expect(find.text('3 free'), findsOneWidget);

    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    expect(find.text('Place the trade'), findsOneWidget);

    await tester.tap(find.text('League'));
    await tester.pumpAndSettle();
    expect(find.text('Bronze'), findsWidgets);
    expect(find.text('Pick today\'s market'), findsOneWidget);

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Rookie'), findsOneWidget);
  });

  testWidgets('place-the-trade exercise runs to a scored result', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: PlaceTradeExercise(replayInterval: Duration(milliseconds: 10)),
      ),
    );
    expect(find.text('Reward : risk'), findsOneWidget);
    expect(
      find.text('1.0 : 1'),
      findsOneWidget,
      reason: 'starts with a cramped 1:1 plan',
    );

    await tester.ensureVisible(find.text('Place trade'));
    await tester.tap(find.text('Place trade'));
    await tester.pump();
    expect(find.textContaining('Trade running'), findsOneWidget);

    for (
      var i = 0;
      i < 80 && find.textContaining('Plan score').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(find.textContaining('Plan score'), findsOneWidget);
    expect(find.text('Try another chart'), findsOneWidget);
  });

  testWidgets('switching to short moves the levels to the short side', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: PlaceTradeExercise()));
    await tester.tap(find.text('Short (sell)'));
    await tester.pump();
    // Levels are re-seeded on the correct side, so the plan is still valid.
    expect(find.text('1.0 : 1'), findsOneWidget);
    await tester.ensureVisible(find.text('Place trade'));
    await tester.tap(find.text('Place trade'));
    await tester.pump();
    expect(find.textContaining('Trade running'), findsOneWidget);
  });
}
