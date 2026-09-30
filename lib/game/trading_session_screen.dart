import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:market_sim/market_sim.dart';

import '../chart/candle_chart.dart';
import '../chart/chart_models.dart';
import '../format.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_button.dart';
import 'session_result.dart';

/// One trading day on one market: read the news, plan, trade at real bid
/// and ask prices while the day plays out, candle by candle.
class TradingSessionScreen extends StatefulWidget {
  const TradingSessionScreen({
    super.key,
    required this.market,
    required this.dayNumber,
    required this.ranked,
    required this.startingBalance,
    this.tick = const Duration(milliseconds: 700),
    this.onComplete,
  });

  final MarketProfile market;
  final int dayNumber;
  final bool ranked;
  final double startingBalance;

  /// Time per candle at 1× speed.
  final Duration tick;

  /// Called once when the session ends; the returned widget is shown next.
  final Future<Widget> Function(SessionResult result)? onComplete;

  @override
  State<TradingSessionScreen> createState() => _TradingSessionScreenState();
}

class _TradingSessionScreenState extends State<TradingSessionScreen> {
  static const _speeds = [1, 2, 4, 8];

  late final TradingDay _day = generateTradingDay(
    widget.market,
    widget.dayNumber,
  );
  late final ReplaySession _s = ReplaySession(
    candles: _day.candles,
    spec: _spec,
    startingBalance: widget.startingBalance,
    startIndex: _day.sessionStart - 1,
    spreads: _day.spreads,
  );
  late final double _atr =
      Indicators.atr(_day.candles.sublist(0, _day.sessionStart)).last ??
      _day.sessionOpen * widget.market.dailyVolatilityPct / 100 / 10;

  InstrumentSpec get _spec => widget.market.spec;

  Timer? _timer;
  var _playing = false;
  var _speed = 1;
  var _eventRevealed = false;
  var _ending = false;

  // Order ticket.
  var _side = Side.long;
  var _type = OrderType.market;
  var _riskPct = 1.0;
  var _autoSize = true;
  var _manualQty = 0.0;
  late double _slDist = _niceDistance(_atr * 2.5);
  late double _tpDist = _niceDistance(_atr * 5);
  late double _orderOffset = _niceDistance(_atr * 2);
  var _useTp = true;
  String? _message;

  bool get _preMarket => _s.currentIndex < _day.sessionStart;

  double get _distStep =>
      _spec.pipSize ?? _niceDistance(math.max(_atr / 4, _spec.tickSize));

