import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_sim/market_sim.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upwiq/daily/daily_challenge_store.dart';
import 'package:upwiq/data/curriculum.dart';
import 'package:upwiq/format.dart';
import 'package:upwiq/game/game_scope.dart';
import 'package:upwiq/game/game_store.dart';
import 'package:upwiq/game/session_result.dart';
import 'package:upwiq/game/session_summary_screen.dart';
import 'package:upwiq/game/trading_session_screen.dart';
import 'package:upwiq/lessons/lesson_model.dart';
import 'package:upwiq/lessons/lesson_player.dart';
import 'package:upwiq/main.dart';
import 'package:upwiq/progress/progress_scope.dart';
import 'package:upwiq/progress/progress_store.dart';
import 'package:upwiq/settings/settings_store.dart';
import 'package:upwiq/theme/app_colors.dart';
import 'package:upwiq/theme/app_theme.dart';

import 'support/fonts.dart';
import 'theme_test.dart' show contrast;

void main() {
  setUpAll(loadAppFonts);

  late DateTime now;

  Future<(ProgressStore, GameStore, SettingsStore)> stores() async {
    SharedPreferences.setMockInitialValues({});
    ProgressStore.reset();
    GameStore.reset();
    SettingsStore.reset();
    return (
      await ProgressStore.load(),
      await GameStore.load(clock: () => now),
      await SettingsStore.load(),
    );
  }

  setUp(() {
    now = DateTime(2026, 11, 11, 10); // Wednesday, week 46
    // Lesson files loaded by one test must not be served from the cache to
    // the next: a cached load never completes in a new test's fake clock.
    rootBundle.clear();
  });

  void phone(WidgetTester tester, {double width = 393, double height = 851}) {
    tester.view.physicalSize = Size(width * 3, height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  group('text on green and red fills', () {
    test('uses dark ink on bright fills and white on deep ones', () {
      for (final p in [AppPalette.dark, AppPalette.light]) {
        for (final (fill, on) in [(p.up, p.onUp), (p.down, p.onDown)]) {
          expect(
            contrast(on, fill),
            greaterThanOrEqualTo(4.5),
            reason: '${p.isDark ? 'dark' : 'light'} theme, fill $fill',
          );
        }
      }
      // White on the dark theme's bright green was only about 2:1.
      expect(AppPalette.dark.onUp, isNot(Colors.white));
      expect(AppPalette.light.onUp, Colors.white);
    });
  });

  for (final palette in [AppPalette.dark, AppPalette.light]) {
    testWidgets('Close is green in profit and red in loss '
        '(${palette.isDark ? 'dark' : 'light'})', (tester) async {
      phone(tester);
      final (_, game, _) = await stores();
      await tester.pumpWidget(
        GameScope(
          store: game,
          child: MaterialApp(
            theme: buildAppTheme(palette),
            home: const TradingSessionScreen(
              market: GameMarkets.eurUsd,
              dayNumber: 272,
              ranked: false,
              startingBalance: 10000,
              tick: Duration(milliseconds: 10),
            ),
          ),
        ),
      );
      Future<void> play(int ms) async {
        await tester.tap(find.byTooltip('Play'));
        await tester.pump(Duration(milliseconds: ms));
        final pause = find.byTooltip('Pause');
        if (pause.evaluate().isNotEmpty) await tester.tap(pause);
        await tester.pump();
      }

      await play(35);
      final close = find.byKey(const Key('close-position'));
      final seen = <bool>{};
      var sellNext = false;
      for (var i = 0; i < 60 && seen.length < 2; i++) {
        if (close.evaluate().isEmpty) {
          // No open trade (first pass, or the last one hit a level): open
          // one, alternating direction so one of them ends up in profit.
          if (find.text('Floating P&L').evaluate().isEmpty) {
            if (sellNext) {
              await tester.tap(find.text('Sell'));
              await tester.pump();
            }
            sellNext = !sellNext;
            final submit = find.textContaining(
              RegExp(r'^(BUY|SELL) [0-9.]+ @'),
            );
            if (submit.evaluate().isEmpty) break; // the day is over
            await tester.ensureVisible(submit);
            await tester.tap(submit);
            await tester.pump();
          }
          continue;
        }
        final label = tester
            .widget<Text>(
              find.descendant(of: close, matching: find.byType(Text)),
            )
            .data!;
        final inProfit = !label.contains('−');
        final button = tester.widget<FilledButton>(
          find.descendant(of: close, matching: find.byType(FilledButton)),
        );
        final fill = button.style!.backgroundColor!.resolve({})!;
        final text = button.style!.foregroundColor!.resolve({})!;
        expect(
          fill,
          inProfit ? palette.up : palette.down,
          reason: 'label "$label"',
        );
        expect(contrast(text, fill), greaterThanOrEqualTo(4.5));
        seen.add(inProfit);
        await play(25);
      }
      expect(seen, {true, false}, reason: 'saw a winning and a losing trade');
    });
  }

  group('league dates', () {
    test('a week that ended while the app stayed open is settled', () async {
      now = DateTime(2026, 11, 9, 10); // Monday, week 46
      final (_, game, _) = await stores();
      for (final day in [9, 10, 11]) {
        now = DateTime(2026, 11, day, 10);
        await game.recordRankedDay(symbol: 'EURUSD', pnl: 400, trades: 1);
      }
      expect(game.seasonDaysPlayed, 3);
      final week46 = game.seasonId;

      // The app is left open; the player returns the following Tuesday.
      now = DateTime(2026, 11, 17, 9);
      expect(game.seasonId, week46, reason: 'not settled until refreshed');
      var notified = 0;
      game.addListener(() => notified++);
      await game.refresh();
      expect(game.seasonId, isNot(week46));
      expect(game.seasonDaysPlayed, 0);
      expect(game.pendingReport, isNotNull);
      expect(game.pendingReport!.seasonId, week46);
      expect(notified, greaterThan(0));
    });

    test('a session belongs to the day it started on', () async {
      final (_, game, _) = await stores();
      final startedOn = game.todayKey; // 11 November, 23:50 say
      now = DateTime(2026, 11, 12, 0, 5); // it ends after midnight
      await game.recordRankedDay(
        symbol: 'XAUUSD',
        pnl: 120,
        trades: 1,
        date: startedOn,
      );
      expect(game.seasonDays.single.date, '2026-11-11');
      expect(
        game.rankedPlayedToday,
        isFalse,
        reason: 'the 12th still has its own session',
      );
    });

    testWidgets('coming back to the app the next day shows the new day', (
      tester,
    ) async {
      phone(tester);
      final (progress, game, settings) = await stores();
      final daily = DailyChallengeStore.memory(clock: () => now);
      await daily.record(
        daily.todayKey,
        const DailyResult(chart: 100, sizing: 100, plan: 100),
      );
      await game.recordRankedDay(symbol: 'EURUSD', pnl: 50, trades: 1);
      await tester.pumpWidget(
        UpwiqApp(
          progress: progress,
          game: game,
          settings: settings,
          daily: daily,
        ),
      );
      await tester.tap(find.text('Practice'));
      await tester.pumpAndSettle();
      expect(find.text('See today\'s result'), findsOneWidget);

      // The app goes to the background overnight and is reopened.
      for (final state in const [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      now = now.add(const Duration(days: 1));
      for (final state in const [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
      expect(find.text('Start today\'s challenge'), findsOneWidget);

      await tester.tap(find.text('League'));
      await tester.pumpAndSettle();
      expect(find.text('Pick today\'s market'), findsOneWidget);
    });

    test('the daily challenge store announces a new day on refresh', () {
      final daily = DailyChallengeStore.memory(clock: () => now);
      var notified = 0;
      daily.addListener(() => notified++);
      daily.refresh();
      expect(notified, 1);
    });
  });

  group('learning path', () {
    test('counts the lessons that can be taken today', () {
      final files = Directory('assets/lessons')
          .listSync()
          .where((f) => f.path.endsWith('.json'))
          .length;
      expect(availableLessons.length, files);
      expect(availableLessons.length, 28);
      expect(availableLessons.first.lesson.id, 'L0-01');
    });

    test('next lesson: in order, skipping finished ones, wrapping', () {
      final done = <String>{};
      expect(nextLesson(done.contains)!.lesson.id, 'L0-01');
      done.addAll(['L0-01', 'L0-02']);
      expect(nextLesson(done.contains)!.lesson.id, 'L0-03');
      // After finishing the last lesson of a level, on to the next level.
      expect(nextLesson(done.contains, afterId: 'L0-07')!.lesson.id, 'L1-01');
      // From the end of the path, back to the earliest gap.
      expect(nextLesson(done.contains, afterId: 'L7-03')!.lesson.id, 'L0-03');
      done.addAll(availableLessons.map((r) => r.lesson.id!));
      expect(nextLesson(done.contains), isNull);
      expect(nextLesson(done.contains, afterId: 'L1-01'), isNull);
    });

    testWidgets('Learn offers the next lesson and honest progress', (
      tester,
    ) async {
      phone(tester);
      final (progress, game, settings) = await stores();
      await tester.pumpWidget(
        UpwiqApp(progress: progress, game: game, settings: settings),
      );
      expect(find.text('START HERE'), findsOneWidget);
      expect(find.text('0 of 28 lessons'), findsOneWidget);
      expect(
        find.text('What a market is: buyers, sellers and price'),
        findsOneWidget,
        reason: 'shown on the card while the levels are folded',
      );

      await progress.complete('L0-01', correctAnswers: 2);
      await tester.pump();
      expect(find.text('UP NEXT'), findsOneWidget);
      expect(find.text('1 of 28 lessons'), findsOneWidget);
      expect(
        find.text('Bid, ask and spread: the cost of every trade'),
        findsOneWidget,
      );

      // One tap opens it.
      await tester.tap(find.text('UP NEXT'));
      await tester.pumpAndSettle();
      expect(find.byType(LessonPlayerScreen), findsOneWidget);
      expect(find.text('There are two prices, not one'), findsOneWidget);
    });

    testWidgets('when every free lesson is done, Learn points to the Daily '
        'Challenge', (tester) async {
      phone(tester);
      final (progress, game, settings) = await stores();
      for (final ref in availableLessons) {
        await progress.complete(ref.lesson.id!, correctAnswers: 0);
      }
      await tester.pumpWidget(
        UpwiqApp(progress: progress, game: game, settings: settings),
      );
      expect(find.text('ALL FREE LESSONS DONE'), findsOneWidget);
      expect(find.text('28 of 28 lessons'), findsOneWidget);
      await tester.tap(find.text('ALL FREE LESSONS DONE'));
      await tester.pumpAndSettle();
      expect(find.text('Today\'s challenge'), findsOneWidget);
    });

    testWidgets('an opened level stays open after visiting another tab', (
      tester,
    ) async {
      phone(tester);
      final (progress, game, settings) = await stores();
      await tester.pumpWidget(
        UpwiqApp(progress: progress, game: game, settings: settings),
      );
      final lesson = find.text('Reading a candlestick');
      expect(lesson, findsNothing);
      await tester.scrollUntilVisible(find.text('Market Foundations'), 200);
      await tester.tap(find.text('Market Foundations'));
      await tester.pumpAndSettle();
      expect(lesson, findsOneWidget);

      await tester.tap(find.text('Practice'));
      await tester.pumpAndSettle();
      expect(lesson, findsNothing);
      await tester.tap(find.text('Learn'));
      await tester.pumpAndSettle();
      expect(lesson, findsOneWidget, reason: 'still open');
    });

    for (final scale in const [1.0, 1.3]) {
      testWidgets('lesson complete screen offers the next lesson and fits a '
          '320dp phone at ${(scale * 100).round()}% text', (tester) async {
        phone(tester, width: 320, height: 640);
        final (progress, _, _) = await stores();
        final lesson = LessonContent.fromJson(
          jsonDecode(File('assets/lessons/L0-07.json').readAsStringSync())
              as Map<String, dynamic>,
        );
        await tester.pumpWidget(
          ProgressScope(
            store: progress,
            child: MaterialApp(
              theme: buildAppTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: LessonPlayerScreen(
                lessonId: lesson.id,
                content: lesson,
                initialStep: lesson.steps.length - 1,
              ),
            ),
          ),
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Finish'));
        await tester.pumpAndSettle();
        expect(find.text('Lesson complete!'), findsOneWidget);
        expect(find.text('UP NEXT'), findsOneWidget);
        // The last lesson of Level 0 leads into Level 1.
        expect(
          find.text('Trends: higher highs and higher lows'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: 'layout overflow');

        final next = find.widgetWithText(FilledButton, 'Next lesson');
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pumpAndSettle();
        final player = tester.widget<LessonPlayerScreen>(
          find.byType(LessonPlayerScreen),
        );
        expect(player.lessonId, 'L1-01');
        expect(find.text('What a trend really is'), findsOneWidget);
      });
    }
  });

  test('compact money for small tiles', () {
    expect(compactMoney(10000), '\$10k');
    expect(compactMoney(10450), '\$10.4k');
    expect(compactMoney(9850.4), '\$9,850');
    expect(compactMoney(987), '\$987');
    expect(compactMoney(1240000), '\$1.2M');
    expect(compactMoney(0), '\$0');
  });

  testWidgets('Account shows the real league balance', (tester) async {
    phone(tester);
    final (progress, game, settings) = await stores();
    await game.recordRankedDay(symbol: 'EURUSD', pnl: 450, trades: 1);
    await tester.pumpWidget(
      UpwiqApp(progress: progress, game: game, settings: settings),
    );
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.text('\$10.4k'), findsOneWidget);
    expect(find.text('0/28'), findsOneWidget);
  });

  testWidgets('a practice summary offers another market', (tester) async {
    phone(tester);
    final (_, game, _) = await stores();
    final day = generateTradingDay(GameMarkets.eurUsd, 272);
    await tester.pumpWidget(
      GameScope(
        store: game,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: SessionSummaryScreen(
            result: SessionResult(
              day: day,
              trades: const [],
              startBalance: 10000,
              endBalance: 10000,
              ranked: false,
            ),
          ),
        ),
      ),
    );
    final again = find.widgetWithText(FilledButton, 'Trade another market');
    await tester.scrollUntilVisible(again, 300);
    await tester.tap(again);
    await tester.pumpAndSettle();
    expect(find.text('Practice session'), findsOneWidget);
  });
}
