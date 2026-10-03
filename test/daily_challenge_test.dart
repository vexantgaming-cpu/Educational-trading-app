import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_sim/market_sim.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upwiq/daily/daily_challenge_screen.dart';
import 'package:upwiq/daily/daily_challenge_store.dart';
import 'package:upwiq/progress/progress_scope.dart';
import 'package:upwiq/progress/progress_store.dart';
import 'package:upwiq/screens/practice_screen.dart';
import 'package:upwiq/theme/app_colors.dart';
import 'package:upwiq/theme/app_theme.dart';

import 'support/fonts.dart';

const _good = DailyResult(chart: 100, sizing: 100, plan: 85);

void main() {
  setUpAll(loadAppFonts);

  group('store', () {
    test('only the first result of a day counts', () async {
      final store = DailyChallengeStore.memory(
        clock: () => DateTime(2026, 10, 3, 9),
      );
      expect(store.todayResult, isNull);
      expect(await store.record('2026-10-03', _good), isTrue);
      expect(
        await store.record(
          '2026-10-03',
          const DailyResult(chart: 0, sizing: 0, plan: 0),
        ),
        isFalse,
      );
      expect(store.todayResult!.total, 285);
      expect(store.todayResult!.xp, 19);
      expect(store.best, 285);
    });

    test('streak counts days in a row and survives an unplayed today', () {
      var now = DateTime(2026, 10, 5, 8);
      final store = DailyChallengeStore.memory(clock: () => now);
      expect(store.streak, 0);
      store.record('2026-10-03', _good);
      store.record('2026-10-04', _good);
      expect(store.streak, 2, reason: 'today not played yet');
      store.record('2026-10-05', _good);
      expect(store.streak, 3);
      now = DateTime(2026, 10, 7, 8);
      expect(store.streak, 0, reason: 'missed the 6th');
      final week = store.lastDays(7);
      expect(week.length, 7);
      expect(week.last.$1, DateTime(2026, 10, 7));
      expect(week.where((d) => d.$2 != null).length, 3);
    });

    test('streak is counted in calendar days across a clock change', () {
      // Europe's clocks go back on 25 October 2026.
      final store = DailyChallengeStore.memory(
        clock: () => DateTime(2026, 10, 27, 0, 30),
      );
      for (final d in ['2026-10-24', '2026-10-25', '2026-10-26']) {
        store.record(d, _good);
      }
      expect(store.streak, 3);
    });

    test('next challenge at local midnight', () {
      final store = DailyChallengeStore.memory(
        clock: () => DateTime(2026, 10, 3, 22, 15),
      );
      expect(store.untilNext, const Duration(hours: 1, minutes: 45));
      expect(untilText(store.untilNext), '1 h 45 min');
    });

    test('results are saved on the device', () async {
      SharedPreferences.setMockInitialValues({});
      DailyChallengeStore.reset();
      DateTime clock() => DateTime(2026, 10, 3, 9);
      final a = await DailyChallengeStore.load(clock: clock);
      await a.record('2026-10-03', _good);
      DailyChallengeStore.reset();
      final b = await DailyChallengeStore.load(clock: clock);
      expect(b.todayResult?.total, 285);
    });
  });

  Future<(ProgressStore, DailyChallengeStore)> pump(
    WidgetTester tester,
    Widget home, {
    required DateTime now,
    double width = 393,
    double height = 851,
    double scale = 1,
    AppPalette palette = AppPalette.dark,
    DailyResult? done,
  }) async {
    tester.view.physicalSize = Size(width * 3, height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    ProgressStore.reset();
    final progress = await ProgressStore.load();
    final daily = DailyChallengeStore.memory(clock: () => now);
    if (done != null) await daily.record(DailyChallenge.dateKeyOf(now), done);
    await tester.pumpWidget(
      ProgressScope(
        store: progress,
        child: DailyScope(
          store: daily,
          child: MaterialApp(
            theme: buildAppTheme(palette),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            routes: {
              '/': (_) => home,
              dailyChallengeRoute: (_) => const DailyChallengeScreen(
                replayInterval: Duration(milliseconds: 5),
              ),
            },
          ),
        ),
      ),
    );
    await tester.pump();
    return (progress, daily);
  }

  Future<void> press(WidgetTester tester, String label) async {
    final button = find.widgetWithText(FilledButton, label);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('play a whole challenge from the Practice tab', (tester) async {
    // 5 October 2026 is challenge #5, a "spot the trend" day.
    final day = DateTime(2026, 10, 5, 9);
    final challenge = DailyChallenge.forDate(day);
    expect(challenge.chart.task, ChartTask.trend);
    final (progress, daily) = await pump(
      tester,
      const Scaffold(body: PracticeScreen()),
      now: day,
    );

    await tester.scrollUntilVisible(find.text('Start today\'s challenge'), 200);
    await press(tester, 'Start today\'s challenge');
    expect(find.text('Today\'s challenge'), findsOneWidget);
    expect(find.text('Monday 5 October'), findsOneWidget);
    await press(tester, 'Start');

    // Round 1: read the trend.
    final answer = switch (challenge.chart.trend!) {
      TrendDirection.up => 'Up',
      TrendDirection.down => 'Down',
      TrendDirection.sideways => 'Sideways',
    };
    await tester.ensureVisible(find.text(answer));
    await tester.pumpAndSettle();
    await tester.tap(find.text(answer));
    await tester.pump();
    await press(tester, 'Check');
    expect(find.text('Correct! +100'), findsOneWidget);
    await press(tester, 'Continue');

    // Round 2: size it, deliberately wrong.
    final sizing = challenge.sizing;
    final wrong = sizing.options[(sizing.answer + 1) % 4];
    await tester.ensureVisible(find.text(wrong));
    await tester.pumpAndSettle();
    await tester.tap(find.text(wrong));
    await tester.pump();
    await press(tester, 'Check');
    expect(find.text('Not quite'), findsOneWidget);
    await press(tester, 'Continue');

    // Round 3: plan the trade with the starting levels.
    await press(tester, 'Open today\'s chart');
    expect(find.text('Round 3 · Plan the trade'), findsOneWidget);
    expect(find.byTooltip('New chart'), findsNothing);
    await tester.ensureVisible(find.text('Place trade'));
    await tester.tap(find.text('Place trade'));
    for (
      var i = 0;
      i < 200 && find.text('See today\'s score').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    await press(tester, 'See today\'s score');

    final result = daily.todayResult!;
    expect(result.chart, 100);
    expect(result.sizing, 0);
    expect(result.plan, inInclusiveRange(0, 100));
    expect(find.text('${result.total}'), findsOneWidget);
    expect(find.text('+${result.xp} XP'), findsOneWidget);
    expect(progress.xp, result.xp);
    expect(find.text('1-day streak'), findsOneWidget);

    // Back on Practice, the card shows today's result.
    await press(tester, 'Done');
    expect(find.text('See today\'s result'), findsOneWidget);
    expect(
      find.textContaining('Done for today: ${result.total}'),
      findsOneWidget,
    );
  });

  testWidgets('a finished challenge opens on the results', (tester) async {
    final day = DateTime(2026, 10, 3, 9);
    final (_, daily) = await pump(
      tester,
      const Scaffold(body: PracticeScreen()),
      now: day,
    );
    await daily.record('2026-10-03', _good);
    await tester.pump();
    await tester.scrollUntilVisible(find.text('See today\'s result'), 200);
    await press(tester, 'See today\'s result');
    expect(find.text('285'), findsOneWidget);
    expect(find.text('Excellent'), findsOneWidget);
    expect(find.text('Start'), findsNothing);
  });

  for (final palette in [AppPalette.dark, AppPalette.light]) {
    for (final date in [
      DateTime(2026, 10, 5),
      DateTime(2026, 10, 6),
      DateTime(2026, 10, 8),
    ]) {
      testWidgets('rounds fit a 320dp phone at 130% text: '
          '${date.day} Oct, ${palette.isDark ? 'dark' : 'light'}', (
        tester,
      ) async {
        await pump(
          tester,
          const DailyChallengeScreen(),
          now: date.add(const Duration(hours: 9)),
          width: 320,
          height: 640,
          scale: 1.3,
          palette: palette,
        );
        expect(tester.takeException(), isNull, reason: 'intro');
        await press(tester, 'Start');
        expect(tester.takeException(), isNull, reason: 'round 1');
        final state = tester.state(find.byType(DailyChallengeScreen));
        expect(state.mounted, isTrue);
      });
    }
  }

  testWidgets('sizing round and results fit a 320dp phone at 130% text', (
    tester,
  ) async {
    final day = DateTime(2026, 10, 5, 9);
    final challenge = DailyChallenge.forDate(day);
    await pump(
      tester,
      const DailyChallengeScreen(),
      now: day,
      width: 320,
      height: 640,
      scale: 1.3,
    );
    await press(tester, 'Start');
    final trend = find.text(switch (challenge.chart.trend!) {
      TrendDirection.up => 'Up',
      TrendDirection.down => 'Down',
      TrendDirection.sideways => 'Sideways',
    });
    await tester.ensureVisible(trend);
    await tester.pumpAndSettle();
    await tester.tap(trend);
    await tester.pump();
    await press(tester, 'Check');
    await press(tester, 'Continue');
    expect(tester.takeException(), isNull, reason: 'round 2');
    final option = find.text(challenge.sizing.options.first);
    await tester.ensureVisible(option);
    await tester.pumpAndSettle();
    await tester.tap(option);
    await tester.pump();
    await press(tester, 'Check');
    expect(tester.takeException(), isNull, reason: 'round 2 feedback');
    await press(tester, 'Continue');
    expect(tester.takeException(), isNull, reason: 'round 3');
  });

  for (final palette in [AppPalette.dark, AppPalette.light]) {
    testWidgets('results fit a 320dp phone at 130% text '
        '(${palette.isDark ? 'dark' : 'light'})', (tester) async {
      await pump(
        tester,
        const DailyChallengeScreen(),
        now: DateTime(2026, 10, 5, 9),
        width: 320,
        height: 640,
        scale: 1.3,
        palette: palette,
        done: _good,
      );
      expect(find.text('285'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