  double _niceDistance(double d) {
    final unit = _spec.pipSize ?? _spec.tickSize;
    final steps = math.max(1, (d / unit).round());
    return _spec.roundPrice(steps * unit);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ---- Playback ----------------------------------------------------------

  void _togglePlay() {
    if (_ending) return;
    setState(() => _playing = !_playing);
    _restartTimer();
  }

  void _cycleSpeed() {
    setState(
      () => _speed = _speeds[(_speeds.indexOf(_speed) + 1) % _speeds.length],
    );
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (!_playing) return;
    _timer = Timer.periodic(
      Duration(microseconds: widget.tick.inMicroseconds ~/ _speed),
      (_) => _advance(),
    );
  }

  void _advance() {
    if (!mounted || _ending) return;
    if (!_s.hasNextBar) {
      _end();
      return;
    }
    final event = _s.step();
    final closed = event.closedTrade;
    setState(() {
      if (event.entryFilled) {
        _toast(
          'Order filled at ${_price(_s.position?.entryPrice ?? closed?.entryPrice ?? 0)}',
        );
      }
      if (closed != null) _toast(_closeMessage(closed));
      if (_s.currentIndex == _day.event.index) {
        _eventRevealed = true;
        _playing = false; // pause so the player can react to the news
        _timer?.cancel();
      }
    });
    if (!_s.hasNextBar) _end();
  }

  Future<void> _end() async {
    if (_ending) return;
    _ending = true;
    _timer?.cancel();
    _s.finish();
    final result = SessionResult(
      day: _day,
      trades: List.of(_s.trades),
      startBalance: widget.startingBalance,
      endBalance: _s.balance,
      ranked: widget.ranked,
    );
    final next = await widget.onComplete?.call(result);
    if (!mounted) return;
    if (next != null) {
      await Navigator.of(context)
          .pushReplacement(MaterialPageRoute<void>(builder: (_) => next));
    } else {
      Navigator.of(context).pop(result);
    }
  }

  // ---- Ticket maths ------------------------------------------------------

  double get _entry {
    final buy = _side == Side.long;
    final ref = buy ? _s.ask : _s.bid;
    return switch (_type) {
      OrderType.market => ref,
      OrderType.limit => _spec.roundPrice(
        buy ? ref - _orderOffset : ref + _orderOffset,
      ),
      OrderType.stop => _spec.roundPrice(
        buy ? ref + _orderOffset : ref - _orderOffset,
      ),
    };
  }

  double get _stop => _spec.roundPrice(_entry - _side.sign * _slDist);
  double? get _target =>
      _useTp ? _spec.roundPrice(_entry + _side.sign * _tpDist) : null;

  double get _qty {
    if (!_autoSize) return _manualQty;
    return Risk.positionSize(
      balance: _s.equity,
      riskPct: _riskPct,
      entry: _entry,
      stop: _stop,
      spec: _spec,
    ).quantity;
  }

  double _riskAmount(double qty) =>
      _spec.toAccount((_entry - _stop).abs() * qty * _spec.contractSize, _stop);

  String? get _ruleProblem {
    final qty = _qty;
    if (qty <= 0) {
      return 'Position size is zero. Increase the risk % or tighten the stop.';
    }
    if (widget.ranked) {
      final pct = _riskAmount(qty) / _s.equity * 100;
      if (pct > LeagueRules.maxRiskPct + 1e-9) {
        return 'League rule: risk at most ${LeagueRules.maxRiskPct.toStringAsFixed(0)}% '
            'per trade (this is ${pct.toStringAsFixed(1)}%).';
      }
    }
    if (_type == OrderType.market && _preMarket) {
      return 'The market opens at 08:00. Press play, or place a limit/stop order.';
    }
    return null;
  }

  void _place() {
    final problem = _ruleProblem;
    if (problem != null) {
      setState(() => _message = problem);
      return;
    }
    final qty = _qty;
    try {
      _s.submit(
        OrderRequest(
          side: _side,
          quantity: qty,
          type: _type,
          price: _type == OrderType.market ? null : _entry,
          stopLoss: _stop,
          takeProfit: _target,
        ),
      );
      setState(() {
        _message = null;
        if (_type == OrderType.market) {
          _toast(
            '${_side == Side.long ? 'Bought' : 'Sold'} ${quantity(qty)} ${_spec.quantityUnit} at ${_price(_s.position!.entryPrice)}',
          );
        } else {
          _toast('${_orderName(_side, _type)} placed at ${_price(_entry)}');
        }
      });
    } on OrderRejected catch (e) {
      setState(() => _message = e.message);
    }
  }

  void _closePosition() {
    final trade = _s.closePosition();
    setState(() => _toast(_closeMessage(trade)));
  }

  void _breakeven() {
    final p = _s.position!;
    try {
      _s.updateLevels(stopLoss: p.entryPrice, takeProfit: p.takeProfit);
      setState(() => _toast('Stop moved to break-even'));
    } on OrderRejected catch (e) {
      setState(() => _message = e.message);
    }
  }

  void _onDrag(String id, double price) {
    final position = _s.position;
    setState(() {
      _message = null;
      if (position != null) {
        final stop = id == 'sl' ? _spec.roundPrice(price) : position.stopLoss;
        final target = id == 'tp'
            ? _spec.roundPrice(price)
            : position.takeProfit;
        try {
          _s.updateLevels(stopLoss: stop, takeProfit: target);
        } on OrderRejected {
          // Ignore drags past the current price.
        }
        return;
      }
      final minDist = math.max(_spec.tickSize, _s.spread);
      switch (id) {
        case 'sl':
          _slDist = _spec.roundPrice(
            math.max(minDist, (_entry - price) * _side.sign),
          );
        case 'tp':
          _tpDist = _spec.roundPrice(
            math.max(minDist, (price - _entry) * _side.sign),
          );
        case 'order':
          final buy = _side == Side.long;
          final ref = buy ? _s.ask : _s.bid;
          final towardsPrice = _type == OrderType.limit
              ? (buy ? ref - price : price - ref)
              : (buy ? price - ref : ref - price);
          _orderOffset = _spec.roundPrice(
            math.max(_spec.tickSize, towardsPrice),
          );
      }
    });
  }

  // ---- Helpers -----------------------------------------------------------

  String _price(double p) => p.toStringAsFixed(_spec.priceDecimals);

  String _orderName(Side side, OrderType type) =>
      '${side == Side.long ? 'Buy' : 'Sell'} ${type == OrderType.limit ? 'limit' : 'stop'}';

  String _closeMessage(ClosedTrade t) {
    final what = switch (t.exitReason) {
      ExitReason.stopLoss => 'Stop-loss hit',
      ExitReason.takeProfit => 'Take-profit hit',
      ExitReason.manual => 'Position closed',
      ExitReason.endOfSession => 'Closed at the end of the day',
      ExitReason.stopOut => 'Margin stop-out',
    };
    return '$what: ${money(t.netPnl, signed: true)}';
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
      );
  }

