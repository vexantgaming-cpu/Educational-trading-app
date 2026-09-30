import 'candle.dart';

enum SwingType { high, low }

/// A turning point: a bar whose high (or low) is the extreme of its
/// neighbourhood.
class Swing {
  const Swing({required this.index, required this.price, required this.type});

  final int index;
  final double price;
  final SwingType type;

  @override
  String toString() => 'Swing(${type.name} @ $index: $price)';
}

enum TrendDirection { up, down, sideways }

/// Finds swing highs and lows. A swing high at bar i has a higher high than
/// the [strength] bars on each side (ties on the right are allowed so equal
/// highs are only counted once).
List<Swing> findSwings(List<Candle> candles, {int strength = 3}) {
  final swings = <Swing>[];
  for (var i = strength; i < candles.length - strength; i++) {
    var isHigh = true, isLow = true;
    for (var j = 1; j <= strength; j++) {
      if (candles[i - j].high >= candles[i].high ||
          candles[i + j].high > candles[i].high) {
        isHigh = false;
      }
      if (candles[i - j].low <= candles[i].low ||
          candles[i + j].low < candles[i].low) {
        isLow = false;
      }
    }
    if (isHigh) {
      swings.add(Swing(index: i, price: candles[i].high, type: SwingType.high));
    }
    if (isLow) {
      swings.add(Swing(index: i, price: candles[i].low, type: SwingType.low));
    }
  }
  return swings;
}

/// Classic market-structure read: higher highs and higher lows = up,
/// lower highs and lower lows = down, anything else = sideways.
TrendDirection classifyTrend(List<Swing> swings) {
  final highs = swings.where((s) => s.type == SwingType.high).toList();
  final lows = swings.where((s) => s.type == SwingType.low).toList();
  if (highs.length < 2 || lows.length < 2) return TrendDirection.sideways;
  final higherHigh = highs.last.price > highs[highs.length - 2].price;
  final higherLow = lows.last.price > lows[lows.length - 2].price;
  if (higherHigh && higherLow) return TrendDirection.up;
  if (!higherHigh && !higherLow) return TrendDirection.down;
  return TrendDirection.sideways;
}
