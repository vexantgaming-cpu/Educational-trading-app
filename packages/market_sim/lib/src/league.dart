import 'dart:math' as math;

import 'rng.dart';
import 'trading_day.dart' show stableHash;

enum League { bronze, silver, gold, platinum, diamond, master }

extension LeagueInfo on League {
  String get title => switch (this) {
    League.bronze => 'Bronze',
    League.silver => 'Silver',
    League.gold => 'Gold',
    League.platinum => 'Platinum',
    League.diamond => 'Diamond',
    League.master => 'Master',
  };

  League? get next =>
      index + 1 < League.values.length ? League.values[index + 1] : null;
  League? get previous => index > 0 ? League.values[index - 1] : null;
}

/// League rules. The risk rules mirror how funded-trader challenges work,
/// which keeps the competition about skill rather than all-in gambles.
class LeagueRules {
  static const groupSize = 30;
  static const promoteCount = 10;
  static const demoteCount = 10;
  static const minDaysToPromote = 3;
  static const startingBalance = 10000.0;

  /// The account is "blown" when equity falls below this share of the
  /// starting balance.
  static const blownFraction = 0.1;
  static const maxRiskPct = 5.0;
  static const stopLossRequired = true;
}

/// ISO-8601 week of [date] as yyyyww, e.g. 202640. Seasons run Monday to
/// Sunday.
int seasonIdFor(DateTime date) {
  final day = DateTime.utc(date.year, date.month, date.day);
  final thursday = day.add(Duration(days: 4 - day.weekday));
  final firstThursday = DateTime.utc(thursday.year, 1, 1);
  final week = (thursday.difference(firstThursday).inDays ~/ 7) + 1;
  return thursday.year * 100 + week;
}

/// Midnight at the start of next Monday (local), when the season ends.
DateTime seasonEndAfter(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return today.add(Duration(days: 8 - now.weekday));
}

/// A simulated league opponent (used until online leagues launch).
class Rival {
  const Rival({
    required this.name,
    required this.avatarSeed,
    required this.dailyReturns,
  });

  final String name;
  final int avatarSeed;

  /// Return in percent for each of the 7 days; null = didn't trade.
  final List<double?> dailyReturns;

  ({double returnPct, int daysPlayed}) resultAfter(int days) {
    var growth = 1.0;
    var played = 0;
    for (var d = 0; d < math.min(days, dailyReturns.length); d++) {
      final r = dailyReturns[d];
      if (r == null) continue;
      growth *= 1 + r / 100;
      played++;
    }
    return (returnPct: (growth - 1) * 100, daysPlayed: played);
  }
}

class Standing {
  const Standing({
    required this.name,
    required this.returnPct,
    required this.daysPlayed,
    required this.avatarSeed,
    required this.rank,
    this.isYou = false,
  });

  final String name;
  final double returnPct;
  final int daysPlayed;
  final int avatarSeed;
  final int rank;
  final bool isYou;
}

enum SeasonOutcome { promoted, stayed, demoted }

const _adjectives = [
  'Swift',
  'Calm',
  'Bold',
  'Steady',
  'Sharp',
  'Quiet',
  'Brave',
  'Rapid',
  'Silent',
  'Golden',
  'Iron',
  'Clever',
  'Patient',
  'Wild',
  'Lucky',
  'Cool',
];
const _nouns = [
  'Bull',
  'Bear',
  'Fox',
  'Hawk',
  'Wolf',
  'Pip',
  'Candle',
  'Owl',
  'Tiger',
  'Falcon',
  'Lynx',
  'Otter',
  'Raven',
  'Whale',
  'Trader',
  'Scalper',
];

/// Mean and spread of simulated rivals' daily returns (%). Higher leagues
/// have steadier, slightly better players.
(double mean, double sd) _skill(League league) => switch (league) {
  League.bronze => (-0.25, 2.4),
  League.silver => (-0.1, 2.0),
  League.gold => (0.0, 1.7),
  League.platinum => (0.08, 1.5),
  League.diamond => (0.15, 1.3),
  League.master => (0.25, 1.1),
};

/// The 29 simulated rivals in a player's group for a season.
List<Rival> simulateRivals({
  required int seasonId,
  required League league,
  required String groupKey,
}) {
  final rng = SeededRandom(stableHash('$seasonId:${league.name}:$groupKey'));
  final (mean, sd) = _skill(league);
  final names = <String>{};
  final rivals = <Rival>[];
  while (rivals.length < LeagueRules.groupSize - 1) {
    var name =
        '${_adjectives[rng.nextInt(_adjectives.length)]}'
        '${_nouns[rng.nextInt(_nouns.length)]}';
    if (rng.nextBool(0.5)) name += '${10 + rng.nextInt(90)}';
    if (!names.add(name)) continue;
    final personalEdge = rng.nextGaussian() * 0.2;
    final activity = rng.nextRange(0.45, 0.95);
    final returns = <double?>[
      for (var d = 0; d < 7; d++)
        rng.nextBool(activity)
            ? ((mean + personalEdge + rng.nextGaussian() * sd).clamp(
                -15.0,
                15.0,
              )).toDouble()
            : null,
    ];
    rivals.add(
      Rival(
        name: name,
        avatarSeed: rng.nextInt(1 << 30),
        dailyReturns: returns,
      ),
    );
  }
  return rivals;
}

/// Ranks everyone by return for the season so far (best first). Ties go to
/// whoever traded more days.
List<Standing> rankGroup({
  required List<Rival> rivals,
  required int daysElapsed,
  required String yourName,
  required double yourReturnPct,
  required int yourDaysPlayed,
}) {
  final rows = [
    for (final r in rivals)
      (r.name, r.resultAfter(daysElapsed), r.avatarSeed, false),
    (yourName, (returnPct: yourReturnPct, daysPlayed: yourDaysPlayed), 0, true),
  ];
  rows.sort((a, b) {
    final byReturn = b.$2.returnPct.compareTo(a.$2.returnPct);
    if (byReturn != 0) return byReturn;
    final byDays = b.$2.daysPlayed.compareTo(a.$2.daysPlayed);
    if (byDays != 0) return byDays;
    return a.$1.compareTo(b.$1);
  });
  return [
    for (var i = 0; i < rows.length; i++)
      Standing(
        name: rows[i].$1,
        returnPct: rows[i].$2.returnPct,
        daysPlayed: rows[i].$2.daysPlayed,
        avatarSeed: rows[i].$3,
        rank: i + 1,
        isYou: rows[i].$4,
      ),
  ];
}

/// Top 10 move up (if they traded at least 3 days), bottom 10 move down.
/// Nobody is promoted beyond Master or demoted below Bronze.
SeasonOutcome seasonOutcome({
  required int rank,
  required League league,
  required int daysPlayed,
  int groupSize = LeagueRules.groupSize,
}) {
  if (rank <= LeagueRules.promoteCount &&
      league.next != null &&
      daysPlayed >= LeagueRules.minDaysToPromote) {
    return SeasonOutcome.promoted;
  }
  if (rank > groupSize - LeagueRules.demoteCount && league.previous != null) {
    return SeasonOutcome.demoted;
  }
  return SeasonOutcome.stayed;
}
