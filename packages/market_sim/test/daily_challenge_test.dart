import 'package:market_sim/market_sim.dart';
import 'package:test/test.dart';

void main() {
  final start = DateTime(2026, 10, 1);
  final year = [for (var d = 0; d < 366; d++) start.add(Duration(days: d))];

  test('same date, same challenge; a new one every day', () {
    final a = DailyChallenge.forDate(DateTime(2026, 10, 3, 8));
    final b = DailyChallenge.forDate(DateTime(2026, 10, 3, 23, 59));
    expect(a.dateKey, '2026-10-03');
    expect(a.number, 3);
    expect(b.chart.seed, a.chart.seed);
    expect(b.sizing.facts, a.sizing.facts);
    expect(b.sizing.options, a.sizing.options);
    expect(b.trade.seed, a.trade.seed);

    final days = year.map(DailyChallenge.forDate).toList();
    expect(days.map((c) => c.chart.seed).toSet().length, days.length);
    expect(
      days.map((c) => c.sizing.facts.join('|')).toSet().length,
      greaterThan(250),
    );
  });

  test('identical on the phone and on the web (pinned values)', () {
    final c = DailyChallenge.forDate(DateTime(2026, 10, 3));
    expect(c.chart.task, ChartTask.resistance);
    expect(c.chart.seed, 2989613777);
    expect(c.trade.kind, TradeSetupKind.resistanceFade);
    expect(c.trade.seed, 1734372215);
    expect(c.trade.trendPct, closeTo(10.963466338347644, 1e-12));
    expect(c.sizing.facts, [
      'Account \$10,000 · risk 1% (\$100)',
      'Stop-loss \$5 below your entry',
      '1 lot = 100 ounces, so \$1 = \$100 per lot',
    ]);
    expect(c.sizing.options, [
      '0.20 lots',
      '0.10 lots',
      '0.02 lots',
      '0.80 lots',
    ]);
    expect(c.sizing.answer, 0);
  });

  test('consecutive days use a different chart task and market', () {
    for (var i = 1; i < year.length; i++) {
      final a = DailyChallenge.forDate(year[i - 1]);
      final b = DailyChallenge.forDate(year[i]);
      expect(b.chart.task, isNot(a.chart.task));
      expect(b.sizing.market, isNot(a.sizing.market));
    }
  });

  test('every round type and market comes up', () {
    final days = year.map(DailyChallenge.forDate).toList();
    for (final task in ChartTask.values) {
      expect(
        days.where((c) => c.chart.task == task).length,
        greaterThan(40),
        reason: '$task',
      );
    }
    for (final kind in TradeSetupKind.values) {
      expect(days.where((c) => c.trade.kind == kind).length, greaterThan(100));
    }
    for (final market in [
      'Nova Robotics shares',
      'EUR/USD',
      'Gold',
      'US 500 index',
      'Bitcoin',
    ]) {
      expect(
        days.where((c) => c.sizing.market == market),
        isNotEmpty,
        reason: market,
      );
    }
  });

  test('sizing questions: four different options, one right answer', () {
    for (final day in year) {
      final s = DailyChallenge.forDate(day).sizing;
      expect(s.options.length, 4, reason: day.toString());
      expect(s.options.toSet().length, 4, reason: '${s.options}');
      expect(s.answer, inInclusiveRange(0, 3));
      final value = double.parse(s.options[s.answer].split(' ').first);
      expect(value, greaterThan(0), reason: s.facts.join(' / '));
      expect(s.explanation, contains(s.options[s.answer]));
    }
  });

  test('sizing answer matches the risk formula', () {
    // Recompute from the facts for a few known cases.
    for (final day in year.take(60)) {
      final s = DailyChallenge.forDate(day).sizing;
      final risk = double.parse(
        RegExp(
          r'\(\$([\d,]+)\)',
        ).firstMatch(s.facts[0])!.group(1)!.replaceAll(',', ''),
      );
      final perUnit = double.parse(
        RegExp(
          r'÷ \$([\d,]+(?:\.\d+)?)',
        ).firstMatch(s.explanation)!.group(1)!.replaceAll(',', ''),
      );
      final answer = double.parse(s.options[s.answer].split(' ').first);
      expect(answer, lessThanOrEqualTo(risk / perUnit + 1e-9));
      // Rounded down by less than one step.
      final step = switch (s.unit) {
        'shares' => 1.0,
        'contracts' => 0.1,
        'BTC' => 0.001,
        _ => 0.01,
      };
      expect(
        risk / perUnit - answer,
        lessThan(step + 1e-9),
        reason: s.explanation,
      );
    }
  });

  test('chart rounds have the answer they promise', () {
    for (final day in year) {
      final round = DailyChallenge.forDate(day).chart;
      final scenario = ScenarioGenerator(
        seed: round.seed,
      ).generate(round.segments);
      final candles = scenario.candles;
      switch (round.task) {
        case ChartTask.trend:
          final first = candles[12].close, last = candles.last.close;
          final move = (last / first - 1) * 100;
          switch (round.trend!) {
            case TrendDirection.up:
              expect(move, greaterThan(6), reason: day.toString());
            case TrendDirection.down:
              expect(move, lessThan(-6), reason: day.toString());
            case TrendDirection.sideways:
              expect(scenario.zones, isNotEmpty);
          }
        case ChartTask.support:
        case ChartTask.resistance:
          expect(scenario.zones.length, 2);
        case ChartTask.breakout:
          final span = scenario.spans.firstWhere((s) => s.label == 'breakout');
          final up = span.kind == 'uptrend';
          final level = up
              ? scenario.zones
                    .firstWhere((z) => z.kind == ZoneKind.resistance)
                    .high
              : scenario.zones
                    .firstWhere((z) => z.kind == ZoneKind.support)
                    .low;
          final breaks = [
            for (var i = span.fromIndex; i <= span.toIndex; i++)
              if (up ? candles[i].close > level : candles[i].close < level) i,
          ];
          expect(breaks, isNotEmpty, reason: day.toString());
          // The breakout comes early in the leg, so it's clearly visible.
          expect(breaks.first - span.fromIndex, lessThan(12));
      }
    }
  });
}
