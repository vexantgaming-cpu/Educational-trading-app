import 'package:market_sim/market_sim.dart';
import 'package:test/test.dart';

/// No costs, so the maths in these tests is exact.
const free = InstrumentSpec(
  symbol: 'T',
  name: 'Test',
  assetClass: AssetClass.synthetic,
  tickSize: 0.01,
  maxLeverage: 10,
);

Candle c(double o, double h, double l, double cl) =>
    Candle(open: o, high: h, low: l, close: cl);

ReplaySession session(List<Candle> bars, {InstrumentSpec spec = free}) =>
    ReplaySession(candles: [c(100, 100, 100, 100), ...bars], spec: spec);

void main() {
  test('long market order hits take-profit', () {
    final s = session([c(100, 101, 99.5, 100.5), c(100.5, 103, 100, 102.5)]);
    s.submit(
      const OrderRequest(
        side: Side.long,
        quantity: 10,
        stopLoss: 98,
        takeProfit: 102,
      ),
    );
    expect(s.position!.entryPrice, 100);
    expect(s.step().closedTrade, isNull);
    final trade = s.step().closedTrade!;
    expect(trade.exitReason, ExitReason.takeProfit);
    expect(trade.exitPrice, 102);
    expect(trade.netPnl, closeTo(20, 1e-9));
    expect(trade.rMultiple, closeTo(1, 1e-9));
    expect(s.balance, closeTo(10020, 1e-9));
    expect(s.isFlat, isTrue);
  });

  test('short trade hits stop-loss', () {
    final s = session([c(100, 102, 99.8, 101.5)]);
    s.submit(
      const OrderRequest(
        side: Side.short,
        quantity: 10,
        stopLoss: 101,
        takeProfit: 97,
      ),
    );
    final trade = s.step().closedTrade!;
    expect(trade.exitReason, ExitReason.stopLoss);
    expect(trade.netPnl, closeTo(-10, 1e-9));
    expect(trade.rMultiple, closeTo(-1, 1e-9));
  });

  test('when one bar hits both levels, the stop is assumed first', () {
    final s = session([c(100, 103, 97, 100)]);
    s.submit(
      const OrderRequest(
        side: Side.long,
        quantity: 1,
        stopLoss: 98,
        takeProfit: 102,
      ),
    );
    expect(s.step().closedTrade!.exitReason, ExitReason.stopLoss);
  });

  test('a gap through the stop fills at the open (worse than the stop)', () {
    final s = session([c(96, 97, 95, 96.5)]);
    s.submit(const OrderRequest(side: Side.long, quantity: 10, stopLoss: 98));
    final trade = s.step().closedTrade!;
    expect(trade.exitPrice, 96);
    expect(trade.rMultiple, closeTo(-2, 1e-9));
  });

  test('a gap through the target fills at the open (better than target)', () {
    final s = session([c(104, 105, 103.5, 104.5)]);
    s.submit(
      const OrderRequest(
        side: Side.long,
        quantity: 1,
        stopLoss: 98,
        takeProfit: 102,
      ),
    );
    final trade = s.step().closedTrade!;
    expect(trade.exitReason, ExitReason.takeProfit);
    expect(trade.exitPrice, 104);
  });

  test('buy limit waits, fills at its price, and checks the stop that bar', () {
    final s = session([c(100, 100.5, 99.5, 100), c(99.8, 100, 98.5, 99)]);
    s.submit(
      const OrderRequest(
        side: Side.long,
        quantity: 10,
        type: OrderType.limit,
        price: 99,
        stopLoss: 98.8,
        takeProfit: 103,
      ),
    );
    expect(s.step().entryFilled, isFalse);
    final event = s.step();
    expect(event.entryFilled, isTrue);
    expect(event.closedTrade!.entryPrice, 99);
    expect(event.closedTrade!.exitReason, ExitReason.stopLoss);
  });

  test('buy limit that gaps below fills at the (better) open', () {
    final s = session([c(98, 99, 97.5, 98.5)]);
    s.submit(
      const OrderRequest(
        side: Side.long,
        quantity: 1,
        type: OrderType.limit,
        price: 99,
        stopLoss: 97,
      ),
    );
    s.step();
    expect(s.position!.entryPrice, 98);
  });

  test(
    'a limit fill that opens beyond the stop exits immediately at the fill',
    () {
      final s = session([c(96, 96.5, 95, 96)]);
      s.submit(
        const OrderRequest(
          side: Side.long,
          quantity: 1,
          type: OrderType.limit,
          price: 99,
          stopLoss: 97,
        ),
      );
      final trade = s.step().closedTrade!;
      expect(trade.entryPrice, 96);
      expect(trade.exitPrice, 96);
      expect(trade.exitReason, ExitReason.stopLoss);
    },
  );

  test('buy stop triggers on a breakout, or at the open after a gap', () {
    final s = session([
      c(100, 100.8, 99.5, 100.5),
      c(100.5, 102, 100.2, 101.8),
    ]);
    s.submit(
      const OrderRequest(
        side: Side.long,
        quantity: 1,
        type: OrderType.stop,
        price: 101,
        stopLoss: 99,
      ),
    );
    expect(s.step().entryFilled, isFalse);
    expect(s.step().entryFilled, isTrue);
    expect(s.position!.entryPrice, 101);

    final gap = session([c(102, 103, 101.5, 102.5)]);
    gap.submit(
      const OrderRequest(
        side: Side.long,
        quantity: 1,
        type: OrderType.stop,
        price: 101,
        stopLoss: 99,
      ),
    );
    gap.step();
    expect(gap.position!.entryPrice, 102);
  });

  test('rejects orders with a helpful explanation', () {
    final s = session([c(100, 101, 99, 100)]);
    expect(
      () => s.submit(
        const OrderRequest(
          side: Side.long,
          quantity: 1,
          type: OrderType.limit,
          price: 101,
        ),
      ),
      throwsA(
        isA<OrderRejected>().having(
          (e) => e.message,
          'message',
          contains('below the current price'),
        ),
      ),
    );
    expect(
      () => s.submit(
        const OrderRequest(side: Side.long, quantity: 1, stopLoss: 101),
      ),
      throwsA(
        isA<OrderRejected>().having(
          (e) => e.message,
          'message',
          contains('below your entry'),
        ),
      ),
    );
    expect(
      () => s.submit(const OrderRequest(side: Side.long, quantity: 2000)),
      throwsA(
        isA<OrderRejected>().having(
          (e) => e.message,
          'message',
          contains('margin'),
        ),
      ),
    );
    s.submit(const OrderRequest(side: Side.long, quantity: 1));
    expect(
      () => s.submit(const OrderRequest(side: Side.long, quantity: 1)),
      throwsA(isA<OrderRejected>()),
    );
  });

  test('buys fill at the ask, sells at the bid; commission on both sides', () {
    const costly = InstrumentSpec(
      symbol: 'C',
      name: 'Costly',
      assetClass: AssetClass.stock,
      tickSize: 0.01,
      spread: 0.1,
      commissionRate: 0.001,
      maxLeverage: 1,
    );
    final s = session([c(100, 102.5, 99.5, 102)], spec: costly);
    // Candles are bid prices; the ask is the bid plus the spread.
    expect(s.bid, closeTo(100, 1e-9));
    expect(s.ask, closeTo(100.1, 1e-9));
    s.submit(
      const OrderRequest(side: Side.long, quantity: 10, takeProfit: 102),
    );
    expect(s.position!.entryPrice, closeTo(100.1, 1e-9));
    final trade = s.step().closedTrade!;
    // Exit at the target (the bid high 102.5 reached 102).
    expect(trade.exitPrice, 102);
    expect(trade.grossPnl, closeTo((102 - 100.1) * 10, 1e-9));
    // Commission: 1001 × 0.1% + 1020 × 0.1%.
    expect(trade.fees, closeTo(1.001 + 1.02, 1e-9));
    expect(trade.spreadCost, closeTo(1.0, 1e-9));
    expect(s.balance, closeTo(10000 + 19 - 2.021, 1e-9));
    expect(trade.rMultiple, isNull, reason: 'no stop-loss, so no R');
  });

  test(
    'a widening spread can trigger a short\'s stop the chart never touched',
    () {
      // Shorts exit by buying at the ask. The bid high 100.8 stays below the
      // 101 stop, but with a 0.4 spread the ask reaches 101.2.
      final bars = [c(100, 100.8, 99.6, 100.2)];
      ReplaySession make(double newsSpread) => ReplaySession(
        candles: [c(100, 100, 100, 100), ...bars],
        spec: free,
        spreads: [0, newsSpread],
      );
      final calm = make(0);
      calm.submit(
        const OrderRequest(side: Side.short, quantity: 1, stopLoss: 101),
      );
      expect(calm.step().closedTrade, isNull);

      final news = make(0.4);
      news.submit(
        const OrderRequest(side: Side.short, quantity: 1, stopLoss: 101),
      );
      expect(news.step().closedTrade!.exitReason, ExitReason.stopLoss);
    },
  );

  test('buy stops trigger on the ask', () {
    final s = ReplaySession(
      candles: [c(100, 100, 100, 100), c(100, 100.95, 99.8, 100.5)],
      spec: free,
      spreads: const [0.1, 0.1],
    );
    // Bid high 100.95 + spread 0.1 = ask high 101.05, reaching a 101 buy stop.
    s.submit(
      const OrderRequest(
        side: Side.long,
        quantity: 1,
        type: OrderType.stop,
        price: 101,
        stopLoss: 99,
      ),
    );
    expect(s.step().entryFilled, isTrue);
    expect(s.position!.entryPrice, 101);
  });

  test('spread cost: longs pay it on entry, shorts on exit', () {
    ReplaySession make() => ReplaySession(
      candles: [c(100, 100, 100, 100), c(100, 100.5, 99.5, 100)],
      spec: free,
      spreads: const [0.1, 0.3],
    );
    final long = make();
    long.submit(const OrderRequest(side: Side.long, quantity: 10));
    long.step();
    expect(long.closePosition().spreadCost, closeTo(1.0, 1e-9));
    final short = make();
    short.submit(const OrderRequest(side: Side.short, quantity: 10));
    short.step();
    expect(short.closePosition().spreadCost, closeTo(3.0, 1e-9));
  });

  test('USD/JPY profits are converted from yen to dollars', () {
    final s = ReplaySession(
      candles: [
        const Candle(open: 150, high: 150, low: 150, close: 150),
        const Candle(open: 150, high: 151.2, low: 149.9, close: 151),
      ],
      spec: GameInstruments.usdJpy,
      spreads: const [0, 0],
    );
    s.submit(const OrderRequest(side: Side.long, quantity: 1, stopLoss: 149.5));
    // 1 lot = 100 000 USD notional; margin at 30:1 ≈ \$3,333.
    expect(s.usedMargin, closeTo(100000 / 30, 1e-6));
    s.step();
    final trade = s.closePosition();
    // +1.000 yen × 100 000 = 100 000 JPY = \$662.25 at 151.
    expect(trade.grossPnl, closeTo(100000 / 151, 1e-6));
    expect(trade.riskAmount, closeTo(0.5 * 100000 / 149.5, 1e-6));
  });

  test('margin stop-out closes the trade at 50% margin level', () {
    // 10:1 leverage; 900 units at 100 = 90 000 notional, 9 000 margin.
    final s = session([c(100, 100.2, 88, 90)]);
    s.submit(const OrderRequest(side: Side.long, quantity: 900));
    expect(s.usedMargin, closeTo(9000, 1e-9));
    final trade = s.step().closedTrade!;
    expect(trade.exitReason, ExitReason.stopOut);
    // Equity hits 4 500 (50% of margin) when price = 100 − 5 500 / 900.
    expect(trade.exitPrice, closeTo(100 - 5500 / 900, 1e-9));
    expect(s.balance, closeTo(4500, 1e-6));
  });

  test(
    'negative balance protection: a gap cannot make the balance negative',
    () {
      final s = session([c(80, 81, 79, 80)]);
      s.submit(const OrderRequest(side: Side.long, quantity: 900));
      final trade = s.step().closedTrade!;
      expect(trade.exitReason, ExitReason.stopOut);
      expect(trade.exitPrice, 80, reason: 'gapped through, filled at the open');
      expect(s.balance, 0);
    },
  );

  test('equity tracks the open trade; finish closes it at the last price', () {
    final s = session([c(100, 101, 99, 100.8), c(100.8, 101.5, 100.5, 101.2)]);
    s.submit(const OrderRequest(side: Side.long, quantity: 10, stopLoss: 95));
    final events = s.runUntilFlat();
    expect(events, hasLength(2), reason: 'data ran out before the stop');
    expect(s.equity, closeTo(10012, 1e-9));
    final trade = s.finish()!;
    expect(trade.exitReason, ExitReason.endOfSession);
    expect(trade.netPnl, closeTo(12, 1e-9));
    expect(() => s.step(), throwsStateError);
  });

  test('moving the stop is validated against the current price', () {
    final s = session([c(100, 101, 99.5, 100.8)]);
    s.submit(const OrderRequest(side: Side.long, quantity: 1, stopLoss: 98));
    s.step();
    s.updateLevels(stopLoss: 100, takeProfit: 105);
    expect(s.position!.stopLoss, 100);
    expect(
      s.position!.initialStop,
      98,
      reason: 'R is measured from the first stop',
    );
    expect(
      () => s.updateLevels(stopLoss: 101),
      throwsA(
        isA<OrderRejected>().having(
          (e) => e.message,
          'message',
          contains('current price'),
        ),
      ),
    );
  });
}
