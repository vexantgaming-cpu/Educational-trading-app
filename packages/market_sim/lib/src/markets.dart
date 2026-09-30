import 'instrument.dart';
import 'trading_day.dart';

/// The markets of the trading game. Prices are simulated; reference levels
/// only set the scale. All headlines are fictional and generic, and the only
/// company named is fictional (Nova Robotics).
class GameMarkets {
  static const eurUsd = MarketProfile(
    spec: GameInstruments.eurUsd,
    referencePrice: 1.1650,
    dailyVolatilityPct: 0.55,
    news: NewsBook(
      bullish: [
        (
          'Eurozone inflation comes in hotter than forecast',
          'Higher inflation makes higher European interest rates more likely, which tends to support the euro.',
        ),
        (
          'US jobless claims jump to a three-month high',
          'Signs of a weaker US job market can weigh on the dollar, lifting EUR/USD.',
        ),
        (
          'Eurozone business activity beats expectations',
          'Stronger European growth tends to attract money into the euro.',
        ),
      ],
      bearish: [
        (
          'Eurozone factory orders slump for a third month',
          'Weak European growth can push the euro lower against the dollar.',
        ),
        (
          'US retail sales beat forecasts',
          'Strong US spending supports the dollar, which pushes EUR/USD down.',
        ),
        (
          'European central bankers hint at further rate cuts',
          'Lower expected interest rates make the euro less attractive to hold.',
        ),
      ],
      neutral: [
        (
          'Quiet calendar as traders await next week\'s central bank meetings',
          'With little new information, price often moves sideways.',
        ),
        (
          'Mixed data on both sides of the Atlantic',
          'When news points both ways, there is no clear bias.',
        ),
      ],
      eventName: 'US inflation release',
      eventUp: (
        'US inflation cooler than expected',
        'Lower US inflation reduces the chance of higher US rates, weakening the dollar and lifting EUR/USD.',
      ),
      eventDown: (
        'US inflation hotter than expected',
        'Higher US inflation can mean higher US rates, strengthening the dollar and pushing EUR/USD down.',
      ),
    ),
  );

  static const gbpUsd = MarketProfile(
    spec: GameInstruments.gbpUsd,
    referencePrice: 1.3450,
    dailyVolatilityPct: 0.65,
    news: NewsBook(
      bullish: [
        (
          'UK wage growth accelerates',
          'Faster wage growth can keep UK interest rates higher, supporting the pound.',
        ),
        (
          'UK economy grows faster than expected',
          'Stronger growth tends to attract investors to the pound.',
        ),
        (
          'Dollar slips as US bond yields fall',
          'Lower US yields make the dollar less attractive, lifting GBP/USD.',
        ),
      ],
      bearish: [
        (
          'UK retail sales fall sharply',
          'Weak spending can lead to lower UK rates, weighing on the pound.',
        ),
        (
          'UK central bank signals rates may fall sooner',
          'Expected rate cuts make the pound less attractive to hold.',
        ),
        (
          'Strong US factory data lifts the dollar',
          'A firmer dollar pushes GBP/USD lower.',
        ),
      ],
      neutral: [
        (
          'UK bank holiday thins trading',
          'With fewer traders active, price action is often quiet and choppy.',
        ),
        (
          'Traders square positions ahead of the weekend',
          'Position squaring rarely creates a clear direction.',
        ),
      ],
      eventName: 'US jobs report',
      eventUp: (
        'US hiring slows more than expected',
        'A cooler US job market tends to weaken the dollar.',
      ),
      eventDown: (
        'US hiring beats expectations',
        'Strong hiring supports the dollar, pushing GBP/USD down.',
      ),
    ),
  );

  static const usdJpy = MarketProfile(
    spec: GameInstruments.usdJpy,
    referencePrice: 148.50,
    dailyVolatilityPct: 0.7,
    news: NewsBook(
      bullish: [
        (
          'US bond yields climb to a monthly high',
          'Higher US yields widen the gap with Japan\'s low rates, supporting USD/JPY.',
        ),
        (
          'Risk appetite improves as global stocks rally',
          'When investors feel confident they tend to sell the safe-haven yen.',
        ),
        (
          'Japan\'s central bank keeps policy ultra-loose',
          'Very low Japanese rates keep the yen weak.',
        ),
      ],
      bearish: [
        (
          'Japan\'s central bank signals a possible rate hike',
          'Higher Japanese rates would make the yen more attractive.',
        ),
        (
          'Investors rush to safety as markets tumble',
          'In a risk-off mood the yen often strengthens as a safe haven.',
        ),
        (
          'US yields drop after weak data',
          'Falling US yields reduce the appeal of the dollar against the yen.',
        ),
      ],
      neutral: [
        (
          'Tokyo holiday keeps Asian trading quiet',
          'Thin trading often means small, choppy moves.',
        ),
        (
          'Markets wait for next week\'s policy meetings',
          'Traders often hold back before big decisions.',
        ),
      ],
      eventName: 'US inflation release',
      eventUp: (
        'US inflation hotter than expected',
        'Higher US inflation points to higher US rates, lifting the dollar against the yen.',
      ),
      eventDown: (
        'US inflation cooler than expected',
        'Lower US inflation points to lower US rates, weakening the dollar against the yen.',
      ),
    ),
  );

