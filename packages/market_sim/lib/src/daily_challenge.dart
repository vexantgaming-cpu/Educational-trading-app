import 'generator.dart';
import 'rng.dart';
import 'swings.dart';
import 'trading_day.dart' show stableHash;

/// The Daily Challenge: three short rounds that change every day and are
/// the same for everyone on a given date.
///
/// 1. [ChartRound]: read a chart (trend, a support/resistance zone, or the
///    breakout candle).
/// 2. [SizingRound]: work out a position size on a different market.
/// 3. [TradeSetup]: plan a trade (long at support or short at resistance),
///    scored on the plan, not the outcome.
class DailyChallenge {
  const DailyChallenge._({
    required this.dateKey,
    required this.number,
    required this.chart,
    required this.sizing,
    required this.trade,
  });

  /// The challenge for the calendar day of [day] (its local date).
  factory DailyChallenge.forDate(DateTime day) {
    final key = dateKeyOf(day);
    final number = challengeNumber(day);
    final rng = SeededRandom(stableHash('daily-challenge:$key'));
    // Chart task and market rotate, so two days in a row always differ;
    // the details are random.
    int rotate(int length) => ((number - 1) % length + length) % length;
    return DailyChallenge._(
      dateKey: key,
      number: number,
      chart: ChartRound._generate(
        rng,
        stableHash('daily-chart:$key'),
        ChartTask.values[rotate(ChartTask.values.length)],
      ),
      sizing: SizingRound._generate(rng, rotate(5)),
      trade: TradeSetup._generate(rng, stableHash('daily-trade:$key')),
    );
  }

  /// `yyyy-mm-dd` of the local date.
  final String dateKey;

  /// Challenge #1 was on 1 October 2026.
  final int number;
  final ChartRound chart;
  final SizingRound sizing;
  final TradeSetup trade;

  static String dateKeyOf(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  static int challengeNumber(DateTime day) =>
      DateTime.utc(
        day.year,
        day.month,
        day.day,
      ).difference(DateTime.utc(2026, 10, 1)).inDays +
      1;
}

enum ChartTask { trend, support, resistance, breakout }

/// Round 1: a generated chart and what to find on it.
class ChartRound {
  const ChartRound({
    required this.task,
    required this.seed,
    required this.segments,
    this.trend,
  });

  factory ChartRound._generate(SeededRandom rng, int seed, ChartTask task) {
    switch (task) {
      case ChartTask.trend:
        final direction = TrendDirection.values[rng.nextInt(3)];
        final segments = switch (direction) {
          TrendDirection.up => [
            RangeSegment(bars: 12, belowPct: 1.5, abovePct: 1.5),
            TrendSegment(bars: 58, movePct: rng.nextRange(9, 15)),
          ],
          TrendDirection.down => [
            RangeSegment(bars: 12, belowPct: 1.5, abovePct: 1.5),
            TrendSegment(bars: 58, movePct: -rng.nextRange(8, 13)),
          ],
          TrendDirection.sideways => [
            TrendSegment(bars: 15, movePct: rng.nextBool(0.5) ? 4 : -4),
            RangeSegment(
              bars: 55,
              belowPct: rng.nextRange(2.5, 4),
              abovePct: rng.nextRange(2.5, 4),
            ),
          ],
        };
        return ChartRound(
          task: task,
          seed: seed,
          segments: segments,
          trend: direction,
        );
      case ChartTask.support:
      case ChartTask.resistance:
        final up = rng.nextBool(0.5);
        return ChartRound(
          task: task,
          seed: seed,
          segments: [
            TrendSegment(
              bars: 25,
              movePct: (up ? 1 : -1) * rng.nextRange(5, 8),
            ),
            RangeSegment(
              bars: 45,
              belowPct: up ? rng.nextRange(4, 5.5) : 0.4,
              abovePct: up ? 0.4 : rng.nextRange(4, 5.5),
            ),
          ],
        );
      case ChartTask.breakout:
        final up = rng.nextBool(0.6);
        return ChartRound(
          task: task,
          seed: seed,
          segments: [
            TrendSegment(
              bars: 22,
              movePct: (up ? 1 : -1) * rng.nextRange(4, 7),
            ),
            RangeSegment(
              bars: 40,
              belowPct: up ? rng.nextRange(3.5, 5) : 0.4,
              abovePct: up ? 0.4 : rng.nextRange(3.5, 5),
              volumeMultiplier: 0.7,
            ),
            TrendSegment(
              bars: 22,
              movePct: (up ? 1 : -1) * rng.nextRange(7, 10),
              volumeMultiplier: 1.8,
              label: 'breakout',
            ),
          ],
        );
    }
  }

