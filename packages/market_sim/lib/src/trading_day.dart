import 'dart:math' as math;

import 'candle.dart';
import 'generator.dart';
import 'instrument.dart';
import 'rng.dart';

/// FNV-1a: a string hash that is identical on every platform, so a seed
/// derived from a date and symbol gives every player the same market.
int stableHash(String input) {
  var hash = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = mul32(hash, 0x01000193);
  }
  return hash;
}

enum Bias { bullish, bearish, neutral }

enum NewsImpact { low, medium, high }

/// A headline plus the reason it matters (shown after the session).
class NewsItem {
  const NewsItem({
    required this.headline,
    required this.why,
    required this.bias,
    required this.impact,
  });

  final String headline;
  final String why;
  final Bias bias;
  final NewsImpact impact;
}

/// The scheduled release during the session.
class NewsEvent {
  const NewsEvent({
    required this.name,
    required this.index,
    required this.time,
    required this.headline,
    required this.why,
    required this.outcome,
  });

  final String name;

  /// Candle index at which the release hits.
  final int index;
  final String time;
  final String headline;
  final String why;
  final Bias outcome;
}

typedef NewsStory = (String headline, String why);

/// The news that can appear for one market.
class NewsBook {
  const NewsBook({
    required this.bullish,
    required this.bearish,
    required this.neutral,
    required this.eventName,
    required this.eventUp,
    required this.eventDown,
  });

  final List<NewsStory> bullish;
  final List<NewsStory> bearish;
  final List<NewsStory> neutral;
  final String eventName;
  final NewsStory eventUp;
  final NewsStory eventDown;
}

/// A tradable market in the game: specs, typical price and volatility, and
/// its news. All news is simulated.
class MarketProfile {
  const MarketProfile({
    required this.spec,
    required this.referencePrice,
    required this.dailyVolatilityPct,
    required NewsBook news,
  }) : _news = news;

  final InstrumentSpec spec;

  /// Typical price level; each day starts within a few percent of it.
  final double referencePrice;

  /// Typical daily range in percent.
  final double dailyVolatilityPct;
  final NewsBook _news;

  String get symbol => spec.symbol;
  String get eventName => _news.eventName;

  /// Slowly wandering start price, so consecutive days look continuous.
  double startPriceFor(int dayNumber) {
    final phase = (stableHash(spec.symbol) % 1000) / 1000 * 2 * math.pi;
    final drift =
        0.05 * math.sin(dayNumber / 11 + phase) +
        0.02 * math.sin(dayNumber / 3.7 + phase * 2);
    return referencePrice * (1 + drift);
  }
}

enum DayArchetype { follow, fade, surprise, range, drift }

/// One trading day: yesterday's candles for context, today's session of
/// 96 five-minute candles (08:00–16:00), spreads, news and the answer key.
class TradingDay {
  const TradingDay({
    required this.market,
    required this.dayNumber,
    required this.candles,
    required this.spreads,
    required this.sessionStart,
    required this.briefing,
    required this.event,
    required this.archetype,
  });

  static const sessionBars = 96;
  static const historyBars = 72;
  static const eventOffset = 66; // 13:30
  static const barMinutes = 5;
  static const openMinutes = 8 * 60;

  final MarketProfile market;
  final int dayNumber;
  final List<Candle> candles;
  final List<double> spreads;
  final int sessionStart;
  final NewsItem briefing;
  final NewsEvent event;
  final DayArchetype archetype;

  int get sessionEnd => candles.length - 1;
  double get sessionOpen => candles[sessionStart].open;
  double get sessionClose => candles.last.close;
  double get sessionChangePct => (sessionClose / sessionOpen - 1) * 100;

  /// Clock time at the close of candle [index] ("Yesterday" before the open).
  String timeAt(int index) {
    if (index < sessionStart) return 'Pre-market';
    return clock(openMinutes + (index - sessionStart + 1) * barMinutes);
  }

