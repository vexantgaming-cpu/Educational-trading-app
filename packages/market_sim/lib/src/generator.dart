import 'dart:math' as math;

import 'candle.dart';
import 'rng.dart';

/// One scripted piece of a teaching chart.
sealed class Segment {
  const Segment({required this.bars, this.label});

  final int bars;

  /// Optional name for the answer key, e.g. "breakout".
  final String? label;
}

/// A trending leg made of impulses and pullbacks (clean HH/HL or LH/LL
/// structure). The segment closes exactly [movePct] away from where it began.
class TrendSegment extends Segment {
  const TrendSegment({
    required super.bars,
    required this.movePct,
    this.volatilityPct = 1.0,
    this.volumeMultiplier = 1.0,
    this.pullbacks = true,
    super.label,
  });

  /// Total move over the segment in percent: +12 = up 12%, -8 = down 8%.
  final double movePct;
  final double volatilityPct;
  final double volumeMultiplier;
  final bool pullbacks;
}

/// Sideways market bouncing between a support and a resistance zone.
///
/// Support sits [belowPct] below the starting price and resistance
/// [abovePct] above it.
class RangeSegment extends Segment {
  const RangeSegment({
    required super.bars,
    required this.belowPct,
    required this.abovePct,
    this.volatilityPct = 0.8,
    this.volumeMultiplier = 0.8,
    super.label,
  });

  final double belowPct;
  final double abovePct;
  final double volatilityPct;
  final double volumeMultiplier;
}

enum ZoneKind { support, resistance }

/// A price zone the learner should be able to find, e.g. for "Spot it".
class Zone {
  const Zone({
    required this.kind,
    required this.low,
    required this.high,
    required this.fromIndex,
    required this.toIndex,
  });

  final ZoneKind kind;
  final double low;
  final double high;
  final int fromIndex;
  final int toIndex;

  double get mid => (low + high) / 2;
  bool contains(double price, {double tolerance = 0}) =>
      price >= low - tolerance && price <= high + tolerance;
}

/// Which bars belong to which segment ("uptrend", "range", ...).
class SegmentSpan {
  const SegmentSpan({
    required this.kind,
    required this.fromIndex,
    required this.toIndex,
    this.label,
  });

  final String kind;
  final int fromIndex;
  final int toIndex;
  final String? label;
}

/// A generated chart plus its answer key.
class Scenario {
  const Scenario({
    required this.seed,
    required this.candles,
    required this.zones,
    required this.spans,
  });

  final int seed;
  final List<Candle> candles;
  final List<Zone> zones;
  final List<SegmentSpan> spans;

  Map<String, dynamic> toJson() => {
    'seed': seed,
    'candles': [for (final c in candles) c.toJson()],
    'zones': [
      for (final z in zones)
        {
          'kind': z.kind.name,
          'low': z.low,
          'high': z.high,
          'from': z.fromIndex,
          'to': z.toIndex,
        },
    ],
    'spans': [
      for (final s in spans)
        {
          'kind': s.kind,
          'from': s.fromIndex,
          'to': s.toIndex,
          if (s.label != null) 'label': s.label,
        },
    ],
  };
}

/// Builds synthetic, realistic-looking charts from scripted segments.
///
/// Synthetic charts cost nothing to license, work for any "instrument", and
/// come with an exact answer key (where the support is, where the trend
/// starts), which makes exercises gradable. The same seed always gives the
/// same chart.
class ScenarioGenerator {
  ScenarioGenerator({
    required this.seed,
    this.startPrice = 100,
    this.tickSize = 0.01,
    this.baseVolume = 1000,
  }) : _rng = SeededRandom(seed);

  final int seed;
  final double startPrice;
  final double tickSize;
  final double baseVolume;
  final SeededRandom _rng;

  Scenario generate(List<Segment> segments) {
    final closes = <double>[];
    final vols = <double>[];
    final volumeMults = <double>[];
    final zones = <Zone>[];
    final spans = <SegmentSpan>[];
    var price = startPrice;

    for (final segment in segments) {
      final from = closes.length;
      final to = from + segment.bars - 1;
      switch (segment) {
        case TrendSegment():
          closes.addAll(_trendPath(price, segment));
          vols.addAll(List.filled(segment.bars, segment.volatilityPct));
          volumeMults.addAll(
            List.filled(segment.bars, segment.volumeMultiplier),
          );
          spans.add(
            SegmentSpan(
              kind: segment.movePct >= 0 ? 'uptrend' : 'downtrend',
              fromIndex: from,
              toIndex: to,
              label: segment.label,
            ),
          );
        case RangeSegment():
          final support = price * (1 - segment.belowPct / 100);
          final resistance = price * (1 + segment.abovePct / 100);
          final halfWidth = math.max(
            price * segment.volatilityPct / 100 * 0.5,
            tickSize * 5,
          );
          closes.addAll(
            _rangePath(price, support, resistance, halfWidth, segment),
          );
          vols.addAll(List.filled(segment.bars, segment.volatilityPct));
          volumeMults.addAll(
            List.filled(segment.bars, segment.volumeMultiplier),
          );
          zones
            ..add(
              Zone(
                kind: ZoneKind.support,
                low: _round(support - halfWidth),
                high: _round(support + halfWidth),
                fromIndex: from,
                toIndex: to,
              ),
            )
            ..add(
              Zone(
                kind: ZoneKind.resistance,
                low: _round(resistance - halfWidth),
                high: _round(resistance + halfWidth),
                fromIndex: from,
                toIndex: to,
              ),
            );
          spans.add(
            SegmentSpan(
              kind: 'range',
              fromIndex: from,
              toIndex: to,
              label: segment.label,
            ),
          );
      }
      price = closes.last;
    }

    return Scenario(
      seed: seed,
      candles: _buildCandles(closes, vols, volumeMults),
      zones: zones,
      spans: spans,
    );
  }

