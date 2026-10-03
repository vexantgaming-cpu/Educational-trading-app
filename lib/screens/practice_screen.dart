import 'package:flutter/material.dart';
import 'package:market_sim/market_sim.dart';

import '../chart/candle_chart.dart';
import '../daily/daily_challenge_screen.dart';
import '../daily/daily_challenge_store.dart';
import '../data/curriculum.dart';
import '../exercises/trade_scenario.dart';
import '../game/market_picker_screen.dart';
import '../theme/app_colors.dart';
import '../theme/illustrations.dart';
import '../widgets/gradient_button.dart';
import '../widgets/tab_hero.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: BrandBar()),
        SliverToBoxAdapter(
          child: TabHero(
            title: 'Practice',
            highlight: 'without risk',
            subtitle: 'Trade with virtual money and learn from every result.',
            art: PracticeArt(context.palette),
            footer: Row(
              children: [
                Pill(
                  label: '\$10,000 virtual balance',
                  icon: Icons.account_balance_wallet,
                  color: context.palette.gold,
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('EXERCISES', style: theme.textTheme.labelSmall),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList.list(
            children: [
              const _DailyCard(),
              const SizedBox(height: 12),
              _PracticeCard(
                icon: Icons.candlestick_chart,
                colors: const [Color(0xFFFFC857), Color(0xFFFF7A2F)],
                title: 'Place the trade',
                body:
                    'Plan a trade at support: set your stop-loss and target, '
                    'then watch it play out candle by candle.',
                preview: const _ChartPreview(),
                onStart: () => Navigator.of(context).pushNamed(placeTradeRoute),
              ),
              const SizedBox(height: 12),
              _PracticeCard(
                icon: Icons.replay,
                colors: const [Color(0xFF34D399), Color(0xFF059669)],
                title: 'Practice Arena',
                body:
                    'Trade a full market day with \$10,000 of virtual money: '
                    'read the news, buy at the ask, sell at the bid. Unranked.',
                onStart: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MarketPickerScreen(ranked: false),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Today's Daily Challenge: start it, or see how it went.
class _DailyCard extends StatelessWidget {
  const _DailyCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final store = DailyScope.of(context);
    final result = store.todayResult;
    final streak = store.streak;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.gold.withValues(alpha: 0.45)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(
                icon: Icons.today,
                colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Daily Challenge',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Pill(label: '#${store.today.number}', color: palette.cyan),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            result == null
                ? 'Three quick rounds: read a chart, size a position, plan a '
                      'trade. New every day, the same for everyone.'
                : 'Done for today: ${result.total} / ${DailyResult.maxTotal}, '
                      '${result.verdict.toLowerCase()}. Next challenge in '
                      '${untilText(store.untilNext)}.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.textMuted,
            ),
          ),
          if (streak > 0) ...[
            const SizedBox(height: 10),
            Pill(
              label: streak == 1 ? '1-day streak' : '$streak-day streak',
              icon: Icons.local_fire_department,
              color: palette.gold,
            ),
          ],
          const SizedBox(height: 14),
          GradientButton(
            label: result == null
                ? 'Start today\'s challenge'
                : 'See today\'s result',
            icon: result == null
                ? Icons.play_arrow
                : Icons.emoji_events_outlined,
            onPressed: () =>
                Navigator.of(context).pushNamed(dailyChallengeRoute),
          ),
        ],
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({
    required this.icon,
    required this.colors,
    required this.title,
    required this.body,
    this.preview,
    this.onStart,
  });

  final IconData icon;
  final List<Color> colors;
  final String title;
  final String body;
  final Widget? preview;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = onStart != null;
    return Container(
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: available
              ? context.palette.gold.withValues(alpha: 0.45)
              : context.palette.outline,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: icon, colors: colors, size: 44),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              if (!available) const Pill(label: 'Coming soon'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.palette.textMuted,
            ),
          ),
          if (preview != null) ...[const SizedBox(height: 12), preview!],
          if (available) ...[
            const SizedBox(height: 14),
            GradientButton(
              label: 'Start',
              icon: Icons.play_arrow,
              onPressed: onStart,
            ),
          ],
        ],
      ),
    );
  }
}

/// A non-interactive glimpse of the exercise chart.
class _ChartPreview extends StatelessWidget {
  const _ChartPreview();

  static final List<Candle> _candles = () {
    final s = TradeScenario.supportBounce(7);
    return s.scenario.candles.sublist(0, s.revealIndex + 1);
  }();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
      decoration: BoxDecoration(
        color: context.palette.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: IgnorePointer(
        child: CandleChart(
          candles: _candles,
          visibleBars: 60,
          futureSlots: 4,
          showVolume: false,
        ),
      ),
    );
  }
}