  static String clock(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  /// Plain-English explanation of what happened, for the day summary.
  String get recap {
    final direction = sessionChangePct >= 0 ? 'up' : 'down';
    return switch (archetype) {
      DayArchetype.follow =>
        'The market followed the news: the morning bias was right, and the '
            '${event.name} added fuel to the move.',
      DayArchetype.fade =>
        '"Buy the rumour, sell the news": price moved with the morning bias '
            'early, then reversed after the ${event.name}.',
      DayArchetype.surprise =>
        'The ${event.name} surprised against the morning mood, and price '
            'turned the other way.',
      DayArchetype.range =>
        'The news was already priced in: price chopped sideways and the '
            '${event.name} caused only a short spike.',
      DayArchetype.drift =>
        'No clear news bias today; price drifted $direction on its own flows.',
    };
  }
}

TradingDay generateTradingDay(MarketProfile market, int dayNumber) {
  final seed = stableHash('${market.symbol}:$dayNumber');
  final rng = SeededRandom(seed);
  final v = market.dailyVolatilityPct;
  final barVol = v / 18;

  // Morning briefing.
  final biasRoll = rng.nextDouble();
  final bias = biasRoll < 0.4
      ? Bias.bullish
      : biasRoll < 0.8
      ? Bias.bearish
      : Bias.neutral;
  final impactRoll = rng.nextDouble();
  final impact = impactRoll < 0.3
      ? NewsImpact.low
      : impactRoll < 0.75
      ? NewsImpact.medium
      : NewsImpact.high;
  final book = market._news;
  final stories = switch (bias) {
    Bias.bullish => book.bullish,
    Bias.bearish => book.bearish,
    Bias.neutral => book.neutral,
  };
  final story = stories[rng.nextInt(stories.length)];
  final briefing = NewsItem(
    headline: story.$1,
    why: story.$2,
    bias: bias,
    impact: bias == Bias.neutral ? NewsImpact.low : impact,
  );

  // How the day unfolds. The news gives an edge, not a certainty.
  final b = bias == Bias.bearish ? -1.0 : 1.0;
  final m =
      v *
      switch (briefing.impact) {
        NewsImpact.low => 0.6,
        NewsImpact.medium => 0.9,
        NewsImpact.high => 1.2,
      };
  final followChance = switch (briefing.impact) {
    NewsImpact.low => 0.55,
    NewsImpact.medium => 0.62,
    NewsImpact.high => 0.68,
  };

  const pre = TradingDay.eventOffset;
  const post = TradingDay.sessionBars - TradingDay.eventOffset - 2;
  TrendSegment trend(
    int bars,
    double move, {
    double volMul = 1,
    double volume = 1,
  }) => TrendSegment(
    bars: bars,
    movePct: move,
    volatilityPct: barVol * volMul,
    volumeMultiplier: volume,
  );
  RangeSegment range(int bars, double halfWidth) => RangeSegment(
    bars: bars,
    belowPct: halfWidth,
    abovePct: halfWidth,
    volatilityPct: barVol,
  );
  TrendSegment spike(double move) => trend(2, move, volMul: 3.5, volume: 4);

  final DayArchetype archetype;
  final double spikeDirection;
  final List<Segment> session;
  if (bias == Bias.neutral) {
    if (rng.nextBool(0.6)) {
      archetype = DayArchetype.range;
      spikeDirection = rng.nextBool() ? 1 : -1;
      session = [
        range(pre, 0.3 * v),
        spike(spikeDirection * 0.25 * v),
        trend(post, -spikeDirection * 0.25 * v),
      ];
    } else {
      archetype = DayArchetype.drift;
      spikeDirection = rng.nextBool() ? 1 : -1;
      session = [
        range(12, 0.15 * v),
        trend(pre - 12, spikeDirection * 0.4 * v),
        spike(spikeDirection * 0.15 * v),
        trend(post, spikeDirection * 0.15 * v),
      ];
    }
  } else {
    final roll = rng.nextDouble();
    if (roll < followChance) {
      archetype = DayArchetype.follow;
      spikeDirection = b;
      session = [
        range(12, 0.12 * v),
        trend(pre - 12, b * 0.45 * m),
        spike(b * 0.25 * m),
        trend(post, b * 0.3 * m),
      ];
    } else if (rng.nextBool()) {
      archetype = DayArchetype.fade;
      spikeDirection = b;
      session = [
        range(8, 0.1 * v),
        trend(pre - 8, b * 0.5 * m),
        spike(b * 0.15 * m),
        trend(post, -b * 0.95 * m),
      ];
    } else {
      archetype = DayArchetype.surprise;
      spikeDirection = -b;
      session = [
        range(pre, 0.2 * v),
        spike(-b * 0.45 * m),
        trend(post, -b * 0.4 * m),
      ];
    }
  }

  // Yesterday, for context.
  final historyMove = (rng.nextDouble() - 0.5) * v;
  final history = <Segment>[
    trend(TradingDay.historyBars ~/ 2, historyMove),
    range(TradingDay.historyBars - TradingDay.historyBars ~/ 2, 0.25 * v),
  ];

  final scenario = ScenarioGenerator(
    seed: seed ^ 0x5bd1e995,
    startPrice: market.startPriceFor(dayNumber),
    tickSize: market.spec.tickSize,
  ).generate([...history, ...session]);

  const sessionStart = TradingDay.historyBars;
  const eventIndex = sessionStart + TradingDay.eventOffset;
  final base = market.spec.spread;
  // Wider spreads at the open and around the release, kept on the tick grid.
  double widen(double factor) => market.spec.roundPrice(base * factor);
  final spreads = [
    for (var i = 0; i < scenario.candles.length; i++)
      if (i == sessionStart || i == sessionStart + 1)
        widen(1.5)
      else if (i == eventIndex - 1)
        widen(2)
      else if (i == eventIndex || i == eventIndex + 1)
        widen(3)
      else
        base,
  ];

  final eventStory = spikeDirection > 0 ? book.eventUp : book.eventDown;
  return TradingDay(
    market: market,
    dayNumber: dayNumber,
    candles: scenario.candles,
    spreads: spreads,
    sessionStart: sessionStart,
    briefing: briefing,
    event: NewsEvent(
      name: book.eventName,
      index: eventIndex,
      time: TradingDay.clock(
        TradingDay.openMinutes + TradingDay.eventOffset * TradingDay.barMinutes,
      ),
      headline: eventStory.$1,
      why: eventStory.$2,
      outcome: spikeDirection > 0 ? Bias.bullish : Bias.bearish,
    ),
    archetype: archetype,
  );
}
