import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'gradient_button.dart';
import 'upwiq_logo.dart';

/// The key visual at the top of each tab: headline (with a gradient
/// highlight), a short line, optional footer, and an illustration.
class TabHero extends StatelessWidget {
  const TabHero({
    super.key,
    required this.title,
    required this.highlight,
    required this.subtitle,
    required this.art,
    this.footer,
  });

  final String title;
  final String highlight;
  final String subtitle;
  final CustomPainter art;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = theme.textTheme.headlineSmall?.copyWith(
      fontSize: 25,
      fontWeight: FontWeight.w700,
      height: 1.15,
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        gradient: context.palette.heroGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.palette.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    context.palette.gold.withValues(alpha: 0.14),
                    context.palette.gold.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: headline),
                          GradientText(highlight, style: headline),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: context.palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 118,
                      height: 118,
                      child: CustomPaint(painter: art),
                    ),
                  ],
                ),
                if (footer != null) ...[const SizedBox(height: 16), footer!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Thin progress bar filled with the brand gradient.
class GradientProgressBar extends StatelessWidget {
  const GradientProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.gradient,
  });

  final double value;
  final double height;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: context.palette.surfaceHighest),
            ),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: gradient ?? AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(height),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Upwiq logo, shown at the top of the tabs.
class BrandBar extends StatelessWidget {
  const BrandBar({super.key, this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SizedBox(
        height: 34,
        child: Row(
          children: [const UpwiqLogo(height: 28), const Spacer(), ?trailing],
        ),
      ),
    );
  }
}
