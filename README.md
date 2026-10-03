# 📈 Upwiq

**Upwiq** (say "up-wick") is a beginner-friendly app that teaches **how to read any market** (stocks, forex,
crypto, commodities, indices) with bite-sized lessons, interactive charts and
**simulated trades with virtual money**. Android first (Google Play), built with
Flutter. Educational only: no real trading, no financial advice.

- Product & build plan: [`docs/PLAN.md`](docs/PLAN.md)
- Status: **Phase 1 in progress.** Done: simulation engine, chart, lesson player,
  the whole free path: **28 lessons** (Levels 0, 1 and 2, plus the 3 free Trading
  Psychology lessons) with an illustration or chart for each idea, the **Daily
  Challenge** (three new rounds every day), the "Place the trade" exercise, XP, ranks and
  progress saved on the device, dark and light themes (switch in Account), the Upwiq logo and
  app icon from the design system, a "Leave feedback" form in Account, and **the League**:
  a daily trading game with news, realistic execution, weekly leagues and a leaderboard
  (simulated rivals until online leagues launch). See `docs/PLAN.md` §5b.

## Try it on your Android phone

Every push builds a test APK:

1. Open the repo's **Actions** tab → latest **CI** run → download
   **upwiq-test-apk** (a zip containing `app-release.apk`).
2. Copy the APK to your phone and open it. Android will ask you to allow
   installs from that source (Files/Chrome) the first time.

This test build is signed with a development key. The Play Store build will be
signed separately (Phase 2).

## Project layout

| Path | What it is |
|---|---|
| `packages/market_sim/` | Pure-Dart core: candles, instruments, synthetic charts, indicators, position sizing, bid/ask replay engine, daily markets with news, league rules, stats, plan scoring. Fully unit-tested. |
| `lib/chart/` | Custom candlestick chart widget (draggable levels, zones, markers, volume, moving average) |
| `lib/exercises/` | Interactive exercises ("Place the trade") |
| `lib/lessons/` | Lesson player: explain, quiz, "spot it" on a chart, exercise and recap steps; illustrations for the psychology lessons (`mind_art.dart`) |
| `assets/lessons/` | Lesson content as JSON (one file per lesson, validated by `test/lessons_test.dart`) |
| `lib/progress/` | XP and completed lessons, saved on the device |
| `lib/game/` | The League: market picker, trading session, day summary, leaderboard, league account |
| `lib/theme/` | Colours, typography and the vector key visuals for each tab |
| `lib/widgets/` | Shared styled widgets (logo, gradient button, tab hero, badges) |
| `docs/brand/` | Design brief, logo SVGs and app-icon sources from the Upwiq design system (`app-icon-512.png` is the Play Store icon) |
| `assets/fonts/` | Poppins and Inter (SIL Open Font License) |
| `lib/screens/` | Learn path, Practice hub, Account, feedback form |
| `lib/app_info.dart` | App version and the address feedback is sent to |
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
and profile builds `?step=N` jumps to a step for previews. The feedback form is
at `/#/feedback`.

### Feedback

"Leave feedback" in Account collects a star rating, a topic and a message and
opens the user's email app addressed to `feedbackEmail` in `lib/app_info.dart`
(currently `feedback@upwiq.com`, which needs a mailbox or forwarding once the
domain is registered). Nothing is sent until the user presses send there. If no
email app is installed, the text is copied to the clipboard instead.

### Writing a lesson

Add `assets/lessons/<id>.json` and set `id: '<id>'` on the lesson in
`lib/data/curriculum.dart`. Step types: `explain` (text + optional chart, or
an `art` illustration such as `"art": "fearGreed"`; names in `LessonArt`),
`candle_anatomy`, `quiz`, `spot` (tap the `support`/`resistance` zone, the
`highest`/`lowest` candle, the most recent `swingHigh`/`swingLow`, or the
`breakout` candle of a segment labelled `"breakout"`), `exercise` and `recap`.
Charts are synthetic and reproducible: a `seed` plus `trend`/`range` segments.
Quiz options are shown in a fixed mixed-up order, so write the right answer
anywhere (options starting "All of"/"None of" stay last; `"shuffle": false`
keeps the written order). `flutter test` checks every lesson (valid answers,
charts render, spot answers are unambiguous, every illustration is used).

Illustrations are drawn in code in `lib/lessons/art/`, one part file per
level. Add a name to `LessonArt` in `lesson_model.dart`, a description and a
case in `lesson_art.dart`, and the scene in the level's part file.

### Daily Challenge

`packages/market_sim/lib/src/daily_challenge.dart` builds the day's three
rounds from the date: read a chart, size a position, plan a trade. Everyone
gets the same challenge on the same date, the chart task and market rotate
daily, and only the first finished attempt counts (`lib/daily/`). Previews:
`/#/daily`, and in debug/profile builds `/#/daily/trade?date=2026-10-03` opens
that day's trade round.
