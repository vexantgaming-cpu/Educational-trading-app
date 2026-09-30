import 'package:market_sim/market_sim.dart';
import 'package:test/test.dart';

void main() {
  test('stableHash is FNV-1a and identical on every platform', () {
    expect(stableHash(''), 0x811c9dc5);
    expect(stableHash('a'), 0xe40c292c);
    // Reference values from a 32-bit FNV-1a implementation in JavaScript.
    expect(stableHash('US500:275'), _jsFnv['US500:275']);
    expect(stableHash('EURUSD:272'), _jsFnv['EURUSD:272']);
  });

  test('a known day has the same prices on every platform', () {
    final d = generateTradingDay(GameMarkets.us500, 275);
    expect(d.candles[d.sessionStart].close, _us500Day275FirstClose);
  });

  test('the same market and day give everyone the same chart and news', () {
    final a = generateTradingDay(GameMarkets.eurUsd, 270);
    final b = generateTradingDay(GameMarkets.eurUsd, 270);
    expect(
      [for (final c in a.candles) c.close],
      [for (final c in b.candles) c.close],
    );
    expect(a.briefing.headline, b.briefing.headline);
    final other = generateTradingDay(GameMarkets.eurUsd, 271);
    expect(other.candles.last.close, isNot(a.candles.last.close));
  });

  for (final market in GameMarkets.all) {
    test('${market.symbol}: well-formed day with news and wider spreads', () {
      for (var day = 1; day <= 20; day++) {
        final d = generateTradingDay(market, day);
        expect(
          d.candles,
          hasLength(TradingDay.historyBars + TradingDay.sessionBars),
        );
        expect(d.spreads, hasLength(d.candles.length));
        expect(d.sessionStart, TradingDay.historyBars);
        expect(d.event.index, d.sessionStart + TradingDay.eventOffset);
        expect(d.event.time, '13:30');
        expect(d.timeAt(d.sessionStart), '08:05');
        expect(d.timeAt(d.sessionEnd), '16:00');
        expect(
          d.spreads[d.event.index],
          closeTo(market.spec.spread * 3, market.spec.tickSize),
        );
        expect(d.spreads[d.sessionStart + 10], market.spec.spread);
        for (final sp in d.spreads) {
          final ticks = sp / market.spec.tickSize;
          expect(
            (ticks - ticks.round()).abs(),
            lessThan(1e-6),
            reason: 'spreads stay on the tick grid',
          );
        }
        for (final c in d.candles) {
          for (final p in [c.open, c.high, c.low, c.close]) {
            final ticks = p / market.spec.tickSize;
            expect((ticks - ticks.round()).abs(), lessThan(1e-6));
          }
        }
        for (final c in d.candles) {
          expect(c.low, lessThanOrEqualTo(c.high));
          expect(c.low, greaterThan(0));
        }
        // Day range stays in a realistic band for the instrument.
        final session = d.candles.sublist(d.sessionStart);
        final hi = session.map((c) => c.high).reduce((a, b) => a > b ? a : b);
        final lo = session.map((c) => c.low).reduce((a, b) => a < b ? a : b);
        final rangePct = (hi - lo) / d.sessionOpen * 100;
        expect(
          rangePct,
          inInclusiveRange(
            market.dailyVolatilityPct * 0.2,
            market.dailyVolatilityPct * 4,
          ),
        );
        expect(d.recap, isNotEmpty);
        expect(d.briefing.headline, isNotEmpty);
      }
    });
  }

  test('news gives an edge, not a certainty', () {
    var directional = 0, followed = 0;
    for (final market in GameMarkets.all) {
      for (var day = 1; day <= 120; day++) {
        final d = generateTradingDay(market, day);
        if (d.briefing.bias == Bias.neutral) continue;
        directional++;
        final up = d.sessionClose > d.sessionOpen;
        if (up == (d.briefing.bias == Bias.bullish)) followed++;
      }
    }
    final rate = followed / directional;
    expect(
      rate,
      inInclusiveRange(0.5, 0.75),
      reason: 'the bias should be right more often than not, but not always',
    );
  });

  test('start prices wander near the reference level', () {
    for (var day = 0; day < 365; day += 7) {
      final p = GameMarkets.gold.startPriceFor(day);
      expect(p / GameMarkets.gold.referencePrice, inInclusiveRange(0.92, 1.08));
    }
  });
}

/// FNV-1a values computed with Math.imul in JavaScript.
const _jsFnv = {'US500:275': 2875388728, 'EURUSD:272': 2506446648};

/// First session close of US 500 on day 275 (bid).
const _us500Day275FirstClose = 6489.2;