  static const gold = MarketProfile(
    spec: GameInstruments.gold,
    referencePrice: 3850,
    dailyVolatilityPct: 1.4,
    news: NewsBook(
      bullish: [
        (
          'Geopolitical tensions boost demand for safe havens',
          'Investors often buy gold when uncertainty rises.',
        ),
        (
          'Dollar weakens across the board',
          'A weaker dollar makes gold cheaper for buyers using other currencies.',
        ),
        (
          'Central banks report continued gold buying',
          'Steady official demand supports prices.',
        ),
      ],
      bearish: [
        (
          'Rising real yields weigh on gold',
          'Gold pays no interest, so higher real yields make it less attractive.',
        ),
        (
          'Dollar rallies after strong US data',
          'A stronger dollar tends to pressure gold prices.',
        ),
        (
          'Easing tensions reduce safe-haven demand',
          'When fear fades, some investors sell gold.',
        ),
      ],
      neutral: [
        (
          'Gold traders wait for fresh direction',
          'Without a catalyst, gold often trades sideways.',
        ),
        (
          'Mixed signals from the bond market',
          'Conflicting signals leave no clear bias.',
        ),
      ],
      eventName: 'US jobs report',
      eventUp: (
        'US jobs data disappoints',
        'Weak data can mean lower US rates, which tends to support gold.',
      ),
      eventDown: (
        'US jobs data comes in strong',
        'Strong data can mean higher rates and a firmer dollar, pressuring gold.',
      ),
    ),
  );

  static const oil = MarketProfile(
    spec: GameInstruments.oil,
    referencePrice: 64.50,
    dailyVolatilityPct: 2.4,
    news: NewsBook(
      bullish: [
        (
          'Major producers agree to extend supply cuts',
          'Less supply tends to push prices up.',
        ),
        (
          'US crude inventories fall more than expected',
          'Falling stockpiles suggest demand is outpacing supply.',
        ),
        (
          'Shipping disruption raises supply worries',
          'Delivery problems can tighten supply quickly.',
        ),
      ],
      bearish: [
        (
          'Surprise build in US crude stockpiles',
          'Rising stockpiles suggest weaker demand or more supply.',
        ),
        (
          'Factory data raises demand worries',
          'Slower economic activity means less demand for fuel.',
        ),
        (
          'Producers signal higher output next month',
          'More supply tends to push prices down.',
        ),
      ],
      neutral: [
        (
          'Oil steadies as traders weigh supply and demand',
          'Balanced forces often mean a range-bound day.',
        ),
        (
          'Quiet session ahead of producer meeting',
          'Traders often wait for big decisions before committing.',
        ),
      ],
      eventName: 'crude inventory report',
      eventUp: (
        'Crude inventories drop sharply',
        'Lower stockpiles point to tighter supply, lifting prices.',
      ),
      eventDown: (
        'Crude inventories rise unexpectedly',
        'Higher stockpiles point to weaker demand, pushing prices down.',
      ),
    ),
  );

  static const us500 = MarketProfile(
    spec: GameInstruments.us500,
    referencePrice: 6600,
    dailyVolatilityPct: 1.0,
    news: NewsBook(
      bullish: [
        (
          'Big tech earnings beat estimates',
          'Strong profits from the largest companies lift the whole index.',
        ),
        (
          'Inflation cools, boosting rate-cut hopes',
          'Lower expected rates tend to support stock valuations.',
        ),
        (
          'Consumer confidence rises to a yearly high',
          'Confident consumers spend more, which supports company profits.',
        ),
      ],
      bearish: [
        (
          'Bond yields surge, pressuring stocks',
          'Higher yields raise borrowing costs and make bonds more attractive than stocks.',
        ),
        (
          'Retailers cut their profit outlook',
          'Weaker profit expectations weigh on share prices.',
        ),
        (
          'Trade tensions flare up again',
          'Trade disputes can hurt company earnings and confidence.',
        ),
      ],
      neutral: [
        (
          'Stocks tread water ahead of earnings season',
          'Investors often wait for results before taking big positions.',
        ),
        (
          'Light volume as many traders are on holiday',
          'Thin markets tend to drift without clear direction.',
        ),
      ],
      eventName: 'US inflation release',
      eventUp: (
        'US inflation cooler than expected',
        'Cooler inflation raises hopes of lower rates, lifting stocks.',
      ),
      eventDown: (
        'US inflation hotter than expected',
        'Hot inflation raises fears of higher rates, weighing on stocks.',
      ),
    ),
  );

