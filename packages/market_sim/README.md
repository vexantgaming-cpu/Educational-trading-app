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
| `replay.dart` | Deterministic bar-by-bar replay: market/limit/stop orders, stop-loss, take-profit, costs |
| `stats.dart` | Win rate, expectancy, average R, profit factor, max drawdown |
| `process_score.dart` | Scores *how* a trade was planned (stop, R:R, risk %) with beginner feedback |

Run the tests with `dart test`.
