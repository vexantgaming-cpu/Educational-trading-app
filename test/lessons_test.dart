import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_sim/market_sim.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upwiq/data/curriculum.dart';
import 'package:upwiq/lessons/lesson_model.dart';
import 'package:upwiq/lessons/lesson_player.dart';
import 'package:upwiq/progress/progress_scope.dart';
import 'package:upwiq/progress/progress_store.dart';

Map<String, LessonContent> loadAll() => {
  for (final f in Directory(
    'assets/lessons',
  ).listSync().whereType<File>().where((f) => f.path.endsWith('.json')))
    f.uri.pathSegments.last.replaceAll('.json', ''): LessonContent.fromJson(
      jsonDecode(f.readAsStringSync()) as Map<String, dynamic>,
    ),
};

void main() {
  final lessons = loadAll();

  group('lesson content', () {
    test('every curriculum lesson id has content and vice versa', () {
      final ids = {
        for (final level in curriculum)
          for (final l in level.lessons)
            if (l.id != null) l.id!,
      };
      expect(lessons.keys.toSet(), ids);
    });

    lessons.forEach((file, lesson) {
      test('$file is well-formed', () {
        expect(lesson.id, file);
        expect(lesson.steps.length, inInclusiveRange(4, 12));
        expect(lesson.steps.last, isA<RecapStep>());
        for (final step in lesson.steps) {
          switch (step) {
            case QuizStep():
              expect(step.options.length, inInclusiveRange(2, 5));
              expect(
                step.options.toSet().length,
                step.options.length,
                reason: 'duplicate options in "${step.question}"',
              );
              expect(step.answer, inInclusiveRange(0, step.options.length - 1));
              expect(step.explanation, isNotEmpty);
              step.chart?.render();
            case SpotStep():
              final chart = step.chart.render();
              expect(chart.candles, isNotEmpty);
              if (step.target == SpotTarget.support ||
                  step.target == SpotTarget.resistance) {
                expect(
                  chart.zones.map((z) => z.kind.name),
                  contains(step.target.name),
                );
              }
            case ExplainStep(:final chart?):
              expect(chart.render().candles, isNotEmpty);
            case ExerciseStep():
              expect(step.route, placeTradeRoute);
            case RecapStep():
              expect(step.points, isNotEmpty);
            default:
              break;
          }
        }
      });
    });
  });

  test('every illustration is used, and the free path has pictures', () {
    final used = <LessonArt>{};
    for (final lesson in lessons.values) {
      for (final step in lesson.steps.whereType<ExplainStep>()) {
        if (step.art case final art?) used.add(art);
      }
    }
    expect(LessonArt.values.toSet().difference(used), isEmpty);
    // Every free lesson opens its story with a picture or a chart.
    for (final level in curriculum) {
      for (final lesson in level.lessons) {
        if (lesson.id == null || level.isLocked(lesson)) continue;
        final steps = lessons[lesson.id]!.steps;
        final visual = steps.any(
          (s) =>
              (s is ExplainStep && (s.art != null || s.chart != null)) ||
              s is SpotStep ||
              s is CandleAnatomyStep,
        );
        expect(visual, isTrue, reason: '${lesson.id} has no visual');
      }
    }
  });

  group('spot it', () {
    SpotStep spotStep(String lessonId, SpotTarget target) => lessons[lessonId]!
        .steps
        .whereType<SpotStep>()
        .firstWhere((s) => s.target == target);

    test('tapping inside the support zone is correct, far away is not', () {
      final step = spotStep('L1-04', SpotTarget.support);
      final chart = step.chart.render();
      final zone = chart.zones.firstWhere((z) => z.kind == ZoneKind.support);
      final middle = (zone.fromIndex + zone.toIndex) ~/ 2;
      expect(
        isSpotCorrect(step, chart, (index: middle, price: zone.mid)),
        isTrue,
      );
      expect(
        isSpotCorrect(step, chart, (index: middle, price: zone.high + 3)),
        isFalse,
      );
      expect(
        isSpotCorrect(step, chart, (index: 5, price: zone.mid)),
        isFalse,
        reason: 'the zone did not exist yet at bar 5',
      );
    });

    test('highest candle: near misses of a bar or two still count', () {
      final step = spotStep('L0-05', SpotTarget.highest);
      final chart = step.chart.render();
      final peak = spotAnswerIndex(step, chart)!;
      final highs = [for (final c in chart.candles) c.high];
      expect(highs[peak], highs.reduce((a, b) => a > b ? a : b));
      expect(isSpotCorrect(step, chart, (index: peak + 1, price: 0)), isTrue);
      expect(isSpotCorrect(step, chart, (index: peak + 6, price: 0)), isFalse);
    });

    test('swing and breakout questions have one clear answer', () {
      var checked = 0;
      for (final lesson in lessons.values) {
        for (final step in lesson.steps.whereType<SpotStep>()) {
          final chart = step.chart.render();
          final where = '${lesson.id} "${step.prompt}"';
          switch (step.target) {
            case SpotTarget.swingHigh:
            case SpotTarget.swingLow:
              final type = step.target == SpotTarget.swingHigh
                  ? SwingType.high
                  : SwingType.low;
              final answer = spotAnswerIndex(step, chart);
              expect(answer, isNotNull, reason: '$where: no swing');
              // No smaller swing after the answer that could also look
              // like "the most recent" one.
              final later = findSwings(
                chart.candles,
                strength: 2,
              ).where((s) => s.type == type && s.index > answer! + 2);
              expect(later, isEmpty, reason: '$where: a later minor swing');
              // The previous swing of the same kind is well apart.
              final earlier = findSwings(
                chart.candles,
                strength: spotSwingStrength,
              ).where((s) => s.type == type && s.index < answer!);
              if (earlier.isNotEmpty) {
                expect(
                  answer! - earlier.last.index,
                  greaterThan(6),
                  reason: '$where: two swings close together',
                );
              }
              checked++;
            case SpotTarget.breakout:
              final answer = spotAnswerIndex(step, chart);
              expect(answer, isNotNull, reason: '$where: no breakout candle');
              final span = chart.spans.firstWhere((s) => s.label == 'breakout');
              expect(answer, inInclusiveRange(span.fromIndex, span.toIndex));
              checked++;
            default:
              break;
          }
        }
      }
      expect(checked, greaterThanOrEqualTo(5));
    });

    test('quiz options are mixed up but stable', () {
      final positions = <int>[];
      for (final lesson in lessons.values) {
        for (var i = 0; i < lesson.steps.length; i++) {
          final step = lesson.steps[i];
          if (step is! QuizStep) continue;
          final order = quizOptionOrder(lesson.id, i, step);
          expect(order.toSet(), {
            for (var k = 0; k < step.options.length; k++) k,
          });
          expect(quizOptionOrder(lesson.id, i, step), order);
          positions.add(order.indexOf(step.answer));
          for (var k = 0; k < order.length; k++) {
            if (step.options[order[k]].toLowerCase().startsWith('all of')) {
              expect(k, order.length - 1, reason: '"All of…" stays last');
            }
          }
        }
      }
      // The right answer isn't parked in one place.
      for (var p = 0; p < 4; p++) {
        expect(
          positions.where((x) => x == p).length,
          greaterThan(positions.length ~/ 8),
          reason: 'answer position $p is too rare',
        );
      }
    });

    test('"highest/lowest" charts have one clear answer', () {
      for (final lesson in lessons.values) {
        for (final step in lesson.steps.whereType<SpotStep>()) {
          if (step.target != SpotTarget.highest &&
              step.target != SpotTarget.lowest) {
            continue;
          }
          final chart = step.chart.render();
          final best = spotAnswerIndex(step, chart)!;
          final highest = step.target == SpotTarget.highest;
          double value(int i) =>
              highest ? chart.candles[i].high : chart.candles[i].low;
          final runnerUp = [
            for (var i = 0; i < chart.candles.length; i++)
              if ((i - best).abs() > 2) value(i),
          ].reduce((a, b) => highest ? (a > b ? a : b) : (a < b ? a : b));
          final margin = (value(best) - runnerUp).abs() / value(best) * 100;
          expect(
            margin,
            greaterThan(1.0),
            reason: '${lesson.id}: another candle is almost as extreme',
          );
        }
      }
    });
  });

  testWidgets('playing a lesson to the end awards XP once', (tester) async {
    SharedPreferences.setMockInitialValues({});
    ProgressStore.reset();
    final progress = await ProgressStore.load();
    final lesson = lessons['L0-02']!;

    await tester.pumpWidget(
      ProgressScope(
        store: progress,
        child: MaterialApp(
          home: LessonPlayerScreen(lessonId: lesson.id, content: lesson),
        ),
      ),
    );

    Future<void> press(String label) async {
      final button = find.widgetWithText(FilledButton, label);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    for (final step in lesson.steps) {
      if (step is QuizStep) {
        final option = find.text(step.options[step.answer]);
        await tester.ensureVisible(option);
        await tester.tap(option);
        await tester.pump();
        await press('Check');
        expect(find.text('Correct!'), findsOneWidget);
      }
      await press(identical(step, lesson.steps.last) ? 'Finish' : 'Continue');
    }

    expect(find.text('Lesson complete!'), findsOneWidget);
    expect(find.text('3 of 3 answers correct'), findsOneWidget);
    expect(find.text('+25 XP'), findsOneWidget);
    expect(progress.isCompleted('L0-02'), isTrue);
    expect(progress.xp, 25);
    expect(
      await progress.complete('L0-02', correctAnswers: 3),
      0,
      reason: 'no XP for repeating a lesson',
    );
  });

  testWidgets('a wrong answer shows the explanation', (tester) async {
    SharedPreferences.setMockInitialValues({});
    ProgressStore.reset();
    final progress = await ProgressStore.load();
    final lesson = lessons['L0-04']!;
    final quiz = lesson.steps.whereType<QuizStep>().first;

    await tester.pumpWidget(
      ProgressScope(
        store: progress,
        child: MaterialApp(
          home: LessonPlayerScreen(lessonId: lesson.id, content: lesson),
        ),
      ),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    final wrong = quiz.options[(quiz.answer + 1) % quiz.options.length];
    await tester.tap(find.text(wrong));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Check'));
    await tester.pumpAndSettle();
    expect(find.text('Not quite'), findsOneWidget);
    expect(
      find.textContaining('Shorts profit when price falls', findRichText: true),
      findsOneWidget,
    );
  });
}
