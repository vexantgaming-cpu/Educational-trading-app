import 'package:flutter/material.dart';

import '../data/curriculum.dart';
import '../lessons/lesson_player.dart';
import '../progress/progress_scope.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = curriculum.fold<int>(0, (a, l) => a + l.lessons.length);
    final progress = ProgressScope.of(context);
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
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _Stat(icon: Icons.bolt, label: '${progress.xp} XP'),
                const SizedBox(width: 12),
                _Stat(
                  icon: Icons.check_circle_outline,
                  label: '${progress.completedCount} of $total done',
                ),
              ],
            ),
          ),
        ),
        for (final level in curriculum) ...[
          SliverToBoxAdapter(child: _LevelHeader(level: level)),
          SliverList.builder(
            itemCount: level.lessons.length,
            itemBuilder: (context, i) => _LessonTile(
              level: level,
              lesson: level.lessons[i],
              number: i + 1,
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(icon, size: 18, color: theme.colorScheme.primary),
      label: Text(label),
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
                Text(
                  'LEVEL ${level.number}',
                  style: theme.textTheme.labelSmall,
                ),
                Text(level.title, style: theme.textTheme.titleLarge),
                Text(level.summary, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Chip(
            label: Text(level.premium ? 'Premium' : 'Free'),
            avatar: Icon(
              level.premium ? Icons.workspace_premium : Icons.lock_open,
              size: 16,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
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
    final playable = lesson.isPlayable;
    final done =
        lesson.id != null && ProgressScope.of(context).isCompleted(lesson.id!);
    final hasExercise = lesson.exercise != null && lesson.id == null;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: done
            ? const Color(0xFF26A69A)
            : playable
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        foregroundColor: playable || done
            ? Colors.white
            : theme.colorScheme.onSurfaceVariant,
        child: done ? const Icon(Icons.check) : Text('$number'),
      ),
      title: Text(lesson.title),
      subtitle: Text(
        done
            ? '${lesson.minutes} min · Completed'
            : hasExercise
            ? '${lesson.minutes} min · Interactive exercise ready'
            : '${lesson.minutes} min',
      ),
      trailing: Icon(
        playable
            ? (done ? Icons.replay : Icons.play_circle_fill)
            : level.premium
            ? Icons.lock_outline
            : Icons.schedule,
        color: playable ? theme.colorScheme.primary : null,
      ),
      onTap: () {
        final navigator = Navigator.of(context);
        if (lesson.id != null) {
          navigator.push(
            MaterialPageRoute<bool>(
              builder: (_) => LessonPlayerScreen(lessonId: lesson.id!),
            ),
          );
        } else if (lesson.exercise != null) {
          navigator.pushNamed(lesson.exercise!);
        } else {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('This lesson is coming soon.')),
            );
        }
      },
    );
  }
}