  final ChartTask task;
  final int seed;
  final List<Segment> segments;

  /// The answer when [task] is [ChartTask.trend].
  final TrendDirection? trend;

  String get prompt => switch (task) {
    ChartTask.trend => 'Which way is this market heading?',
    ChartTask.support => 'Tap the support zone.',
    ChartTask.resistance => 'Tap the resistance zone.',
    ChartTask.breakout => 'Tap the candle where price broke out of the range.',
  };

  String get explanation => switch (task) {
    ChartTask.trend => switch (trend!) {
      TrendDirection.up => 'Higher highs and higher lows: an **uptrend**.',
      TrendDirection.down => 'Lower highs and lower lows: a **downtrend**.',
      TrendDirection.sideways =>
        'Price keeps turning at about the same high and low: a **range**.',
    },
    ChartTask.support =>
      'Support is the area near the **bottom** of the range, where the dips '
          'kept stopping.',
    ChartTask.resistance =>
      'Resistance is the area near the **top** of the range, where the '
          'rallies kept failing.',
    ChartTask.breakout =>
      'The breakout candle is the first one to **close** beyond the range. '
          'Wicks poking through don\'t count until a candle closes there.',
  };
}

/// Round 2: "Size it". A position-sizing question with four options.
class SizingRound {
  const SizingRound({
    required this.market,
    required this.facts,
    required this.options,
    required this.answer,
    required this.unit,
    required this.explanation,
  });

