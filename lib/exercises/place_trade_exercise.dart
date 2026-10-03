import 'dart:async';

import 'package:flutter/material.dart';
import 'package:market_sim/market_sim.dart';

import '../chart/candle_chart.dart';
import '../chart/chart_models.dart';
import '../format.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_button.dart';
import 'trade_scenario.dart';

enum _Phase { planning, running, done }

/// "Place the trade": drag the stop-loss and take-profit, see the risk and
/// position size update live, then watch the trade play out bar by bar.
///
/// With a [challenge] it is round 3 of the Daily Challenge: today's chart,
/// no "new chart" button, and it closes with the plan's [ProcessScore].
class PlaceTradeExercise extends StatefulWidget {
  const PlaceTradeExercise({
    super.key,
    this.seed = 7,
    this.replayInterval = const Duration(milliseconds: 140),
    this.challenge,
  });

  final int seed;
  final Duration replayInterval;
  final TradeSetup? challenge;

  @override
  State<PlaceTradeExercise> createState() => _PlaceTradeExerciseState();
}

class _PlaceTradeExerciseState extends State<PlaceTradeExercise> {
  static const spec = Instruments.synthetic;
  static const balance = 10000.0;
  static const maxReplayBars = 60;
  static const rules = ProcessRules();

  late int _seed;
  late TradeScenario _scenario;
  late ReplaySession _session;
  late List<double?> _ma;
  var _phase = _Phase.planning;
  var _side = Side.long;
  var _riskPct = 1.0;
  late double _stop;
  late double _target;
  Timer? _timer;
  var _barsReplayed = 0;
  ClosedTrade? _result;
  ProcessScore? _score;
  String? _error;

