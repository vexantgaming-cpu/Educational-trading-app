import 'dart:math' as math;

enum AssetClass { stock, forex, crypto, commodity, stockIndex, synthetic }

/// Everything the simulator needs to know about a tradable instrument.
///
/// The account currency is assumed to be the instrument's quote currency, so
/// profit = price change × quantity × [contractSize].
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

  /// Money gained or lost when price moves by one tick for 1 quantity.
  double get tickValue => tickSize * contractSize;

  /// Number of decimals needed to display a price.
  int get priceDecimals {
    if (tickSize >= 1) return 0;
    return (-math.log(tickSize) / math.ln10).ceil().clamp(0, 10);
  }

  double roundPrice(double price) =>
      double.parse(((price / tickSize).round() * tickSize)
          .toStringAsFixed(priceDecimals));

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
