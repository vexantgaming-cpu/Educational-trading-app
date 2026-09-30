import 'package:market_sim/market_sim.dart';

/// Prints how each market behaves over 200 simulated days: average session
/// range vs the target volatility, how often the news bias played out, and
/// the mix of day types. Run: dart run tool/calibrate_days.dart
void main() {
  for (final m in GameMarkets.all) {
    var range = 0.0, directional = 0, followed = 0;
    final types = <DayArchetype, int>{};
    for (var day = 1; day <= 200; day++) {
      final d = generateTradingDay(m, day);
      final s = d.candles.sublist(d.sessionStart);
      final hi = s.map((c) => c.high).reduce((a, b) => a > b ? a : b);
      final lo = s.map((c) => c.low).reduce((a, b) => a < b ? a : b);
      range += (hi - lo) / d.sessionOpen * 100;
      types[d.archetype] = (types[d.archetype] ?? 0) + 1;
      if (d.briefing.bias != Bias.neutral) {
        directional++;
        if ((d.sessionClose > d.sessionOpen) == (d.briefing.bias == Bias.bullish)) followed++;
      }
    }
    print('${m.symbol.padRight(7)} range ${(range / 200).toStringAsFixed(2)}% '
        '(target ${m.dailyVolatilityPct}%)  bias right ${(followed / directional * 100).toStringAsFixed(0)}%  '
        '${types.entries.map((e) => '${e.key.name}:${e.value}').join(' ')}');
  }
}
