# Answers for the Play Console forms

Play Console asks a set of questions about every app (**Policy → App
content**, shown as tasks on the dashboard under "Set up your app"). These
are the truthful answers for Upwiq 1.0. Google renames and reorders these
forms from time to time; if a question isn't listed here, answer it from the
facts in the last section, or ask.

If the app changes (accounts, ads, analytics, purchases, online leagues),
these answers and the privacy policy must change **before** that version is
released. `test/play_store_test.dart` fails when the app starts storing
something new, adds a dependency or asks for a new permission, as a reminder.

## Privacy policy

`https://vexantgaming-cpu.github.io/Educational-trading-app/privacy/`

## App access

**All functionality is available without special access.** There is no
login, and nothing is locked behind a code or a purchase.

## Ads

**No, my app does not contain ads.**

## Content rating (questionnaire)

- Email address: `upwiqapp@gmail.com`.
- Category: **All other app types** (it is an education app, not a game, a
  social app or a browser).
- Violence, fear, sexuality, bad language, drugs, alcohol, tobacco: **No**.
- Gambling, including simulated gambling: **No**. (Practice trades use
  virtual money that can't be bought, won as a prize or cashed out, and
  there are no casino-style games.)
- Can users interact or exchange content with other users? **No.** (The
  leaderboard rivals are simulated.)
- Does the app share the user's location? **No.**
- Does the app allow purchases of digital goods? **No.**

Expected result: the lowest rating (Everyone / PEGI 3 / USK 0).

## Target audience and content

- Target age group: **18 and over** only.
- Could the store listing unintentionally appeal to children? **No.**

Choosing 18+ keeps Upwiq outside Google's Families policy, which is right
for an app about trading.

## Data safety

- Does your app collect or share any of the required user data types?
  **No.**

Why: "collect" means the app sending data off the phone. Upwiq can't: it has
no accounts, ads or analytics and doesn't ask for internet permission (CI
checks this on every build). Progress stays in the app's private storage.

One judgement call: "Leave feedback" hands a draft to the person's own email
app, and they decide whether to send it. Email sent that way is not data
collected by the app, so the answer stays **No**; the privacy policy still
explains what we receive when someone writes to us.

With "No" the form asks nothing more, and the listing shows "No data
collected" and "No data shared with third parties".

## Advertising ID

- Does your app use advertising ID? **No.**

## Financial features

- **My app doesn't provide any financial features.** Upwiq teaches and
  simulates; it offers no real trading, accounts, loans, advice or crypto
  exchange.

## Other declarations

- Government app: **No.**
- News app: **No.**
- Health apps: **none of the health features** apply.

## Pricing and countries

- **Free.** (Google doesn't let a free app become a paid download later;
  that is fine, because Premium is planned as an in-app subscription.)
- Countries: all of Europe (EU and EEA countries, United Kingdom,
  Switzerland and the rest) and the United States. For the closed test,
  also include any country your testers live in.

## App signing

- Accept **Play App Signing** (the default): Google keeps the real signing
  key, and the key GitHub uses is only the *upload* key, which can be
  replaced if it is ever lost.
- Upload key certificate, SHA-256 (also in `upload-key-sha256.txt`):
  `6A:B0:48:78:06:DA:AF:20:45:CC:E2:A2:38:18:03:54:13:E5:4A:26:07:96:13:42:64:8A:C7:1D:AC:87:D2:CA`

## The facts behind these answers

| Question | Upwiq 1.0 |
|---|---|
| Accounts or sign-in | None |
| Internet access | None (no `INTERNET` permission in the release build) |
| Ads, analytics, crash reporting, other companies' SDKs | None |
| Permissions | Show notifications (asked only when the daily reminder is switched on), run at phone start-up (to keep booked reminders), vibrate |
| Data stored | Progress, virtual league account, Daily Challenge history and settings, on the phone only |
| Purchases | None |
| Content made by users | None |
| Other people in the app | None; leaderboard rivals are simulated |
| Real money or real trading | None |
| Minimum Android version | Android 7.0 (API 24); targets Android 16 (API 36) |