  /// A random mix of trends and ranges for free practice in the Arena.
  Scenario randomMarket({int bars = 200}) {
    final segments = <Segment>[];
    var total = 0;
    while (total < bars) {
      final length = math.min(20 + _rng.nextInt(31), bars - total);
      final roll = _rng.nextDouble();
      if (roll < 0.4) {
        segments.add(
          TrendSegment(bars: length, movePct: _rng.nextRange(5, 20)),
        );
      } else if (roll < 0.7) {
        segments.add(
          TrendSegment(bars: length, movePct: -_rng.nextRange(5, 16)),
        );
      } else {
        segments.add(
          RangeSegment(
            bars: length,
            belowPct: _rng.nextRange(1.5, 5),
            abovePct: _rng.nextRange(1.5, 5),
          ),
        );
      }
      total += length;
    }
    return generate(segments);
  }

  List<double> _trendPath(double start, TrendSegment segment) {
    final totalLog = math.log(1 + segment.movePct / 100);
    final impulses = segment.pullbacks && segment.bars >= 8
        ? math.max(1, segment.bars ~/ 10)
        : 1;

    // Leg sizes in log space: impulse, pullback, impulse, ... impulse.
    final pullbackRatios = List.generate(
      impulses - 1,
      (_) => _rng.nextRange(0.3, 0.6),
    );
    final impulse =
        totalLog / (impulses - pullbackRatios.fold<double>(0, (a, b) => a + b));
    final legs = <double>[];
    final weights = <double>[];
    for (var i = 0; i < impulses; i++) {
      legs.add(impulse);
      weights.add(1);
      if (i < impulses - 1) {
        legs.add(-impulse * pullbackRatios[i]);
        weights.add(0.6);
      }
    }
    final legBars = _allocate(segment.bars, weights);

    final path = <double>[];
    var current = start;
    for (var i = 0; i < legs.length; i++) {
      final target = current * math.exp(legs[i]);
      path.addAll(_bridge(current, target, legBars[i], segment.volatilityPct));
      current = target;
    }
    return path;
  }

  List<double> _rangePath(
    double start,
    double support,
    double resistance,
    double halfWidth,
    RangeSegment segment,
  ) {
    final path = <double>[];
    var current = start;
    // Head for the farther boundary first, then alternate.
    var goingDown = (start - support) > (resistance - start);
    while (path.length < segment.bars) {
      final legLength = 4 + _rng.nextInt(6);
      final target = goingDown
          ? support + _rng.nextRange(-0.2, 1.0) * halfWidth
          : resistance - _rng.nextRange(-0.2, 1.0) * halfWidth;
      final leg = _bridge(
        current,
        target,
        legLength,
        segment.volatilityPct * 0.6,
      );
      for (final p in leg) {
        if (path.length == segment.bars) break;
        path.add(p.clamp(support - halfWidth, resistance + halfWidth));
      }
      current = target;
      goingDown = !goingDown;
    }
    return path;
  }

  /// Brownian bridge in log space from [from] to exactly [to] over [bars].
  List<double> _bridge(double from, double to, int bars, double volPct) {
    final x0 = math.log(from), x1 = math.log(to);
    final walk = <double>[];
    var sum = 0.0;
    for (var i = 0; i < bars; i++) {
      sum += _rng.nextGaussian() * volPct / 100;
      walk.add(sum);
    }
    return [
      for (var k = 1; k <= bars; k++)
        math.exp(
          x0 +
              walk[k - 1] -
              (k / bars) * walk[bars - 1] +
              (k / bars) * (x1 - x0),
        ),
    ];
  }

  /// Splits [total] bars across legs in proportion to [weights] (min 2 each).
  List<int> _allocate(int total, List<double> weights) {
    final sum = weights.fold<double>(0, (a, b) => a + b);
    final bars = [
      for (final w in weights) math.max(2, (total * w / sum).floor()),
    ];
    var diff = total - bars.fold<int>(0, (a, b) => a + b);
    var i = 0;
    while (diff != 0) {
      final index = i % bars.length;
      if (diff > 0) {
        bars[index]++;
        diff--;
      } else if (bars[index] > 1) {
        bars[index]--;
        diff++;
      }
      i++;
    }
    return bars;
  }

  List<Candle> _buildCandles(
    List<double> closes,
    List<double> vols,
    List<double> volumeMults,
  ) {
    final candles = <Candle>[];
    var previousClose = startPrice;
    for (var i = 0; i < closes.length; i++) {
      final open = _round(previousClose);
      final close = _round(closes[i]);
      final wickScale = closes[i] * vols[i] / 100 * 0.5;
      final high = _round(
        math.max(open, close) + _rng.nextGaussian().abs() * wickScale,
      );
      final low = _round(
        math.min(open, close) - _rng.nextGaussian().abs() * wickScale,
      );
      final move = (close - open).abs() / (closes[i] * vols[i] / 100);
      final volume =
          (baseVolume *
                  volumeMults[i] *
                  (0.6 + 0.8 * _rng.nextDouble()) *
                  (1 + 0.8 * move))
              .roundToDouble();
      candles.add(
        Candle(open: open, high: high, low: low, close: close, volume: volume),
      );
      previousClose = closes[i];
    }
    return candles;
  }

  double _round(double price) {
    final decimals = tickSize >= 1
        ? 0
        : (-math.log(tickSize) / math.ln10).ceil().clamp(0, 10);
    return double.parse(
      ((price / tickSize).round() * tickSize).toStringAsFixed(decimals),
    );
  }
}
