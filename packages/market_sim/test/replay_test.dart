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
    s.submit(const OrderRequest(
        side: Side.long, quantity: 10, stopLoss: 98, takeProfit: 102));
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
    s.submit(const OrderRequest(
        side: Side.short, quantity: 10, stopLoss: 101, takeProfit: 97));
    final trade = s.step().closedTrade!;
    expect(trade.exitReason, ExitReason.stopLoss);
    expect(trade.netPnl, closeTo(-10, 1e-9));
    expect(trade.rMultiple, closeTo(-1, 1e-9));
  });

  test('when one bar hits both levels, the stop is assumed first', () {
    final s = session([c(100, 103, 97, 100)]);
    s.submit(const OrderRequest(
        side: Side.long, quantity: 1, stopLoss: 98, takeProfit: 102));
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
    s.submit(const OrderRequest(
        side: Side.long, quantity: 1, stopLoss: 98, takeProfit: 102));
    final trade = s.step().closedTrade!;
    expect(trade.exitReason, ExitReason.takeProfit);
    expect(trade.exitPrice, 104);
  });

  test('buy limit waits, fills at its price, and checks the stop that bar', () {
    final s = session([c(100, 100.5, 99.5, 100), c(99.8, 100, 98.5, 99)]);
    s.submit(const OrderRequest(
        side: Side.long,
        quantity: 10,
        type: OrderType.limit,
        price: 99,
        stopLoss: 98.8,
        takeProfit: 103));
    expect(s.step().entryFilled, isFalse);
    final event = s.step();
    expect(event.entryFilled, isTrue);
    expect(event.closedTrade!.entryPrice, 99);
    expect(event.closedTrade!.exitReason, ExitReason.stopLoss);
  });

  test('buy limit that gaps below fills at the (better) open', () {
    final s = session([c(98, 99, 97.5, 98.5)]);
    s.submit(const OrderRequest(
        side: Side.long, quantity: 1, type: OrderType.limit, price: 99, stopLoss: 97));
    s.step();
    expect(s.position!.entryPrice, 98);
  });

  test('a limit fill that opens beyond the stop exits immediately at the fill', () {
    final s = session([c(96, 96.5, 95, 96)]);
    s.submit(const OrderRequest(
        side: Side.long, quantity: 1, type: OrderType.limit, price: 99, stopLoss: 97));
    final trade = s.step().closedTrade!;
    expect(trade.entryPrice, 96);
    expect(trade.exitPrice, 96);
    expect(trade.exitReason, ExitReason.stopLoss);
  });

  test('buy stop triggers on a breakout, or at the open after a gap', () {
    final s = session([c(100, 100.8, 99.5, 100.5), c(100.5, 102, 100.2, 101.8)]);
    s.submit(const OrderRequest(
        side: Side.long, quantity: 1, type: OrderType.stop, price: 101, stopLoss: 99));
    expect(s.step().entryFilled, isFalse);
    expect(s.step().entryFilled, isTrue);
    expect(s.position!.entryPrice, 101);

    final gap = session([c(102, 103, 101.5, 102.5)]);
    gap.submit(const OrderRequest(
        side: Side.long, quantity: 1, type: OrderType.stop, price: 101, stopLoss: 99));
    gap.step();
    expect(gap.position!.entryPrice, 102);
  });

  test('rejects orders with a helpful explanation', () {
    final s = session([c(100, 101, 99, 100)]);
    expect(
        () => s.submit(const OrderRequest(
            side: Side.long, quantity: 1, type: OrderType.limit, price: 101)),
        throwsA(isA<OrderRejected>()
            .having((e) => e.message, 'message', contains('below the current price'))));
    expect(
        () => s.submit(
            const OrderRequest(side: Side.long, quantity: 1, stopLoss: 101)),
        throwsA(isA<OrderRejected>()
            .having((e) => e.message, 'message', contains('below your entry'))));
    expect(
        () => s.submit(const OrderRequest(side: Side.long, quantity: 2000)),
        throwsA(isA<OrderRejected>()
            .having((e) => e.message, 'message', contains('margin'))));
    s.submit(const OrderRequest(side: Side.long, quantity: 1));
    expect(() => s.submit(const OrderRequest(side: Side.long, quantity: 1)),
        throwsA(isA<OrderRejected>()));
  });

  test('spread and commission are charged on entry and exit', () {
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
    s.submit(const OrderRequest(side: Side.long, quantity: 10, takeProfit: 102));
    final trade = s.step().closedTrade!;
    // Entry: 1000 × 0.1% + 0.05 × 10 = 1.5; exit: 1020 × 0.1% + 0.5 = 1.52.
    expect(trade.fees, closeTo(3.02, 1e-9));
    expect(trade.grossPnl, closeTo(20, 1e-9));
    expect(s.balance, closeTo(10000 + 20 - 3.02, 1e-9));
    expect(trade.rMultiple, isNull, reason: 'no stop-loss, so no R');
  });

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
    expect(s.position!.initialStop, 98, reason: 'R is measured from the first stop');
    expect(() => s.updateLevels(stopLoss: 101),
        throwsA(isA<OrderRejected>()
            .having((e) => e.message, 'message', contains('current price'))));
  });
}
