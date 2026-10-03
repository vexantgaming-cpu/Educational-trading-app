import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:market_sim/market_sim.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Points from one day's challenge: 0–100 per round.
class DailyResult {
  const DailyResult({
    required this.chart,
    required this.sizing,
    required this.plan,
  });

  factory DailyResult.fromJson(Map<String, dynamic> json) => DailyResult(
    chart: json['chart'] as int,
    sizing: json['sizing'] as int,
    plan: json['plan'] as int,
  );

  final int chart;
  final int sizing;
  final int plan;

  int get total => chart + sizing + plan;
  static const maxTotal = 300;

  /// XP for finishing the day's challenge: 10, plus up to 10 for the score.
  int get xp => 10 + total ~/ 30;

  String get verdict {
    if (total >= 270) return 'Excellent';
    if (total >= 200) return 'Good work';
    if (total >= 120) return 'Getting there';
    return 'Keep practising';
  }

  Map<String, dynamic> toJson() => {
    'chart': chart,
    'sizing': sizing,
    'plan': plan,
  };
}

/// The Daily Challenge history, saved on the device. Only the first finished
/// attempt of a day counts.
class DailyChallengeStore extends ChangeNotifier {
  DailyChallengeStore._(this._prefs, this._clock) {
    final raw = _prefs?.getString(_key);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        (json['results'] as Map<String, dynamic>).forEach((day, value) {
          _results[day] = DailyResult.fromJson(value as Map<String, dynamic>);
        });
      } catch (_) {
        // A damaged save starts a fresh history rather than crashing.
      }
    }
  }

  /// In-memory only (previews and tests).
  DailyChallengeStore.memory({DateTime Function()? clock})
    : this._(null, clock ?? DateTime.now);

  static const _key = 'daily_challenge_v1';
  static const _keepDays = 400;

  static DailyChallengeStore? _instance;

  static Future<DailyChallengeStore> load({DateTime Function()? clock}) async {
    if (_instance != null) return _instance!;
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      prefs = null;
    }
    return _instance = DailyChallengeStore._(prefs, clock ?? DateTime.now);
  }

  @visibleForTesting
  static void reset() => _instance = null;

  final SharedPreferences? _prefs;
  final DateTime Function() _clock;
  final _results = <String, DailyResult>{};

  DateTime get now => _clock();
  String get todayKey => DailyChallenge.dateKeyOf(now);
  DailyChallenge get today => DailyChallenge.forDate(now);

  DailyResult? resultFor(String dateKey) => _results[dateKey];
  DailyResult? get todayResult => _results[todayKey];
  int get played => _results.length;

  int? get best => _results.isEmpty
      ? null
      : _results.values.map((r) => r.total).reduce((a, b) => a > b ? a : b);

  /// Days in a row with a finished challenge, up to today. Today not played
  /// yet doesn't break the streak; a missed day starts a new one.
  int get streak {
    var day = _dayOnly(now);
    if (!_results.containsKey(DailyChallenge.dateKeyOf(day))) {
      // Calendar arithmetic, not 24 hours: safe across clock changes.
      day = DateTime(day.year, day.month, day.day - 1);
    }
    var count = 0;
    while (_results.containsKey(DailyChallenge.dateKeyOf(day))) {
      count++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return count;
  }

  /// The last [count] days, oldest first, with their results.
  List<(DateTime, DailyResult?)> lastDays(int count) {
    final today = _dayOnly(now);
    return [
      for (var i = count - 1; i >= 0; i--)
        () {
          final day = DateTime(today.year, today.month, today.day - i);
          return (day, _results[DailyChallenge.dateKeyOf(day)]);
        }(),
    ];
  }

  /// Time until the next challenge (local midnight).
  Duration get untilNext {
    final t = now;
    return DateTime(t.year, t.month, t.day + 1).difference(t);
  }

  /// Saves [result] for [dateKey] if that day has no result yet. Returns
  /// whether it was saved.
  Future<bool> record(String dateKey, DailyResult result) async {
    if (_results.containsKey(dateKey)) return false;
    _results[dateKey] = result;
    if (_results.length > _keepDays) {
      final keys = _results.keys.toList()..sort();
      for (final k in keys.take(_results.length - _keepDays)) {
        _results.remove(k);
      }
    }
    notifyListeners();
    await _prefs?.setString(
      _key,
      jsonEncode({
        'results': {for (final e in _results.entries) e.key: e.value.toJson()},
      }),
    );
    return true;
  }

  static DateTime _dayOnly(DateTime t) => DateTime(t.year, t.month, t.day);
}

class DailyScope extends InheritedNotifier<DailyChallengeStore> {
  const DailyScope({
    super.key,
    required DailyChallengeStore store,
    required super.child,
  }) : super(notifier: store);

  static DailyChallengeStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DailyScope>()!.notifier!;
}
