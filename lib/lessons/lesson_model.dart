import 'package:market_sim/market_sim.dart';

/// A lesson loaded from `assets/lessons/<id>.json`.
class LessonContent {
  const LessonContent({
    required this.id,
    required this.title,
    required this.steps,
  });

  factory LessonContent.fromJson(Map<String, dynamic> json) => LessonContent(
    id: json['id'] as String,
    title: json['title'] as String,
    steps: [
      for (final s in json['steps'] as List)
        LessonStep.fromJson(s as Map<String, dynamic>),
    ],
  );

  final String id;
  final String title;
  final List<LessonStep> steps;

  int get questionCount =>
      steps.where((s) => s is QuizStep || s is SpotStep).length;
}

sealed class LessonStep {
  const LessonStep();

  factory LessonStep.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'explain' => ExplainStep(
        title: json['title'] as String?,
        text: json['text'] as String,
        chart: _chart(json['chart']),
        art: switch (json['art']) {
          final String name => LessonArt.values.byName(name),
          _ => null,
        },
      ),
      'candle_anatomy' => CandleAnatomyStep(
        title: json['title'] as String?,
        text: json['text'] as String,
      ),
      'quiz' => QuizStep(
        question: json['question'] as String,
        options: [for (final o in json['options'] as List) o as String],
        answer: json['answer'] as int,
        explanation: json['explanation'] as String,
        chart: _chart(json['chart']),
      ),
      'spot' => SpotStep(
        prompt: json['prompt'] as String,
        target: SpotTarget.values.byName(json['target'] as String),
        explanation: json['explanation'] as String,
        chart: ChartSpec.fromJson(json['chart'] as Map<String, dynamic>),
      ),
      'exercise' => ExerciseStep(
        title: json['title'] as String,
        text: json['text'] as String,
        route: json['route'] as String,
      ),
      'recap' => RecapStep(
        points: [for (final p in json['points'] as List) p as String],
      ),
      _ => throw FormatException('Unknown lesson step type: $type'),
    };
  }

  static ChartSpec? _chart(Object? json) =>
      json == null ? null : ChartSpec.fromJson(json as Map<String, dynamic>);
}

class ExplainStep extends LessonStep {
  const ExplainStep({this.title, required this.text, this.chart, this.art});

  final String? title;

  /// Supports **bold** markup and blank-line paragraphs.
  final String text;
  final ChartSpec? chart;

  /// Illustration shown above the title (used by the psychology lessons).
  final LessonArt? art;
}

/// Illustrations available to explain steps, by their JSON `art` name.
/// Drawn by `MindArtPainter` in `mind_art.dart`.
enum LessonArt {
  stress,
  fearGreed,
  lossAversion,
  calmPlan,
  nameIt,
  lossesNormal,
  goodBadLoss,
  reset,
  lossLimit,
  tilt,
  rest,
  warningSigns,
  support,
  safePractice,
}

class CandleAnatomyStep extends LessonStep {
  const CandleAnatomyStep({this.title, required this.text});

  final String? title;
  final String text;
}

class QuizStep extends LessonStep {
  const QuizStep({
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
    this.chart,
  });

  final String question;
  final List<String> options;

  /// Index of the correct option.
  final int answer;
  final String explanation;
  final ChartSpec? chart;
}

enum SpotTarget { support, resistance, highest, lowest }

/// "Spot it": tap the right place on a chart.
class SpotStep extends LessonStep {
  const SpotStep({
    required this.prompt,
    required this.target,
    required this.explanation,
    required this.chart,
  });

  final String prompt;
  final SpotTarget target;
  final String explanation;
  final ChartSpec chart;
}

/// Opens an interactive exercise screen (e.g. "Place the trade").
class ExerciseStep extends LessonStep {
  const ExerciseStep({
    required this.title,
    required this.text,
    required this.route,
  });

  final String title;
  final String text;
  final String route;
}

class RecapStep extends LessonStep {
  const RecapStep({required this.points});

  final List<String> points;
}

/// Describes a synthetic chart for a lesson step. The same spec always
/// renders the same chart.
class ChartSpec {
  const ChartSpec({
    required this.seed,
    required this.segments,
    this.startPrice = 100,
    this.reveal,
    this.aggregate = 1,
    this.visibleBars = 70,
    this.showZones = false,
    this.movingAverage,
  });

  factory ChartSpec.fromJson(Map<String, dynamic> json) => ChartSpec(
    seed: json['seed'] as int,
    startPrice: (json['startPrice'] as num? ?? 100).toDouble(),
    segments: [
      for (final s in json['segments'] as List)
        _segment(s as Map<String, dynamic>),
    ],
    reveal: json['reveal'] as int?,
    aggregate: json['aggregate'] as int? ?? 1,
    visibleBars: json['visibleBars'] as int? ?? 70,
    showZones: json['showZones'] as bool? ?? false,
    movingAverage: json['ma'] as int?,
  );

  final int seed;
  final double startPrice;
  final List<Segment> segments;

  /// Number of (base-timeframe) bars shown; all when null.
  final int? reveal;

  /// Combine this many bars into one candle (higher timeframe view).
  final int aggregate;
  final int visibleBars;
  final bool showZones;
  final int? movingAverage;

  static Segment _segment(Map<String, dynamic> json) {
    final bars = json['bars'] as int;
    final label = json['label'] as String?;
    return switch (json['type'] as String) {
      'trend' => TrendSegment(
        bars: bars,
        movePct: (json['movePct'] as num).toDouble(),
        volatilityPct: (json['volatilityPct'] as num? ?? 1.0).toDouble(),
        volumeMultiplier: (json['volume'] as num? ?? 1.0).toDouble(),
        label: label,
      ),
      'range' => RangeSegment(
        bars: bars,
        belowPct: (json['belowPct'] as num).toDouble(),
        abovePct: (json['abovePct'] as num).toDouble(),
        volatilityPct: (json['volatilityPct'] as num? ?? 0.8).toDouble(),
        volumeMultiplier: (json['volume'] as num? ?? 0.8).toDouble(),
        label: label,
      ),
      final other => throw FormatException('Unknown segment type: $other'),
    };
  }

  /// Generates the chart. Zones keep base-timeframe indices, so they are
  /// only offered when [aggregate] is 1.
  RenderedChart render() {
    final scenario = ScenarioGenerator(
      seed: seed,
      startPrice: startPrice,
    ).generate(segments);
    var candles = scenario.candles;
    if (reveal != null && reveal! < candles.length) {
      candles = candles.sublist(0, reveal);
    }
    candles = aggregateCandles(candles, aggregate);
    return RenderedChart(
      candles: candles,
      zones: aggregate == 1 ? scenario.zones : const [],
      movingAverage: movingAverage == null
          ? null
          : Indicators.sma([for (final c in candles) c.close], movingAverage!),
    );
  }
}

class RenderedChart {
  const RenderedChart({
    required this.candles,
    required this.zones,
    this.movingAverage,
  });

  final List<Candle> candles;
  final List<Zone> zones;
  final List<double?>? movingAverage;
}
