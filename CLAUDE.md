# Upwiq: notes for Claude

Beginner trading-education app (Flutter, Android first). Owner is not a
developer: Claude writes the code, owner tests on their phone via the CI APK.
Read `docs/PLAN.md` §0 for the agreed decisions before making product changes.

Git: work on `main` and push straight to it (owner's choice, 2 Oct 2026).
Every push builds a test APK in CI. Once the app is live on Google Play, switch
to a branch and pull request per batch so `main` only holds released code.

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
The logo and app icon come from the owner's Upwiq design system (a claude.ai
Design System artifact); copies of the SVGs live in `docs/brand/logo/` and
`docs/brand/app-icon/`. In the app the logo is drawn in code
(`lib/widgets/upwiq_logo.dart`, same geometry) so the letters follow the theme;
the Android adaptive icon is `res/drawable/ic_launcher_*.xml` and the legacy and
web PNGs are rendered from `app-icon.svg`. Keep them in sync if the logo changes.

## Things that bite
- Tests that pump the whole app need
  `SharedPreferences.setMockInitialValues({'welcome_seen': true})`, or they get
  the first-run welcome instead of the tabs. Tests that load lesson assets
  need `setUp(rootBundle.clear)`.
- Daily reminder: `flutter_local_notifications` stays on 22.x until the
  project moves to `compileSdk` 37 and AGP 9.1.1 (what 23.x requires). Tests
  use `test/support/fake_reminders.dart`; real delivery can only be checked on
  the owner's phone. Don't add exact-alarm permissions (Play restricts them).
- The app's navigator key is created in `main()` and passed in, not a global:
  a global key would carry the old navigator into a rebuilt app in tests.

## Google Play
- Launch kit and owner's guide: `docs/play-store/`. Keep it current when the
  release process changes.
- The repository is public: never commit a keystore, `key.properties` or a
  password. The upload key lives in the GitHub secrets
  `UPLOAD_KEYSTORE_BASE64` and `UPLOAD_KEYSTORE_PASSWORD`; only its public
  certificate is in `docs/play-store/`. The owner holds the key file.
- CI's "Play Store bundle" job builds the `.aab` on `main` with version code
  = the CI run number, so don't rename `.github/workflows/ci.yml`. The
  visible version is `version:` in `pubspec.yaml` plus `appVersion`.
- Privacy promises are public (`site/privacy/`, the Data safety form in
  `docs/play-store/console-answers.md`): no accounts, no network, no
  analytics. `test/play_store_test.dart` fails when a preference key, a
  dependency or a permission is added, and CI fails if the release build
  asks for `INTERNET`. Update the policy and the form answers first, and tell
  the owner the Play Console form needs changing too.
- Store listing texts are length-checked by the same test. Regenerate the
  graphics with `tool/store_graphics.mjs` after visible UI changes.
