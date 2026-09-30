import 'dart:math' as math;

enum AssetClass { stock, forex, crypto, commodity, stockIndex, synthetic }

/// How a distance in price is shown to the learner.
enum DistanceUnit { pips, points, currency }

/// Everything the simulator needs to know about a tradable instrument.
///
/// Accounts are in US dollars. For most instruments the quote currency is
/// USD, so profit = price change × quantity × [contractSize]. For pairs like
/// USD/JPY ([baseIsAccountCurrency]), the result is in JPY and is converted
/// back to USD at the current price.
class InstrumentSpec {
  const InstrumentSpec({
    required this.symbol,
    required this.name,
    required this.assetClass,
    required this.tickSize,
    this.contractSize = 1,
    this.lotStep = 1,
    this.spread = 0,
    this.commissionRate = 0,
    this.maxLeverage = 1,
    this.quantityUnit = 'units',
    this.baseIsAccountCurrency = false,
    this.pipSize,
    this.distanceUnit = DistanceUnit.currency,
  });

  final String symbol;
  final String name;
  final AssetClass assetClass;

  /// Smallest price increment (0.01 for a stock, 0.00001 for EUR/USD).
  final double tickSize;

  /// Units of the underlying per 1 quantity (1 share, 100 000 for an FX lot).
  final double contractSize;

  /// Smallest quantity increment (1 share, 0.01 lot, 0.0001 BTC).
  final double lotStep;

  /// Ask minus bid, in price units. Half is paid on entry, half on exit.
  final double spread;

  /// Commission as a fraction of notional value, charged per side.
  final double commissionRate;

  /// Maximum leverage allowed (1 = no leverage).
  final double maxLeverage;

  /// What one quantity is called in the UI: "shares", "lots", "BTC".
  final String quantityUnit;

  /// True for pairs like USD/JPY, where profits are in the quote currency and
  /// must be divided by the price to get dollars.
  final bool baseIsAccountCurrency;

  /// Size of one pip for currency pairs (0.0001, or 0.01 for JPY pairs).
  final double? pipSize;
  final DistanceUnit distanceUnit;

  /// Converts an amount in the quote currency to the account currency.
  double toAccount(double quoteAmount, double price) =>
      baseIsAccountCurrency ? quoteAmount / price : quoteAmount;

  /// Position value in the account currency.
  double notionalInAccount(double price, double quantity) =>
      toAccount(notional(price, quantity), price);

  /// Account-currency value of a one-pip (or one-point) move for 1 quantity.
  double pipValue(double price) =>
      toAccount((pipSize ?? 1) * contractSize, price);

  /// "25.0 pips", "12.5 pts", "\$1.85".
  String formatDistance(double priceDistance) {
    final d = priceDistance.abs();
    return switch (distanceUnit) {
      DistanceUnit.pips =>
        '${(d / (pipSize ?? tickSize)).toStringAsFixed(1)} pips',
      DistanceUnit.points => '${d.toStringAsFixed(priceDecimals)} pts',
      DistanceUnit.currency => '\$${d.toStringAsFixed(priceDecimals)}',
    };
  }

  /// Money gained or lost when price moves by one tick for 1 quantity.
  double get tickValue => tickSize * contractSize;

  /// Number of decimals needed to display a price.
  int get priceDecimals {
    if (tickSize >= 1) return 0;
    return (-math.log(tickSize) / math.ln10).ceil().clamp(0, 10);
  }

  double roundPrice(double price) => double.parse(
    ((price / tickSize).round() * tickSize).toStringAsFixed(priceDecimals),
  );

  /// Rounds a quantity down to a whole number of [lotStep]s.
  double roundQuantityDown(double quantity) {
    final steps = (quantity / lotStep + 1e-9).floorToDouble();
    final decimals = lotStep >= 1
        ? 0
        : (-math.log(lotStep) / math.ln10).ceil().clamp(0, 10);
    return double.parse((steps * lotStep).toStringAsFixed(decimals));
  }

  double notional(double price, double quantity) =>
      price * quantity * contractSize;
}

/// Example instruments. Leverage caps follow the EU (ESMA) retail limits,
/// which is also a good teaching default: 30:1 major FX, 20:1 gold and major
/// indices, 5:1 single stocks, 2:1 crypto.
class Instruments {
  static const synthetic = InstrumentSpec(
    symbol: 'MKT',
    name: 'Practice Market',
    assetClass: AssetClass.synthetic,
    tickSize: 0.01,
    contractSize: 1,
    lotStep: 1,
    spread: 0.02,
    maxLeverage: 5,
    quantityUnit: 'units',
  );

  static const stock = InstrumentSpec(
    symbol: 'STOCK',
    name: 'Example Stock',
    assetClass: AssetClass.stock,
    tickSize: 0.01,
    contractSize: 1,
    lotStep: 1,
    spread: 0.02,
    commissionRate: 0.0005,
    maxLeverage: 5,
    quantityUnit: 'shares',
  );

  static const eurUsd = InstrumentSpec(
    symbol: 'EURUSD',
    name: 'Euro / US Dollar',
    assetClass: AssetClass.forex,
    tickSize: 0.00001,
    contractSize: 100000,
    lotStep: 0.01,
    spread: 0.0001,
    maxLeverage: 30,
    quantityUnit: 'lots',
  );

