import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:market_sim/market_sim.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Result of one ranked trading day.
class DayResult {
  const DayResult({
    required this.date,
    required this.symbol,
    required this.pnl,
    required this.returnPct,
    required this.trades,
  });

  factory DayResult.fromJson(Map<String, dynamic> j) => DayResult(
    date: j['date'] as String,
    symbol: j['symbol'] as String,
    pnl: (j['pnl'] as num).toDouble(),
    returnPct: (j['returnPct'] as num).toDouble(),
    trades: j['trades'] as int,
  );

  final String date;
  final String symbol;
  final double pnl;
  final double returnPct;
  final int trades;

  Map<String, dynamic> toJson() => {
    'date': date,
    'symbol': symbol,
    'pnl': pnl,
    'returnPct': returnPct,
    'trades': trades,
  };
}

/// What happened at the end of a season (shown once).
class SeasonReport {
  const SeasonReport({
    required this.seasonId,
    required this.from,
    required this.to,
    required this.rank,
    required this.returnPct,
    required this.outcome,
  });

  factory SeasonReport.fromJson(Map<String, dynamic> j) => SeasonReport(
    seasonId: j['seasonId'] as int,
    from: League.values.byName(j['from'] as String),
    to: League.values.byName(j['to'] as String),
    rank: j['rank'] as int,
    returnPct: (j['returnPct'] as num).toDouble(),
    outcome: SeasonOutcome.values.byName(j['outcome'] as String),
  );

  final int seasonId;
  final League from;
  final League to;
  final int rank;
  final double returnPct;
  final SeasonOutcome outcome;

  Map<String, dynamic> toJson() => {
    'seasonId': seasonId,
    'from': from.name,
    'to': to.name,
    'rank': rank,
    'returnPct': returnPct,
    'outcome': outcome.name,
  };
}

/// The player's league account: paper-money balance, league, weekly season
/// and group. Saved on the device. Online leagues will move the group and
/// validation to a server; the rules stay the same.
class GameStore extends ChangeNotifier {
  GameStore._(this._prefs, this._clock) {
    _read();
    _rollSeasonIfNeeded();
  }

  static const _key = 'league_state_v1';
  static final _epoch = DateTime.utc(2026, 1, 1);

  static GameStore? _instance;

