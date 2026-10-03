import 'dart:async';

import 'package:flutter/material.dart';
import 'package:market_sim/market_sim.dart';

import '../chart/candle_chart.dart';
import '../chart/chart_models.dart';
import '../exercises/place_trade_exercise.dart';
import '../lessons/lesson_model.dart';
import '../lessons/lesson_player.dart';
import '../lessons/rich_text.dart';
import '../progress/progress_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_button.dart';
import '../widgets/tab_hero.dart';
import 'daily_challenge_store.dart';

const dailyChallengeRoute = '/daily';

enum _Stage { intro, chart, sizing, plan, results }

/// The Daily Challenge: read a chart, size a position, plan a trade. New
/// every day, the same for everyone, scored on process.
class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({
    super.key,
    this.replayInterval = const Duration(milliseconds: 140),
  });

  /// Speed of the trade replay in round 3 (faster in tests).
  final Duration replayInterval;

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  DailyChallenge? _challenge;
  var _stage = _Stage.intro;

  // Round scores (0–100).
  var _chartPoints = 0;
  var _sizingPoints = 0;
  int? _earnedXp;

  // Answer state of the current round.
  int? _selected;
  ({int index, double price})? _tap;
  var _checked = false;
  var _correct = false;
  RenderedChart? _rendered;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_challenge != null) return;
    final store = DailyScope.of(context);
    // Fixed when the screen opens, so midnight can't swap it mid-game.
    _challenge = store.today;
    if (store.todayResult != null) _stage = _Stage.results;
  }

  DailyChallenge get challenge => _challenge!;

  SpotStep? get _spot => switch (challenge.chart.task) {
    ChartTask.trend => null,
    final task => SpotStep(
      prompt: challenge.chart.prompt,
      target: switch (task) {
        ChartTask.support => SpotTarget.support,
        ChartTask.resistance => SpotTarget.resistance,
        _ => SpotTarget.breakout,
      },
      explanation: challenge.chart.explanation,
      chart: ChartSpec(
        seed: challenge.chart.seed,
        segments: challenge.chart.segments,
        visibleBars: 84,
      ),
    ),
  };

  RenderedChart get _chart => _rendered ??= ChartSpec(
    seed: challenge.chart.seed,
    segments: challenge.chart.segments,
    visibleBars: 84,
  ).render();

  void _resetAnswer() {
    _selected = null;
    _tap = null;
    _checked = false;
    _correct = false;
  }

  void _check() {
    final correct = switch (_stage) {
      _Stage.chart => switch (_spot) {
        final spot? => isSpotCorrect(spot, _chart, _tap!),
        null => _selected == challenge.chart.trend!.index,
      },
      _Stage.sizing => _selected == challenge.sizing.answer,
      _ => false,
    };
    setState(() {
      _checked = true;
      _correct = correct;
      if (_stage == _Stage.chart) _chartPoints = correct ? 100 : 0;
      if (_stage == _Stage.sizing) _sizingPoints = correct ? 100 : 0;
    });
  }

  void _next() {
    setState(() {
      _resetAnswer();
      _stage = switch (_stage) {
        _Stage.intro => _Stage.chart,
        _Stage.chart => _Stage.sizing,
        _Stage.sizing => _Stage.plan,
        _ => _stage,
      };
    });
  }

  Future<void> _openTrade() async {
    final score = await Navigator.of(context).push<ProcessScore>(
      MaterialPageRoute(
        builder: (_) => PlaceTradeExercise(
          challenge: challenge.trade,
          replayInterval: widget.replayInterval,
        ),
      ),
    );
    if (score == null || !mounted) return;
    final result = DailyResult(
      chart: _chartPoints,
      sizing: _sizingPoints,
      plan: (score.score / score.maxScore * 100).round(),
    );
    final store = DailyScope.of(context);
    final progress = ProgressScope.of(context);
    final saved = await store.record(challenge.dateKey, result);
    if (saved) await progress.addXp(result.xp);
    if (!mounted) return;
    setState(() {
      _earnedXp = saved ? result.xp : null;
      _stage = _Stage.results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final round = switch (_stage) {
      _Stage.chart => 1,
      _Stage.sizing => 2,
      _Stage.plan => 3,
      _ => null,
    };
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: round == null
            ? Text('Daily Challenge #${challenge.number}')
            : GradientProgressBar(value: (round - (_checked ? 0 : 0.5)) / 3),
      ),
      body: SafeArea(
        child: switch (_stage) {
          _Stage.intro => _intro(context),
          _Stage.chart => _round(
            context,
            number: 1,
            title: 'Read the chart',
            body: _chartRound(context),
            explanation: challenge.chart.explanation,
          ),
          _Stage.sizing => _round(
            context,
            number: 2,
            title: 'Size it',
            body: _sizingRound(context),
            explanation: challenge.sizing.explanation,
          ),
          _Stage.plan => _planRound(context),
          _Stage.results => _ResultsView(
            challenge: challenge,
            earnedXp: _earnedXp,
          ),
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Intro

  Widget _intro(BuildContext context) {
    final theme = Theme.of(context);
    final store = DailyScope.of(context);
    final palette = context.palette;
    final task = switch (challenge.chart.task) {
      ChartTask.trend => 'Spot the trend',
      ChartTask.support => 'Find the support zone',
      ChartTask.resistance => 'Find the resistance zone',
      ChartTask.breakout => 'Find the breakout candle',
    };
    final setup = challenge.trade.kind == TradeSetupKind.supportBounce
        ? 'A long trade at support'
        : 'A short trade at resistance';
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Row(
                children: [
                  const IconBadge(
                    icon: Icons.today,
                    colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                    size: 52,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today\'s challenge',
                          style: theme.textTheme.headlineSmall,
                        ),
                        Text(
                          longDate(store.now),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Three quick rounds, about three minutes. A new challenge '
                'every day, the same for everyone. You\'re scored on how you '
                'think, not on luck.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 18),
              _RoundRow(
                number: 1,
                title: 'Read the chart',
                subtitle: task,
                icon: Icons.candlestick_chart,
              ),
              _RoundRow(
                number: 2,
                title: 'Size it',
                subtitle: 'Position size on ${challenge.sizing.market}',
                icon: Icons.calculate_outlined,
              ),
              _RoundRow(
                number: 3,
                title: 'Plan the trade',
                subtitle: setup,
                icon: Icons.track_changes,
              ),
              if (store.streak > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Pill(
                      label: '${store.streak}-day streak',
                      icon: Icons.local_fire_department,
                      color: palette.gold,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: GradientButton(
            label: 'Start',
            icon: Icons.play_arrow,
            onPressed: _next,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Rounds 1 and 2

  Widget _round(
    BuildContext context, {
    required int number,
    required String title,
    required Widget body,
    required String explanation,
  }) {
    final theme = Theme.of(context);
    final canCheck = _selected != null || _tap != null;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ROUND $number OF 3',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: context.palette.gold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 12),
                body,
              ],
            ),
          ),
        ),
        if (_checked) _Feedback(correct: _correct, explanation: explanation),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: GradientButton(
            label: _checked ? 'Continue' : 'Check',
            onPressed: _checked ? _next : (canCheck ? _check : null),
          ),
        ),
      ],
    );
  }

  Widget _chartRound(BuildContext context) {
    final theme = Theme.of(context);
    final spot = _spot;
    final chart = _chart;
    final colors = ChartColors.of(context);
    final palette = context.palette;
    final tap = _tap;
    final zoneTarget = spot != null && spot.target != SpotTarget.breakout;
    final zones = <ChartZone>[
      if (_checked && zoneTarget)
        for (final z in chart.zones)
          if (z.kind.name == spot.target.name)
            ChartZone(
              low: z.low,
              high: z.high,
              fromIndex: z.fromIndex,
              toIndex: z.toIndex,
              color: z.kind == ZoneKind.support ? palette.cyan : palette.orange,
              label: z.kind == ZoneKind.support ? 'Support' : 'Resistance',
            ),
    ];
    final answer = spot == null ? null : spotAnswerIndex(spot, chart);
    final markers = <ChartMarker>[
      if (tap != null)
        ChartMarker(
          index: tap.index,
          price: tap.price,
          pointsUp: true,
          color: _checked
              ? (_correct ? colors.up : colors.down)
              : theme.colorScheme.primary,
        ),
      if (_checked && !_correct && spot != null && answer != null)
        ChartMarker(
          index: answer,
          price: spotAnswerAtHigh(spot, chart)
              ? chart.candles[answer].high
              : chart.candles[answer].low,
          pointsUp: !spotAnswerAtHigh(spot, chart),
          color: colors.up,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(challenge.chart.prompt, style: theme.textTheme.titleMedium),
        if (spot != null)
          Text(
            _checked ? ' ' : 'Tap on the chart.',
            style: theme.textTheme.bodySmall,
          ),
        const SizedBox(height: 10),
        SizedBox(
          // Shorter on small phones so the answers stay in view.
          height: (MediaQuery.sizeOf(context).height * 0.32).clamp(170, 250),
          child: CandleChart(
            candles: chart.candles,
            visibleBars: 84,
            futureSlots: 2,
            zones: zones,
            markers: markers,
            onTapPrice: spot == null || _checked
                ? null
                : (index, price) {
                    if (index < 0 || index >= chart.candles.length) return;
                    setState(() => _tap = (index: index, price: price));
                  },
          ),
        ),
        if (spot == null) ...[
          const SizedBox(height: 14),
          for (final direction in TrendDirection.values)
            _OptionTile(
              label: switch (direction) {
                TrendDirection.up => 'Up',
                TrendDirection.down => 'Down',
                TrendDirection.sideways => 'Sideways',
              },
              icon: switch (direction) {
                TrendDirection.up => Icons.trending_up,
                TrendDirection.down => Icons.trending_down,
                TrendDirection.sideways => Icons.trending_flat,
              },
              selected: _selected == direction.index,
              state: !_checked
                  ? null
                  : direction == challenge.chart.trend
                  ? true
                  : _selected == direction.index
                  ? false
                  : null,
              onTap: _checked
                  ? null
                  : () => setState(() => _selected = direction.index),
            ),
        ],
      ],
    );
  }

  Widget _sizingRound(BuildContext context) {
    final theme = Theme.of(context);
    final sizing = challenge.sizing;
    final palette = context.palette;
    const icons = [
      Icons.account_balance_wallet_outlined,
      Icons.shield_outlined,
      Icons.straighten,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sizing.market.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: palette.gold,
                ),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < sizing.facts.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icons[i], size: 20, color: palette.textMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          sizing.facts[i],
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'What size risks exactly that amount if the stop is hit?',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < sizing.options.length; i++)
          _OptionTile(
            label: sizing.options[i],
            selected: _selected == i,
            state: !_checked
                ? null
                : i == sizing.answer
                ? true
                : _selected == i
                ? false
                : null,
            onTap: _checked ? null : () => setState(() => _selected = i),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Round 3

  Widget _planRound(BuildContext context) {
    final theme = Theme.of(context);
    final long = challenge.trade.kind == TradeSetupKind.supportBounce;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Text(
                'ROUND 3 OF 3',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: context.palette.gold,
                ),
              ),
              const SizedBox(height: 4),
              Text('Plan the trade', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              LessonText(
                long
                    ? 'Price is back at **support** after a rise. Plan a '
                          '**long** trade: a stop-loss below the zone and a '
                          'realistic target.'
                    : 'Price is back at **resistance** after a fall. Plan a '
                          '**short** trade: a stop-loss above the zone and a '
                          'realistic target.',
              ),
              const SizedBox(height: 12),
              const LessonText(
                'You\'re scored on the **plan**: a stop-loss, at least '
                '**1.5 : 1** reward to risk, and **1%** risk or less. The '
                'result doesn\'t change your score.',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _ScoreChip(label: 'Round 1', points: _chartPoints),
                  const SizedBox(width: 8),
                  _ScoreChip(label: 'Round 2', points: _sizingPoints),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: GradientButton(
            label: 'Open today\'s chart',
            icon: Icons.candlestick_chart,
            onPressed: _openTrade,
          ),
        ),
      ],
    );
  }
}

/// "Saturday 3 October".
String longDate(DateTime d) {
  const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
}

/// "7 h 12 min", "45 min".
String untilText(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60;
  return h > 0 ? '$h h $m min' : '${d.inMinutes < 1 ? 1 : m} min';
}

class _RoundRow extends StatelessWidget {
  const _RoundRow({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final int number;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: Text(
              '$number',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.onGold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Icon(icon, color: palette.textMuted),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.state,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool selected;

  /// After checking: true = right answer, false = wrong pick, null = neither.
  final bool? state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final border = switch (state) {
      true => palette.up,
      false => palette.down,
      null => selected ? palette.gold : theme.colorScheme.outlineVariant,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? palette.gold.withValues(alpha: 0.1) : palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: border,
            width: state != null || selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: palette.textMuted),
                  const SizedBox(width: 12),
                ],
                Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
                if (state == true) Icon(Icons.check_circle, color: palette.up),
                if (state == false) Icon(Icons.cancel, color: palette.down),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.correct, required this.explanation});

  final bool correct;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final color = correct ? context.palette.up : context.palette.down;
    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.12),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(correct ? Icons.check_circle : Icons.info, color: color),
              const SizedBox(width: 8),
              Text(
                correct ? 'Correct! +100' : 'Not quite',
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
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.label, required this.points});

  final String label;
  final int points;

  @override
  Widget build(BuildContext context) => Pill(
    label: '$label: $points',
    icon: points > 0 ? Icons.check_circle : Icons.remove_circle_outline,
    color: points > 0 ? context.palette.up : context.palette.textMuted,
  );
}

