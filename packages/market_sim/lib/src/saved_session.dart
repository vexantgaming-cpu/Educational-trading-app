import 'markets.dart';
import 'replay.dart';
import 'risk.dart';
import 'trading_day.dart';

/// One thing the player did during a trading session, and the bar it
/// happened on. A session is saved as the list of these: because the market
/// day is generated from its number and the engine is deterministic, replaying
/// the same actions on the same bars rebuilds the session exactly.
sealed class SessionAction {
  const SessionAction(this.index);

  factory SessionAction.fromJson(Map<String, dynamic> json) {
    final index = json['i'] as int;
    double? number(String key) => (json[key] as num?)?.toDouble();
    return switch (json['a'] as String) {
      'submit' => SubmitOrder(
        index,
        OrderRequest(
          side: Side.values.byName(json['side'] as String),
          quantity: number('qty')!,
          type: OrderType.values.byName(json['type'] as String),
          price: number('price'),
          stopLoss: number('sl'),
          takeProfit: number('tp'),
        ),
      ),
      'close' => ClosePosition(index),
      'levels' => UpdateLevels(
        index,
        stopLoss: number('sl'),
        takeProfit: number('tp'),
      ),
      'cancel' => CancelPending(index),
      final other => throw FormatException('Unknown session action: $other'),
    };
  }

  /// The bar the session was on when this happened.
  final int index;

  void apply(ReplaySession session);
  Map<String, dynamic> toJson();
}

/// A market, limit or stop order was placed.
class SubmitOrder extends SessionAction {
  const SubmitOrder(super.index, this.order);

  final OrderRequest order;

  @override
  void apply(ReplaySession session) => session.submit(order);

  @override
  Map<String, dynamic> toJson() => {
    'a': 'submit',
    'i': index,
    'side': order.side.name,
    'qty': order.quantity,
    'type': order.type.name,
    if (order.price != null) 'price': order.price,
    if (order.stopLoss != null) 'sl': order.stopLoss,
    if (order.takeProfit != null) 'tp': order.takeProfit,
  };
}

/// The open trade was closed by hand.
class ClosePosition extends SessionAction {
  const ClosePosition(super.index);

  @override
  void apply(ReplaySession session) => session.closePosition();

  @override
  Map<String, dynamic> toJson() => {'a': 'close', 'i': index};
}

/// The stop-loss and take-profit of the open trade were moved.
class UpdateLevels extends SessionAction {
  const UpdateLevels(super.index, {this.stopLoss, this.takeProfit});

  final double? stopLoss;
  final double? takeProfit;

  @override
  void apply(ReplaySession session) =>
      session.updateLevels(stopLoss: stopLoss, takeProfit: takeProfit);

  @override
  Map<String, dynamic> toJson() => {
    'a': 'levels',
    'i': index,
    if (stopLoss != null) 'sl': stopLoss,
    if (takeProfit != null) 'tp': takeProfit,
  };
}

/// The waiting limit or stop order was cancelled.
class CancelPending extends SessionAction {
  const CancelPending(super.index);

  @override
  void apply(ReplaySession session) => session.cancelPending();

  @override
  Map<String, dynamic> toJson() => {'a': 'cancel', 'i': index};
}

/// A trading session in progress, small enough to save after every candle:
/// which day on which market, how far it has played, and what the player did.
class SavedSession {
  const SavedSession({
    required this.symbol,
    required this.dayNumber,
    required this.ranked,
    required this.startingBalance,
    required this.startedOn,
    required this.index,
    required this.actions,
  });

  factory SavedSession.fromJson(Map<String, dynamic> json) => SavedSession(
    symbol: json['symbol'] as String,
    dayNumber: json['day'] as int,
    ranked: json['ranked'] as bool,
    startingBalance: (json['balance'] as num).toDouble(),
    startedOn: json['date'] as String,
    index: json['index'] as int,
    actions: [
      for (final a in json['actions'] as List)
        SessionAction.fromJson(a as Map<String, dynamic>),
    ],
  );

  final String symbol;
  final int dayNumber;
  final bool ranked;
  final double startingBalance;

  /// `yyyy-mm-dd` of the day the session was started.
  final String startedOn;

  /// The last bar that has been revealed.
  final int index;
  final List<SessionAction> actions;

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'day': dayNumber,
    'ranked': ranked,
    'balance': startingBalance,
    'date': startedOn,
    'index': index,
    'actions': [for (final a in actions) a.toJson()],
  };

  /// The market of this session; throws if it no longer exists.
  MarketProfile get market =>
      GameMarkets.bySymbol(symbol) ??
      (throw FormatException('Unknown market: $symbol'));

  /// The session's market day.
  TradingDay get day => generateTradingDay(market, dayNumber);

  /// A fresh engine for [day], before the market opens.
  static ReplaySession newEngine(TradingDay day, double startingBalance) =>
      ReplaySession(
        candles: day.candles,
        spec: day.market.spec,
        startingBalance: startingBalance,
        startIndex: day.sessionStart - 1,
        spreads: day.spreads,
      );

  /// Rebuilds the session as it was: same balance, open trade, waiting
  /// order and closed trades. Throws a [FormatException] if the saved data
  /// doesn't describe a valid session.
  ReplaySession restore() {
    final day = this.day;
    final session = newEngine(day, startingBalance);
    final last = index.clamp(session.currentIndex, day.candles.length - 1);
    var next = 0;
    try {
      while (true) {
        while (next < actions.length &&
            actions[next].index == session.currentIndex) {
          actions[next].apply(session);
          next++;
        }
        if (session.currentIndex >= last) break;
        session.step();
      }
    } on OrderRejected catch (e) {
      throw FormatException('Saved session cannot be replayed: ${e.message}');
    }
    if (next != actions.length) {
      throw const FormatException('Saved session has actions out of order.');
    }
    return session;
  }

  /// The result if the session ended now: an open trade is closed at the
  /// current price and a waiting order is dropped.
  ({double pnl, int trades}) settle() {
    final session = restore()..finish();
    return (
      pnl: session.balance - startingBalance,
      trades: session.trades.length,
    );
  }
}