  Future<bool> _confirmLeave() async {
    if (_ending) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End today\'s session?'),
        content: Text(
          widget.ranked
              ? 'Any open trade will be closed at the current price and your ranked session for today will end.'
              : 'Any open trade will be closed at the current price.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep trading'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End session'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  // ---- UI ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave()) _end();
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_spec.name),
              Text(
                widget.ranked
                    ? 'Ranked session'
                    : 'Practice session (unranked)',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _cycleSpeed,
              child: Text(
                '$_speed×',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton.filled(
              tooltip: _playing ? 'Pause' : 'Play',
              onPressed: _togglePlay,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.onGold,
              ),
              icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _priceBar(theme),
              _newsBar(theme),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 4, 0, 2),
                  child: CandleChart(
                    candles: _day.candles.sublist(0, _s.currentIndex + 1),
                    visibleBars: 80,
                    futureSlots: 12,
                    priceDecimals: _spec.priceDecimals,
                    lines: _lines(),
                    markers: _markers(),
                    onLineDragged: _ending ? null : _onDrag,
                  ),
                ),
              ),
              _accountStrip(theme),
              SizedBox(
                height: 292,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.outline)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    child: _s.position != null
                        ? _positionPanel(theme)
                        : _s.pendingOrder != null
                        ? _pendingPanel(theme)
                        : _ticket(theme),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceBar(ThemeData theme) {
    final wide = _s.spread > _spec.spread * 1.01;
    Widget box(String label, double price, Color color) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
            Text(
              _price(price),
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(
        children: [
          box('SELL · BID', _s.bid, AppColors.down),
          SizedBox(
            width: 92,
            child: Column(
              children: [
                Text(
                  _preMarket ? 'Pre-market' : _day.timeAt(_s.currentIndex),
                  maxLines: 1,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: _preMarket ? 13 : 16,
                  ),
                ),
                Text(
                  'Spread ${_spec.formatDistance(_s.spread)}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: wide ? AppColors.orange : AppColors.textMuted,
                    fontWeight: wide ? FontWeight.w700 : null,
                  ),
                ),
              ],
            ),
          ),
          box('BUY · ASK', _s.ask, AppColors.up),
        ],
      ),
    );
  }

  Widget _newsBar(ThemeData theme) {
    final briefing = _day.briefing;
    final dots = switch (briefing.impact) {
      NewsImpact.low => 1,
      NewsImpact.medium => 2,
      NewsImpact.high => 3,
    };
    final barsToEvent = _day.event.index - _s.currentIndex;
    final eventLine = _eventRevealed || barsToEvent <= 0
        ? '${_day.event.time} · ${_day.event.headline}'
        : '${_day.event.time} · ${_capitalise(_day.event.name)} '
              '(in ${_duration(barsToEvent * TradingDay.barMinutes)})';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: _eventRevealed ? AppColors.orange : AppColors.gold,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('MORNING NEWS', style: theme.textTheme.labelSmall),
              const SizedBox(width: 6),
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(
                    Icons.circle,
                    size: 7,
                    color: i < dots ? AppColors.gold : AppColors.surfaceHighest,
                  ),
                ),
              const Spacer(),
              Text('Simulated', style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            briefing.headline,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            (_eventRevealed ? 'BREAKING ' : '') + eventLine,
            style: theme.textTheme.bodySmall?.copyWith(
              color: _eventRevealed ? AppColors.orange : AppColors.textMuted,
              fontWeight: _eventRevealed ? FontWeight.w700 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountStrip(ThemeData theme) {
    final today = _s.equity - widget.startingBalance;
    Widget item(String label, String value, [Color? color]) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.4),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color ?? AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
    final level = _s.marginLevelPct;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      child: Row(
        children: [
          item('BALANCE', money(_s.balance)),
          item('EQUITY', money(_s.equity)),
          item(
            'TODAY',
            money(today, signed: true),
            today >= 0 ? AppColors.up : AppColors.down,
          ),
          item(
            'MARGIN LVL',
            level == null ? '—' : '${level.toStringAsFixed(0)}%',
            level != null && level < 150 ? AppColors.down : null,
          ),
        ],
      ),
    );
  }

  Widget _ticket(ThemeData theme) {
    final qty = _qty;
    final risk = _riskAmount(qty);
    final riskPct = _s.equity == 0 ? 0 : risk / _s.equity * 100;
    final target = _target;
    final reward = target == null
        ? null
        : _spec.toAccount(_tpDist * qty * _spec.contractSize, target);
    final margin = _spec.notionalInAccount(_entry, qty) / _spec.maxLeverage;
    final problem = _ruleProblem;
    final buy = _side == Side.long;
    final color = buy ? AppColors.up : AppColors.down;
    final label = _type == OrderType.market
        ? '${buy ? 'BUY' : 'SELL'} ${quantity(qty)} @ ${_price(_entry)}'
        : 'Place ${_orderName(_side, _type).toLowerCase()} @ ${_price(_entry)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SegmentedButton<Side>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: Side.long, label: Text('Buy')),
                  ButtonSegment(value: Side.short, label: Text('Sell')),
                ],
                selected: {_side},
                onSelectionChanged: (s) => setState(() {
                  _side = s.first;
                  _message = null;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SegmentedButton<OrderType>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: const [
                  ButtonSegment(value: OrderType.market, label: Text('Mkt')),
                  ButtonSegment(value: OrderType.limit, label: Text('Limit')),
                  ButtonSegment(value: OrderType.stop, label: Text('Stop')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() {
                  _type = s.first;
                  _message = null;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _Stepper(
                label: 'Stop-loss',
                value: _spec.formatDistance(_slDist),
                color: AppColors.down,
                onMinus: () => setState(
                  () => _slDist = _spec.roundPrice(
                    math.max(_distStep, _slDist - _distStep),
                  ),
                ),
                onPlus: () => setState(
                  () => _slDist = _spec.roundPrice(_slDist + _distStep),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Stepper(
                label: _useTp ? 'Take-profit' : 'Take-profit (off)',
                value: _useTp ? _spec.formatDistance(_tpDist) : '—',
                color: AppColors.up,
                onLabelTap: () => setState(() => _useTp = !_useTp),
                onMinus: _useTp
                    ? () => setState(
                        () => _tpDist = _spec.roundPrice(
                          math.max(_distStep, _tpDist - _distStep),
                        ),
                      )
                    : null,
                onPlus: _useTp
                    ? () => setState(
                        () => _tpDist = _spec.roundPrice(_tpDist + _distStep),
                      )
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _Stepper(
                label: 'Size (${_spec.quantityUnit})',
                value: quantity(qty),
                color: AppColors.gold,
                onMinus: () => setState(() {
                  _autoSize = false;
                  _manualQty = _spec.roundQuantityDown(
                    math.max(0, qty - _spec.lotStep),
                  );
                }),
                onPlus: () => setState(() {
                  _autoSize = false;
                  _manualQty = _spec.roundQuantityDown(
                    qty + _spec.lotStep * 1.0000001,
                  );
                }),
              ),
            ),
            const SizedBox(width: 8),
            for (final pct in const [0.5, 1.0, 2.0])
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: ChoiceChip(
                  visualDensity: VisualDensity.compact,
                  showCheckmark: false,
                  label: Text(
                    '${pct == pct.roundToDouble() ? pct.toStringAsFixed(0) : pct}%',
                  ),
                  selected: _autoSize && _riskPct == pct,
                  onSelected: (_) => setState(() {
                    _autoSize = true;
                    _riskPct = pct;
                  }),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 2,
          children: [
            _Info(
              'Risk',
              '${money(risk)} (${riskPct.toStringAsFixed(1)}%)',
              AppColors.down,
            ),
            if (reward != null) _Info('Reward', money(reward), AppColors.up),
            if (reward != null && risk > 0)
              _Info('R:R', (reward / risk).toStringAsFixed(1)),
            _Info('Margin', money(margin)),
            _Info(
              'Per ${_spec.distanceUnit == DistanceUnit.pips
                  ? 'pip'
                  : _spec.distanceUnit == DistanceUnit.points
                  ? 'point'
                  : '\$1 move'}',
              money(
                _spec.toAccount(
                  (_spec.pipSize ?? 1) * qty * _spec.contractSize,
                  _entry,
                ),
              ),
            ),
          ],
        ),
        if (_message != null || problem != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _message ?? problem!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.orange,
              ),
            ),
          ),
        const SizedBox(height: 10),
        _SideButton(
          label: label,
          color: color,
          onPressed: problem == null ? _place : null,
        ),
      ],
    );
  }

  Widget _positionPanel(ThemeData theme) {
    final p = _s.position!;
    final pnl = _s.unrealizedPnl;
    final risk = p.riskAmount;
    final r = risk == null || risk == 0 ? null : pnl / risk;
    final buy = p.side == Side.long;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Pill(
              label: buy ? 'LONG' : 'SHORT',
              color: buy ? AppColors.up : AppColors.down,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${quantity(p.quantity)} ${_spec.quantityUnit} @ ${_price(p.entryPrice)}',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Floating P&L', style: theme.textTheme.bodySmall),
                  Text(
                    money(pnl, signed: true),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: pnl >= 0 ? AppColors.up : AppColors.down,
                    ),
                  ),
                ],
              ),
            ),
            if (r != null)
              Text(rMultiple(r), style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: [
            _Info(
              'Stop',
              p.stopLoss == null ? '—' : _price(p.stopLoss!),
              AppColors.down,
            ),
            _Info(
              'Target',
              p.takeProfit == null ? '—' : _price(p.takeProfit!),
              AppColors.up,
            ),
            _Info('Margin', money(p.margin)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Drag the red and green lines on the chart to adjust.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: (p.stopLoss ?? 0) == p.entryPrice
                    ? null
                    : _breakeven,
                child: const Text('Break-even'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SideButton(
                label: 'Close ${money(pnl, signed: true)}',
                color: buy ? AppColors.down : AppColors.up,
                onPressed: _closePosition,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pendingPanel(ThemeData theme) {
    final o = _s.pendingOrder!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${_orderName(o.side, o.type)} waiting',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          '${quantity(o.quantity)} ${_spec.quantityUnit} at ${_price(o.price!)} · '
          'stop ${_price(o.stopLoss!)}'
          '${o.takeProfit == null ? '' : ' · target ${_price(o.takeProfit!)}'}',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 6),
        Text(
          o.type == OrderType.limit
              ? 'Fills if price comes back to your level.'
              : 'Fills if price breaks through your level.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => setState(() {
            _s.cancelPending();
            _toast('Order cancelled');
          }),
          child: const Text('Cancel order'),
        ),
      ],
    );
  }

  List<PriceLine> _lines() {
    final position = _s.position;
    final pending = _s.pendingOrder;
    if (_ending) return const [];
    if (position != null) {
      return [
        PriceLine(
          id: 'entry',
          price: position.entryPrice,
          color: AppColors.textMuted,
          label: 'Entry',
          dashed: true,
        ),
        if (position.stopLoss != null)
          PriceLine(
            id: 'sl',
            price: position.stopLoss!,
            color: AppColors.down,
            label: 'Stop-loss',
            draggable: true,
          ),
        if (position.takeProfit != null)
          PriceLine(
            id: 'tp',
            price: position.takeProfit!,
            color: AppColors.up,
            label: 'Take-profit',
            draggable: true,
          ),
      ];
    }
    if (pending != null) {
      return [
        PriceLine(
          id: 'order',
          price: pending.price!,
          color: AppColors.cyan,
          label: _orderName(pending.side, pending.type),
        ),
        if (pending.stopLoss != null)
          PriceLine(
            id: 'psl',
            price: pending.stopLoss!,
            color: AppColors.down,
            label: 'Stop-loss',
            dashed: true,
          ),
        if (pending.takeProfit != null)
          PriceLine(
            id: 'ptp',
            price: pending.takeProfit!,
            color: AppColors.up,
            label: 'Take-profit',
            dashed: true,
          ),
      ];
    }
    final target = _target;
    return [
      if (_type == OrderType.market)
        PriceLine(
          id: 'entry',
          price: _entry,
          color: AppColors.textMuted,
          label: _side == Side.long ? 'Buy at ask' : 'Sell at bid',
          dashed: true,
        )
      else
        PriceLine(
          id: 'order',
          price: _entry,
          color: AppColors.cyan,
          label: _orderName(_side, _type),
          draggable: true,
        ),
      PriceLine(
        id: 'sl',
        price: _stop,
        color: AppColors.down,
        label: 'Stop-loss',
        draggable: true,
      ),
      if (target != null)
        PriceLine(
          id: 'tp',
          price: target,
          color: AppColors.up,
          label: 'Take-profit',
          draggable: true,
        ),
    ];
  }

  List<ChartMarker> _markers() => [
    for (final t in _s.trades) ...[
      ChartMarker(
        index: t.entryIndex,
        price: t.entryPrice,
        pointsUp: t.side == Side.long,
        color: AppColors.cyan,
      ),
      ChartMarker(
        index: t.exitIndex,
        price: t.exitPrice,
        pointsUp: t.side != Side.long,
        color: t.isWin ? AppColors.up : AppColors.down,
      ),
    ],
    if (_s.position case final p?)
      ChartMarker(
        index: p.entryIndex,
        price: p.entryPrice,
        pointsUp: p.side == Side.long,
        color: AppColors.cyan,
      ),
  ];

  static String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String _duration(int minutes) =>
      minutes >= 60 ? '${minutes ~/ 60}h ${minutes % 60}m' : '${minutes}m';
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.color,
    this.onMinus,
    this.onPlus,
    this.onLabelTap,
  });

  final String label;
  final String value;
  final Color color;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final VoidCallback? onLabelTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget button(IconData icon, VoidCallback? onTap) => InkResponse(
      onTap: onTap,
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? AppColors.outline : AppColors.text,
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onLabelTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          button(Icons.remove, onMinus),
          button(Icons.add, onPlus),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value, [this.color]);

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label ', style: theme.textTheme.bodySmall),
          TextSpan(
            text: value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color ?? AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({required this.label, required this.color, this.onPressed});

  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 50),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
