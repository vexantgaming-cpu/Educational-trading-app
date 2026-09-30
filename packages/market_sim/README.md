# market_sim

Pure-Dart core of Trading Academy. No Flutter dependency, so it runs in unit
tests, on-device and (later) on a server for challenge re-simulation.

| File | What it does |
|---|---|
| `candle.dart` | OHLCV bar model |
| `instrument.dart` | Instrument specs (tick size, contract size, spread, leverage) + presets for stocks, FX, crypto, gold, indices |
| `rng.dart` | Seeded PRNG (Mulberry32) that gives identical sequences on the Dart VM and on the web |
| `generator.dart` | Synthetic scenario generator: trends, ranges and breakouts with answer-key annotations |
| `indicators.dart` | SMA, EMA, RSI, ATR |
| `swings.dart` | Swing high/low detection and trend classification (HH/HL, LH/LL) |
| `risk.dart` | Risk:reward and position sizing |
| `replay.dart` | Deterministic bar-by-bar replay with broker-style execution: bid/ask fills, per-candle spreads, market/limit/stop orders, stop-loss, take-profit, commission, margin stop-out, negative balance protection, USD conversion |
| `trading_day.dart` | A day of trading for one market: yesterday's candles, a 08:00–16:00 session, morning news with a bias, a 13:30 release, wider spreads around news |
| `markets.dart` | The 9 game markets with realistic specs and their (simulated) news |
| `league.dart` | Leagues, weekly seasons, simulated rivals, ranking, promotion/demotion |
| `stats.dart` | Win rate, expectancy, average R, profit factor, max drawdown |
| `process_score.dart` | Scores *how* a trade was planned (stop, R:R, risk %) with beginner feedback |

Run the tests with `dart test`. `dart run tool/calibrate_days.dart` prints how
realistic the simulated days are (range vs target volatility, how often the news
bias plays out).
