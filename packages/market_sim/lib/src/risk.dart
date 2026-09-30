import 'instrument.dart';

enum Side { long, short }

extension SideDetails on Side {
  /// +1 for long (profits when price rises), -1 for short.
  int get sign => this == Side.long ? 1 : -1;
  String get label => this == Side.long ? 'Long (buy)' : 'Short (sell)';
}

class PositionSize {
  const PositionSize({
    required this.quantity,
    required this.riskAmount,
    required this.riskPct,
    required this.notional,
    required this.leverage,
    required this.limitedByLeverage,
  });

  static const zero = PositionSize(
    quantity: 0,
    riskAmount: 0,
    riskPct: 0,
    notional: 0,
    leverage: 0,
    limitedByLeverage: false,
  );

  final double quantity;

  /// Money lost if the stop-loss is hit (before costs).
  final double riskAmount;
  final double riskPct;

  /// Total value of the position.
  final double notional;
  final double leverage;

  /// True when the size had to be reduced to respect the leverage cap.
  final bool limitedByLeverage;
}

class Risk {
  /// Reward-to-risk ratio: 2.0 means the target is twice as far away as the
  /// stop. Null when either level is missing or on the wrong side.
  static double? rewardRisk({
    required Side side,
    required double entry,
    double? stop,
    double? target,
  }) {
    if (stop == null || target == null) return null;
    final risk = (entry - stop) * side.sign;
    final reward = (target - entry) * side.sign;
    if (risk <= 0 || reward <= 0) return null;
    return reward / risk;
  }

  /// Explains what is wrong with the levels, or returns null when they make
  /// sense (long: stop below entry, target above; short: the reverse).
  static String? levelError({
    required Side side,
    required double entry,
    double? stop,
    double? target,
  }) {
    if (stop != null && (entry - stop) * side.sign <= 0) {
      return side == Side.long
          ? 'For a long trade the stop-loss goes below your entry.'
          : 'For a short trade the stop-loss goes above your entry.';
    }
    if (target != null && (target - entry) * side.sign <= 0) {
      return side == Side.long
          ? 'For a long trade the take-profit goes above your entry.'
          : 'For a short trade the take-profit goes below your entry.';
    }
    return null;
  }

  /// The largest position whose loss at the stop is at most [riskPct] of
  /// [balance], rounded down to the instrument's lot step and capped by its
  /// maximum leverage. The same formula works for shares, lots and coins.
  static PositionSize positionSize({
    required double balance,
    required double riskPct,
    required double entry,
    required double stop,
    required InstrumentSpec spec,
  }) {
    final riskPerQuantity = (entry - stop).abs() * spec.contractSize;
    if (riskPerQuantity <= 0 || balance <= 0 || entry <= 0) {
      return PositionSize.zero;
    }
    var quantity =
        spec.roundQuantityDown(balance * riskPct / 100 / riskPerQuantity);
    final maxByLeverage = spec.roundQuantityDown(
        balance * spec.maxLeverage / (entry * spec.contractSize));
    var limited = false;
    if (quantity > maxByLeverage) {
      quantity = maxByLeverage;
      limited = true;
    }
    final riskAmount = quantity * riskPerQuantity;
    final notional = spec.notional(entry, quantity);
    return PositionSize(
      quantity: quantity,
      riskAmount: riskAmount,
      riskPct: riskAmount / balance * 100,
      notional: notional,
      leverage: notional / balance,
      limitedByLeverage: limited,
    );
  }
}
