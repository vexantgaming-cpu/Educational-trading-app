import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(title: const Text('Profile')),
        SliverList.list(
          children: [
            const ListTile(
              leading: Icon(Icons.account_balance_wallet_outlined),
              title: Text('Virtual balance'),
              subtitle: Text('\$10,000.00 · practice money, never real'),
            ),
            const ListTile(
              leading: Icon(Icons.workspace_premium_outlined),
              title: Text('Premium'),
              subtitle: Text(
                'Unlock Levels 3–6 and unlimited practice (coming soon)',
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Trading Academy is an educational app. It does not provide '
                'financial advice or recommendations, and it does not offer real '
                'trading. All trades are simulated with virtual money that cannot '
                'be bought or withdrawn. Simulated results do not reflect real '
                'trading, where costs, slippage and emotions differ. Trading '
                'involves risk of loss.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
