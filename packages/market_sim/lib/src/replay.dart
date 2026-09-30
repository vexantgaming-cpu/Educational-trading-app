import 'dart:math' as math;

import 'candle.dart';
import 'instrument.dart';
import 'risk.dart';

enum OrderType { market, limit, stop }

enum ExitReason { stopLoss, takeProfit, manual, endOfSession }

class OrderRequest {
  const OrderRequest({
    required this.side,
    required this.quantity,
    this.type = OrderType.market,
    this.price,
    this.stopLoss,
    this.takeProfit,
  });

  final Side side;
  final double quantity;
  final OrderType type;

  /// Trigger price for limit and stop orders.
  final double? price;
  final double? stopLoss;
  final double? takeProfit;
}

class OpenPosition {
  OpenPosition({
    required this.side,
    required this.quantity,
    required this.entryPrice,
    required this.entryIndex,
    required this.entryFees,
    required this.riskAmount,
    required this.initialStop,
    this.stopLoss,
    this.takeProfit,
  });

  final Side side;
  final double quantity;
  final double entryPrice;
  final int entryIndex;
  final double entryFees;

  /// Money at risk between entry and the initial stop (null without a stop).
  final double? riskAmount;
  final double? initialStop;
  double? stopLoss;
  double? takeProfit;
}

class ClosedTrade {
  const ClosedTrade({
    required this.side,
    required this.quantity,
    required this.entryIndex,
    required this.entryPrice,
    required this.exitIndex,
    required this.exitPrice,
    required this.exitReason,
    required this.grossPnl,
    required this.fees,
    required this.riskAmount,
    this.initialStop,
    this.takeProfit,
  });

  final Side side;
  final double quantity;
  final int entryIndex;
  final double entryPrice;
  final int exitIndex;
  final double exitPrice;
  final ExitReason exitReason;
  final double grossPnl;

  /// Spread + commission paid on entry and exit.
  final double fees;
  final double? riskAmount;
  final double? initialStop;
  final double? takeProfit;

  double get netPnl => grossPnl - fees;
  bool get isWin => netPnl > 0;

  /// Result in multiples of the initial risk ("R"). +2R = won twice what was
  /// risked. Null when the trade had no stop-loss.
  double? get rMultiple {
    final risk = riskAmount;
    if (risk == null || risk == 0) return null;
    return netPnl / risk;
  }
}

/// Raised when an order can't be accepted. [message] is written for the
/// learner, so the UI can show it as-is.
class OrderRejected implements Exception {
  const OrderRejected(this.message);

  final String message;

  @override
  String toString() => 'OrderRejected: $message';
}

class StepEvent {
  const StepEvent({
    required this.index,
    required this.candle,
    this.entryFilled = false,
    this.closedTrade,
  });

  final int index;
  final Candle candle;
  final bool entryFilled;
  final ClosedTrade? closedTrade;
}

/// Deterministic bar-by-bar trading simulator.
///
/// Rules (identical everywhere, so results can be re-checked on a server):
/// * Market orders fill at the current bar's close.
/// * Limit/stop entries trigger when a later bar's range reaches the price,
///   or at that bar's open if it gaps through.
/// * Spread and commission are charged as explicit costs on entry and exit.
/// * If one bar reaches both stop-loss and take-profit, the stop-loss is
///   assumed to come first (conservative).
/// * On the bar an entry fills only the stop-loss is checked, because the
///   order of prices inside a bar is unknown.
class ReplaySession {
  ReplaySession({
    required this.candles,
    required this.spec,
    this.startingBalance = 10000,
    int startIndex = 0,
  })  : assert(candles.isNotEmpty),
        _index = math.min(startIndex, candles.length - 1),
        balance = startingBalance;

  final List<Candle> candles;
  final InstrumentSpec spec;
  final double startingBalance;

  /// Realised account balance (closed trades and paid costs).
  double balance;
  final List<ClosedTrade> trades = [];

  int _index;
  OpenPosition? _position;
  OrderRequest? _pending;

