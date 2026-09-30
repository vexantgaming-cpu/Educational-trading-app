import 'package:market_sim/market_sim.dart';

/// Everything the day summary needs.
class SessionResult {
  const SessionResult({
    required this.day,
    required this.trades,
    required this.startBalance,
    required this.endBalance,
    required this.ranked,
  });

  final TradingDay day;
  final List<ClosedTrade> trades;
  final double startBalance;
  final double endBalance;
  final bool ranked;

  double get pnl => endBalance - startBalance;
  double get returnPct => startBalance == 0 ? 0 : pnl / startBalance * 100;
}
