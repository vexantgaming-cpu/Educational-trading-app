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

  Map<String, dynamic> toJson() =>
      {'o': open, 'h': high, 'l': low, 'c': close, 'v': volume};

  @override
  String toString() => 'Candle(o: $open, h: $high, l: $low, c: $close)';
}