  int get currentIndex => _index;
  Candle get currentCandle => candles[_index];
  double get currentPrice => currentCandle.close;
  bool get hasNextBar => _index < candles.length - 1;
  OpenPosition? get position => _position;
  OrderRequest? get pendingOrder => _pending;
  bool get isFlat => _position == null && _pending == null;

  double get unrealizedPnl {
    final p = _position;
    if (p == null) return 0;
    return (currentPrice - p.entryPrice) *
        p.side.sign *
        p.quantity *
        spec.contractSize;
  }

  double get equity => balance + unrealizedPnl;

  void submit(OrderRequest order) {
    if (!isFlat) {
      throw const OrderRejected(
          'You already have a trade or order open. Close it first.');
    }
    final quantity = spec.roundQuantityDown(order.quantity);
    if (quantity <= 0) {
      throw const OrderRejected('The position size is too small.');
    }
    final price = order.type == OrderType.market ? currentPrice : order.price;
    if (price == null) {
      throw const OrderRejected('Limit and stop orders need a price.');
    }
    _checkPendingPrice(order.side, order.type, price);
    final levelError = Risk.levelError(
      side: order.side,
      entry: price,
      stop: order.stopLoss,
      target: order.takeProfit,
    );
    if (levelError != null) throw OrderRejected(levelError);
    if (spec.notional(price, quantity) / spec.maxLeverage > equity) {
      throw OrderRejected(
          'Not enough margin: at ${spec.maxLeverage.toStringAsFixed(0)}:1 '
          'leverage this position needs more than your account balance.');
    }

    final sized = OrderRequest(
      side: order.side,
      quantity: quantity,
      type: order.type,
      price: order.price,
      stopLoss: order.stopLoss,
      takeProfit: order.takeProfit,
    );
    if (order.type == OrderType.market) {
      _open(sized, currentPrice);
    } else {
      _pending = sized;
    }
  }

  bool cancelPending() {
    final hadPending = _pending != null;
    _pending = null;
    return hadPending;
  }

  /// Moves the protective levels of the open position.
  void updateLevels({double? stopLoss, double? takeProfit}) {
    final p = _position;
    if (p == null) throw const OrderRejected('There is no open trade.');
    final error = Risk.levelError(
        side: p.side, entry: currentPrice, stop: stopLoss, target: takeProfit);
    if (error != null) {
      throw OrderRejected(error.replaceAll('your entry', 'the current price'));
    }
    p
      ..stopLoss = stopLoss
      ..takeProfit = takeProfit;
  }

  /// Closes the open position at the current price.
  ClosedTrade closePosition() {
    if (_position == null) throw const OrderRejected('There is no open trade.');
    return _close(currentPrice, ExitReason.manual);
  }

  /// Reveals the next bar and processes fills, stops and targets.
  StepEvent step() {
    if (!hasNextBar) throw StateError('No more bars to replay.');
    _index++;
    final bar = currentCandle;

    final pending = _pending;
    if (pending != null) {
      final fill = _triggerPrice(pending, bar);
      if (fill == null) return StepEvent(index: _index, candle: bar);
      _pending = null;
      final p = _open(pending, fill);
      ClosedTrade? closed;
      final stop = p.stopLoss;
      if (stop != null) {
        final gappedThrough = (fill - stop) * p.side.sign <= 0;
        final touched =
            p.side == Side.long ? bar.low <= stop : bar.high >= stop;
        if (gappedThrough) {
          closed = _close(fill, ExitReason.stopLoss);
        } else if (touched) {
          closed = _close(stop, ExitReason.stopLoss);
        }
      }
      return StepEvent(
          index: _index, candle: bar, entryFilled: true, closedTrade: closed);
    }

    if (_position != null) {
      return StepEvent(index: _index, candle: bar, closedTrade: _checkExits(bar));
    }
    return StepEvent(index: _index, candle: bar);
  }

  /// Steps until the trade closes (or the data ends / [maxBars] pass).
  List<StepEvent> runUntilFlat({int? maxBars}) {
    final events = <StepEvent>[];
    while (!isFlat && hasNextBar && (maxBars == null || events.length < maxBars)) {
      events.add(step());
    }
    return events;
  }

