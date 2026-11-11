import 'package:flutter/material.dart';
import 'package:market_sim/market_sim.dart';

import 'game_scope.dart';
import 'session_summary_screen.dart';
import 'trading_session_screen.dart';

/// Opens a trading session and wires up what happens when it ends.
///
/// A ranked session is saved as it is played (see `GameStore.rankedSession`),
/// so it can be paused, survives the app being closed, and can't be started
/// over once the chart has been seen. Pass [resume] to continue one.
/// Practice sessions are not saved.
Future<void> openTradingSession(
  BuildContext context, {
  required MarketProfile market,
  required int dayNumber,
  required bool ranked,
  SavedSession? resume,
  bool replace = false,
}) {
  final store = GameScope.of(context);
  // The session belongs to the day it starts on, even if it ends later.
  final startedOn = resume?.startedOn ?? store.todayKey;
  final route = MaterialPageRoute<void>(
    builder: (_) => TradingSessionScreen(
      market: market,
      dayNumber: dayNumber,
      ranked: ranked,
      startingBalance:
          resume?.startingBalance ??
          (ranked ? store.balance : LeagueRules.startingBalance),
      resume: resume,
      startedOn: startedOn,
      onProgress: ranked ? store.saveRankedSession : null,
      onComplete: (result) async {
        if (ranked) {
          await store.recordRankedDay(
            symbol: market.symbol,
            pnl: result.pnl,
            trades: result.trades.length,
            date: startedOn,
          );
        }
        return SessionSummaryScreen(result: result);
      },
    ),
  );
  final navigator = Navigator.of(context);
  final closed = replace
      ? navigator.pushReplacement(route)
      : navigator.push(route);
  // The store doesn't announce every candle; on the way back, let the
  // League tab catch up (where the session was paused, or a new day).
  return closed.whenComplete(store.refresh);
}

/// Continues the ranked session in progress, if there is one.
Future<void> resumeRankedSession(BuildContext context) async {
  final saved = GameScope.of(context).rankedSession;
  if (saved == null) return;
  await openTradingSession(
    context,
    market: saved.market,
    dayNumber: saved.dayNumber,
    ranked: true,
    resume: saved,
  );
}

/// Where a saved session stands, for a card or a prompt: "EUR/USD, paused
/// at 11:35" or "Gold, before the open".
String describeSavedSession(SavedSession saved) {
  final day = saved.day;
  final name = saved.market.spec.name;
  return saved.index < day.sessionStart
      ? '$name, before the open'
      : '$name, paused at ${day.timeAt(saved.index)}';
}
