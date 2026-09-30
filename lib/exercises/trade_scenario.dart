import 'package:market_sim/market_sim.dart';

/// A chart for the "Place the trade" exercise: an uptrend that pauses in a
/// range, revealed up to a moment when price is back at support.
class TradeScenario {
  TradeScenario._(
    this.scenario,
    this.revealIndex,
    this.support,
    this.resistance,
  );

  factory TradeScenario.supportBounce(int seed) {
    final scenario = ScenarioGenerator(seed: seed).generate(const [
      TrendSegment(bars: 45, movePct: 12, volatilityPct: 0.9),
      RangeSegment(bars: 45, belowPct: 5, abovePct: 0.4),
      TrendSegment(
        bars: 30,
        movePct: 9,
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

    // Stop the chart at the first retest of support after the range has had
    // time to form, so the learner can see the level before trading it.
    final tolerance = (support.high - support.low) * 0.3;
    final first = support.fromIndex + 18;
    final last = support.toIndex - 6;
    var reveal = -1;
    for (var i = first; i <= last; i++) {
      if (support.contains(scenario.candles[i].close, tolerance: tolerance)) {
        reveal = i;
        break;
      }
    }
    if (reveal < 0) {
      reveal = first;
      for (var i = first; i <= last; i++) {
        if (scenario.candles[i].close < scenario.candles[reveal].close) {
          reveal = i;
        }
      }
    }
    return TradeScenario._(scenario, reveal, support, resistance);
  }

  final Scenario scenario;
  final int revealIndex;
  final Zone support;
  final Zone resistance;
}
