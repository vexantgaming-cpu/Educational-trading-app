import 'package:flutter/material.dart';
import 'package:market_sim/market_sim.dart';

import '../chart/candle_chart.dart';
import '../chart/chart_models.dart';
import '../format.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_button.dart';
import 'game_scope.dart';
import 'session_result.dart';

/// End-of-day debrief: result, what the news did, every trade, and coaching.
class SessionSummaryScreen extends StatelessWidget {
  const SessionSummaryScreen({super.key, required this.result});

  final SessionResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final day = result.day;
    final spec = day.market.spec;
    final win = result.pnl >= 0;
    final trades = result.trades;
    final spreadPaid = trades.fold<double>(0, (a, t) => a + t.spreadCost);
    final commission = trades.fold<double>(0, (a, t) => a + t.fees);
    final store = result.ranked ? GameScope.of(context) : null;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('${spec.name} · day summary'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.ranked ? 'RANKED SESSION' : 'PRACTICE SESSION',
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    money(result.pnl, signed: true),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: win ? AppColors.up : AppColors.down,
                      fontSize: 34,
                    ),
                  ),
                  Text(
                    '${result.returnPct >= 0 ? '+' : ''}${result.returnPct.toStringAsFixed(2)}% · '
                    'balance ${money(result.endBalance)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (store != null) ...[
                    const SizedBox(height: 12),
                    if (store.justBlown)
                      Text(
                        'Account blown: equity fell below 10% of the starting balance. '
                        'You restart in Bronze with a fresh \$10,000.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.down,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Pill(
                            label: '${store.league.title} league',
                            color: AppColors.gold,
                          ),
                          Pill(
                            label:
                                'Rank #${store.you.rank} of ${LeagueRules.groupSize}',
                            color: AppColors.cyan,
                          ),
                          Pill(
                            label:
                                'Week ${store.seasonReturnPct >= 0 ? '+' : ''}${store.seasonReturnPct.toStringAsFixed(2)}%',
                            color: store.seasonReturnPct >= 0
                                ? AppColors.up
                                : AppColors.down,
                          ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: IgnorePointer(
                child: CandleChart(
                  candles: day.candles,
                  visibleBars: TradingDay.sessionBars,
                  futureSlots: 2,
                  priceDecimals: spec.priceDecimals,
                  markers: [
                    for (final t in trades) ...[
                      ChartMarker(
                        index: t.entryIndex,
                        price: t.entryPrice,
                        pointsUp: t.side == Side.long,
                        color: AppColors.cyan,
                      ),
                      ChartMarker(
                        index: t.exitIndex,
                        price: t.exitPrice,
                        pointsUp: t.side != Side.long,
                        color: t.isWin ? AppColors.up : AppColors.down,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'What the news did',
              children: [
                _NewsLine(
                  time: '08:00',
                  headline: day.briefing.headline,
                  why: day.briefing.why,
                ),
                _NewsLine(
                  time: day.event.time,
                  headline: day.event.headline,
                  why: day.event.why,
                ),
                const SizedBox(height: 4),
                Text(
                  '${day.recap} The market ${day.sessionChangePct >= 0 ? 'rose' : 'fell'} '
                  '${day.sessionChangePct.abs().toStringAsFixed(2)}% on the day.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Section(
              title: trades.isEmpty ? 'No trades today' : 'Your trades',
              children: [
                if (trades.isEmpty)
                  Text(
                    'Sitting out is a valid decision when there is no clear setup. '
                    'In leagues, you need at least ${LeagueRules.minDaysToPromote} trading days a week to be promoted.',
                    style: theme.textTheme.bodyMedium,
                  ),
                for (final t in trades) _TradeRow(trade: t, spec: spec),
                if (trades.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Costs: spread ${money(spreadPaid)}${commission > 0 ? ', commission ${money(commission)}' : ''}.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
            if (trades.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Section(
                title: 'Coach notes',
                children: _coachNotes(
                  context,
                  trades,
                  result.startBalance,
                  spec,
                ),
              ),
            ],
            const SizedBox(height: 20),
            GradientButton(
              label: result.ranked ? 'Back to the league' : 'Done',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _coachNotes(
    BuildContext context,
    List<ClosedTrade> trades,
    double balance,
    InstrumentSpec spec,
  ) {
    final theme = Theme.of(context);
    final notes = <String>[];
    for (final t in trades) {
      final score = scoreTradePlan(
        side: t.side,
        entry: t.entryPrice,
        stop: t.initialStop,
        target: t.takeProfit,
        quantity: t.quantity,
        balance: balance,
        spec: spec,
      );
      for (final c in score.checks.where((c) => !c.passed)) {
        notes.add(c.feedback);
      }
    }
    if (trades.any((t) => t.exitReason == ExitReason.stopOut)) {
      notes.add(
        'A margin stop-out closed a trade: the position was too large for the account.',
      );
    }
    final withBias = trades.where(
      (t) =>
          (t.side == Side.long) == (result.day.briefing.bias == Bias.bullish) &&
          result.day.briefing.bias != Bias.neutral,
    );
    if (result.day.briefing.bias != Bias.neutral && withBias.isEmpty) {
      notes.add(
        'You traded against the morning news. That can work, but have a clear reason on the chart.',
      );
    }
    if (trades.length > 4) {
      notes.add(
        '${trades.length} trades in one day: more trades mean more spread costs. Quality beats quantity.',
      );
    }
    if (notes.isEmpty) {
      notes.add(
        'Solid process: stops in place, sensible size and reward:risk. Keep it up.',
      );
    }
    return [
      for (final n in notes.toSet().take(4))
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.tips_and_updates,
                size: 18,
                color: AppColors.gold,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(n, style: theme.textTheme.bodyMedium)),
            ],
          ),
        ),
    ];
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _NewsLine extends StatelessWidget {
  const _NewsLine({
    required this.time,
    required this.headline,
    required this.why,
  });

  final String time;
  final String headline;
  final String why;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              time,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.gold),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(why, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeRow extends StatelessWidget {
  const _TradeRow({required this.trade, required this.spec});

  final ClosedTrade trade;
  final InstrumentSpec spec;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = trade;
    final r = t.rMultiple;
    final reason = switch (t.exitReason) {
      ExitReason.stopLoss => 'stop-loss',
      ExitReason.takeProfit => 'take-profit',
      ExitReason.manual => 'closed',
      ExitReason.endOfSession => 'day end',
      ExitReason.stopOut => 'stop-out',
    };
    String p(double v) => v.toStringAsFixed(spec.priceDecimals);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Pill(
            label: t.side == Side.long ? 'BUY' : 'SELL',
            color: t.side == Side.long ? AppColors.up : AppColors.down,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${quantity(t.quantity)} ${spec.quantityUnit} · ${p(t.entryPrice)} → ${p(t.exitPrice)}',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(reason, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                money(t.netPnl, signed: true),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: t.isWin ? AppColors.up : AppColors.down,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (r != null)
                Text(rMultiple(r), style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
