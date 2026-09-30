/// The learning path. Lesson content is added lesson by lesson: entries with
/// an [Lesson.id] have content in `assets/lessons/<id>.json`; entries with
/// only an [Lesson.exercise] open that exercise directly.
class Lesson {
  const Lesson(this.title, {this.minutes = 4, this.id, this.exercise});

  final String title;
  final int minutes;

  /// Lesson content id (`assets/lessons/<id>.json`).
  final String? id;

  /// Route of an interactive exercise that is already built.
  final String? exercise;

  bool get isPlayable => id != null || exercise != null;
}

class Level {
  const Level({
    required this.number,
    required this.title,
    required this.summary,
    required this.premium,
    required this.lessons,
  });

  final int number;
  final String title;
  final String summary;
  final bool premium;
  final List<Lesson> lessons;
}

const placeTradeRoute = '/exercise/place-trade';

const curriculum = <Level>[
  Level(
    number: 0,
    title: 'Market Foundations',
    summary: 'What a market is and how to read a candle.',
    premium: false,
    lessons: [
      Lesson(
        'What a market is: buyers, sellers and price',
        minutes: 3,
        id: 'L0-01',
      ),
      Lesson(
        'Bid, ask and spread: the cost of every trade',
        minutes: 3,
        id: 'L0-02',
      ),
      Lesson(
        'Stocks, forex, crypto, commodities, indices: what differs',
        minutes: 5,
        id: 'L0-03',
      ),
      Lesson('Order types: market, limit, stop. Long vs short', id: 'L0-04'),
      Lesson('Reading a candlestick', id: 'L0-05'),
      Lesson('Timeframes: same market, different stories', id: 'L0-06'),
      Lesson('Volume and liquidity', id: 'L0-07'),
    ],
  ),
  Level(
    number: 1,
    title: 'Market Structure',
    summary: 'Trends, ranges, support and resistance.',
    premium: false,
    lessons: [
      Lesson('Trends: higher highs and higher lows'),
      Lesson('Ranges and consolidation'),
      Lesson('Swing highs and swing lows'),
      Lesson('Support and resistance are zones', minutes: 6, id: 'L1-04'),
      Lesson('When support becomes resistance'),
      Lesson('Trendlines and channels'),
      Lesson('Breakouts vs fakeouts'),
      Lesson('Pullbacks and retracements'),
      Lesson('Multi-timeframe analysis', minutes: 5),
    ],
  ),
  Level(
    number: 2,
    title: 'Risk Management',
    summary: 'The skill that keeps you in the game. Always free.',
    premium: false,
    lessons: [
      Lesson('Why most beginners lose'),
      Lesson('Risk per trade and the 1% guideline'),
      Lesson('Where to put a stop-loss'),
      Lesson('Take-profit and reward:risk', exercise: placeTradeRoute),
      Lesson('Win rate × reward:risk = expectancy', minutes: 5),
      Lesson('Position sizing for any instrument', minutes: 5),
      Lesson('Leverage and margin'),
      Lesson('Drawdown maths'),
      Lesson('Fees, spread and slippage'),
    ],
  ),
  Level(
    number: 3,
    title: 'Candlestick & Chart Patterns',
    summary: 'Engulfing, pin bars, double tops, flags and more.',
    premium: true,
    lessons: [
      Lesson('Engulfing candles'),
      Lesson('Pin bars and hammers'),
      Lesson('Doji and inside bars'),
      Lesson('Double tops and bottoms'),
      Lesson('Head and shoulders'),
      Lesson('Triangles'),
      Lesson('Flags and pennants'),
      Lesson('Wedges'),
      Lesson('Context beats pattern', minutes: 5),
    ],
  ),
  Level(
    number: 4,
    title: 'Indicators',
    summary: 'Moving averages, RSI, MACD, ATR, VWAP.',
    premium: true,
    lessons: [
      Lesson('Moving averages'),
      Lesson('RSI and divergence'),
      Lesson('MACD'),
      Lesson('Bollinger Bands'),
      Lesson('ATR: volatility-based stops'),
      Lesson('VWAP'),
      Lesson('Volume profile basics'),
      Lesson('Indicator pitfalls', minutes: 5),
    ],
  ),
  Level(
    number: 5,
    title: 'Market Context',
    summary: 'Sessions, news, correlations and sentiment.',
    premium: true,
    lessons: [
      Lesson('Trading sessions and liquidity'),
      Lesson('Gaps'),
      Lesson('The economic calendar'),
      Lesson('Earnings and company news'),
      Lesson('Correlations and risk-on / risk-off'),
      Lesson('Sentiment'),
      Lesson('Fundamental vs technical analysis', minutes: 5),
    ],
  ),
  Level(
    number: 6,
    title: 'Your Trading Plan',
    summary: 'Setups, journaling, backtesting and psychology.',
    premium: true,
    lessons: [
      Lesson('Define a setup with a checklist'),
      Lesson('The trade journal'),
      Lesson('Reviewing your trades'),
      Lesson('Backtesting and sample size', minutes: 5),
      Lesson('FOMO and revenge trading'),
      Lesson('Overtrading and loss aversion'),
      Lesson('From simulator to real money', minutes: 5),
    ],
  ),
];
