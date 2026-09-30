import 'package:flutter/material.dart';

import '../data/curriculum.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = curriculum.fold<int>(0, (a, l) => a + l.lessons.length);
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(title: const Text('Learn')),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              '$total bite-sized lessons that work for any market: stocks, '
              'forex, crypto, commodities and indices.',
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
        for (final level in curriculum) ...[
          SliverToBoxAdapter(child: _LevelHeader(level: level)),
          SliverList.builder(
            itemCount: level.lessons.length,
            itemBuilder: (context, i) =>
                _LessonTile(level: level, lesson: level.lessons[i], number: i + 1),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _LevelHeader extends StatelessWidget {
  const _LevelHeader({required this.level});

  final Level level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LEVEL ${level.number}', style: theme.textTheme.labelSmall),
                Text(level.title, style: theme.textTheme.titleLarge),
                Text(level.summary, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Chip(
            label: Text(level.premium ? 'Premium' : 'Free'),
            avatar: Icon(level.premium ? Icons.workspace_premium : Icons.lock_open,
                size: 16),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.level, required this.lesson, required this.number});

  final Level level;
  final Lesson lesson;
  final int number;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playable = lesson.exercise != null;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: playable
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        foregroundColor:
            playable ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
        child: Text('$number'),
      ),
      title: Text(lesson.title),
      subtitle: Text(playable
          ? '${lesson.minutes} min · Interactive exercise ready'
          : '${lesson.minutes} min'),
      trailing: Icon(
        playable
            ? Icons.play_circle_fill
            : level.premium
                ? Icons.lock_outline
                : Icons.schedule,
        color: playable ? theme.colorScheme.primary : null,
      ),
      onTap: () {
        if (playable) {
          Navigator.of(context).pushNamed(lesson.exercise!);
        } else {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('This lesson is coming soon.')));
        }
      },
    );
  }
}