  /// Ends the session: cancels pending orders and closes any open trade.
  ClosedTrade? finish() {
    _pending = null;
    if (_position == null) return null;
    return _close(currentPrice, ExitReason.endOfSession);
  }

  ClosedTrade? _checkExits(Candle bar) {
    final p = _position!;
    final long = p.side == Side.long;
    final stop = p.stopLoss, target = p.takeProfit;

    // Gaps: the bar opens beyond a level, so it fills at the open.
    if (stop != null && (long ? bar.open <= stop : bar.open >= stop)) {
      return _close(bar.open, ExitReason.stopLoss);
    }
    if (target != null && (long ? bar.open >= target : bar.open <= target)) {
      return _close(bar.open, ExitReason.takeProfit);
    }
    final hitStop = stop != null && (long ? bar.low <= stop : bar.high >= stop);
    final hitTarget =
        target != null && (long ? bar.high >= target : bar.low <= target);
    if (hitStop) return _close(stop, ExitReason.stopLoss);
    if (hitTarget) return _close(target, ExitReason.takeProfit);
    return null;
  }

  double? _triggerPrice(OrderRequest order, Candle bar) {
    final p = order.price!;
    final buy = order.side == Side.long;
    final limit = order.type == OrderType.limit;
    // Buy limit / sell stop trigger on the way down; the others on the way up.
    final fillsBelow = buy == limit;
    if (fillsBelow) {
      if (bar.open <= p) return bar.open;
      if (bar.low <= p) return p;
    } else {
      if (bar.open >= p) return bar.open;
      if (bar.high >= p) return p;
    }
    return null;
  }

  void _checkPendingPrice(Side side, OrderType type, double price) {
    if (type == OrderType.market) return;
    final buy = side == Side.long;
    final below = price < currentPrice;
    final above = price > currentPrice;
    switch ((type, buy)) {
      case (OrderType.limit, true) when !below:
        throw const OrderRejected(
            'A buy limit waits for a lower price. Set it below the current price.');
      case (OrderType.limit, false) when !above:
        throw const OrderRejected(
            'A sell limit waits for a higher price. Set it above the current price.');
      case (OrderType.stop, true) when !above:
        throw const OrderRejected(
            'A buy stop triggers on a breakout. Set it above the current price.');
      case (OrderType.stop, false) when !below:
        throw const OrderRejected(
            'A sell stop triggers on a breakdown. Set it below the current price.');
      default:
        return;
    }
  }

  OpenPosition _open(OrderRequest order, double price) {
    final fees = _fees(price, order.quantity);
    balance -= fees;
    final stop = order.stopLoss;
    return _position = OpenPosition(
      side: order.side,
      quantity: order.quantity,
      entryPrice: price,
      entryIndex: _index,
      entryFees: fees,
      riskAmount: stop == null
          ? null
          : (price - stop).abs() * order.quantity * spec.contractSize,
      initialStop: stop,
      stopLoss: stop,
      takeProfit: order.takeProfit,
    );
  }

  ClosedTrade _close(double price, ExitReason reason) {
    final p = _position!;
    final gross =
        (price - p.entryPrice) * p.side.sign * p.quantity * spec.contractSize;
    final exitFees = _fees(price, p.quantity);
    balance += gross - exitFees;
    final trade = ClosedTrade(
      side: p.side,
      quantity: p.quantity,
      entryIndex: p.entryIndex,
      entryPrice: p.entryPrice,
      exitIndex: _index,
      exitPrice: price,
      exitReason: reason,
      grossPnl: gross,
      fees: p.entryFees + exitFees,
      riskAmount: p.riskAmount,
      initialStop: p.initialStop,
      takeProfit: p.takeProfit,
    );
    trades.add(trade);
    _position = null;
    return trade;
  }

  double _fees(double price, double quantity) =>
      spec.notional(price, quantity) * spec.commissionRate +
      spec.spread / 2 * quantity * spec.contractSize;
}
