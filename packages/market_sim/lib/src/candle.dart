/// One price bar: open, high, low, close and volume.
class Candle {
  const Candle({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume = 0,
  });

  factory Candle.fromJson(Map<String, dynamic> json) => Candle(
    open: (json['o'] as num).toDouble(),
    high: (json['h'] as num).toDouble(),
    low: (json['l'] as num).toDouble(),
    close: (json['c'] as num).toDouble(),
    volume: (json['v'] as num? ?? 0).toDouble(),
  );

  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  bool get isBullish => close >= open;
  double get range => high - low;
  double get body => (close - open).abs();
  double get upperWick => high - (open > close ? open : close);
  double get lowerWick => (open < close ? open : close) - low;

  Map<String, dynamic> toJson() => {
    'o': open,
    'h': high,
    'l': low,
    'c': close,
    'v': volume,
  };

  @override
  String toString() => 'Candle(o: $open, h: $high, l: $low, c: $close)';
}

/// Combines every [factor] consecutive candles into one, turning e.g. 1-hour
/// candles into 4-hour candles. A trailing partial group is kept.
List<Candle> aggregateCandles(List<Candle> candles, int factor) {
  if (factor <= 1) return List.of(candles);
  final out = <Candle>[];
  for (var i = 0; i < candles.length; i += factor) {
    final group = candles.sublist(
      i,
      i + factor > candles.length ? candles.length : i + factor,
    );
    var high = group.first.high, low = group.first.low, volume = 0.0;
    for (final c in group) {
      if (c.high > high) high = c.high;
      if (c.low < low) low = c.low;
      volume += c.volume;
    }
    out.add(
      Candle(
        open: group.first.open,
        high: high,
        low: low,
        close: group.last.close,
        volume: volume,
      ),
    );
  }
  return out;
}
