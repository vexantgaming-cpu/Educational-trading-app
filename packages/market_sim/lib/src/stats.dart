import 'replay.dart';

/// Performance summary of a list of closed trades.
class TradeStats {
  const TradeStats({
    required this.count,
    required this.wins,
    required this.losses,
    required this.netPnl,
    required this.winRate,
    required this.averageWin,
    required this.averageLoss,
    required this.expectancy,
    required this.profitFactor,
    required this.averageR,
    required this.maxDrawdownPct,
  });

  factory TradeStats.from(List<ClosedTrade> trades,
      {double startingBalance = 10000}) {
    final winners = trades.where((t) => t.netPnl > 0).toList();
    final losers = trades.where((t) => t.netPnl <= 0).toList();
    final grossWins = winners.fold<double>(0, (a, t) => a + t.netPnl);
    final grossLosses = losers.fold<double>(0, (a, t) => a + t.netPnl).abs();
    final rValues = [
      for (final t in trades)
        if (t.rMultiple != null) t.rMultiple!
    ];

    var equity = startingBalance, peak = startingBalance, maxDrawdown = 0.0;
    for (final t in trades) {
      equity += t.netPnl;
      if (equity > peak) peak = equity;
      final drawdown = peak <= 0 ? 0.0 : (peak - equity) / peak;
      if (drawdown > maxDrawdown) maxDrawdown = drawdown;
    }

    final net = grossWins - grossLosses;
    return TradeStats(
      count: trades.length,
      wins: winners.length,
      losses: losers.length,
      netPnl: net,
      winRate: trades.isEmpty ? 0 : winners.length / trades.length,
      averageWin: winners.isEmpty ? 0 : grossWins / winners.length,
      averageLoss: losers.isEmpty ? 0 : grossLosses / losers.length,
      expectancy: trades.isEmpty ? 0 : net / trades.length,
      profitFactor: grossLosses == 0 ? null : grossWins / grossLosses,
      averageR: rValues.isEmpty
          ? null
          : rValues.reduce((a, b) => a + b) / rValues.length,
      maxDrawdownPct: maxDrawdown * 100,
    );
  }

  final int count;
  final int wins;

  /// Break-even trades count as losses (costs were paid for nothing).
  final int losses;
  final double netPnl;

  /// 0–1.
  final double winRate;
  final double averageWin;

  /// Positive number: the average size of a losing trade.
  final double averageLoss;

  /// Average net result per trade.
  final double expectancy;

  /// Gross wins ÷ gross losses; null when there are no losses yet.
  final double? profitFactor;
  final double? averageR;
  final double maxDrawdownPct;
}
