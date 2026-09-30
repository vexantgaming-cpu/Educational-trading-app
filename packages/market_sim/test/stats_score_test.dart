import 'package:market_sim/market_sim.dart';
import 'package:test/test.dart';

ClosedTrade trade(double pnl, {double? risk = 100}) => ClosedTrade(
      side: Side.long,
      quantity: 1,
      entryIndex: 0,
      entryPrice: 100,
      exitIndex: 1,
      exitPrice: 100 + pnl,
      exitReason: pnl > 0 ? ExitReason.takeProfit : ExitReason.stopLoss,
      grossPnl: pnl,
      fees: 0,
      riskAmount: risk,
    );

void main() {
  test('TradeStats', () {
    final stats =
        TradeStats.from([trade(200), trade(-100), trade(150), trade(-100)]);
    expect(stats.count, 4);
    expect(stats.wins, 2);
    expect(stats.winRate, 0.5);
    expect(stats.netPnl, closeTo(150, 1e-9));
    expect(stats.expectancy, closeTo(37.5, 1e-9));
    expect(stats.profitFactor, closeTo(1.75, 1e-9));
    expect(stats.averageR, closeTo(0.375, 1e-9));
    expect(stats.averageLoss, closeTo(100, 1e-9));
    // Peak 10 200 → 10 100 is the deepest dip: 100 / 10 200.
    expect(stats.maxDrawdownPct, closeTo(100 / 10200 * 100, 1e-9));
  });

  test('TradeStats with no trades or no losses', () {
    final empty = TradeStats.from(const []);
    expect(empty.count, 0);
    expect(empty.winRate, 0);
    expect(empty.averageR, isNull);
    expect(TradeStats.from([trade(50)]).profitFactor, isNull);
  });

  group('scoreTradePlan', () {
    ProcessScore score({double? stop, double? target, double quantity = 50}) =>
        scoreTradePlan(
          side: Side.long,
          entry: 100,
          stop: stop,
          target: target,
          quantity: quantity,
          balance: 10000,
          spec: Instruments.stock,
        );

    test('a stop, 2:1 target and 1% risk scores 100', () {
      final s = score(stop: 98, target: 104);
      expect(s.score, 100);
      expect(s.grade, 'Excellent plan');
      expect(s.checks.every((c) => c.passed), isTrue);
    });

    test('no stop-loss scores 0 and explains why', () {
      final s = score(target: 104);
      expect(s.score, 0);
      expect(s.checks.first.feedback, contains('No stop-loss'));
    });

    test('partial credit for a thin target and slightly large size', () {
      final s = score(stop: 98, target: 102.4, quantity: 75);
      expect(s.checks[1].points, 15); // 1.2 : 1
      expect(s.checks[2].points, 10); // 1.5% risk
      expect(s.score, 65);
    });

    test('oversized risk shows the cost of a losing streak', () {
      final s = score(stop: 98, target: 104, quantity: 250); // 5% risk
      expect(s.checks[2].points, 0);
      expect(s.checks[2].feedback, contains('23%'));
    });

    test('shorts are scored the same way', () {
      final s = scoreTradePlan(
        side: Side.short,
        entry: 100,
        stop: 102,
        target: 96,
        quantity: 50,
        balance: 10000,
        spec: Instruments.stock,
      );
      expect(s.score, 100);
    });
  });
}
