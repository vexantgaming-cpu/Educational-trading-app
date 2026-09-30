import 'dart:convert';

import 'package:market_sim/market_sim.dart';
import 'package:test/test.dart';

const script = [
  TrendSegment(bars: 60, movePct: 15),
  RangeSegment(bars: 40, belowPct: 4, abovePct: 0.5),
  TrendSegment(bars: 25, movePct: 8, volumeMultiplier: 2, label: 'breakout'),
  TrendSegment(bars: 40, movePct: -12),
];

void main() {
  test('same seed gives the same chart; different seeds differ', () {
    String run(int seed) =>
        jsonEncode(ScenarioGenerator(seed: seed).generate(script).toJson());
    expect(run(11), run(11));
    expect(run(11), isNot(run(12)));
  });

  test('candles are well-formed and continuous', () {
    final s = ScenarioGenerator(seed: 3).generate(script);
    expect(s.candles, hasLength(165));
    for (var i = 0; i < s.candles.length; i++) {
      final c = s.candles[i];
      expect(c.high, greaterThanOrEqualTo(c.open));
      expect(c.high, greaterThanOrEqualTo(c.close));
      expect(c.low, lessThanOrEqualTo(c.open));
      expect(c.low, lessThanOrEqualTo(c.close));
      expect(c.volume, greaterThan(0));
      if (i > 0) expect(c.open, closeTo(s.candles[i - 1].close, 0.011));
    }
  });

  test('trend segments end exactly at the scripted move', () {
    final s = ScenarioGenerator(seed: 5, startPrice: 100).generate(script);
    expect(s.candles[59].close, closeTo(115, 0.01));
    expect(s.spans.first.kind, 'uptrend');
    expect(s.spans.last.kind, 'downtrend');
    expect(s.spans[2].label, 'breakout');
  });

  test('range closes stay inside the answer-key zones', () {
    for (final seed in [1, 2, 3, 4, 5]) {
      final s = ScenarioGenerator(seed: seed).generate(script);
      final support = s.zones.firstWhere((z) => z.kind == ZoneKind.support);
      final resistance = s.zones.firstWhere((z) => z.kind == ZoneKind.resistance);
      expect(support.fromIndex, 60);
      expect(support.toIndex, 99);
      expect(support.high, lessThan(resistance.low));
      for (var i = support.fromIndex; i <= support.toIndex; i++) {
        final close = s.candles[i].close;
        expect(close, greaterThanOrEqualTo(support.low - 0.01));
        expect(close, lessThanOrEqualTo(resistance.high + 0.01));
      }
      // Price should visit both zones at least twice so the range is obvious.
      final visitsSupport = [
        for (var i = 60; i < 100; i++)
          if (support.contains(s.candles[i].low)) i
      ];
      expect(visitsSupport.length, greaterThanOrEqualTo(2), reason: 'seed $seed');
    }
  });

  test('a scripted uptrend reads as higher highs and higher lows', () {
    final s = ScenarioGenerator(seed: 9)
        .generate(const [TrendSegment(bars: 80, movePct: 25, volatilityPct: 0.6)]);
    expect(classifyTrend(findSwings(s.candles, strength: 2)), TrendDirection.up);
  });

  test('randomMarket produces the requested number of bars', () {
    final s = ScenarioGenerator(seed: 99).randomMarket(bars: 250);
    expect(s.candles, hasLength(250));
    expect(s.candles.every((c) => c.low > 0), isTrue);
  });
}
