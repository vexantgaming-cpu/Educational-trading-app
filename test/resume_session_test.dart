import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_sim/market_sim.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upwiq/game/game_scope.dart';
import 'package:upwiq/game/game_store.dart';
import 'package:upwiq/game/league_screen.dart';
import 'package:upwiq/game/trading_session_screen.dart';
import 'package:upwiq/main.dart';
import 'package:upwiq/progress/progress_store.dart';
import 'package:upwiq/settings/settings_store.dart';
import 'package:upwiq/theme/app_theme.dart';

import 'support/fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  late DateTime now;
  setUp(() {
    now = DateTime(2026, 11, 11, 10); // Wednesday, week 46
    rootBundle.clear();
  });

  /// Stores as a fresh install has them, or as the phone has them after the
  /// app was closed ([keepSaved]: read what is already on "disk").
  Future<(ProgressStore, GameStore, SettingsStore)> stores({
    bool keepSaved = false,
  }) async {
    if (!keepSaved) {
      SharedPreferences.setMockInitialValues({'welcome_seen': true});
    }
    ProgressStore.reset();
    GameStore.reset();
    SettingsStore.reset();
    return (
      await ProgressStore.load(),
      await GameStore.load(clock: () => now),
      await SettingsStore.load(),
    );
  }

  void phone(WidgetTester tester, {double width = 393, double height = 851}) {
    tester.view.physicalSize = Size(width * 3, height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  /// A session with one open trade, a few candles into the day.
  SavedSession sessionWithOpenTrade({String startedOn = '2026-11-11'}) {
    final day = generateTradingDay(GameMarkets.eurUsd, 314);
    final engine = SavedSession.newEngine(day, 10000);
    for (var i = 0; i < 6; i++) {
      engine.step();
    }
    final order = OrderRequest(
      side: Side.long,
      quantity: 0.5,
      stopLoss: GameMarkets.eurUsd.spec.roundPrice(engine.ask - 0.0030),
    );
    engine.submit(order);
    final at = engine.currentIndex;
    for (var i = 0; i < 4; i++) {
      engine.step();
    }
    return SavedSession(
      symbol: 'EURUSD',
      dayNumber: 314,
      ranked: true,
      startingBalance: 10000,
      startedOn: startedOn,
      index: engine.currentIndex,
      actions: [SubmitOrder(at, order)],
    );
  }

  group('league store', () {
    test('keeps the session in progress across an app restart', () async {
      final (_, game, _) = await stores();
      expect(game.rankedSession, isNull);
      var notified = 0;
      game.addListener(() => notified++);
      final saved = sessionWithOpenTrade();
      await game.saveRankedSession(saved);
      await game.saveRankedSession(saved);
      expect(notified, 1, reason: 'announced once, not on every candle');

      final (_, again, _) = await stores(keepSaved: true);
      final restored = again.rankedSession!;
      expect(restored.symbol, 'EURUSD');
      expect(restored.index, saved.index);
      expect(restored.actions, hasLength(1));
      expect(restored.restore().position, isNotNull);
      expect(again.rankedPlayedToday, isFalse);
    });

    test('recording the day or resetting the account clears it', () async {
      final (_, game, _) = await stores();
      await game.saveRankedSession(sessionWithOpenTrade());
      await game.recordRankedDay(symbol: 'EURUSD', pnl: 40, trades: 1);
      expect(game.rankedSession, isNull);
      var (_, again, _) = await stores(keepSaved: true);
      expect(again.rankedSession, isNull);
      expect(again.rankedPlayedToday, isTrue);

      await again.saveRankedSession(sessionWithOpenTrade());
      await again.resetAccount();
      expect(again.rankedSession, isNull);
      (_, again, _) = await stores(keepSaved: true);
      expect(again.rankedSession, isNull);
    });

    test('a damaged save is dropped instead of breaking the app', () async {
      for (final junk in [
        'not json',
        '{"symbol":"NOPE"}',
        jsonEncode({
          ...sessionWithOpenTrade().toJson(),
          'actions': [
            {'a': 'close', 'i': 80},
          ],
        }),
      ]) {
        SharedPreferences.setMockInitialValues({
          'welcome_seen': true,
          'ranked_session_v1': junk,
        });
        final (_, game, _) = await stores(keepSaved: true);
        expect(game.rankedSession, isNull, reason: junk);
        expect(game.balance, 10000);
      }
    });

    test(
      'a session left unfinished last week is settled into that week',
      () async {
        now = DateTime(2026, 11, 9, 10); // Monday
        final (_, game, _) = await stores();
        await game.recordRankedDay(symbol: 'XAUUSD', pnl: 100, trades: 1);
        now = DateTime(2026, 11, 11, 10);
        final saved = sessionWithOpenTrade();
        final expected = saved.settle();
        expect(expected.trades, 1);
        await game.saveRankedSession(saved);

        // Opened again the following week.
        now = DateTime(2026, 11, 17, 9);
        final (_, later, _) = await stores(keepSaved: true);
        expect(later.rankedSession, isNull);
        expect(later.balance, closeTo(10100 + expected.pnl, 1e-6));
        expect(later.pendingReport, isNotNull, reason: 'last week was settled');
        expect(later.seasonDaysPlayed, 0, reason: 'a fresh week');
        expect(later.rankedPlayedToday, isFalse);
      },
    );
  });

  Future<void> play(WidgetTester tester, {int candles = 3}) async {
    await tester.tap(find.byTooltip('Play'));
    // 700 ms per candle at normal speed.
    await tester.pump(Duration(milliseconds: 700 * candles + 50));
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
  }

  Future<void> startRanked(WidgetTester tester) async {
    await tester.tap(find.text('League'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pick today\'s market'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EUR/USD'));
    await tester.pumpAndSettle();
    expect(find.byType(TradingSessionScreen), findsOneWidget);
  }

  String clockShown(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .firstWhere((t) => RegExp(r'^\d\d:\d\d$').hasMatch(t));

  testWidgets('a ranked session survives the app being closed', (tester) async {
    phone(tester);
    var (progress, game, settings) = await stores();
    await tester.pumpWidget(
      UpwiqApp(progress: progress, game: game, settings: settings),
    );
    await startRanked(tester);
    expect(
      game.rankedSession,
      isNotNull,
      reason: 'saved as soon as the market is chosen',
    );

    await play(tester);
    final buy = find.textContaining(RegExp(r'^BUY [0-9.]+ @'));
    await tester.ensureVisible(buy);
    await tester.tap(buy);
    await tester.pump();
    await play(tester, candles: 2);
    await tester.pumpAndSettle();
    expect(find.text('Floating P&L'), findsOneWidget);
    final time = clockShown(tester);
    final index = game.rankedSession!.index;
    expect(game.rankedSession!.actions.whereType<SubmitOrder>(), hasLength(1));

    // The phone closes the app. Next launch: everything is read from disk.
    (progress, game, settings) = await stores(keepSaved: true);
    await tester.pumpWidget(
      UpwiqApp(
        key: UniqueKey(),
        progress: progress,
        game: game,
        settings: settings,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Resume your ranked session?'), findsOneWidget);
    expect(find.textContaining('EUR/USD, paused at $time'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Resume'));
    await tester.pumpAndSettle();

    expect(find.byType(TradingSessionScreen), findsOneWidget);
    expect(clockShown(tester), time, reason: 'same candle as before');
    expect(find.text('Floating P&L'), findsOneWidget, reason: 'trade is open');
    expect(game.rankedSession!.index, index);

    // It keeps going from there and counts once it ends.
    await play(tester, candles: 2);
    expect(game.rankedSession!.index, greaterThan(index));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Leave the session?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'End session'));
    await tester.pumpAndSettle();
    expect(find.text('RANKED SESSION'), findsOneWidget);
    expect(game.rankedSession, isNull);
    expect(game.rankedPlayedToday, isTrue);
    expect(game.seasonDays.single.trades, 1);
    expect(game.seasonDays.single.date, '2026-11-11');
  });

  testWidgets('pause a ranked session and resume it from the League tab', (
    tester,
  ) async {
    phone(tester);
    final (progress, game, settings) = await stores();
    await tester.pumpWidget(
      UpwiqApp(progress: progress, game: game, settings: settings),
    );
    await startRanked(tester);
    await play(tester);
    final time = clockShown(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Pause'));
    await tester.pumpAndSettle();

    // Back on the League tab: the day is not over and can't be restarted.
    expect(find.byType(TradingSessionScreen), findsNothing);
    expect(find.text('Session in progress'), findsOneWidget);
    expect(find.textContaining('EUR/USD, paused at $time'), findsOneWidget);
    expect(find.text('Pick today\'s market'), findsNothing);
    expect(game.rankedPlayedToday, isFalse);
    expect(game.seasonDays, isEmpty);

    await tester.tap(find.widgetWithText(FilledButton, 'Resume session'));
    await tester.pumpAndSettle();
    expect(find.byType(TradingSessionScreen), findsOneWidget);
    expect(clockShown(tester), time);
  });

  testWidgets('"Later" keeps the session for the League tab', (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues({
      'welcome_seen': true,
      'ranked_session_v1': jsonEncode(sessionWithOpenTrade().toJson()),
    });
    final (progress, game, settings) = await stores(keepSaved: true);
    await tester.pumpWidget(
      UpwiqApp(progress: progress, game: game, settings: settings),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Later'));
    await tester.pumpAndSettle();
    expect(find.byType(TradingSessionScreen), findsNothing);
    expect(game.rankedSession, isNotNull);

    await tester.tap(find.text('League'));
    await tester.pumpAndSettle();
    expect(find.text('Resume session'), findsOneWidget);
    // Switching tabs doesn't ask again.
    await tester.tap(find.text('Learn'));
    await tester.pumpAndSettle();
    expect(find.text('Resume your ranked session?'), findsNothing);
  });

  testWidgets('practice sessions are not saved and can only be ended', (
    tester,
  ) async {
    phone(tester);
    final (progress, game, settings) = await stores();
    await tester.pumpWidget(
      UpwiqApp(progress: progress, game: game, settings: settings),
    );
    await tester.tap(find.text('League'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Practice session (unranked)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EUR/USD'));
    await tester.pumpAndSettle();
    await play(tester);
    expect(game.rankedSession, isNull);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('End this session?'), findsOneWidget);
    expect(find.text('Pause'), findsNothing);
    await tester.tap(find.widgetWithText(TextButton, 'Keep trading'));
    await tester.pumpAndSettle();
    expect(find.byType(TradingSessionScreen), findsOneWidget);
  });

  for (final scale in const [1.0, 1.3]) {
    testWidgets('resume card and leave dialog fit a 320dp phone at '
        '${(scale * 100).round()}% text', (tester) async {
      phone(tester, width: 320, height: 640);
      final (_, game, _) = await stores();
      await game.saveRankedSession(sessionWithOpenTrade());
      Widget app(Widget home) => GameScope(
        store: game,
        child: MaterialApp(
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: home,
        ),
      );
      await tester.pumpWidget(app(const Scaffold(body: LeagueScreen())));
      await tester.pump();
      expect(find.text('Session in progress'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'league card');

      final saved = game.rankedSession!;
      await tester.pumpWidget(
        app(
          TradingSessionScreen(
            market: saved.market,
            dayNumber: saved.dayNumber,
            ranked: true,
            startingBalance: saved.startingBalance,
            resume: saved,
            startedOn: saved.startedOn,
            onProgress: game.saveRankedSession,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Floating P&L'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Leave the session?'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'leave dialog');
    });
  }
}
