import 'package:market_sim/market_sim.dart';

/// A chart for the "Place the trade" exercise: a trend that pauses in a
/// range, revealed up to a moment when price is back at the edge of the
/// range, ready for a trade.
class TradeScenario {
  TradeScenario._(
    this.scenario,
    this.revealIndex,
    this.support,
    this.resistance,
    this.side,
  );

  /// Uptrend, range, and price back at **support**: a long setup.
  factory TradeScenario.supportBounce(
    int seed, {
    double trendPct = 12,
    double rangePct = 5,
  }) => TradeScenario._build(seed, Side.long, trendPct, rangePct);

  /// Downtrend, range, and price back at **resistance**: a short setup.
  factory TradeScenario.resistanceFade(
    int seed, {
    double trendPct = 12,
    double rangePct = 5,
  }) => TradeScenario._build(seed, Side.short, trendPct, rangePct);

  /// The Daily Challenge's chart.
  factory TradeScenario.forSetup(TradeSetup setup) => switch (setup.kind) {
    TradeSetupKind.supportBounce => TradeScenario.supportBounce(
      setup.seed,
      trendPct: setup.trendPct,
      rangePct: setup.rangePct,
    ),
    TradeSetupKind.resistanceFade => TradeScenario.resistanceFade(
      setup.seed,
      trendPct: setup.trendPct,
      rangePct: setup.rangePct,
    ),
  };

  factory TradeScenario._build(
    int seed,
    Side side,
    double trendPct,
    double rangePct,
  ) {
    final long = side == Side.long;
    final scenario = ScenarioGenerator(seed: seed).generate([
      TrendSegment(
        bars: 45,
        movePct: long ? trendPct : -trendPct,
        volatilityPct: 0.9,
      ),
      RangeSegment(
        bars: 45,
        belowPct: long ? rangePct : 0.4,
        abovePct: long ? 0.4 : rangePct,
      ),
      TrendSegment(
        bars: 30,
        movePct: long ? 9 : -9,
        volumeMultiplier: 1.8,
        label: 'breakout',
      ),
    ]);
    final support = scenario.zones.firstWhere(
      (z) => z.kind == ZoneKind.support,
    );
    final resistance = scenario.zones.firstWhere(
      (z) => z.kind == ZoneKind.resistance,
    );

    // Stop the chart at the first retest of the level after the range has
    // had time to form, so the learner can see it before trading it.
    final level = long ? support : resistance;
    final tolerance = (level.high - level.low) * 0.3;
    final first = level.fromIndex + 18;
    final last = level.toIndex - 6;
    var reveal = -1;
    for (var i = first; i <= last; i++) {
      if (level.contains(scenario.candles[i].close, tolerance: tolerance)) {
        reveal = i;
        break;
      }
    }
    if (reveal < 0) {
      // Otherwise the closest approach to the level.
      reveal = first;
      for (var i = first; i <= last; i++) {
        final close = scenario.candles[i].close;
        final best = scenario.candles[reveal].close;
        if (long ? close < best : close > best) reveal = i;
      }
    }
    return TradeScenario._(scenario, reveal, support, resistance, side);
  }

  final Scenario scenario;
  final int revealIndex;
  final Zone support;
  final Zone resistance;

  /// The trade this setup suggests: long at support, short at resistance.
  final Side side;
}
