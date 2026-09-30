# 📈 Trading Academy

Beginner-friendly app that teaches **how to read any market** (stocks, forex,
crypto, commodities, indices) with bite-sized lessons, interactive charts and
**simulated trades with virtual money**. Android first (Google Play), built with
Flutter. Educational only: no real trading, no financial advice.

- Product & build plan: [`docs/PLAN.md`](docs/PLAN.md)
- Status: **Phase 1 in progress.** Done: simulation engine, chart, lesson player,
  11 lessons (all of Level 0, "Support and resistance are zones", and the 3 free
  Trading Psychology lessons), the "Place the trade" exercise, XP, ranks and
  progress saved on the device, dark gold/orange visual theme.

## Try it on your Android phone

Every push builds a test APK:

1. Open the repo's **Actions** tab → latest **CI** run → download
   **trading-academy-test-apk** (a zip containing `app-release.apk`).
2. Copy the APK to your phone and open it. Android will ask you to allow
   installs from that source (Files/Chrome) the first time.

This test build is signed with a development key. The Play Store build will be
signed separately (Phase 2).

## Project layout

| Path | What it is |
|---|---|
| `packages/market_sim/` | Pure-Dart core: candles, instruments, synthetic charts, indicators, position sizing, bar-by-bar replay engine, stats, plan scoring. Fully unit-tested. |
| `lib/chart/` | Custom candlestick chart widget (draggable levels, zones, markers, volume, moving average) |
| `lib/exercises/` | Interactive exercises ("Place the trade") |
| `lib/lessons/` | Lesson player: explain, quiz, "spot it" on a chart, exercise and recap steps |
| `assets/lessons/` | Lesson content as JSON (one file per lesson, validated by `test/lessons_test.dart`) |
| `lib/progress/` | XP and completed lessons, saved on the device |
| `lib/theme/` | Colours, typography and the vector key visuals for each tab |
| `lib/widgets/` | Shared styled widgets (gradient button, tab hero, badges) |
| `assets/fonts/` | Poppins and Inter (SIL Open Font License) |
| `lib/screens/` | Learn path, Practice hub, Profile |
| `lib/data/curriculum.dart` | The 56-lesson learning path |
| `docs/PLAN.md` | Product plan, decisions, compliance notes, roadmap |

## Development

```bash
# engine tests
cd packages/market_sim && dart test && cd ../..
# app checks
flutter analyze && flutter test
# run in a browser
flutter run -d chrome
```

Open a lesson directly with `/#/lesson/<id>` (e.g. `/#/lesson/L0-05`). In debug
and profile builds `?step=N` jumps to a step for previews.

### Writing a lesson

Add `assets/lessons/<id>.json` and set `id: '<id>'` on the lesson in
`lib/data/curriculum.dart`. Step types: `explain` (text + optional chart),
`candle_anatomy`, `quiz`, `spot` (tap the support/resistance zone or the
highest/lowest candle), `exercise` and `recap`. Charts are synthetic and
reproducible: a `seed` plus `trend`/`range` segments. `flutter test` checks
every lesson (valid answers, charts render, spot answers are unambiguous).
