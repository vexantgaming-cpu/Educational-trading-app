import 'package:flutter/material.dart';
import 'package:market_sim/market_sim.dart';

import '../format.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_button.dart';
import '../widgets/tab_hero.dart';
import 'game_scope.dart';
import 'game_store.dart';
import 'leaderboard_screen.dart';
import 'league_style.dart';
import 'market_picker_screen.dart';

/// The trading game: your league, today's session, and the leaderboard.
class LeagueScreen extends StatefulWidget {
  const LeagueScreen({super.key});

  @override
  State<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends State<LeagueScreen> {
  var _noticeShown = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = GameScope.of(context);
    _maybeShowNotice(store);
    final you = store.you;
    final ends = store.seasonEnds.difference(store.now);
    final standings = store.standings;

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: BrandBar()),
        SliverToBoxAdapter(
          child: TabHero(
            title: store.league.title,
            highlight: 'League',
            subtitle:
                'Week ${store.seasonId % 100} · ends in ${ends.inDays}d ${ends.inHours % 24}h',
            art: LeagueBadgeArt(store.league),
            footer: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Pill(
                  label: 'Rank #${you.rank} of ${LeagueRules.groupSize}',
                  icon: Icons.leaderboard,
                  color: AppColors.gold,
                ),
                Pill(
                  label:
                      '${store.seasonReturnPct >= 0 ? '+' : ''}${store.seasonReturnPct.toStringAsFixed(2)}% this week',
                  color: store.seasonReturnPct >= 0
                      ? AppColors.up
                      : AppColors.down,
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverList.list(
            children: [
              _TodayCard(store: store),
              const SizedBox(height: 12),
              _AccountCard(store: store),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('LEADERBOARD', style: theme.textTheme.labelSmall),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LeaderboardScreen(),
                      ),
                    ),
                    child: const Text('See all 30'),
                  ),
                ],
              ),
              for (final s in _preview(standings))
                StandingRow(standing: s, league: store.league),
              const SizedBox(height: 8),
              const SimulatedRivalsNote(),
              const SizedBox(height: 20),
              Text('LEAGUES', style: theme.textTheme.labelSmall),
              const SizedBox(height: 10),
              _Ladder(current: store.league, best: store.bestLeague),
              const SizedBox(height: 20),
              const _Rules(),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () => _confirmReset(context, store),
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: const Text('Reset account'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  /// Top 3, then you and your neighbours.
  List<Standing> _preview(List<Standing> all) {
    final you = all.indexWhere((s) => s.isYou);
    final picks = <int>{
      0,
      1,
      2,
      you - 1,
      you,
      you + 1,
    }.where((i) => i >= 0 && i < all.length).toList()..sort();
    return [for (final i in picks) all[i]];
  }

  void _maybeShowNotice(GameStore store) {
    if (_noticeShown || (store.pendingReport == null && !store.justBlown)) {
      return;
    }
    _noticeShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final report = store.pendingReport;
      if (report != null) {
        final (title, body) = switch (report.outcome) {
          SeasonOutcome.promoted => (
            'Promoted to ${report.to.title}!',
            'You finished #${report.rank} with ${report.returnPct.toStringAsFixed(2)}%.',
          ),
          SeasonOutcome.demoted => (
            'Moved down to ${report.to.title}',
            'You finished #${report.rank}. A new week, a fresh start.',
          ),
          SeasonOutcome.stayed => (
            'You stay in ${report.to.title}',
            'You finished #${report.rank} with ${report.returnPct.toStringAsFixed(2)}%.',
          ),
        };
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            icon: SizedBox(
              width: 72,
              height: 72,
              child: CustomPaint(painter: LeagueBadgeArt(report.to)),
            ),
            title: Text(title),
            content: Text(body),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Let\'s go'),
              ),
            ],
          ),
        );
      }
      await store.clearNotices();
    });
  }

  Future<void> _confirmReset(BuildContext context, GameStore store) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset your account?'),
        content: const Text(
          'You restart in Bronze with \$10,000 and a new group. This can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok ?? false) await store.resetAccount();
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.store});

  final GameStore store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = store.rankedPlayedToday;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: done
              ? AppColors.outline
              : AppColors.gold.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const IconBadge(
                icon: Icons.newspaper,
                colors: [Color(0xFFFFC857), Color(0xFFFF7A2F)],
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      done ? 'Today\'s session is done' : 'Today\'s session',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      done
                          ? 'New markets and news tomorrow.'
                          : 'Read the news, pick a market, trade 08:00–16:00.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!done)
            GradientButton(
              label: 'Pick today\'s market',
              icon: Icons.play_arrow,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MarketPickerScreen(ranked: true),
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MarketPickerScreen(ranked: false),
              ),
            ),
            icon: const Icon(Icons.fitness_center, size: 18),
            label: const Text('Practice session (unranked)'),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.store});

  final GameStore store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget tile(String label, String value, [Color? color]) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              color: color ?? AppColors.text,
            ),
          ),
        ],
      ),
    );
    final pnl = store.seasonPnl;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          tile('BALANCE', money(store.balance)),
          tile(
            'WEEK P&L',
            money(pnl, signed: true),
            pnl >= 0 ? AppColors.up : AppColors.down,
          ),
          tile('DAYS TRADED', '${store.seasonDaysPlayed} / 7'),
        ],
      ),
    );
  }
}

class _Ladder extends StatelessWidget {
  const _Ladder({required this.current, required this.best});

  final League current;
  final League best;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (final league in League.values)
          Expanded(
            child: Opacity(
              opacity: league.index <= best.index || league == current
                  ? 1
                  : 0.35,
              child: Column(
                children: [
                  SizedBox(
                    width: league == current ? 50 : 38,
                    height: league == current ? 50 : 38,
                    child: CustomPaint(
                      painter: LeagueBadgeArt(league, glow: league == current),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    league.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: league == current
                          ? AppColors.gold
                          : AppColors.textMuted,
                      fontWeight: league == current ? FontWeight.w700 : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Rules extends StatelessWidget {
  const _Rules();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const rules = [
      'Everyone starts with \$10,000 of paper money in Bronze.',
      'One ranked session a day: pick a market, trade 08:00–16:00. Open trades close at 16:00.',
      'Weekly seasons in groups of 30, ranked by return %. Top 10 move up a league, bottom 10 move down.',
      'Trade at least 3 days in a week to be promoted.',
      'Every trade needs a stop-loss, and can risk at most 5% of your account.',
      'Real-world costs: bid/ask spread (wider at the open and around news), commission on shares, EU leverage limits and a 50% margin stop-out.',
      'If your account falls below \$1,000 it is blown: you restart in Bronze with \$10,000.',
    ];
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outline),
        ),
        child: ExpansionTile(
          leading: const Icon(Icons.gavel, color: AppColors.gold),
          title: Text('League rules', style: theme.textTheme.titleMedium),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            for (final r in rules)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle, size: 6, color: AppColors.gold),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(r, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
