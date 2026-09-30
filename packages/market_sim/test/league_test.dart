import 'package:market_sim/market_sim.dart';
import 'package:test/test.dart';

void main() {
  test('ISO week season ids', () {
    expect(seasonIdFor(DateTime(2026, 9, 30)), 202640);
    expect(seasonIdFor(DateTime(2026, 1, 1)), 202601);
    expect(seasonIdFor(DateTime(2027, 1, 1)), 202653);
    expect(seasonEndAfter(DateTime(2026, 9, 30, 15)), DateTime(2026, 10, 5));
    expect(seasonEndAfter(DateTime(2026, 10, 4, 23)), DateTime(2026, 10, 5));
  });

  test('ladder order', () {
    expect(League.bronze.previous, isNull);
    expect(League.bronze.next, League.silver);
    expect(League.master.next, isNull);
  });

  test('a group has 29 unique, reproducible rivals', () {
    final a = simulateRivals(
      seasonId: 202640,
      league: League.gold,
      groupKey: 'p1',
    );
    final b = simulateRivals(
      seasonId: 202640,
      league: League.gold,
      groupKey: 'p1',
    );
    expect(a, hasLength(29));
    expect(a.map((r) => r.name).toSet(), hasLength(29));
    expect(
      [for (final r in a) r.resultAfter(7).returnPct],
      [for (final r in b) r.resultAfter(7).returnPct],
    );
  });

  test('higher leagues have stronger rivals on average', () {
    double average(League league) {
      var total = 0.0;
      for (var g = 0; g < 20; g++) {
        for (final r in simulateRivals(
          seasonId: 202640,
          league: league,
          groupKey: 'g$g',
        )) {
          total += r.resultAfter(7).returnPct;
        }
      }
      return total / (20 * 29);
    }

    expect(average(League.master), greaterThan(average(League.bronze)));
  });

  test('ranking puts you in the right place', () {
    final rivals = simulateRivals(
      seasonId: 202640,
      league: League.silver,
      groupKey: 'x',
    );
    final best = rankGroup(
      rivals: rivals,
      daysElapsed: 7,
      yourName: 'You',
      yourReturnPct: 500,
      yourDaysPlayed: 5,
    );
    expect(best.first.isYou, isTrue);
    expect(best.first.rank, 1);
    final worst = rankGroup(
      rivals: rivals,
      daysElapsed: 7,
      yourName: 'You',
      yourReturnPct: -99,
      yourDaysPlayed: 5,
    );
    expect(worst.last.isYou, isTrue);
    expect(worst.last.rank, 30);
    expect(worst.map((s) => s.rank), [for (var i = 1; i <= 30; i++) i]);
  });

  test('top 10 promote, bottom 10 demote, with ladder limits', () {
    expect(
      seasonOutcome(rank: 1, league: League.gold, daysPlayed: 5),
      SeasonOutcome.promoted,
    );
    expect(
      seasonOutcome(rank: 10, league: League.gold, daysPlayed: 3),
      SeasonOutcome.promoted,
    );
    expect(
      seasonOutcome(rank: 10, league: League.gold, daysPlayed: 2),
      SeasonOutcome.stayed,
      reason: 'must trade at least 3 days to move up',
    );
    expect(
      seasonOutcome(rank: 11, league: League.gold, daysPlayed: 5),
      SeasonOutcome.stayed,
    );
    expect(
      seasonOutcome(rank: 20, league: League.gold, daysPlayed: 5),
      SeasonOutcome.stayed,
    );
    expect(
      seasonOutcome(rank: 21, league: League.gold, daysPlayed: 5),
      SeasonOutcome.demoted,
    );
    expect(
      seasonOutcome(rank: 30, league: League.bronze, daysPlayed: 5),
      SeasonOutcome.stayed,
    );
    expect(
      seasonOutcome(rank: 1, league: League.master, daysPlayed: 7),
      SeasonOutcome.stayed,
    );
  });
}
