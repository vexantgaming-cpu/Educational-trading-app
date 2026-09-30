import 'package:market_sim/market_sim.dart';
import 'package:test/test.dart';

Candle bar(double h, double l, {double? o, double? c}) =>
    Candle(open: o ?? (h + l) / 2, high: h, low: l, close: c ?? (h + l) / 2);

void main() {
  group('Indicators', () {
    test('SMA', () {
      expect(Indicators.sma([1, 2, 3, 4, 5], 3), [null, null, 2, 3, 4]);
    });

    test('EMA is seeded with the SMA', () {
      // k = 2 / (3 + 1) = 0.5
      expect(Indicators.ema([1, 2, 3, 4, 5], 3), [null, null, 2, 3, 4]);
      expect(
        Indicators.ema([2, 4, 6, 10], 3).last,
        closeTo(10 * 0.5 + 4 * 0.5, 1e-9),
      );
    });

    test('RSI: only gains = 100, flat = 50, alternating ≈ 50', () {
      expect(
        Indicators.rsi([for (var i = 0; i < 20; i++) i.toDouble()]).last,
        100,
      );
      expect(Indicators.rsi(List.filled(20, 5.0)).last, 50);
      final zigzag = [for (var i = 0; i < 60; i++) i.isEven ? 10.0 : 11.0];
      expect(Indicators.rsi(zigzag).last, closeTo(50, 5));
    });

    test('ATR of identical bars equals their range', () {
      final candles = List.generate(20, (_) => bar(102, 100, o: 101, c: 101));
      expect(Indicators.atr(candles).last, closeTo(2, 1e-9));
      expect(Indicators.atr(candles)[12], isNull);
    });
  });

  test('aggregateCandles builds higher-timeframe candles', () {
    const candles = [
      Candle(open: 10, high: 12, low: 9, close: 11, volume: 100),
      Candle(open: 11, high: 15, low: 10, close: 14, volume: 200),
      Candle(open: 14, high: 14.5, low: 8, close: 9, volume: 50),
      Candle(open: 9, high: 10, low: 7, close: 8, volume: 10),
      Candle(open: 8, high: 9, low: 6, close: 6.5, volume: 5),
    ];
    final fours = aggregateCandles(candles, 4);
    expect(fours, hasLength(2));
    expect(
      [
        fours[0].open,
        fours[0].high,
        fours[0].low,
        fours[0].close,
        fours[0].volume,
      ],
      [10, 15, 7, 8, 360],
    );
    expect(fours[1].close, 6.5, reason: 'partial last group is kept');
  });

  group('Swings', () {
    test('finds a clear peak and trough', () {
      final highs = <double>[10, 11, 12, 15, 12, 11, 10, 9, 8, 7, 8, 9, 10];
      final candles = [for (final h in highs) bar(h, h - 1)];
      final swings = findSwings(candles, strength: 2);
      expect(swings.map((s) => (s.type, s.index)), [
        (SwingType.high, 3),
        (SwingType.low, 9),
      ]);
    });

    test('classifies higher highs and higher lows as an uptrend', () {
      const up = [
        Swing(index: 1, price: 10, type: SwingType.low),
        Swing(index: 3, price: 14, type: SwingType.high),
        Swing(index: 5, price: 12, type: SwingType.low),
        Swing(index: 7, price: 16, type: SwingType.high),
      ];
      expect(classifyTrend(up), TrendDirection.up);
      const mixed = [
        Swing(index: 1, price: 10, type: SwingType.low),
        Swing(index: 3, price: 14, type: SwingType.high),
        Swing(index: 5, price: 9, type: SwingType.low),
        Swing(index: 7, price: 16, type: SwingType.high),
      ];
      expect(classifyTrend(mixed), TrendDirection.sideways);
    });
  });
}