  static Future<GameStore> load({DateTime Function()? clock}) async {
    if (_instance != null) return _instance!;
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      prefs = null;
    }
    return _instance = GameStore._(prefs, clock ?? DateTime.now);
  }

  @visibleForTesting
  static void reset() => _instance = null;

  final SharedPreferences? _prefs;
  final DateTime Function() _clock;

  late String playerId;
  double balance = LeagueRules.startingBalance;
  League league = League.bronze;
  int seasonId = 0;
  double seasonStartBalance = LeagueRules.startingBalance;
  List<DayResult> seasonDays = [];
  String? lastRankedDate;
  int resets = 0;
  int groupVersion = 0;
  League bestLeague = League.bronze;
  SeasonReport? pendingReport;
  bool justBlown = false;

  DateTime get now => _clock();

  /// Same number for every player on a given date, so everyone trades the
  /// same market that day.
  int get dayNumber {
    final n = now;
    return DateTime.utc(n.year, n.month, n.day).difference(_epoch).inDays;
  }

  String get todayKey {
    final n = now;
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  bool get rankedPlayedToday => lastRankedDate == todayKey;
  double get seasonReturnPct => (balance / seasonStartBalance - 1) * 100;
  double get seasonPnl => balance - seasonStartBalance;
  int get seasonDaysPlayed => seasonDays.length;
  DateTime get seasonEnds => seasonEndAfter(now);
  String get _groupKey => '$playerId:$groupVersion';

  List<Rival> get rivals =>
      simulateRivals(seasonId: seasonId, league: league, groupKey: _groupKey);

  List<Standing> standingsAfter(int days) => rankGroup(
    rivals: rivals,
    daysElapsed: days,
    yourName: 'You',
    yourReturnPct: seasonReturnPct,
    yourDaysPlayed: seasonDaysPlayed,
  );

  /// Live standings: rivals' results up to and including today.
  List<Standing> get standings => standingsAfter(now.weekday);
  Standing get you => standings.firstWhere((s) => s.isYou);

  /// Records today's ranked session and applies it to the account.
  Future<void> recordRankedDay({
    required String symbol,
    required double pnl,
    required int trades,
  }) async {
    final before = balance;
    balance = math.max(0, balance + pnl);
    seasonDays = [
      ...seasonDays,
      DayResult(
        date: todayKey,
        symbol: symbol,
        pnl: pnl,
        returnPct: before == 0 ? 0 : pnl / before * 100,
        trades: trades,
      ),
    ];
    lastRankedDate = todayKey;
    if (balance < LeagueRules.startingBalance * LeagueRules.blownFraction) {
      _resetAccount();
      justBlown = true;
    }
    await _save();
    notifyListeners();
  }

  /// Starts over: fresh \$10,000 in Bronze, in a new group.
  Future<void> resetAccount() async {
    _resetAccount();
    await _save();
    notifyListeners();
  }

  Future<void> clearNotices() async {
    pendingReport = null;
    justBlown = false;
    await _save();
    notifyListeners();
  }

  /// Re-checks the season (call when the app returns to the foreground).
  Future<void> refresh() async {
    if (_rollSeasonIfNeeded()) {
      await _save();
      notifyListeners();
    }
  }

  void _resetAccount() {
    balance = LeagueRules.startingBalance;
    league = League.bronze;
    seasonStartBalance = LeagueRules.startingBalance;
    seasonDays = [];
    groupVersion++;
    resets++;
  }

  /// Settles a finished season: top 10 up, bottom 10 down.
  bool _rollSeasonIfNeeded() {
    final current = seasonIdFor(now);
    if (seasonId == current) return false;
    if (seasonId != 0 && seasonDaysPlayed > 0) {
      final finalStandings = standingsAfter(7);
      final me = finalStandings.firstWhere((s) => s.isYou);
      final outcome = seasonOutcome(
        rank: me.rank,
        league: league,
        daysPlayed: seasonDaysPlayed,
      );
      final to = switch (outcome) {
        SeasonOutcome.promoted => league.next!,
        SeasonOutcome.demoted => league.previous!,
        SeasonOutcome.stayed => league,
      };
      pendingReport = SeasonReport(
        seasonId: seasonId,
        from: league,
        to: to,
        rank: me.rank,
        returnPct: seasonReturnPct,
        outcome: outcome,
      );
      league = to;
      if (to.index > bestLeague.index) bestLeague = to;
    }
    seasonId = current;
    seasonStartBalance = balance;
    seasonDays = [];
    return true;
  }

  void _read() {
    final raw = _prefs?.getString(_key);
    if (raw == null) {
      playerId = _newPlayerId();
      return;
    }
    final j = jsonDecode(raw) as Map<String, dynamic>;
    playerId = j['playerId'] as String;
    balance = (j['balance'] as num).toDouble();
    league = League.values.byName(j['league'] as String);
    seasonId = j['seasonId'] as int;
    seasonStartBalance = (j['seasonStartBalance'] as num).toDouble();
    seasonDays = [
      for (final d in j['seasonDays'] as List)
        DayResult.fromJson(d as Map<String, dynamic>),
    ];
    lastRankedDate = j['lastRankedDate'] as String?;
    resets = j['resets'] as int? ?? 0;
    groupVersion = j['groupVersion'] as int? ?? 0;
    bestLeague = League.values.byName(j['bestLeague'] as String? ?? 'bronze');
    final report = j['pendingReport'];
    pendingReport = report == null
        ? null
        : SeasonReport.fromJson(report as Map<String, dynamic>);
    justBlown = j['justBlown'] as bool? ?? false;
  }

  Future<void> _save() async {
    await _prefs?.setString(
      _key,
      jsonEncode({
        'playerId': playerId,
        'balance': balance,
        'league': league.name,
        'seasonId': seasonId,
        'seasonStartBalance': seasonStartBalance,
        'seasonDays': [for (final d in seasonDays) d.toJson()],
        'lastRankedDate': lastRankedDate,
        'resets': resets,
        'groupVersion': groupVersion,
        'bestLeague': bestLeague.name,
        'pendingReport': pendingReport?.toJson(),
        'justBlown': justBlown,
      }),
    );
  }

  String _newPlayerId() {
    final r = math.Random();
    return List.generate(12, (_) => r.nextInt(36).toRadixString(36)).join();
  }
}
