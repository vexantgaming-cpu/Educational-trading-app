import 'package:flutter/material.dart';
import 'package:market_sim/market_sim.dart';

import '../theme/app_colors.dart';
import 'game_scope.dart';
import 'league_style.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = GameScope.of(context);
    final standings = store.standings;
    final canPromote = store.league.next != null;
    final canDemote = store.league.previous != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${store.league.title} League · week ${store.seasonId % 100}',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const SimulatedRivalsNote(),
          const SizedBox(height: 12),
          for (final s in standings) ...[
            if (canPromote && s.rank == 1)
              _ZoneLabel(
                'Promotion zone',
                context.palette.up,
                Icons.arrow_upward,
              ),
            if (canPromote && s.rank == LeagueRules.promoteCount + 1)
              const Divider(height: 20),
            if (canDemote &&
                s.rank == LeagueRules.groupSize - LeagueRules.demoteCount + 1)
              _ZoneLabel(
                'Demotion zone',
                context.palette.down,
                Icons.arrow_downward,
              ),
            StandingRow(standing: s, league: store.league),
          ],
          const SizedBox(height: 12),
          Text(
            'Ranked by return this week. Top ${LeagueRules.promoteCount} move up (with at least '
            '${LeagueRules.minDaysToPromote} trading days), bottom ${LeagueRules.demoteCount} move down.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class SimulatedRivalsNote extends StatelessWidget {
  const SimulatedRivalsNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.palette.cyan.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.cyan.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: context.palette.cyan),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Preview: you are competing against 29 simulated rivals at your level. '
              'Online leagues with real players are coming.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: context.palette.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneLabel extends StatelessWidget {
  const _ZoneLabel(this.text, this.color, this.icon);

  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class StandingRow extends StatelessWidget {
  const StandingRow({super.key, required this.standing, required this.league});

  final Standing standing;
  final League league;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = standing;
    final promote = league.next != null && s.rank <= LeagueRules.promoteCount;
    final demote =
        league.previous != null &&
        s.rank > LeagueRules.groupSize - LeagueRules.demoteCount;
    final rankColor = promote
        ? context.palette.up
        : demote
        ? context.palette.down
        : context.palette.textMuted;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: s.isYou
            ? context.palette.gold.withValues(alpha: 0.1)
            : context.palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: s.isYou
              ? context.palette.gold.withValues(alpha: 0.6)
              : context.palette.outline,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${s.rank}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: rankColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TraderAvatar(name: s.name, seed: s.avatarSeed, isYou: s.isYou),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: s.isYou
                        ? context.palette.gold
                        : context.palette.text,
                  ),
                ),
                Text(
                  '${s.daysPlayed} day${s.daysPlayed == 1 ? '' : 's'} traded',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '${s.returnPct >= 0 ? '+' : ''}${s.returnPct.toStringAsFixed(2)}%',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: s.returnPct >= 0
                  ? context.palette.up
                  : context.palette.down,
            ),
          ),
        ],
      ),
    );
  }
}
