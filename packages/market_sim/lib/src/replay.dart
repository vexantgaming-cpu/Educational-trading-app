import 'candle.dart';
import 'instrument.dart';
import 'risk.dart';

enum OrderType { market, limit, stop }

enum ExitReason { stopLoss, takeProfit, manual, endOfSession, stopOut }

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
    required this.entrySpread,
    required this.margin,
    required this.riskAmount,
    required this.initialStop,
    this.stopLoss,
    this.takeProfit,
  });

  final Side side;
  final double quantity;

  /// Actual fill price (the ask for buys, the bid for sells).
  final double entryPrice;
  final int entryIndex;
  final double entryFees;
  final double entrySpread;

  /// Margin locked for this position, in account currency.
  final double margin;

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
    this.spreadCost = 0,
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

  /// Result from the fill prices (which already include the spread).
  final double grossPnl;

  /// Commission paid on entry and exit.
  final double fees;

  /// How much worse the fills were than the chart (bid) prices because of
  /// the spread. Already inside [grossPnl]; shown for learning.
  final double spreadCost;
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

/// Deterministic bar-by-bar trading simulator with broker-style execution.
///
/// Candle prices are bid prices, as on most trading platforms. Each bar has a
/// spread (default: the instrument's; it can widen, e.g. around news), so
/// ask = bid + spread and every quote stays on the tick grid:
/// * Buys fill at the ask, sells at the bid. Market orders fill at the
///   current bar's close.
/// * Buy orders and the exits of short positions trigger on the ask; sell
///   orders and the exits of long positions trigger on the bid. A widening
///   spread can therefore hit a stop, just like with a real broker.
/// * Orders that gap through their price fill at the bar's open.
/// * If one bar reaches both stop-loss and take-profit, the stop-loss is
///   assumed to come first (conservative). On the bar an entry fills, only
///   the stop-loss is checked.
/// * Commission is charged on entry and exit.
/// * If equity falls below [stopOutLevel] × margin, the position is closed
///   (the EU retail 50% margin close-out rule). The balance never goes below
///   zero (negative balance protection).
class ReplaySession {
  ReplaySession({
    required this.candles,
    required this.spec,
    this.startingBalance = 10000,
    int startIndex = 0,
    List<double>? spreads,
    this.stopOutLevel = 0.5,
  }) : assert(candles.isNotEmpty),
       assert(spreads == null || spreads.length == candles.length),
       _spreads = spreads,
       _index = startIndex.clamp(0, candles.length - 1),
       balance = startingBalance;

  final List<Candle> candles;
  final InstrumentSpec spec;
  final double startingBalance;
  final double stopOutLevel;
  final List<double>? _spreads;

  /// Realised account balance (closed trades and paid commission).
  double balance;
  final List<ClosedTrade> trades = [];

  int _index;
  OpenPosition? _position;
  OrderRequest? _pending;

  int get currentIndex => _index;
  Candle get currentCandle => candles[_index];

  /// Bid price at the close of the current bar.
  double get currentPrice => currentCandle.close;
  double spreadAt(int index) => _spreads?[index] ?? spec.spread;
  double get spread => spreadAt(_index);
  double get bid => currentPrice;
  double get ask => currentPrice + spread;
  bool get hasNextBar => _index < candles.length - 1;
  OpenPosition? get position => _position;
  OrderRequest? get pendingOrder => _pending;
  bool get isFlat => _position == null && _pending == null;

  /// Price at which the open position could be closed right now.
  double get exitPrice => _position?.side == Side.short ? ask : bid;

  double get unrealizedPnl {
    final p = _position;
    if (p == null) return 0;
    return _pnl(p, exitPrice);
  }

  double get equity => balance + unrealizedPnl;
  double get usedMargin => _position?.margin ?? 0;
  double get freeMargin => equity - usedMargin;

  /// Equity as a percentage of used margin (null when nothing is open).
  double? get marginLevelPct =>
      _position == null ? null : equity / _position!.margin * 100;

