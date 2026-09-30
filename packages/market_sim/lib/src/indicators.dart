import 'dart:math' as math;

import 'candle.dart';

/// Technical indicators. Each returns one value per input bar, with `null`
/// until enough bars exist to compute it.
class Indicators {
  /// Simple moving average.
  static List<double?> sma(List<double> values, int period) {
    final out = List<double?>.filled(values.length, null);
    var sum = 0.0;
    for (var i = 0; i < values.length; i++) {
      sum += values[i];
      if (i >= period) sum -= values[i - period];
      if (i >= period - 1) out[i] = sum / period;
    }
    return out;
  }

  /// Exponential moving average, seeded with the SMA of the first [period].
  static List<double?> ema(List<double> values, int period) {
    final out = List<double?>.filled(values.length, null);
    if (values.length < period) return out;
    final k = 2 / (period + 1);
    var previous = values.take(period).fold<double>(0, (a, b) => a + b) / period;
    out[period - 1] = previous;
    for (var i = period; i < values.length; i++) {
      previous = values[i] * k + previous * (1 - k);
      out[i] = previous;
    }
    return out;
  }

  /// Relative Strength Index with Wilder's smoothing (0–100).
  static List<double?> rsi(List<double> values, {int period = 14}) {
    final out = List<double?>.filled(values.length, null);
    if (values.length <= period) return out;
    var gain = 0.0, loss = 0.0;
    for (var i = 1; i <= period; i++) {
      final change = values[i] - values[i - 1];
      if (change >= 0) {
        gain += change;
      } else {
        loss -= change;
      }
    }
    gain /= period;
    loss /= period;
    out[period] = _rsiValue(gain, loss);
    for (var i = period + 1; i < values.length; i++) {
      final change = values[i] - values[i - 1];
      gain = (gain * (period - 1) + math.max(change, 0)) / period;
      loss = (loss * (period - 1) + math.max(-change, 0)) / period;
      out[i] = _rsiValue(gain, loss);
    }
    return out;
  }

  /// Average True Range with Wilder's smoothing.
  static List<double?> atr(List<Candle> candles, {int period = 14}) {
    final out = List<double?>.filled(candles.length, null);
    if (candles.length < period) return out;
    final trueRanges = [
      for (var i = 0; i < candles.length; i++)
        i == 0
            ? candles[i].range
            : [
                candles[i].range,
                (candles[i].high - candles[i - 1].close).abs(),
                (candles[i].low - candles[i - 1].close).abs(),
              ].reduce(math.max),
    ];
    var value = trueRanges.take(period).fold<double>(0, (a, b) => a + b) / period;
    out[period - 1] = value;
    for (var i = period; i < candles.length; i++) {
      value = (value * (period - 1) + trueRanges[i]) / period;
      out[i] = value;
    }
    return out;
  }

  static double _rsiValue(double avgGain, double avgLoss) {
    if (avgLoss == 0) return avgGain == 0 ? 50 : 100;
    final rs = avgGain / avgLoss;
    return 100 - 100 / (1 + rs);
  }
}