  factory SizingRound._generate(SeededRandom rng, int marketIndex) {
    const balances = [5000.0, 10000.0, 20000.0, 25000.0];
    const risks = [0.5, 1.0, 1.0, 2.0];
    final balance = balances[rng.nextInt(balances.length)];
    final riskPct = risks[rng.nextInt(risks.length)];
    final riskAmount = balance * riskPct / 100;
    final account =
        'Account ${_money(balance)} · risk ${_pct(riskPct)} '
        '(${_money(riskAmount)})';

    late String market, unit, stopFact, unitFact, perUnitText;
    late double lossPerUnit, step;
    switch (marketIndex) {
      case 0:
        final entry = 20.0 + rng.nextInt(60);
        final stop = 0.5 * (1 + rng.nextInt(8));
        market = 'Nova Robotics shares';
        unit = 'shares';
        step = 1;
        lossPerUnit = stop;
        stopFact =
            'Buy at ${_money(entry, cents: true)}, stop-loss at '
            '${_money(entry - stop, cents: true)}';
        unitFact = 'Each share moves \$1 for every \$1 in price';
        perUnitText = 'One share loses ${_money(stop, cents: true)}';
      case 1:
        final pips = 10 + 5 * rng.nextInt(9);
        market = 'EUR/USD';
        unit = 'lots';
        step = 0.01;
        lossPerUnit = pips * 10.0;
        stopFact = 'Stop-loss $pips pips from your entry';
        unitFact = '1 pip = \$10 per lot';
        perUnitText = 'One lot loses $pips × \$10 = ${_money(lossPerUnit)}';
      case 2:
        final dollars = 2 + rng.nextInt(14);
        market = 'Gold';
        unit = 'lots';
        step = 0.01;
        lossPerUnit = dollars * 100.0;
        stopFact = 'Stop-loss \$$dollars below your entry';
        unitFact = '1 lot = 100 ounces, so \$1 = \$100 per lot';
        perUnitText = 'One lot loses \$$dollars × 100 = ${_money(lossPerUnit)}';
      case 3:
        final points = 10 + 5 * rng.nextInt(7);
        market = 'US 500 index';
        unit = 'contracts';
        step = 0.1;
        lossPerUnit = points.toDouble();
        stopFact = 'Stop-loss $points points from your entry';
        unitFact = '\$1 per point per contract';
        perUnitText = 'One contract loses ${_money(lossPerUnit)}';
      default:
        final dollars = 500 + 100 * rng.nextInt(16);
        market = 'Bitcoin';
        unit = 'BTC';
        step = 0.001;
        lossPerUnit = dollars.toDouble();
        stopFact = 'Stop-loss ${_money(lossPerUnit)} below your entry';
        unitFact = '1 BTC moves \$1 for every \$1 in price';
        perUnitText = 'One BTC loses ${_money(lossPerUnit)}';
    }

    final exact = riskAmount / lossPerUnit;
    final answer = _roundDown(exact, step);
    final decimals = _decimals(step);
    // Lots keep two decimals, as brokers show them; other units drop
    // trailing zeros ("4 contracts", "0.25 BTC").
    String fmt(double v) =>
        unit == 'lots' ? v.toStringAsFixed(decimals) : _trim(v);
    final rounded = (exact - answer).abs() > 1e-9;

    // Classic mistakes: off by ten, or by two.
    final candidates = [
      answer * 10,
      answer / 10,
      answer * 2,
      answer / 2,
      answer * 4,
      answer * 3,
    ];
    final wrong = <double>[];
    for (final i in rng.shuffled(List.generate(candidates.length, (i) => i))) {
      final v = candidates[i];
      if (v < step) continue;
      if ((_roundDown(v, step) - v).abs() > 1e-9) continue;
      if (fmt(v) == fmt(answer) || wrong.any((w) => fmt(w) == fmt(v))) {
        continue;
      }
      wrong.add(v);
      if (wrong.length == 3) break;
    }
    final options = rng.shuffled([answer, ...wrong]);
    return SizingRound(
      market: market,
      facts: [account, stopFact, unitFact],
      options: [for (final o in options) '${fmt(o)} $unit'],
      answer: options.indexOf(answer),
      unit: unit,
      explanation:
          '$perUnitText at the stop. Size = ${_money(riskAmount)} ÷ '
          '${_money(lossPerUnit)} = ${rounded ? '${_trim(exact)}, rounded '
                    'down to ' : ''}**${fmt(answer)} $unit**.',
    );
  }

  /// "EUR/USD", "Gold", ...
  final String market;

  /// The givens, one per line.
  final List<String> facts;
  final List<String> options;
  final int answer;
  final String unit;
  final String explanation;
}

enum TradeSetupKind { supportBounce, resistanceFade }

/// Round 3: which "Place the trade" chart to show.
class TradeSetup {
  const TradeSetup({
    required this.kind,
    required this.seed,
    required this.trendPct,
    required this.rangePct,
  });

  factory TradeSetup._generate(SeededRandom rng, int seed) => TradeSetup(
    kind: rng.nextBool(0.5)
        ? TradeSetupKind.supportBounce
        : TradeSetupKind.resistanceFade,
    seed: seed,
    trendPct: rng.nextRange(9, 14),
    rangePct: rng.nextRange(4, 6),
  );

  final TradeSetupKind kind;
  final int seed;

  /// Size of the trend before the range, in percent.
  final double trendPct;

  /// Height of the range, in percent.
  final double rangePct;
}

double _roundDown(double v, double step) =>
    (v / step + 1e-9).floorToDouble() * step;

int _decimals(double step) => step >= 1
    ? 0
    : step >= 0.1
    ? 1
    : step >= 0.01
    ? 2
    : 3;

String _trim(double v) {
  final s = v.toStringAsFixed(4);
  return s.contains('.')
      ? s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
      : s;
}

String _pct(double v) =>
    '${v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString()}%';

/// "\$1,250", or with cents when needed (or asked for): "\$0.50".
String _money(double v, {bool cents = false}) {
  final showCents = cents || (v - v.roundToDouble()).abs() > 1e-9;
  final fixed = v.toStringAsFixed(showCents ? 2 : 0);
  final parts = fixed.split('.');
  final digits = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return '\$$buf${parts.length > 1 ? '.${parts[1]}' : ''}';
}