  void submit(OrderRequest order) {
    if (!isFlat) {
      throw const OrderRejected(
        'You already have a trade or order open. Close it first.',
      );
    }
    final quantity = spec.roundQuantityDown(order.quantity);
    if (quantity <= 0) {
      throw const OrderRejected('The position size is too small.');
    }
    final buy = order.side == Side.long;
    final price = order.type == OrderType.market
        ? (buy ? ask : bid)
        : order.price;
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
    final margin = spec.notionalInAccount(price, quantity) / spec.maxLeverage;
    if (margin > freeMargin) {
      throw OrderRejected(
        'Not enough margin: this position needs '
        '\$${margin.toStringAsFixed(2)} at '
        '${spec.maxLeverage.toStringAsFixed(0)}:1 leverage, but only '
        '\$${freeMargin.toStringAsFixed(2)} is free.',
      );
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
      _open(sized, price);
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
      side: p.side,
      entry: exitPrice,
      stop: stopLoss,
      target: takeProfit,
    );
    if (error != null) {
      throw OrderRejected(error.replaceAll('your entry', 'the current price'));
    }
    p
      ..stopLoss = stopLoss
      ..takeProfit = takeProfit;
  }

  /// Closes the open position at the current bid (long) or ask (short).
  ClosedTrade closePosition() {
    if (_position == null) throw const OrderRejected('There is no open trade.');
    return _close(exitPrice, ExitReason.manual);
  }

  /// Reveals the next bar and processes fills, stops, targets and margin.
  StepEvent step() {
    if (!hasNextBar) throw StateError('No more bars to replay.');
    _index++;
    final bar = currentCandle;
    final spread = this.spread;

    final pending = _pending;
    if (pending != null) {
      final fill = _triggerPrice(pending, bar, spread);
      if (fill == null) return StepEvent(index: _index, candle: bar);
      _pending = null;
      final p = _open(pending, fill);
      ClosedTrade? closed;
      final stop = p.stopLoss;
      if (stop != null) {
        final long = p.side == Side.long;
        final gappedThrough = (fill - stop) * p.side.sign <= 0;
        final touched = long ? bar.low <= stop : bar.high + spread >= stop;
        if (gappedThrough) {
          closed = _close(
            long ? fill - spread : fill + spread,
            ExitReason.stopLoss,
          );
        } else if (touched) {
          closed = _close(stop, ExitReason.stopLoss);
        }
      }
      closed ??= _checkStopOut(bar, spread);
      return StepEvent(
        index: _index,
        candle: bar,
        entryFilled: true,
        closedTrade: closed,
      );
    }

    if (_position != null) {
      final closed = _checkExits(bar, spread) ?? _checkStopOut(bar, spread);
      return StepEvent(index: _index, candle: bar, closedTrade: closed);
    }
    return StepEvent(index: _index, candle: bar);
  }

  /// Steps until the trade closes (or the data ends / [maxBars] pass).
  List<StepEvent> runUntilFlat({int? maxBars}) {
    final events = <StepEvent>[];
    while (!isFlat &&
        hasNextBar &&
        (maxBars == null || events.length < maxBars)) {
      events.add(step());
    }
    return events;
  }

  /// Ends the session: cancels pending orders and closes any open trade.
  ClosedTrade? finish() {
    _pending = null;
    if (_position == null) return null;
    return _close(exitPrice, ExitReason.endOfSession);
  }

  ClosedTrade? _checkExits(Candle bar, double spread) {
    final p = _position!;
    final long = p.side == Side.long;
    final stop = p.stopLoss, target = p.takeProfit;
    // Longs exit by selling at the bid; shorts by buying at the ask.
    final shift = long ? 0.0 : spread;
    final open = bar.open + shift;
    final high = bar.high + shift;
    final low = bar.low + shift;

    if (stop != null && (long ? open <= stop : open >= stop)) {
      return _close(open, ExitReason.stopLoss);
    }
    if (target != null && (long ? open >= target : open <= target)) {
      return _close(open, ExitReason.takeProfit);
    }
    final hitStop = stop != null && (long ? low <= stop : high >= stop);
    final hitTarget = target != null && (long ? high >= target : low <= target);
    if (hitStop) return _close(stop, ExitReason.stopLoss);
    if (hitTarget) return _close(target, ExitReason.takeProfit);
    return null;
  }

