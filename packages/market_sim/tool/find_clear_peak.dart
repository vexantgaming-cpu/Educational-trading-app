import 'package:market_sim/market_sim.dart';

/// Finds seeds whose chart has one clearly highest candle (for "spot the
/// highest high" exercises). Prints seed and the margin in percent.
void main() {
  const segments = [
    TrendSegment(bars: 18, movePct: 8, volatilityPct: 0.8),
    TrendSegment(bars: 18, movePct: -7, volatilityPct: 0.8),
  ];
  final results = <(int, double)>[];
  for (var seed = 1; seed <= 300; seed++) {
    final c = ScenarioGenerator(seed: seed).generate(segments).candles;
    var peak = 0;
    for (var i = 0; i < c.length; i++) {
      if (c[i].high > c[peak].high) peak = i;
    }
    var second = 0.0;
    for (var i = 0; i < c.length; i++) {
      if ((i - peak).abs() > 2 && c[i].high > second) second = c[i].high;
    }
    results.add((seed, (c[peak].high - second) / c[peak].high * 100));
  }
  results.sort((a, b) => b.$2.compareTo(a.$2));
  for (final r in results.take(5)) {
    print('seed ${r.$1}: margin ${r.$2.toStringAsFixed(2)}%');
  }
}
