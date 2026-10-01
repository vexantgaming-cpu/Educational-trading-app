import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_sim/market_sim.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upwiq/game/game_scope.dart';
import 'package:upwiq/game/game_store.dart';
import 'package:upwiq/game/session_result.dart';
import 'package:upwiq/game/trading_session_screen.dart';

void main() {
  late DateTime now;

  Future<GameStore> freshStore() async {
    SharedPreferences.setMockInitialValues({});
    GameStore.reset();
    return GameStore.load(clock: () => now);
  }

  group('GameStore', () {
    test(
      'starts in Bronze with \$10,000 and one ranked session a day',
      () async {
        now = DateTime(2026, 9, 30, 10); // Wednesday, week 40
        final store = await freshStore();
        expect(store.league, League.bronze);
        expect(store.balance, 10000);
        expect(store.seasonId, 202640);
        expect(store.rankedPlayedToday, isFalse);
        await store.recordRankedDay(symbol: 'EURUSD', pnl: 250, trades: 2);
        expect(store.balance, 10250);
        expect(store.rankedPlayedToday, isTrue);
        expect(store.seasonReturnPct, closeTo(2.5, 1e-9));
        expect(store.standings.where((s) => s.isYou), hasLength(1));
        now = DateTime(2026, 10, 1, 9);
        expect(
          store.rankedPlayedToday,
          isFalse,
          reason: 'a new day, a new session',
        );
      },
    );

    test('a blown account restarts in Bronze with \$10,000', () async {
      now = DateTime(2026, 9, 30, 10);
      final store = await freshStore();
      await store.recordRankedDay(symbol: 'BTCUSD', pnl: -9500, trades: 3);
      expect(store.justBlown, isTrue);
      expect(store.balance, 10000);
      expect(store.league, League.bronze);
      expect(store.resets, 1);
      await store.clearNotices();
      expect(store.justBlown, isFalse);
    });

    test(
      'top of the group is promoted, bottom is demoted, at season end',
      () async {
        now = DateTime(2026, 9, 28, 10); // Monday
        final store = await freshStore();
        for (final day in [28, 29, 30]) {
          now = DateTime(2026, 9, day, 10);
          await store.recordRankedDay(
            symbol: 'XAUUSD',
            pnl: store.balance * 0.1,
            trades: 1,
          );
        }
        now = DateTime(2026, 10, 5, 9); // next Monday
        await store.refresh();
        expect(store.pendingReport!.outcome, SeasonOutcome.promoted);
        expect(store.league, League.silver);
        expect(store.seasonDaysPlayed, 0, reason: 'new season starts clean');
        await store.clearNotices();

        for (final day in [5, 6, 7]) {
          now = DateTime(2026, 10, day, 10);
          await store.recordRankedDay(
            symbol: 'XAUUSD',
            pnl: -store.balance * 0.25,
            trades: 1,
          );
        }
        now = DateTime(2026, 10, 12, 9);
        await store.refresh();
        expect(store.pendingReport!.outcome, SeasonOutcome.demoted);
        expect(store.league, League.bronze);
        expect(store.bestLeague, League.silver);
      },
    );

    test('a week without trading changes nothing', () async {
      now = DateTime(2026, 9, 30, 10);
      final store = await freshStore();
      now = DateTime(2026, 10, 7, 10);
      await store.refresh();
      expect(store.pendingReport, isNull);
      expect(store.league, League.bronze);
    });

    test('state survives an app restart', () async {
      now = DateTime(2026, 9, 30, 10);
      final store = await freshStore();
      await store.recordRankedDay(symbol: 'US500', pnl: 120, trades: 1);
      GameStore.reset();
      final again = await GameStore.load(clock: () => now);
      expect(again.balance, 10120);
      expect(again.playerId, store.playerId);
      expect(again.rankedPlayedToday, isTrue);
    });
  });

  testWidgets('a full session: pre-market, buy, news pause, day end', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    now = DateTime(2026, 9, 30, 10);
    final store = await freshStore();
    SessionResult? result;

    await tester.pumpWidget(
      GameScope(
        store: store,
        child: MaterialApp(
          home: TradingSessionScreen(
            market: GameMarkets.eurUsd,
            dayNumber: 272,
            ranked: false,
            startingBalance: 10000,
            tick: const Duration(milliseconds: 10),
            onComplete: (r) async {
              result = r;
              return const Scaffold(body: Text('summary'));
            },
          ),
        ),
      ),
    );

    expect(find.text('Pre-market'), findsOneWidget);
    expect(find.textContaining('The market opens at 08:00'), findsOneWidget);

    // Open the market and let a few candles print.
    await tester.tap(find.byTooltip('Play'));
    await tester.pump(const Duration(milliseconds: 55));
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(find.text('Pre-market'), findsNothing);

    final buy = find.textContaining(RegExp(r'^BUY [0-9.]+ @'));
    await tester.ensureVisible(buy);
    await tester.tap(buy);
    await tester.pump();
    expect(find.text('Floating P&L'), findsOneWidget);

    // Play until the news release pauses the session (or the trade closes).
    await tester.tap(find.byTooltip('Play'));
    for (
      var i = 0;
      i < 200 && find.textContaining('BREAKING').evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(find.textContaining('BREAKING'), findsOneWidget);
    expect(
      find.byTooltip('Play'),
      findsOneWidget,
      reason: 'news pauses the replay',
    );

    await tester.tap(find.byTooltip('Play'));
    for (var i = 0; i < 100 && result == null; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.trades, isNotEmpty);
    expect(result!.trades.first.entryPrice, greaterThan(0));
    expect(find.text('summary'), findsOneWidget);
  });
}