  static const gold = InstrumentSpec(
    symbol: 'XAUUSD',
    name: 'Gold',
    assetClass: AssetClass.commodity,
    tickSize: 0.01,
    contractSize: 100,
    lotStep: 0.01,
    spread: 0.3,
    maxLeverage: 20,
    quantityUnit: 'lots',
  );

  static const us500 = InstrumentSpec(
    symbol: 'US500',
    name: 'US 500 Index',
    assetClass: AssetClass.stockIndex,
    tickSize: 0.1,
    contractSize: 1,
    lotStep: 0.1,
    spread: 0.5,
    maxLeverage: 20,
    quantityUnit: 'contracts',
  );

  static const btcUsd = InstrumentSpec(
    symbol: 'BTCUSD',
    name: 'Bitcoin / US Dollar',
    assetClass: AssetClass.crypto,
    tickSize: 0.01,
    contractSize: 1,
    lotStep: 0.0001,
    spread: 10,
    commissionRate: 0.001,
    maxLeverage: 2,
    quantityUnit: 'BTC',
  );

  static const all = [synthetic, stock, eurUsd, gold, us500, btcUsd];
}

/// Instruments of the trading game with realistic retail specs: default
/// spreads typical of major brokers, contract sizes, and EU (ESMA) retail
/// leverage caps (30:1 major FX, 20:1 gold and major indices, 10:1 other
/// commodities, 5:1 shares, 2:1 crypto).
class GameInstruments {
  static const eurUsd = InstrumentSpec(
    symbol: 'EURUSD',
    name: 'EUR/USD',
    assetClass: AssetClass.forex,
    tickSize: 0.00001,
    contractSize: 100000,
    lotStep: 0.01,
    spread: 0.0001,
    maxLeverage: 30,
    quantityUnit: 'lots',
    pipSize: 0.0001,
    distanceUnit: DistanceUnit.pips,
  );

  static const gbpUsd = InstrumentSpec(
    symbol: 'GBPUSD',
    name: 'GBP/USD',
    assetClass: AssetClass.forex,
    tickSize: 0.00001,
    contractSize: 100000,
    lotStep: 0.01,
    spread: 0.00015,
    maxLeverage: 30,
    quantityUnit: 'lots',
    pipSize: 0.0001,
    distanceUnit: DistanceUnit.pips,
  );

  static const usdJpy = InstrumentSpec(
    symbol: 'USDJPY',
    name: 'USD/JPY',
    assetClass: AssetClass.forex,
    tickSize: 0.001,
    contractSize: 100000,
    lotStep: 0.01,
    spread: 0.012,
    maxLeverage: 30,
    quantityUnit: 'lots',
    baseIsAccountCurrency: true,
    pipSize: 0.01,
    distanceUnit: DistanceUnit.pips,
  );

  static const gold = InstrumentSpec(
    symbol: 'XAUUSD',
    name: 'Gold',
    assetClass: AssetClass.commodity,
    tickSize: 0.01,
    contractSize: 100,
    lotStep: 0.01,
    spread: 0.30,
    maxLeverage: 20,
    quantityUnit: 'lots',
  );

  static const oil = InstrumentSpec(
    symbol: 'USOIL',
    name: 'US Crude Oil',
    assetClass: AssetClass.commodity,
    tickSize: 0.01,
    contractSize: 1000,
    lotStep: 0.01,
    spread: 0.03,
    maxLeverage: 10,
    quantityUnit: 'lots',
  );

  static const us500 = InstrumentSpec(
    symbol: 'US500',
    name: 'US 500',
    assetClass: AssetClass.stockIndex,
    tickSize: 0.1,
    contractSize: 1,
    lotStep: 0.1,
    spread: 0.5,
    maxLeverage: 20,
    quantityUnit: 'contracts',
    distanceUnit: DistanceUnit.points,
  );

  static const tech100 = InstrumentSpec(
    symbol: 'US100',
    name: 'US Tech 100',
    assetClass: AssetClass.stockIndex,
    tickSize: 0.1,
    contractSize: 1,
    lotStep: 0.1,
    spread: 1.5,
    maxLeverage: 20,
    quantityUnit: 'contracts',
    distanceUnit: DistanceUnit.points,
  );

  static const btcUsd = InstrumentSpec(
    symbol: 'BTCUSD',
    name: 'Bitcoin',
    assetClass: AssetClass.crypto,
    tickSize: 0.01,
    contractSize: 1,
    lotStep: 0.001,
    spread: 30,
    maxLeverage: 2,
    quantityUnit: 'BTC',
  );

  /// A fictional company, so no real firm is attached to made-up news.
  static const nova = InstrumentSpec(
    symbol: 'NOVA',
    name: 'Nova Robotics',
    assetClass: AssetClass.stock,
    tickSize: 0.01,
    contractSize: 1,
    lotStep: 1,
    spread: 0.04,
    commissionRate: 0.0005,
    maxLeverage: 5,
    quantityUnit: 'shares',
  );
}
