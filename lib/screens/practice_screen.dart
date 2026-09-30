import 'package:flutter/material.dart';

import '../data/curriculum.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(title: const Text('Practice')),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.list(
            children: [
              _PracticeCard(
                icon: Icons.candlestick_chart,
                title: 'Place the trade',
                body:
                    'Plan a trade at support: set your stop-loss and target, '
                    'then watch it play out bar by bar.',
                action: 'Start',
                onTap: () => Navigator.of(context).pushNamed(placeTradeRoute),
              ),
              const _PracticeCard(
                icon: Icons.today,
                title: 'Daily Challenge',
                body:
                    'One chart, one trade, the same for everyone. Scored on '
                    'how well you plan, not on luck.',
                action: 'Coming soon',
              ),
              const _PracticeCard(
                icon: Icons.replay,
                title: 'Practice Arena',
                body:
                    'Replay a market bar by bar with \$10,000 of virtual '
                    'money. Buy, sell, set stops, reset any time.',
                action: 'Coming soon',
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
    required this.title,
    required this.body,
    required this.action,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(body, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: onTap == null
                  ? Text(action, style: theme.textTheme.labelLarge)
                  : FilledButton(onPressed: onTap, child: Text(action)),
            ),
          ],
        ),
      ),
    );
  }
}
