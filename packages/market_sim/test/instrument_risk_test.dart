import 'package:market_sim/market_sim.dart';
import 'package:test/test.dart';

void main() {
  group('InstrumentSpec', () {
    test('rounds quantities down to the lot step', () {
      expect(Instruments.eurUsd.roundQuantityDown(0.0199), 0.01);
      expect(Instruments.stock.roundQuantityDown(49.99), 49);
      expect(Instruments.btcUsd.roundQuantityDown(0.123456), 0.1234);
    });

    test('knows how many decimals a price needs', () {
      expect(Instruments.eurUsd.priceDecimals, 5);
      expect(Instruments.stock.priceDecimals, 2);
      expect(Instruments.us500.priceDecimals, 1);
      expect(Instruments.eurUsd.roundPrice(1.1234567), 1.12346);
    });

    test('tick value = tick size × contract size', () {
      expect(
        Instruments.eurUsd.tickValue,
        closeTo(1.0, 1e-9),
      ); // $1 per 0.1 pip per lot
      expect(Instruments.gold.tickValue, closeTo(1.0, 1e-9));
    });
  });

  group('Risk.rewardRisk', () {
    test('long and short', () {
      expect(
        Risk.rewardRisk(side: Side.long, entry: 100, stop: 98, target: 104),
        2,
      );
      expect(
        Risk.rewardRisk(side: Side.short, entry: 100, stop: 101, target: 97),
        3,
      );
    });

    test('null when a level is missing or on the wrong side', () {
      expect(Risk.rewardRisk(side: Side.long, entry: 100, stop: 98), isNull);
      expect(
        Risk.rewardRisk(side: Side.long, entry: 100, stop: 101, target: 104),
        isNull,
      );
      expect(
        Risk.rewardRisk(side: Side.short, entry: 100, stop: 101, target: 102),
        isNull,
      );
    });

    test('levelError explains wrong-side levels', () {
      expect(
        Risk.levelError(side: Side.long, entry: 100, stop: 101),
        contains('below your entry'),
      );
      expect(
        Risk.levelError(side: Side.short, entry: 100, stop: 101, target: 103),
        contains('take-profit goes below'),
      );
      expect(
        Risk.levelError(side: Side.long, entry: 100, stop: 99, target: 103),
        isNull,
      );
    });
  });

  group('Risk.positionSize', () {
    test('shares: risk 1% of 10k with a 2.00 stop = 50 shares', () {
      final size = Risk.positionSize(
        balance: 10000,
        riskPct: 1,
        entry: 100,
        stop: 98,
        spec: Instruments.stock,
      );
      expect(size.quantity, 50);
      expect(size.riskAmount, closeTo(100, 1e-9));
      expect(size.riskPct, closeTo(1, 1e-9));
      expect(size.leverage, closeTo(0.5, 1e-9));
      expect(size.limitedByLeverage, isFalse);
    });

    test('forex: a 50-pip stop risking 1% of 10k = 0.20 lots', () {
      final size = Risk.positionSize(
        balance: 10000,
        riskPct: 1,
        entry: 1.1,
        stop: 1.095,
        spec: Instruments.eurUsd,
      );
      expect(size.quantity, 0.2);
      expect(size.riskAmount, closeTo(100, 1e-6));
    });

    test('USD/JPY: risk is converted from yen at the stop price', () {
      final size = Risk.positionSize(
        balance: 10000,
        riskPct: 1,
        entry: 150,
        stop: 149.5,
        spec: GameInstruments.usdJpy,
      );
      // 50 pips × 100 000 / 149.5 = \$334.45 per lot → 0.29 lots.
      expect(size.quantity, 0.29);
      expect(size.riskAmount, closeTo(0.29 * 0.5 * 100000 / 149.5, 1e-6));
    });

    test('pip values and distance labels', () {
      expect(GameInstruments.eurUsd.pipValue(1.1), closeTo(10, 1e-9));
      expect(GameInstruments.usdJpy.pipValue(150), closeTo(1000 / 150, 1e-9));
      expect(GameInstruments.eurUsd.formatDistance(0.0025), '25.0 pips');
      expect(GameInstruments.us500.formatDistance(12.5), '12.5 pts');
      expect(GameInstruments.gold.formatDistance(4.2), '\$4.20');
    });

    test('caps the size at the maximum leverage', () {
      // A 0.10 stop would allow 1 000 shares ($100k), but 5:1 caps it at $50k.
      final size = Risk.positionSize(
        balance: 10000,
        riskPct: 1,
        entry: 100,
        stop: 99.9,
        spec: Instruments.stock,
      );
      expect(size.quantity, 500);
      expect(size.limitedByLeverage, isTrue);
      expect(size.riskPct, closeTo(0.5, 1e-9));
    });
  });
}
