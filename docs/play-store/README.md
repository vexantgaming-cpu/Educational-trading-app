# Publishing Upwiq on Google Play

Everything needed to get the free version onto Google Play, in order. Steps
marked **You** need your accounts; the rest is already done in the
repository.

| In this folder | What it is |
|---|---|
| `listing.md` | Texts to paste into the store listing |
| `console-answers.md` | Answers for Play Console's forms (data safety, content rating, …) |
| `graphics/` | Feature graphic and phone screenshots |
| `upload-certificate.pem`, `upload-key-sha256.txt` | The *public* half of the upload key (safe to publish) |

## What is already set up

- **Signed Play bundle.** Every push to `main` builds `upwiq-play-bundle`
  (an `.aab` file, the format Google Play takes) in GitHub Actions, signed
  with the upload key and with a version code that goes up by itself.
- **Test APK** as before (`upwiq-test-apk`), for installing straight onto a
  phone.
- **Website and privacy policy** in `site/`, published by the "Website"
  workflow.
- **Privacy policy link** in the app: Account → Privacy policy.

## Step 1. Contact details (done)

- ✅ **Contact email:** `upwiqapp@gmail.com`. It is public: it appears in the
  privacy policy, the store listing and the app's feedback form. Check that
  mailbox regularly, and use the same address as the developer contact in
  Play Console.
- ✅ **Publisher name:** the privacy policy says Upwiq is published "by an
  independent developer under the name Upwiq" (owner's choice, 13 Nov 2026:
  no personal name, and no registered business yet).

Two things to know about that choice:

- Data protection law (GDPR) expects the publisher to be identifiable. A
  brand name with a working contact address is common for solo developers
  and the app collects nothing, so the risk is small, but it is not the
  strictest reading of the rule. When a business is registered, put its
  name in the policy (ask Claude). This is not legal advice.
- **Google Play decides what it shows about you, whatever the policy says.**
  Google's help pages say a personal account shows the *developer name* you
  choose (this can be "Upwiq"), your *legal name*, your *country* and your
  contact email. Once the app earns money (Premium), EU rules treat you as a
  "trader" and Google also shows an address and phone number to people in
  the EU. Before you pay for the account, look at the **Developer profile**
  preview during sign-up: it shows exactly what will be public. The way to
  keep a personal name off Google Play is an **organization** account, which
  needs a registered business (and a D-U-N-S number).

## Step 2. Give GitHub the upload key (You, 5 minutes)

Claude sent two private files: `upwiq-upload-key.p12` and
`upwiq-github-secrets.txt`.

1. Save both somewhere safe (a password manager is ideal). Never put them in
   this repository; it is public.
2. Open the repository's **Settings → Secrets and variables → Actions →
   New repository secret** and add the two secrets exactly as the text file
   describes: `UPLOAD_KEYSTORE_PASSWORD` and `UPLOAD_KEYSTORE_BASE64`.
3. Open **Actions → CI → Run workflow** (branch `main`). When it finishes,
   the run's page lists **upwiq-play-bundle** under Artifacts.

## Step 3. Switch on the website (You, 2 minutes)

1. Repository **Settings → Pages → Build and deployment → Source: GitHub
   Actions**.
2. **Actions → Website → Run workflow**.
3. Check that
   <https://vexantgaming-cpu.github.io/Educational-trading-app/privacy/>
   opens.

## Step 4. Create the Play developer account (You)

1. Go to <https://play.google.com/console/signup> and choose a **personal**
   account.
2. Pay the one-time US$25 fee and complete identity verification (an ID
   document; Google may also ask you to verify with the Play Console app on
   an Android phone). Approval can take a few days.

## Step 5. Create the app (You)

Play Console → **Create app**:

- App name: from `listing.md`
- Default language: English (United States)
- App or game: App · Free or paid: Free
- Accept the declarations.

Then work through the dashboard's set-up tasks using `console-answers.md`,
and the store listing using `listing.md` and `graphics/`.

## Step 6. Closed test: 12 testers for 14 days (You)

Google requires new personal accounts to run a closed test before an app
can go public: at least **12 testers opted in for 14 days in a row**.

1. **Test and release → Testing → Closed testing** → create a track.
2. **Testers:** create an email list with the Google-account addresses of
   at least 12 people (a few spare is wise: if someone leaves, the count
   must not fall below 12).
3. **Countries:** include every tester's country.
4. **Create new release:** upload `app-release.aab` from the
   `upwiq-play-bundle` artifact (download the zip from the latest CI run and
   unzip it). On the first upload, accept **Play App Signing**.
5. Paste the release notes from `listing.md`, save, and send the release
   for review.
6. When it is approved, copy the **opt-in link** from the track's Testers
   tab and send it to your testers. Each must open it, accept, and install
   the app from Google Play. The 14 days count from when 12 have opted in.

Ask testers to actually use the app and send feedback (Account → Leave
feedback): Google asks about the test when you apply for production.

Before installing the Play version on a phone that has the test APK,
uninstall the test APK first (they are signed with different keys). Its
saved progress is lost.

## Step 7. Go to production (You)

After 14 days: dashboard → **Apply for production access**, answer the
questions about your test, and wait for approval. Then **Production →
Create new release**, add the same or a newer `.aab`, choose the countries
(Europe and the USA), and roll out.

## Later releases

Push to `main`, download the newest `upwiq-play-bundle`, and upload it as a
new release. The version code rises with every build; to change the version
people see (1.0.0), ask Claude to bump it in `pubspec.yaml` and
`lib/app_info.dart`.

## Updating the screenshots

When the app's look changes, ask Claude to regenerate the graphics:
`tool/store_graphics.mjs` takes the screens from the running app and writes
`graphics/screenshot-1.png` … `-8.png` and `graphics/feature-graphic.png`.
The captions are at the top of that script.

## If something goes wrong

- **CI says "No Play bundle".** The two secrets are missing or misnamed
  (Step 2).
- **"Not signed with the upload key".** The pasted `UPLOAD_KEYSTORE_BASE64`
  was cut short; paste the whole line again.
- **Play rejects the upload as signed with the wrong key.** Compare Play
  Console → App integrity → Upload key certificate with
  `upload-key-sha256.txt`.
- **Upload key lost or leaked.** Play Console → App integrity → request an
  upload key reset; ask Claude for a new key.
