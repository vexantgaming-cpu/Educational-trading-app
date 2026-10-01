import 'package:flutter/material.dart';
import 'package:market_sim/market_sim.dart';

import '../theme/app_colors.dart';
import '../widgets/gradient_button.dart';
import 'game_scope.dart';
import 'league_style.dart';
import 'session_summary_screen.dart';
import 'trading_session_screen.dart';

/// Choose today's market. Each card shows that market's morning headline,
/// so reading the news is part of the choice.
class MarketPickerScreen extends StatefulWidget {
  const MarketPickerScreen({super.key, required this.ranked});

  final bool ranked;

  @override
  State<MarketPickerScreen> createState() => _MarketPickerScreenState();
}

class _MarketPickerScreenState extends State<MarketPickerScreen> {
  /// Practice sessions use far-away day numbers, so they never reveal the
  /// ranked chart of today (or of the coming days).
  final _practiceDay = 100000 + DateTime.now().microsecondsSinceEpoch % 900000;

  bool get ranked => widget.ranked;

  int _dayFor(int today) => ranked ? today : _practiceDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = GameScope.of(context);
    final dayNumber = _dayFor(store.dayNumber);
    return Scaffold(
      appBar: AppBar(
        title: Text(ranked ? 'Today\'s ranked session' : 'Practice session'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            ranked
                ? 'Pick one market for today. Read the morning news, then trade the '
                      'session from 08:00 to 16:00. Your result counts for the league.'
                : 'Trade any market with a separate \$10,000. Nothing here affects your league account.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.palette.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          for (final market in GameMarkets.all)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MarketCard(
                market: market,
                day: generateTradingDay(market, dayNumber),
                onTap: () => _start(context, market),
              ),
            ),
        ],
      ),
    );
  }

  void _start(BuildContext context, MarketProfile market) {
    final store = GameScope.of(context);
    final dayNumber = _dayFor(store.dayNumber);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => TradingSessionScreen(
          market: market,
          dayNumber: dayNumber,
          ranked: ranked,
          startingBalance: ranked ? store.balance : LeagueRules.startingBalance,
          onComplete: (result) async {
            if (ranked) {
              await store.recordRankedDay(
                symbol: market.symbol,
                pnl: result.pnl,
                trades: result.trades.length,
              );
            }
            return SessionSummaryScreen(result: result);
          },
        ),
      ),
    );
  }
}

class _MarketCard extends StatelessWidget {
  const _MarketCard({
    required this.market,
    required this.day,
    required this.onTap,
  });

  final MarketProfile market;
  final TradingDay day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spec = market.spec;
    final (icon, colors) = marketStyle(market);
    final dots = switch (day.briefing.impact) {
      NewsImpact.low => 1,
      NewsImpact.medium => 2,
      NewsImpact.high => 3,
    };
    return Material(
      color: context.palette.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: context.palette.outline),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconBadge(icon: icon, colors: colors, size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(spec.name, style: theme.textTheme.titleMedium),
                        Text(
                          '${assetClassLabel(spec.assetClass)} · ${spec.symbol}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        day.sessionOpen.toStringAsFixed(spec.priceDecimals),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Spread ${spec.formatDistance(spec.spread)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('MORNING NEWS', style: theme.textTheme.labelSmall),
                  const SizedBox(width: 6),
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Icon(
                        Icons.circle,
                        size: 7,
                        color: i < dots
                            ? context.palette.gold
                            : context.palette.surfaceHighest,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                day.briefing.headline,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: context.palette.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${day.event.time} · ${day.event.name}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    'Leverage ${spec.maxLeverage.toStringAsFixed(0)}:1',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
