# Upwiq: notes for Claude

Beginner trading-education app (Flutter, Android first). Owner is not a
developer: Claude writes the code, owner tests on their phone via the CI APK.
Read `docs/PLAN.md` §0 for the agreed decisions before making product changes.

## Non-negotiables (product & compliance)
- Education only. No signals, no "buy X now", no personalised recommendations,
  no promotion of any specific broker, exchange or coin.
- Virtual money only; it can never be bought or withdrawn. Premium sells content
  and tools, never balance.
- Score *process* (stop, reward:risk, risk %), not P&L. Never shame losses.
- Risk-management lessons stay free.
- Markets: Europe + USA. Keep copy neutral and accurate; lessons carry the
  "educational, not financial advice" note.

## Code layout & conventions
- `packages/market_sim`: pure Dart, no Flutter imports. All trading maths lives
  here and is unit-tested. Deterministic: same seed/actions → same result.
- `lib/`: Flutter UI. Charts are drawn by our own `CandleChart` (CustomPainter).
- User-facing strings are plain English, short sentences, no jargon without
  explanation.

## Verify before pushing
```bash
cd packages/market_sim && dart analyze && dart test && cd ../..
flutter analyze && flutter test
flutter build web --release --no-web-resources-cdn   # then screenshot with Playwright
```
Flutter SDK is not preinstalled in cloud sessions: download the stable tarball
from storage.googleapis.com/flutter_infra_release into /opt/sdk/flutter.
The Android SDK host is blocked in the sandbox, so APK builds run in GitHub Actions.
The app is called **Upwiq** (say "up-wick"); the Android `applicationId` is
`com.upwiq.app` (agreed with the owner). It is permanent once published on
Play, so don't change it. Brand and design brief: `docs/brand/UPWIQ_DESIGN_BRIEF.md`.