  @override
  void initState() {
    super.initState();
    _seed = widget.seed;
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _load() {
    final challenge = widget.challenge;
    _scenario = challenge != null
        ? TradeScenario.forSetup(challenge)
        : TradeScenario.supportBounce(_seed);
    _session = ReplaySession(
      candles: _scenario.scenario.candles,
      spec: spec,
      startingBalance: balance,
      startIndex: _scenario.revealIndex,
    );
    _ma = Indicators.sma([
      for (final c in _scenario.scenario.candles) c.close,
    ], 20);
    _phase = _Phase.planning;
    _side = _scenario.side;
    _result = null;
    _score = null;
    _error = null;
    _barsReplayed = 0;
    _resetLevels();
  }

  /// Starts with a deliberately cramped 1:1 plan so the learner has to think
  /// about where the stop and target really belong.
  void _resetLevels() {
    final atr =
        Indicators.atr(_scenario.scenario.candles)[_session.currentIndex] ??
        _entry * 0.01;
    _stop = spec.roundPrice(_entry - _side.sign * atr * 0.6);
    _target = spec.roundPrice(_entry + _side.sign * atr * 0.6);
  }

  double get _entry => _session.currentPrice;

  PositionSize get _size {
    if (Risk.levelError(side: _side, entry: _entry, stop: _stop) != null) {
      return PositionSize.zero;
    }
    return Risk.positionSize(
      balance: balance,
      riskPct: _riskPct,
      entry: _entry,
      stop: _stop,
      spec: spec,
    );
  }

  void _placeTrade() {
    final levelError = Risk.levelError(
      side: _side,
      entry: _entry,
      stop: _stop,
      target: _target,
    );
    if (levelError != null) {
      setState(() => _error = levelError);
      return;
    }
    final size = _size;
    try {
      _session.submit(
        OrderRequest(
          side: _side,
          quantity: size.quantity,
          stopLoss: _stop,
          takeProfit: _target,
        ),
      );
    } on OrderRejected catch (e) {
      setState(() => _error = e.message);
      return;
    }
    _score = scoreTradePlan(
      side: _side,
      entry: _entry,
      stop: _stop,
      target: _target,
      quantity: size.quantity,
      balance: balance,
      spec: spec,
      rules: rules,
    );
    setState(() {
      _error = null;
      _phase = _Phase.running;
    });
    _timer = Timer.periodic(widget.replayInterval, (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      if (_session.hasNextBar &&
          !_session.isFlat &&
          _barsReplayed < maxReplayBars) {
        _session.step();
        _barsReplayed++;
      }
      if (_session.isFlat ||
          !_session.hasNextBar ||
          _barsReplayed >= maxReplayBars) {
        _timer?.cancel();
        _session.finish();
        _result = _session.trades.last;
        _phase = _Phase.done;
      }
    });
  }

  void _nextChart() {
    _timer?.cancel();
    setState(() {
      _seed++;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.challenge != null
              ? 'Round 3 · Plan the trade'
              : 'Place the trade',
        ),
        actions: [
          if (widget.challenge == null)
            IconButton(
              tooltip: 'New chart',
              icon: const Icon(Icons.refresh),
              onPressed: _phase == _Phase.running ? null : _nextChart,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Banner(phase: _phase, side: _scenario.side),
            Expanded(
              flex: 11,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
                child: CandleChart(
                  candles: _scenario.scenario.candles.sublist(
                    0,
                    _session.currentIndex + 1,
                  ),
                  visibleBars: 70,
                  futureSlots: 14,
                  movingAverage: _ma,
                  priceDecimals: spec.priceDecimals,
                  lines: _lines(context),
                  zones: _phase == _Phase.done ? _answerZones() : const [],
                  markers: _markers(),
                  onLineDragged: _phase == _Phase.planning ? _onDrag : null,
                ),
              ),
            ),
            Expanded(
              flex: 9,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  border: Border(
                    top: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: switch (_phase) {
                    _Phase.planning => _planningPanel(context),
                    _Phase.running => _runningPanel(context),
                    _Phase.done => _resultPanel(context),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onDrag(String id, double price) {
    setState(() {
      _error = null;
      final rounded = spec.roundPrice(price);
      if (id == 'stop') _stop = rounded;
      if (id == 'target') _target = rounded;
    });
  }

  List<PriceLine> _lines(BuildContext context) {
    final colors = ChartColors.of(context);
    final position = _session.position;
    final planning = _phase == _Phase.planning;
    final entry = position?.entryPrice ?? _result?.entryPrice ?? _entry;
    return [
      PriceLine(
        id: 'entry',
        price: entry,
        color: context.palette.textMuted,
        label: planning ? 'Entry (current price)' : 'Entry',
        dashed: true,
      ),
      PriceLine(
        id: 'stop',
        price: _stop,
        color: colors.down,
        label: 'Stop-loss',
        draggable: planning,
      ),
      PriceLine(
        id: 'target',
        price: _target,
        color: colors.up,
        label: 'Take-profit',
        draggable: planning,
      ),
    ];
  }

  List<ChartZone> _answerZones() => [
    ChartZone(
      low: _scenario.support.low,
      high: _scenario.support.high,
      fromIndex: _scenario.support.fromIndex,
      toIndex: _scenario.support.toIndex,
      color: context.palette.cyan,
      label: 'Support zone',
    ),
    ChartZone(
      low: _scenario.resistance.low,
      high: _scenario.resistance.high,
      fromIndex: _scenario.resistance.fromIndex,
      toIndex: _scenario.resistance.toIndex,
      color: context.palette.orange,
      label: 'Resistance zone',
    ),
  ];

  List<ChartMarker> _markers() {
    final trade = _result;
    final position = _session.position;
    final entryIndex = trade?.entryIndex ?? position?.entryIndex;
    final entryPrice = trade?.entryPrice ?? position?.entryPrice;
    return [
      if (entryIndex != null && entryPrice != null)
        ChartMarker(
          index: entryIndex,
          price: entryPrice,
          pointsUp: _side == Side.long,
          color: context.palette.cyan,
        ),
      if (trade != null)
        ChartMarker(
          index: trade.exitIndex,
          price: trade.exitPrice,
          pointsUp: _side != Side.long,
          color: trade.isWin ? context.palette.up : context.palette.down,
        ),
    ];
  }

  Widget _planningPanel(BuildContext context) {
    final theme = Theme.of(context);
    final size = _size;
    final rr = Risk.rewardRisk(
      side: _side,
      entry: _entry,
      stop: _stop,
      target: _target,
    );
    final reward = (_target - _entry).abs() * size.quantity * spec.contractSize;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<Side>(
          segments: const [
            ButtonSegment(
              value: Side.long,
              label: Text('Long (buy)'),
              icon: Icon(Icons.trending_up),
            ),
            ButtonSegment(
              value: Side.short,
              label: Text('Short (sell)'),
              icon: Icon(Icons.trending_down),
            ),
          ],
          selected: {_side},
          onSelectionChanged: (s) => setState(() {
            _side = s.first;
            _error = null;
            _resetLevels();
          }),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Metric(
                label: 'Reward : risk',
                value: rr == null ? '—' : '${rr.toStringAsFixed(1)} : 1',
                good: rr != null && rr >= rules.minRewardRisk,
              ),
            ),
            Expanded(
              child: _Metric(
                label: 'Position size',
                value: '${quantity(size.quantity)} ${spec.quantityUnit}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _Metric(
                label: 'If stopped out',
                value: money(-size.riskAmount),
                color: context.palette.down,
              ),
            ),
            Expanded(
              child: _Metric(
                label: 'If target hit',
                value: money(reward, signed: true),
                color: context.palette.up,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Risk per trade (of your ${money(balance)} virtual account)',
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            for (final pct in const [0.5, 1.0, 2.0, 5.0])
              ChoiceChip(
                label: Text(
                  '${pct == pct.roundToDouble() ? pct.toStringAsFixed(0) : pct}%',
                ),
                selected: _riskPct == pct,
                onSelected: (_) => setState(() => _riskPct = pct),
              ),
          ],
        ),
        if (size.limitedByLeverage)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Size reduced to stay within ${spec.maxLeverage.toStringAsFixed(0)}:1 leverage.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        const SizedBox(height: 14),
        GradientButton(
          label: 'Place trade',
          icon: Icons.play_arrow,
          onPressed: _placeTrade,
        ),
      ],
    );
  }

  Widget _runningPanel(BuildContext context) {
    final theme = Theme.of(context);
    final pnl = _session.unrealizedPnl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Trade running… bar $_barsReplayed',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _Metric(
          label: 'Open profit / loss',
          value: money(pnl, signed: true),
          color: pnl >= 0 ? context.palette.up : context.palette.down,
        ),
        const SizedBox(height: 8),
        Text(
          'Hands off: the plan is set. Let the stop-loss or take-profit do the work.',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _resultPanel(BuildContext context) {
    final theme = Theme.of(context);
    final trade = _result!;
    final score = _score!;
    final r = trade.rMultiple;
    final headline = switch (trade.exitReason) {
      ExitReason.takeProfit => 'Target hit!',
      ExitReason.stopLoss => 'Stopped out',
      _ => 'Trade closed after $maxReplayBars bars',
    };
    final goodProcess = score.score >= 70;
    final takeaway = switch ((trade.isWin, goodProcess)) {
      (true, true) => 'Good plan, good result. Now repeat it many times.',
      (false, true) => 'A well-planned loss. Losses are part of trading; over many trades a good process is what wins.',
      (true, false) => 'You made money, but the plan was risky. Luck doesn\'t repeat. Process does.',
      (false, false) =>
        'The plan needed work. Check the notes below, then try another chart.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(headline, style: theme.textTheme.titleLarge)),
            Text(
              '${money(trade.netPnl, signed: true)}${r == null ? '' : '  (${rMultiple(r)})'}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: trade.isWin ? context.palette.up : context.palette.down,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Costs paid (spread): ${money(trade.fees)}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Plan score: ${score.score}/${score.maxScore} · ${score.grade}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final check in score.checks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          check.passed
                              ? Icons.check_circle
                              : check.points > 0
                              ? Icons.remove_circle
                              : Icons.cancel,
                          size: 20,
                          color: check.passed
                              ? context.palette.up
                              : check.points > 0
                              ? context.palette.gold
                              : context.palette.down,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${check.label}: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(text: check.feedback),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(takeaway, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 6),
        Text(
          'On the chart: the shaded zones show where support and resistance were. '
          'Stops just beyond a zone survive the normal wiggles inside it.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 14),
        if (widget.challenge != null)
          GradientButton(
            label: 'See today\'s score',
            icon: Icons.emoji_events_outlined,
            onPressed: () => Navigator.of(context).pop(_score),
          )
        else
          GradientButton(
            label: 'Try another chart',
            icon: Icons.refresh,
            onPressed: _nextChart,
          ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.phase, required this.side});

  final _Phase phase;
  final Side side;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = switch (phase) {
      _Phase.planning when side == Side.short =>
        'Price has rallied back to an area where sellers stepped in before. '
            'Plan a short trade: drag the red stop-loss and the green '
            'take-profit.',
      _Phase.planning =>
        'Price has pulled back to an area where buyers stepped in before. '
            'Plan a trade: drag the red stop-loss and the green take-profit.',
      _Phase.running => 'Watching the market…',
      _Phase.done => 'Here is what happened.',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: context.palette.surfaceHigh,
        border: Border(left: BorderSide(color: context.palette.gold, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 2),
          Text(
            'Simulated trade with virtual money. Educational only, not financial advice.',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.color,
    this.good,
  });

  final String label;
  final String value;
  final Color? color;
  final bool? good;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueColor =
        color ??
        switch (good) {
          true => context.palette.up,
          false => context.palette.gold,
          null => theme.colorScheme.onSurface,
        };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
