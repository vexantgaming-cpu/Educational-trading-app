import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/illustrations.dart';
import '../widgets/gradient_button.dart';
import '../widgets/upwiq_logo.dart';

/// What a newcomer needs to know before the first lesson: what the app
/// teaches, that all money in it is virtual, and what to come back for.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.onStartLearning,
    required this.onExplore,
  });

  /// "Start my first lesson" on the last page.
  final VoidCallback onStartLearning;

  /// "Skip" or "Look around first".
  final VoidCallback onExplore;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _controller = PageController();
  var _page = 0;

  static const _pageCount = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() => _controller.nextPage(
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final last = _page == _pageCount - 1;
    final pages = [
      _WelcomePage(
        art: LearnArt(palette),
        title: 'Learn to read',
        highlight: 'any market',
        body:
            'Short lessons with charts you can touch. Stocks, forex, crypto, '
            'commodities and indices, explained from zero.',
      ),
      _WelcomePage(
        art: PracticeArt(palette),
        title: 'Practise',
        highlight: 'without risk',
        body:
            'Every trade in Upwiq uses virtual money. There is nothing to '
            'deposit, nothing to buy and nothing to withdraw.',
      ),
      _WelcomePage(
        art: TrophyArt(palette, showRing: false),
        title: 'Build good habits',
        highlight: 'every day',
        body:
            'A new Daily Challenge each day and a weekly league. You\'re '
            'scored on how well you plan, not on luck.',
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: SizedBox(
                height: 40,
                child: Row(
                  children: [
                    const UpwiqLogo(height: 28),
                    const Spacer(),
                    if (!last)
                      TextButton(
                        onPressed: widget.onExplore,
                        child: const Text('Skip'),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: pages,
              ),
            ),
            Semantics(
              label: 'Page ${_page + 1} of $_pageCount',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pageCount; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: i == _page ? AppColors.primaryGradient : null,
                        color: i == _page ? null : palette.surfaceHighest,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: GradientButton(
                label: last ? 'Start my first lesson' : 'Next',
                icon: last ? Icons.play_arrow : null,
                onPressed: last ? widget.onStartLearning : _next,
              ),
            ),
            // Keeps its height on every page so the button doesn't jump.
            Visibility(
              visible: last,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: TextButton(
                onPressed: last ? widget.onExplore : null,
                child: const Text('Look around first'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'For education only. Upwiq does not give financial advice.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({
    required this.art,
    required this.title,
    required this.highlight,
    required this.body,
  });

  final CustomPainter art;
  final String title;
  final String highlight;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
      height: 1.15,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // The picture gives way first on short screens and large text.
        final artSize = (constraints.maxHeight * 0.42).clamp(96.0, 220.0);
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: artSize,
                  height: artSize,
                  child: CustomPaint(painter: art),
                ),
                const SizedBox(height: 20),
                Text(title, textAlign: TextAlign.center, style: headline),
                GradientText(highlight, style: headline),
                const SizedBox(height: 12),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: context.palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