  static const tech100 = MarketProfile(
    spec: GameInstruments.tech100,
    referencePrice: 24500,
    dailyVolatilityPct: 1.3,
    news: NewsBook(
      bullish: [
        (
          'Chipmakers rally on strong data-center demand',
          'Chip companies are a big part of the tech index.',
        ),
        (
          'Software giants raise their outlook',
          'Better guidance from large companies lifts the index.',
        ),
        (
          'Bond yields dip, lifting growth stocks',
          'Growth companies are sensitive to rates; lower yields help them.',
        ),
      ],
      bearish: [
        (
          'Regulators open probe into large tech platforms',
          'Regulatory risk can weigh on big tech shares.',
        ),
        (
          'Chip export restrictions tightened',
          'Sales restrictions can cut expected profits for chipmakers.',
        ),
        (
          'Yields jump, hitting growth stocks',
          'Higher yields reduce the value of future profits, hurting growth stocks most.',
        ),
      ],
      neutral: [
        (
          'Tech shares mixed as investors rotate sectors',
          'Money moving between sectors can leave the index flat.',
        ),
        (
          'Traders await results from the biggest tech names',
          'Before big results, the index often goes quiet.',
        ),
      ],
      eventName: 'central bank minutes',
      eventUp: (
        'Minutes show officials open to rate cuts',
        'Lower expected rates support growth stocks.',
      ),
      eventDown: (
        'Minutes show officials worried about inflation',
        'Fears of higher rates weigh on growth stocks.',
      ),
    ),
  );

  static const bitcoin = MarketProfile(
    spec: GameInstruments.btcUsd,
    referencePrice: 112000,
    dailyVolatilityPct: 3.0,
    news: NewsBook(
      bullish: [
        (
          'Crypto funds see record weekly inflows',
          'Big inflows mean fresh buying pressure.',
        ),
        (
          'Major payment company expands crypto support',
          'Wider adoption can bring in new buyers.',
        ),
        (
          'Dollar weakens as risk appetite grows',
          'Risk-on moods and a weaker dollar tend to help crypto.',
        ),
      ],
      bearish: [
        (
          'Large exchange suffers an outage',
          'Operational problems shake traders\' confidence.',
        ),
        (
          'Regulators signal tougher crypto rules',
          'Stricter rules can reduce demand.',
        ),
        (
          'Long-dormant coins moved to exchanges',
          'Coins moving onto exchanges can signal that holders plan to sell.',
        ),
      ],
      neutral: [
        (
          'Bitcoin consolidates after last week\'s swings',
          'After big moves, markets often pause and range.',
        ),
        (
          'Weekend-style quiet in crypto markets',
          'Low activity usually means small moves.',
        ),
      ],
      eventName: 'US inflation release',
      eventUp: (
        'US inflation cooler than expected',
        'Hopes of lower rates boost risk assets like crypto.',
      ),
      eventDown: (
        'US inflation hotter than expected',
        'Fears of higher rates weigh on risk assets like crypto.',
      ),
    ),
  );

  static const nova = MarketProfile(
    spec: GameInstruments.nova,
    referencePrice: 148,
    dailyVolatilityPct: 2.2,
    news: NewsBook(
      bullish: [
        (
          'Nova Robotics wins a large factory-automation contract',
          'A big new contract means higher expected revenue.',
        ),
        (
          'Analysts upgrade Nova Robotics after strong orders',
          'Upgrades often bring in new buyers.',
        ),
        (
          'Nova Robotics announces a share buyback',
          'Buybacks reduce the number of shares and signal confidence.',
        ),
      ],
      bearish: [
        (
          'Nova Robotics delays its flagship robot launch',
          'Delays push expected sales further away.',
        ),
        (
          'Nova Robotics\' finance chief departs unexpectedly',
          'Sudden management changes create uncertainty.',
        ),
        (
          'Competitor unveils a cheaper rival robot',
          'More competition can squeeze future profits.',
        ),
      ],
      neutral: [
        (
          'Nova Robotics shares steady ahead of results',
          'Before results, investors often wait on the sidelines.',
        ),
        (
          'No company news; shares follow the wider market',
          'Without news, a stock tends to drift with the market.',
        ),
      ],
      eventName: 'Nova Robotics quarterly results',
      eventUp: (
        'Nova Robotics results beat forecasts',
        'Better-than-expected profits usually lift a share price.',
      ),
      eventDown: (
        'Nova Robotics results miss forecasts',
        'Disappointing profits usually push a share price down.',
      ),
    ),
  );

  static const all = [
    eurUsd,
    gbpUsd,
    usdJpy,
    gold,
    oil,
    us500,
    tech100,
    bitcoin,
    nova,
  ];

  static MarketProfile? bySymbol(String symbol) {
    for (final m in all) {
      if (m.symbol == symbol) return m;
    }
    return null;
  }
}
