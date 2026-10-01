import 'package:flutter/material.dart';

import '../data/curriculum.dart';
import '../progress/progress_scope.dart';
import '../theme/app_colors.dart';
import '../theme/illustrations.dart';
import '../widgets/gradient_button.dart';
import '../widgets/tab_hero.dart';

/// Ranks earned with XP. Purely motivational.
const _ranks = [
  (0, 'Rookie'),
  (50, 'Apprentice'),
  (150, 'Chart Reader'),
  (300, 'Risk Manager'),
  (600, 'Strategist'),
  (1000, 'Market Master'),
];

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = ProgressScope.of(context);
    final xp = progress.xp;
    var rankIndex = 0;
    for (var i = 0; i < _ranks.length; i++) {
      if (xp >= _ranks[i].$1) rankIndex = i;
    }
    final rank = _ranks[rankIndex].$2;
    final next = rankIndex + 1 < _ranks.length ? _ranks[rankIndex + 1] : null;
    final fromXp = _ranks[rankIndex].$1;
    final toNext = next == null ? 1.0 : (xp - fromXp) / (next.$1 - fromXp);
    final totalLessons = curriculum.fold<int>(
      0,
      (a, l) => a + l.lessons.length,
    );

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: BrandBar()),
        SliverToBoxAdapter(
          child: TabHero(
            title: 'Your rank',
            highlight: rank,
            subtitle: next == null
                ? 'Top rank reached. Keep practising!'
                : '${next.$1 - xp} XP to ${next.$2}.',
            art: TrophyArt(progress: toNext),
            footer: GradientProgressBar(value: toNext),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: _StatTile(icon: Icons.bolt, value: '$xp', label: 'XP'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    icon: Icons.menu_book,
                    value: '${progress.completedCount}/$totalLessons',
                    label: 'Lessons',
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: _StatTile(
                    icon: Icons.account_balance_wallet,
                    value: '\$10k',
                    label: 'Virtual',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(child: _PremiumCard()),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text('SETTINGS', style: theme.textTheme.labelSmall),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: Material(
              color: AppColors.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.outline),
              ),
              child: Column(
                children: [
                  const _SettingRow(
                    icon: Icons.notifications_outlined,
                    title: 'Daily reminder',
                    value: 'Soon',
                  ),
                  const Divider(indent: 56),
                  const _SettingRow(
                    icon: Icons.translate,
                    title: 'Language',
                    value: 'English',
                  ),
                  const Divider(indent: 56),
                  _SettingRow(
                    icon: Icons.description_outlined,
                    title: 'Licences',
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'Upwiq',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Text(
              'Upwiq is an educational app. It does not provide '
              'financial advice or recommendations, and it does not offer real '
              'trading. All trades are simulated with virtual money that cannot '
              'be bought or withdrawn. Simulated results do not reflect real '
              'trading, where costs, slippage and emotions differ. Trading '
              'involves risk of loss.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
          ),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF2A1B4D), Color(0xFF17122B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.violet.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              IconBadge(
                icon: Icons.workspace_premium,
                colors: [Color(0xFFC4B5FD), AppColors.violetDeep],
                size: 40,
              ),
              SizedBox(width: 12),
              Pill(label: 'Coming soon', gradient: AppColors.premiumGradient),
            ],
          ),
          const SizedBox(height: 14),
          Text('Premium', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Unlock Levels 3–7, unlimited practice with real historical charts '
            'and advanced trade statistics.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: value != null
          ? Text(value!, style: Theme.of(context).textTheme.bodySmall)
          : const Icon(Icons.chevron_right, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
