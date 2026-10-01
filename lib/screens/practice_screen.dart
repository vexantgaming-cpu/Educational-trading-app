import 'package:flutter/material.dart';
import 'package:market_sim/market_sim.dart';

import '../chart/candle_chart.dart';
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
              const _PracticeCard(
                icon: Icons.today,
                colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                title: 'Daily Challenge',
                body:
                    'One chart, one trade, the same for everyone. Scored on '
                    'how well you plan, not on luck.',
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