/// Today's score, the streak and the last seven days.
class _ResultsView extends StatefulWidget {
  const _ResultsView({required this.challenge, required this.earnedXp});

  final DailyChallenge challenge;
  final int? earnedXp;

  @override
  State<_ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends State<_ResultsView> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Keeps the "next challenge in" countdown fresh.
    _ticker = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final store = DailyScope.of(context);
    final result = store.resultFor(widget.challenge.dateKey);
    if (result == null) return const SizedBox.shrink();
    final best = store.best;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: palette.heroGradient,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: palette.outline),
                ),
                child: Column(
                  children: [
                    Text(
                      longDate(store.now).toUpperCase(),
                      style: theme.textTheme.labelSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        GradientText(
                          '${result.total}',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          ' / ${DailyResult.maxTotal}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Text(result.verdict, style: theme.textTheme.titleMedium),
                    if (widget.earnedXp != null) ...[
                      const SizedBox(height: 10),
                      Pill(
                        label: '+${widget.earnedXp} XP',
                        icon: Icons.bolt,
                        gradient: AppColors.primaryGradient,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ScoreRow(
                title: 'Read the chart',
                points: result.chart,
                icon: Icons.candlestick_chart,
              ),
              _ScoreRow(
                title: 'Size it',
                points: result.sizing,
                icon: Icons.calculate_outlined,
              ),
              _ScoreRow(
                title: 'Plan the trade',
                points: result.plan,
                icon: Icons.track_changes,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: palette.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_fire_department, color: palette.gold),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            store.streak == 1
                                ? '1-day streak'
                                : '${store.streak}-day streak',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (best != null)
                          Text('Best $best', style: theme.textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _WeekStrip(days: store.lastDays(7)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Next challenge in ${untilText(store.untilNext)}.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: GradientButton(
            label: 'Done',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.title,
    required this.points,
    required this.icon,
  });

  final String title;
  final int points;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: palette.textMuted),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: theme.textTheme.bodyLarge)),
          SizedBox(
            width: 90,
            child: GradientProgressBar(value: points / 100, height: 8),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            child: Text(
              '$points',
              textAlign: TextAlign.end,
              style: theme.textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.days});

  final List<(DateTime, DailyResult?)> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final (i, (day, result)) in days.indexed)
          Semantics(
            label:
                '${longDate(day)}: '
                '${result == null ? 'not played' : '${result.total} points'}',
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: result != null ? AppColors.primaryGradient : null,
                    border: result == null
                        ? Border.all(
                            color: i == days.length - 1
                                ? palette.gold
                                : palette.outline,
                            width: 2,
                          )
                        : null,
                  ),
                  child: result != null
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: AppColors.onGold,
                        )
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  letters[day.weekday - 1],
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
