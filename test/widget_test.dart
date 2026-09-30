import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trading_academy/exercises/place_trade_exercise.dart';
import 'package:trading_academy/main.dart';
import 'package:trading_academy/progress/progress_store.dart';

void main() {
  testWidgets('home shows the learning path and navigates tabs', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    ProgressStore.reset();
    final progress = await ProgressStore.load();
    await tester.pumpWidget(TradingAcademyApp(progress: progress));
    expect(find.text('0 XP'), findsOneWidget);
    expect(find.text('Market Foundations'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Support and resistance are zones'),
      300,
    );

    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    expect(find.text('Place the trade'), findsOneWidget);
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
