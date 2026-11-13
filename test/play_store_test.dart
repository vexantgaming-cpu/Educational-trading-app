import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upwiq/app_info.dart';
import 'package:upwiq/game/game_scope.dart';
import 'package:upwiq/game/game_store.dart';
import 'package:upwiq/main.dart';
import 'package:upwiq/progress/progress_scope.dart';
import 'package:upwiq/progress/progress_store.dart';
import 'package:upwiq/screens/account_screen.dart';
import 'package:upwiq/settings/settings_store.dart';
import 'package:upwiq/theme/app_colors.dart';
import 'package:upwiq/theme/app_theme.dart';

import 'support/fonts.dart';

/// What is promised publicly (privacy policy, Play Store listing and forms)
/// has to stay true as the app changes. These tests are the tripwires.
void main() {
  setUpAll(loadAppFonts);

  String read(String path) => File(path).readAsStringSync();

  /// The first ```text block under the "## [heading]" title in listing.md.
  String listingText(String heading) {
    final listing = read('docs/play-store/listing.md');
    final section = listing.split('## $heading').elementAt(1);
    final match = RegExp(r'```text\n([\s\S]*?)\n```').firstMatch(section);
    return match!.group(1)!;
  }

  group('privacy promises', () {
    const update =
        'Update site/privacy/index.html and '
        'docs/play-store/console-answers.md first, then this list.';

    test('the app saves only what the privacy policy describes', () {
      final keys = <String>{};
      final keyPattern = RegExp(
        r"static const _\w*[kK]ey = '([^']+)'",
        multiLine: true,
      );
      for (final file in Directory('lib').listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        for (final m in keyPattern.allMatches(file.readAsStringSync())) {
          keys.add(m.group(1)!);
        }
      }
      expect(
        keys,
        {
          'completed_lessons',
          'xp',
          'league_state_v1',
          'ranked_session_v1',
          'daily_challenge_v1',
          'theme_mode',
          'welcome_seen',
          'reminder_on',
          'reminder_time',
        },
        reason: 'The app stores something new, or stopped storing it. $update',
      );
    });

    test('no new packages that could collect data', () {
      final pubspec = read('pubspec.yaml');
      final section = pubspec
          .split('\ndependencies:')
          .elementAt(1)
          .split('\ndev_dependencies:')
          .first;
      final packages = RegExp(
        r'^  (\w+):',
        multiLine: true,
      ).allMatches(section).map((m) => m.group(1)).toSet();
      expect(
        packages,
        {
          'flutter',
          'cupertino_icons',
          'market_sim',
          'shared_preferences',
          'url_launcher',
          'flutter_local_notifications',
          'timezone',
        },
        reason:
            'A new package can bring data collection or permissions with '
            'it. Check what it does. $update',
      );
    });

    test('the app asks for no internet access and no new permissions', () {
      final manifest = read('android/app/src/main/AndroidManifest.xml');
      final permissions = RegExp(
        r'uses-permission android:name="android\.permission\.(\w+)"',
      ).allMatches(manifest).map((m) => m.group(1)).toSet();
      expect(permissions, {'RECEIVE_BOOT_COMPLETED'}, reason: update);
      // (Notifications and vibrate come from the notifications plugin; CI
      // checks the finished build for INTERNET.)
    });

    test('app code makes no network calls', () {
      final network = RegExp(
        r'''HttpClient|package:http/|WebSocket|NetworkImage|Image\.network|dart:io'\s*show\s*Socket''',
      );
      for (final dir in ['lib', 'packages/market_sim/lib']) {
        for (final file in Directory(dir).listSync(recursive: true)) {
          if (file is! File || !file.path.endsWith('.dart')) continue;
          expect(
            network.hasMatch(file.readAsStringSync()),
            isFalse,
            reason: '${file.path} talks to the network. $update',
          );
        }
      }
    });

    test('the policy page exists where the app and the listing point', () {
      expect(privacyPolicyUrl, '${websiteUrl}privacy/');
      expect(websiteUrl, startsWith('https://'));
      final policy = read('site/privacy/index.html');
      for (final topic in [
        'Learning progress',
        'the League',
        'Daily Challenge',
        'Settings',
        'Reminders',
        'feedback',
        'Children',
        'Clear storage',
      ]) {
        expect(policy, contains(topic));
      }
      for (final doc in ['listing.md', 'console-answers.md', 'README.md']) {
        expect(read('docs/play-store/$doc'), contains(privacyPolicyUrl));
      }
    });

    test('one contact address everywhere', () {
      final policy = read('site/privacy/index.html');
      // Until the owner chooses the address, the policy says so and the
      // website workflow refuses to publish it.
      expect(
        policy.contains(feedbackEmail) || policy.contains('TO-BE-ADDED'),
        isTrue,
        reason:
            'The privacy policy must show the same address the feedback '
            'form sends to ($feedbackEmail).',
      );
      expect(read('.github/workflows/site.yml'), contains('TO-BE-ADDED'));
    });
  });

  group('store listing', () {
    test('texts fit Google Play\'s limits', () {
      expect(listingText('App name').length, lessThanOrEqualTo(30));
      expect(listingText('Short description').length, lessThanOrEqualTo(80));
      expect(listingText('Full description').length, lessThanOrEqualTo(4000));
      expect(listingText('Release notes').length, lessThanOrEqualTo(500));
    });

    test('says what the app is, and what it is not', () {
      final name = listingText('App name');
      final full = listingText('Full description');
      expect(name, startsWith('Upwiq'));
      expect(full, contains('educational app'));
      expect(full, contains('does not provide financial advice'));
      expect(full, contains('virtual money'));
      expect(full, contains('computer rivals'), reason: 'rivals are simulated');
      // Play's metadata policy: no price, ranking or hype words, and
      // nothing that promises an outcome.
      final all = '$name ${listingText('Short description')} $full'
          .toLowerCase();
      for (final phrase in [
        'best app',
        'best trading',
        'the best',
        '#1',
        'number one',
        'top-rated',
        'guarantee',
        'get rich',
        'profit',
        'earn money',
      ]) {
        expect(
          all,
          isNot(contains(phrase)),
          reason: '"$phrase" in the listing',
        );
      }
      // Play does not allow price words in the app's name.
      expect(name.toLowerCase(), isNot(contains('free')));
    });

    test('the lesson count in the listing is the real one', () {
      final lessons = Directory('assets/lessons')
          .listSync()
          .where((f) => f.path.endsWith('.json'))
          .length;
      expect(listingText('Full description'), contains('$lessons free'));
      expect(listingText('Release notes'), contains('$lessons free'));
    });

    test('graphics are the sizes Google Play asks for', () {
      (int, int) pngSize(String path) {
        final b = File(path).readAsBytesSync();
        int be(int o) => b[o] << 24 | b[o + 1] << 16 | b[o + 2] << 8 | b[o + 3];
        expect(b.sublist(1, 4), 'PNG'.codeUnits, reason: '$path is a PNG');
        return (be(16), be(20));
      }

      /// PNG colour type 2 = RGB without transparency, which Play requires
      /// for the feature graphic and screenshots.
      int colourType(String path) => File(path).readAsBytesSync()[25];

      const dir = 'docs/play-store/graphics';
      expect(pngSize('docs/brand/app-icon/app-icon-512.png'), (512, 512));
      expect(pngSize('$dir/feature-graphic.png'), (1024, 500));
      expect(colourType('$dir/feature-graphic.png'), 2);
      final shots =
          Directory(dir)
              .listSync()
              .map((f) => f.path)
              .where((p) => RegExp(r'screenshot-\d\.png$').hasMatch(p))
              .toList()
            ..sort();
      expect(shots.length, inInclusiveRange(4, 8));
      for (final shot in shots) {
        expect(pngSize(shot), (1080, 1920), reason: shot);
        expect(colourType(shot), 2, reason: '$shot must not have transparency');
        expect(
          File(shot).lengthSync(),
          lessThan(8 * 1024 * 1024),
          reason: 'Play limit is 8 MB',
        );
      }
    });
  });

  group('release signing', () {
    test('no signing key or password is in the repository', () {
      final tracked = Process.runSync('git', ['ls-files']).stdout as String;
      for (final path in tracked.split('\n')) {
        expect(
          RegExp(r'(\.p12|\.jks|\.keystore|key\.properties)$').hasMatch(path),
          isFalse,
          reason: '$path must never be committed: the repository is public.',
        );
      }
      final ignore = read('android/.gitignore');
      for (final pattern in [
        'key.properties',
        '*.jks',
        '*.keystore',
        '*.p12',
      ]) {
        expect(ignore, contains(pattern));
      }
      // The public certificate is fine, a private key is not.
      expect(
        read('docs/play-store/upload-certificate.pem'),
        isNot(contains('PRIVATE KEY')),
      );
    });

    test(
      'the Play bundle uses the upload key, the test APK does not need it',
      () {
        final gradle = read('android/app/build.gradle.kts');
        expect(gradle, contains('rootProject.file("key.properties")'));
        expect(gradle, contains('if (hasUploadKey) "upload" else "debug"'));
        final ci = read('.github/workflows/ci.yml');
        expect(
          ci,
          contains('flutter build appbundle --release --build-number='),
        );
        expect(ci, contains('secrets.UPLOAD_KEYSTORE_BASE64'));
        expect(ci, contains('docs/play-store/upload-key-sha256.txt'));
        expect(
          read('docs/play-store/upload-key-sha256.txt').trim(),
          matches(RegExp(r'^([0-9A-F]{2}:){31}[0-9A-F]{2}$')),
        );
      },
    );
  });

  group('privacy policy link in the app', () {
    Future<void> pumpAccount(
      WidgetTester tester, {
      required Future<bool> Function(Uri) openLink,
    }) async {
      tester.view.physicalSize = const Size(393 * 3, 851 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({'welcome_seen': true});
      ProgressStore.reset();
      GameStore.reset();
      SettingsStore.reset();
      final settings = await SettingsStore.load();
      await tester.pumpWidget(
        SettingsScope(
          store: settings,
          child: ProgressScope(
            store: await ProgressStore.load(),
            child: GameScope(
              store: await GameStore.load(),
              child: MaterialApp(
                theme: buildAppTheme(AppPalette.dark),
                home: Scaffold(body: AccountScreen(openLink: openLink)),
              ),
            ),
          ),
        ),
      );
      final row = find.text('Privacy policy');
      await tester.scrollUntilVisible(row, 200);
      await Scrollable.ensureVisible(tester.element(row), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
    }

    testWidgets('opens the policy in the browser', (tester) async {
      final opened = <Uri>[];
      await pumpAccount(
        tester,
        openLink: (uri) async {
          opened.add(uri);
          return true;
        },
      );
      expect(opened, [Uri.parse(privacyPolicyUrl)]);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('no browser: shows the address to copy', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpAccount(tester, openLink: (_) async => false);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(privacyPolicyUrl), findsOneWidget);
      await tester.tap(find.text('Copy link'));
      await tester.pumpAndSettle();
      expect(copied, privacyPolicyUrl);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('is in the real app\'s Account tab', (tester) async {
      tester.view.physicalSize = const Size(393 * 3, 851 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({'welcome_seen': true});
      ProgressStore.reset();
      GameStore.reset();
      SettingsStore.reset();
      await tester.pumpWidget(
        UpwiqApp(
          progress: await ProgressStore.load(),
          game: await GameStore.load(),
          settings: await SettingsStore.load(),
        ),
      );
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Privacy policy'), 200);
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });
  });
}
