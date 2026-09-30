import 'package:flutter/material.dart';

import '../data/curriculum.dart';
import '../lessons/lesson_player.dart';
import '../progress/progress_scope.dart';
import '../theme/app_colors.dart';
import '../theme/illustrations.dart';
import '../widgets/gradient_button.dart';
import '../widgets/tab_hero.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = ProgressScope.of(context);
    final total = curriculum.fold<int>(0, (a, l) => a + l.lessons.length);
    final done = progress.completedCount;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: BrandBar(
            trailing: Pill(
              label: '${progress.xp} XP',
              icon: Icons.bolt,
              color: AppColors.gold,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: TabHero(
            title: 'Learn to read',
            highlight: 'any market',
            subtitle:
                'Bite-sized lessons for stocks, forex, crypto, '
                'commodities and indices.',
            art: LearnArt(),
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Your progress', style: theme.textTheme.bodySmall),
                    const Spacer(),
                    Text(
                      '$done of $total lessons',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GradientProgressBar(value: total == 0 ? 0 : done / total),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('YOUR PATH', style: theme.textTheme.labelSmall),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList.separated(
            itemCount: curriculum.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => LevelCard(level: curriculum[i]),
          ),
        ),
      ],
    );
  }
}

/// A level as a collapsible card: key visual, progress and access badge on
/// top; lessons revealed on tap. Folded by default.
class LevelCard extends StatefulWidget {
  const LevelCard({super.key, required this.level});

  final Level level;

  @override
  State<LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<LevelCard> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = widget.level;
    final progress = ProgressScope.of(context);
    final done = level.lessons
        .where((l) => l.id != null && progress.isCompleted(l.id!))
        .length;
    final accent = level.colors.first;

    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: _expanded ? accent.withValues(alpha: 0.6) : AppColors.outline,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  IconBadge(icon: level.icon, colors: level.colors),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LEVEL ${level.number}',
                          style: theme.textTheme.labelSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          level.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: GradientProgressBar(
                                value: done / level.lessons.length,
                                height: 6,
                                gradient: LinearGradient(colors: level.colors),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '$done/${level.lessons.length}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _accessPill(level),
                      const SizedBox(height: 10),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: const Icon(
                          Icons.expand_more,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          level.summary,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      for (var i = 0; i < level.lessons.length; i++)
                        _LessonRow(
                          level: level,
                          lesson: level.lessons[i],
                          number: i + 1,
                        ),
                      const SizedBox(height: 8),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _accessPill(Level level) {
    if (!level.premium) {
      return const Pill(label: 'Free', color: AppColors.up);
    }
    final free = level.freeLessonCount;
    if (free > 0) {
      return Pill(
        label: '$free free',
        icon: Icons.lock_open,
        color: AppColors.cyan,
      );
    }
    return const Pill(
      label: 'Premium',
      icon: Icons.workspace_premium,
      gradient: AppColors.premiumGradient,
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.level,
    required this.lesson,
    required this.number,
  });

  final Level level;
  final Lesson lesson;
  final int number;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locked = level.isLocked(lesson);
    final playable = lesson.isPlayable && !locked;
    final done =
        lesson.id != null && ProgressScope.of(context).isCompleted(lesson.id!);

    final Widget leading;
    if (done) {
      leading = const CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.up,
        child: Icon(Icons.check, size: 18, color: Colors.white),
      );
    } else if (locked) {
      leading = CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.violet.withValues(alpha: 0.15),
        child: const Icon(Icons.lock, size: 16, color: AppColors.violet),
      );
    } else {
      leading = Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: playable ? AppColors.primaryGradient : null,
          color: playable ? null : AppColors.surfaceHighest,
        ),
        child: Text(
          '$number',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: playable ? AppColors.onGold : AppColors.textMuted,
          ),
        ),
      );
    }

    final subtitle = done
        ? '${lesson.minutes} min · Completed'
        : locked
        ? '${lesson.minutes} min · Premium'
        : playable
        ? (lesson.id == null
              ? '${lesson.minutes} min · Interactive exercise'
              : '${lesson.minutes} min${lesson.free ? ' · Free preview' : ''}')
        : '${lesson.minutes} min · Coming soon';

    return InkWell(
      onTap: () => _open(context, locked),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: playable || done
                          ? AppColors.text
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (playable)
              Icon(
                done ? Icons.replay : Icons.play_circle_fill,
                color: AppColors.gold,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, bool locked) {
    final navigator = Navigator.of(context);
    if (locked) {
      _snack(context, 'Part of Premium. Coming soon.');
    } else if (lesson.id != null) {
      navigator.push(
        MaterialPageRoute<bool>(
          builder: (_) => LessonPlayerScreen(lessonId: lesson.id!),
        ),
      );
    } else if (lesson.exercise != null) {
      navigator.pushNamed(lesson.exercise!);
    } else {
      _snack(context, 'This lesson is coming soon.');
    }
  }

  void _snack(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}
