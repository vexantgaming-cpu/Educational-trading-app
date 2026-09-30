import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:market_sim/market_sim.dart';

import '../chart/candle_chart.dart';
import '../chart/chart_models.dart';
import '../progress/progress_scope.dart';
import '../theme/app_colors.dart';
import '../theme/illustrations.dart';
import '../widgets/gradient_button.dart';
import '../widgets/tab_hero.dart';
import 'candle_anatomy.dart';
import 'lesson_model.dart';
import 'rich_text.dart';

Future<LessonContent> loadLesson(String id, {AssetBundle? bundle}) async {
  final raw = await (bundle ?? rootBundle).loadString(
    'assets/lessons/$id.json',
  );
  return LessonContent.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

/// Plays a lesson one step at a time: explain → check → recap.
class LessonPlayerScreen extends StatefulWidget {
  const LessonPlayerScreen({
    super.key,
    required this.lessonId,
    this.content,
    this.initialStep = 0,
  });

  final String lessonId;

  /// Step to open at (previews only; learners start at 0).
  final int initialStep;

  /// Pre-loaded content (tests); otherwise loaded from assets.
  final LessonContent? content;

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  LessonContent? _lesson;
  Object? _loadError;
  var _index = 0;
  var _correct = 0;
  var _finished = false;
  var _earnedXp = 0;

  // Per-step answer state.
  int? _selected;
  var _checked = false;
  var _wasCorrect = false;
  ({int index, double price})? _tap;

  final _charts = <int, RenderedChart>{};

  @override
  void initState() {
    super.initState();
    final preloaded = widget.content;
    if (preloaded != null) {
      _lesson = preloaded;
      _index = widget.initialStep.clamp(0, preloaded.steps.length - 1);
    } else {
      loadLesson(widget.lessonId).then(
        (l) => setState(() {
          _lesson = l;
          _index = widget.initialStep.clamp(0, l.steps.length - 1);
        }),
        onError: (Object e) => setState(() => _loadError = e),
      );
    }
  }

  RenderedChart _chart(ChartSpec spec) =>
      _charts.putIfAbsent(_index, () => spec.render());

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson;
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This lesson could not be loaded.')),
      );
    }
    if (lesson == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_finished) return _completion(context, lesson);

    final step = lesson.steps[_index];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close lesson',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: GradientProgressBar(
          value: (_index + (_checked ? 1 : 0.5)) / lesson.steps.length,
          height: 10,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: _stepBody(context, step),
              ),
            ),
            if (_checked && (step is QuizStep || step is SpotStep))
              _feedback(context, step),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: GradientButton(
                label: _buttonLabel(step, lesson),
                onPressed: _canProceed(step) ? () => _onButton(step) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _needsCheck(LessonStep step) =>
      (step is QuizStep || step is SpotStep) && !_checked;

  bool _canProceed(LessonStep step) => switch (step) {
    QuizStep() => _checked || _selected != null,
    SpotStep() => _checked || _tap != null,
    _ => true,
  };

  String _buttonLabel(LessonStep step, LessonContent lesson) {
    if (_needsCheck(step)) return 'Check';
    return _index == lesson.steps.length - 1 ? 'Finish' : 'Continue';
  }

  Future<void> _onButton(LessonStep step) async {
    if (_needsCheck(step)) {
      final correct = switch (step) {
        QuizStep() => _selected == step.answer,
        SpotStep() => isSpotCorrect(step, _chart(step.chart), _tap!),
        _ => true,
      };
      setState(() {
        _checked = true;
        _wasCorrect = correct;
        if (correct) _correct++;
      });
      return;
    }
    final lesson = _lesson!;
    if (_index < lesson.steps.length - 1) {
      setState(() {
        _index++;
        _selected = null;
        _checked = false;
        _wasCorrect = false;
        _tap = null;
      });
      return;
    }
    final earned = await ProgressScope.of(context)
        .complete(lesson.id, correctAnswers: _correct);
    setState(() {
      _earnedXp = earned;
      _finished = true;
    });
  }

  Widget _stepBody(BuildContext context, LessonStep step) {
    final theme = Theme.of(context);
    return switch (step) {
      ExplainStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (step.title != null) ...[
            Text(step.title!, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
          ],
          LessonText(step.text),
          if (step.chart != null) ...[
            const SizedBox(height: 16),
            _chartView(step.chart!),
          ],
        ],
      ),
      CandleAnatomyStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (step.title != null) ...[
            Text(step.title!, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
          ],
          LessonText(step.text),
          const SizedBox(height: 16),
          const CandleAnatomy(),
        ],
      ),
      QuizStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(step.question, style: theme.textTheme.titleLarge),
          if (step.chart != null) ...[
            const SizedBox(height: 12),
            _chartView(step.chart!),
          ],
          const SizedBox(height: 16),
          for (var i = 0; i < step.options.length; i++)
            _optionTile(context, step, i),
        ],
      ),
      SpotStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(step.prompt, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            _checked ? ' ' : 'Tap on the chart.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          _chartView(step.chart, spot: step),
        ],
      ),
      ExerciseStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(step.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          LessonText(step.text),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed(step.route),
            icon: const Icon(Icons.candlestick_chart),
            label: const Text('Open the exercise'),
          ),
        ],
      ),
      RecapStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Key points', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          for (final point in step.points)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: LessonText(point)),
                ],
              ),
            ),
        ],
      ),
    };
  }

  Widget _optionTile(BuildContext context, QuizStep step, int i) {
    final theme = Theme.of(context);
    final selected = _selected == i;
    Color? border;
    if (_checked && i == step.answer) {
      border = AppColors.up;
    } else if (_checked && selected) {
      border = AppColors.down;
    } else if (selected) {
      border = AppColors.gold;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected
            ? AppColors.gold.withValues(alpha: 0.1)
            : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: border ?? theme.colorScheme.outlineVariant,
            width: border == null ? 1 : 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _checked ? null : () => setState(() => _selected = i),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(step.options[i], style: theme.textTheme.bodyLarge),
          ),
        ),
      ),
    );
  }

  Widget _chartView(ChartSpec spec, {SpotStep? spot}) {
    final chart = _chart(spec);
    final colors = ChartColors.of(context);
    final showZones =
        spec.showZones ||
        (spot != null &&
            _checked &&
            (spot.target == SpotTarget.support ||
                spot.target == SpotTarget.resistance));
    final zones = <ChartZone>[
      if (showZones)
        for (final z in chart.zones)
          if (spot == null || z.kind.name == spot.target.name || spec.showZones)
            ChartZone(
              low: z.low,
              high: z.high,
              fromIndex: z.fromIndex,
              toIndex: z.toIndex,
              color: z.kind == ZoneKind.support
                  ? AppColors.cyan
                  : AppColors.orange,
              label: z.kind == ZoneKind.support ? 'Support' : 'Resistance',
            ),
    ];
    final tap = _tap;
    final markers = <ChartMarker>[
      if (tap != null)
        ChartMarker(
          index: tap.index,
          price: tap.price,
          pointsUp: true,
          color: _checked
              ? (_wasCorrect ? colors.up : colors.down)
              : Theme.of(context).colorScheme.primary,
        ),
      if (spot != null && _checked && !_wasCorrect)
        if (extremeIndex(spot, chart) case final i?)
          ChartMarker(
            index: i,
            price: spot.target == SpotTarget.highest
                ? chart.candles[i].high
                : chart.candles[i].low,
            pointsUp: spot.target == SpotTarget.lowest,
            color: colors.up,
          ),
    ];
    return SizedBox(
      height: 260,
      child: CandleChart(
        candles: chart.candles,
        visibleBars: spec.visibleBars,
        futureSlots: 2,
        zones: zones,
        markers: markers,
        movingAverage: chart.movingAverage,
        onTapPrice: spot == null || _checked
            ? null
            : (index, price) {
                if (index < 0 || index >= chart.candles.length) return;
                setState(() => _tap = (index: index, price: price));
              },
      ),
    );
  }

  Widget _feedback(BuildContext context, LessonStep step) {
    final explanation = switch (step) {
      QuizStep() => step.explanation,
      SpotStep() => step.explanation,
      _ => '',
    };
    final color = _wasCorrect ? AppColors.up : AppColors.down;
    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.12),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_wasCorrect ? Icons.check_circle : Icons.info, color: color),
              const SizedBox(width: 8),
              Text(
                _wasCorrect ? 'Correct!' : 'Not quite',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LessonText(
            explanation,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _completion(BuildContext context, LessonContent lesson) {
    final theme = Theme.of(context);
    final questions = lesson.questionCount;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: SizedBox(
                  width: 170,
                  height: 170,
                  child: CustomPaint(painter: TrophyArt(showRing: false)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Lesson complete!',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                lesson.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              if (questions > 0)
                Text(
                  '$_correct of $questions answers correct',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              const SizedBox(height: 8),
              Center(
                child: _earnedXp > 0
                    ? GradientText(
                        '+$_earnedXp XP',
                        style: theme.textTheme.headlineMedium,
                      )
                    : Text(
                        'Already completed: no new XP',
                        style: theme.textTheme.titleMedium,
                      ),
              ),
              const SizedBox(height: 32),
              GradientButton(
                label: 'Back to lessons',
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Whether a tap on a "Spot it" chart hits the target.
bool isSpotCorrect(
  SpotStep step,
  RenderedChart chart,
  ({int index, double price}) tap,
) {
  switch (step.target) {
    case SpotTarget.support:
    case SpotTarget.resistance:
      final kind = step.target == SpotTarget.support
          ? ZoneKind.support
          : ZoneKind.resistance;
      final zone = chart.zones.firstWhere((z) => z.kind == kind);
      final tolerance = (zone.high - zone.low) * 0.6;
      return zone.contains(tap.price, tolerance: tolerance) &&
          tap.index >= zone.fromIndex - 2;
    case SpotTarget.highest:
    case SpotTarget.lowest:
      final target = extremeIndex(step, chart);
      return target != null && (tap.index - target).abs() <= 2;
  }
}

/// Index of the highest high / lowest low among the visible candles.
int? extremeIndex(SpotStep step, RenderedChart chart) {
  if (step.target != SpotTarget.highest && step.target != SpotTarget.lowest) {
    return null;
  }
  final candles = chart.candles;
  final start = (candles.length - step.chart.visibleBars).clamp(
    0,
    candles.length,
  );
  var best = start;
  for (var i = start; i < candles.length; i++) {
    if (step.target == SpotTarget.highest
        ? candles[i].high > candles[best].high
        : candles[i].low < candles[best].low) {
      best = i;
    }
  }
  return best;
}