  /// Closes the position if equity falls below the stop-out level during
  /// the bar, at the price where that happens (or the open after a gap).
  ClosedTrade? _checkStopOut(Candle bar, double spread) {
    final p = _position;
    if (p == null) return null;
    final long = p.side == Side.long;
    final worst = long ? bar.low : bar.high + spread;
    final threshold = stopOutLevel * p.margin;
    if (balance + _pnl(p, worst) >= threshold) return null;

    // Solve balance + pnl(price) = threshold for the price.
    final size = p.quantity * spec.contractSize * p.side.sign;
    final target = threshold - balance;
    final double stopOutPrice = spec.baseIsAccountCurrency
        ? -p.entryPrice * size / (target - size)
        : p.entryPrice + target / size;
    final open = long ? bar.open : bar.open + spread;
    final gapped = long ? open <= stopOutPrice : open >= stopOutPrice;
    return _close(gapped ? open : stopOutPrice, ExitReason.stopOut);
  }

  double? _triggerPrice(OrderRequest order, Candle bar, double spread) {
    final p = order.price!;
    final buy = order.side == Side.long;
    // Buy orders trigger on the ask, sell orders on the bid.
    final shift = buy ? spread : 0.0;
    final open = bar.open + shift;
    final high = bar.high + shift;
    final low = bar.low + shift;
    // Buy limit / sell stop trigger on the way down; the others on the way up.
    final fillsBelow = buy == (order.type == OrderType.limit);
    if (fillsBelow) {
      if (open <= p) return open;
      if (low <= p) return p;
    } else {
      if (open >= p) return open;
      if (high >= p) return p;
    }
    return null;
  }

  void _checkPendingPrice(Side side, OrderType type, double price) {
    if (type == OrderType.market) return;
    final buy = side == Side.long;
    final reference = buy ? ask : bid;
    final below = price < reference;
    final above = price > reference;
    switch ((type, buy)) {
      case (OrderType.limit, true) when !below:
        throw const OrderRejected(
          'A buy limit waits for a lower price. Set it below the current price.',
        );
      case (OrderType.limit, false) when !above:
        throw const OrderRejected(
          'A sell limit waits for a higher price. Set it above the current price.',
        );
      case (OrderType.stop, true) when !above:
        throw const OrderRejected(
          'A buy stop triggers on a breakout. Set it above the current price.',
        );
      case (OrderType.stop, false) when !below:
        throw const OrderRejected(
          'A sell stop triggers on a breakdown. Set it below the current price.',
        );
      default:
        return;
    }
  }

  double _pnl(OpenPosition p, double exit) => spec.toAccount(
    (exit - p.entryPrice) * p.side.sign * p.quantity * spec.contractSize,
    exit,
  );

  double _commission(double price, double quantity) =>
      spec.notionalInAccount(price, quantity) * spec.commissionRate;

  OpenPosition _open(OrderRequest order, double price) {
    final fees = _commission(price, order.quantity);
    balance -= fees;
    final stop = order.stopLoss;
    return _position = OpenPosition(
      side: order.side,
      quantity: order.quantity,
      entryPrice: price,
      entryIndex: _index,
      entryFees: fees,
      entrySpread: spread,
      margin: spec.notionalInAccount(price, order.quantity) / spec.maxLeverage,
      riskAmount: stop == null
          ? null
          : spec.toAccount(
              (price - stop).abs() * order.quantity * spec.contractSize,
              stop,
            ),
      initialStop: stop,
      stopLoss: stop,
      takeProfit: order.takeProfit,
    );
  }

  ClosedTrade _close(double price, ExitReason reason) {
    final p = _position!;
    final gross = _pnl(p, price);
    final exitFees = _commission(price, p.quantity);
    balance += gross - exitFees;
    if (balance < 0) balance = 0; // negative balance protection
    // Candles are bids, so a long pays the spread when it buys at the ask
    // and a short pays it when it buys back at the ask.
    final spreadCost = spec.toAccount(
      (p.side == Side.long ? p.entrySpread : spread) *
          p.quantity *
          spec.contractSize,
      price,
    );
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
      spreadCost: spreadCost,
      riskAmount: p.riskAmount,
      initialStop: p.initialStop,
      takeProfit: p.takeProfit,
    );
    trades.add(trade);
    _position = null;
    return trade;
  }
}
