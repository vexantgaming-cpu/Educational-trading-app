import 'dart:convert';

import 'package:market_sim/market_sim.dart';
import 'package:test/test.dart';

/// Plays a session with made-up decisions, recording every action the way
/// the app does, and returns the live engine plus its saved form.
(ReplaySession, SavedSession) play(
  MarketProfile market,
  int dayNumber, {
  required int seed,
  required int bars,
}) {
  final day = generateTradingDay(market, dayNumber);
  final spec = market.spec;
  final s = SavedSession.newEngine(day, 10000);
  final rng = SeededRandom(seed);
  final log = <SessionAction>[];
  final atr = day.sessionOpen * market.dailyVolatilityPct / 100 / 10;

  void act() {
    final roll = rng.nextDouble();
    try {
      if (s.isFlat && roll < 0.35) {
        final side = rng.nextBool() ? Side.long : Side.short;
        final type = OrderType.values[rng.nextInt(3)];
        final ref = side == Side.long ? s.ask : s.bid;
        final sign = side.sign;
        final entry = switch (type) {
          OrderType.market => ref,
          OrderType.limit => spec.roundPrice(ref - sign * atr),
          OrderType.stop => spec.roundPrice(ref + sign * atr),
        };
        final stop = spec.roundPrice(entry - sign * atr * 2.5);
        final order = OrderRequest(
          side: side,
          quantity: Risk.positionSize(
            balance: s.equity,
            riskPct: 1,
            entry: entry,
            stop: stop,
            spec: spec,
          ).quantity,
          type: type,
          price: type == OrderType.market ? null : entry,
          stopLoss: stop,
          takeProfit: rng.nextBool()
              ? spec.roundPrice(entry + sign * atr * 5)
              : null,
        );
        s.submit(order);
        log.add(SubmitOrder(s.currentIndex, order));
      } else if (s.position != null && roll < 0.15) {
        s.closePosition();
        log.add(ClosePosition(s.currentIndex));
      } else if (s.position != null && roll < 0.4) {
        final p = s.position!;
        final stop = spec.roundPrice(
          s.exitPrice - p.side.sign * atr * rng.nextRange(1, 3),
        );
        s.updateLevels(stopLoss: stop, takeProfit: p.takeProfit);
        log.add(
          UpdateLevels(
            s.currentIndex,
            stopLoss: stop,
            takeProfit: p.takeProfit,
          ),
        );
      } else if (s.pendingOrder != null && roll < 0.2) {
        s.cancelPending();
        log.add(CancelPending(s.currentIndex));
      }
    } on OrderRejected {
      // The app shows a message and records nothing.
    }
  }

  for (var i = 0; i < bars && s.hasNextBar; i++) {
    act();
    if (rng.nextBool(0.3)) act(); // sometimes two actions on one bar
    s.step();
  }
  act();
  return (
    s,
    SavedSession(
      symbol: market.symbol,
      dayNumber: dayNumber,
      ranked: true,
      startingBalance: 10000,
      startedOn: '2026-11-11',
      index: s.currentIndex,
      actions: log,
    ),
  );
}

void expectSameState(ReplaySession a, ReplaySession b) {
  expect(b.currentIndex, a.currentIndex);
  expect(b.balance, a.balance);
  expect(b.equity, a.equity);
  expect(b.trades.length, a.trades.length);
  for (var i = 0; i < a.trades.length; i++) {
    expect(b.trades[i].entryIndex, a.trades[i].entryIndex);
    expect(b.trades[i].exitIndex, a.trades[i].exitIndex);
    expect(b.trades[i].entryPrice, a.trades[i].entryPrice);
    expect(b.trades[i].exitPrice, a.trades[i].exitPrice);
    expect(b.trades[i].exitReason, a.trades[i].exitReason);
    expect(b.trades[i].netPnl, a.trades[i].netPnl);
  }
  expect(b.position == null, a.position == null);
  if (a.position case final p?) {
    final q = b.position!;
    expect(q.side, p.side);
    expect(q.quantity, p.quantity);
    expect(q.entryPrice, p.entryPrice);
    expect(q.entryIndex, p.entryIndex);
    expect(q.stopLoss, p.stopLoss);
    expect(q.takeProfit, p.takeProfit);
  }
  expect(b.pendingOrder == null, a.pendingOrder == null);
  if (a.pendingOrder case final o?) {
    expect(b.pendingOrder!.price, o.price);
    expect(b.pendingOrder!.type, o.type);
    expect(b.pendingOrder!.quantity, o.quantity);
  }
}

void main() {
  test('a saved session is restored exactly, on every market', () {
    var withTrades = 0, withOpen = 0, withPending = 0;
    for (final market in GameMarkets.all) {
      for (var k = 0; k < 12; k++) {
        final (live, saved) = play(
          market,
          300 + k,
          seed: 1000 + k * 7,
          bars: 10 + k * 7,
        );
        // Through JSON, as it is stored on the phone.
        final loaded = SavedSession.fromJson(
          jsonDecode(jsonEncode(saved.toJson())) as Map<String, dynamic>,
        );
        expectSameState(live, loaded.restore());
        if (live.trades.isNotEmpty) withTrades++;
        if (live.position != null) withOpen++;
        if (live.pendingOrder != null) withPending++;
      }
    }
    // The made-up player really did exercise every state.
    expect(withTrades, greaterThan(20));
    expect(withOpen, greaterThan(5));
    expect(withPending, greaterThan(3));
  });

  test('settling a saved session equals ending the live one', () {
    for (var k = 0; k < 10; k++) {
      final (live, saved) = play(
        GameMarkets.eurUsd,
        400 + k,
        seed: k,
        bars: 20 + k * 5,
      );
      final settled = saved.settle();
      live.finish();
      expect(settled.pnl, live.balance - 10000);
      expect(settled.trades, live.trades.length);
    }
  });

  test('a session saved before the open restores to the pre-market', () {
    final day = generateTradingDay(GameMarkets.gold, 310);
    final saved = SavedSession(
      symbol: 'XAUUSD',
      dayNumber: 310,
      ranked: true,
      startingBalance: 12500,
      startedOn: '2026-11-11',
      index: day.sessionStart - 1,
      actions: const [],
    );
    final s = saved.restore();
    expect(s.currentIndex, day.sessionStart - 1);
    expect(s.balance, 12500);
    expect(s.isFlat, isTrue);
    expect(saved.settle(), (pnl: 0.0, trades: 0));
  });

  test('damaged saves are rejected, not half-restored', () {
    SavedSession make({
      String symbol = 'EURUSD',
      List<SessionAction>? actions,
    }) => SavedSession(
      symbol: symbol,
      dayNumber: 300,
      ranked: true,
      startingBalance: 10000,
      startedOn: '2026-11-11',
      index: 90,
      actions: actions ?? const [],
    );
    expect(() => make(symbol: 'NOPE').restore(), throwsFormatException);
    // An action dated before the session's first bar can never be applied.
    expect(
      () => make(actions: const [ClosePosition(3)]).restore(),
      throwsFormatException,
    );
    // Closing a trade that was never opened.
    expect(
      () => make(actions: const [ClosePosition(80)]).restore(),
      throwsFormatException,
    );
    expect(
      () => SessionAction.fromJson(const {'a': 'teleport', 'i': 1}),
      throwsFormatException,
    );
  });
}
