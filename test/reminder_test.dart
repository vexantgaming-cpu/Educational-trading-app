import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_sim/market_sim.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upwiq/daily/daily_challenge_screen.dart';
import 'package:upwiq/daily/daily_challenge_store.dart';
import 'package:upwiq/game/game_store.dart';
import 'package:upwiq/lessons/lesson_player.dart';
import 'package:upwiq/main.dart';
import 'package:upwiq/progress/progress_store.dart';
import 'package:upwiq/reminders/reminder_plan.dart';
import 'package:upwiq/reminders/reminder_service.dart';
import 'package:upwiq/screens/reminder_sheet.dart';
import 'package:upwiq/settings/settings_store.dart';

import 'support/fake_reminders.dart';
import 'support/fonts.dart';

const _result = DailyResult(chart: 80, sizing: 70, plan: 60);

void main() {
  setUpAll(loadAppFonts);
  setUp(rootBundle.clear);

  group('which reminders are booked', () {
    const seven = 19 * 60;
    final morning = DateTime(2026, 11, 11, 9, 30);

    List<PlannedReminder> plan({
      DateTime? now,
      int minuteOfDay = seven,
      bool doneToday = false,
      int streak = 0,
    }) => planReminders(
      now: now ?? morning,
      minuteOfDay: minuteOfDay,
      doneToday: doneToday,
      streak: streak,
    );

    test('one a day for two weeks, starting today when the time is ahead', () {
      final reminders = plan();
      expect(reminders, hasLength(14));
      expect(reminders.first.when, DateTime(2026, 11, 11, 19));
      for (var i = 0; i < reminders.length; i++) {
        expect(reminders[i].when, DateTime(2026, 11, 11 + i, 19));
        expect(reminders[i].when.isAfter(morning), isTrue);
        expect(reminders[i].title, isNotEmpty);
        expect(reminders[i].body, isNotEmpty);
      }
      expect(reminders.map((r) => r.id).toSet(), hasLength(14));
    });

    test('today is skipped once the Daily Challenge is done', () {
      expect(plan(doneToday: true).first.when, DateTime(2026, 11, 12, 19));
    });

    test('today is skipped when the time has passed, or is about to', () {
      final evening = DateTime(2026, 11, 11, 21);
      expect(plan(now: evening).first.when, DateTime(2026, 11, 12, 19));
      final justBefore = DateTime(2026, 11, 11, 18, 59, 30);
      expect(plan(now: justBefore).first.when, DateTime(2026, 11, 12, 19));
      final inTime = DateTime(2026, 11, 11, 18, 55);
      expect(plan(now: inTime).first.when, DateTime(2026, 11, 11, 19));
    });

    test('the time of day holds across month ends and clock changes', () {
      // 25 Oct 2026 and 29 Mar 2026 are clock-change days in Europe,
      // 1 Nov and 8 Mar in the USA: whatever zone the tests run in, every
      // reminder must still read 07:15 on the clock.
      for (final start in [DateTime(2026, 10, 20, 12), DateTime(2026, 3, 1)]) {
        final reminders = plan(now: start, minuteOfDay: 7 * 60 + 15);
        final days = <int>{};
        for (final r in reminders) {
          expect((r.when.hour, r.when.minute), (7, 15));
          days.add(DateTime(r.when.year, r.when.month, r.when.day).day);
        }
        expect(days, hasLength(14), reason: 'one per calendar day');
      }
    });

    test('the streak is mentioned only when it is still true', () {
      // Yesterday done, today still open: today's reminder protects it.
      expect(plan(streak: 4).first.title, 'Keep your 4-day streak going');
      // Today done: tomorrow's reminder protects it.
      expect(
        plan(doneToday: true, streak: 5).first.title,
        'Keep your 5-day streak going',
      );
      // Too late for today and not done: by tomorrow the streak may be gone.
      final late = plan(now: DateTime(2026, 11, 11, 22), streak: 4);
      expect(late.first.title, isNot(contains('streak')));
      // Later reminders are only seen after a missed day.
      for (final r in plan(streak: 4).skip(1)) {
        expect(r.title, isNot(contains('streak')));
      }
      expect(plan().first.title, isNot(contains('streak')));
    });

    test('the last one says reminders are about to stop', () {
      final reminders = plan();
      expect(reminders.last.title, 'Still want these reminders?');
      expect(
        reminders.where((r) => r.title == reminders.last.title),
        hasLength(1),
      );
    });

    test('nothing in the wording promises results or gives advice', () {
      for (final r in [...plan(), ...plan(streak: 3)]) {
        final text = '${r.title} ${r.body}'.toLowerCase();
        for (final word in ['profit', 'earn', 'win', 'buy now', 'signal']) {
          expect(text, isNot(contains(word)), reason: r.toString());
        }
      }
    });
  });

  group('Android wiring', () {
    // The APK is only built by CI, so keep the pieces that must agree by
    // name from drifting apart.
    String read(String path) => File(path).readAsStringSync();

    test('the status-bar icon exists and survives release shrinking', () {
      final scheduler = read('lib/reminders/local_notification_scheduler.dart');
      expect(scheduler, contains("_icon = 'ic_stat_upwiq'"));
      final icon = read('android/app/src/main/res/drawable/ic_stat_upwiq.xml');
      expect(icon, contains('<vector'));
      expect(
        RegExp('Color="#(?!FFFFFFFF|00000000)').hasMatch(icon),
        isFalse,
        reason: 'status-bar icons must be plain white on transparent',
      );
      expect(
        read('android/app/src/main/res/raw/keep.xml'),
        contains('tools:keep="@drawable/ic_stat_upwiq"'),
      );
    });

    test('the manifest lets booked reminders fire and survive a restart', () {
      final manifest = read('android/app/src/main/AndroidManifest.xml');
      const plugin = 'com.dexterous.flutterlocalnotifications';
      expect(manifest, contains('$plugin.ScheduledNotificationReceiver'));
      expect(manifest, contains('$plugin.ScheduledNotificationBootReceiver'));
      expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
      // "Around this time" reminders need no exact-alarm permission, which
      // Google Play restricts.
      expect(manifest, isNot(contains('EXACT_ALARM')));
    });

    test('the build enables what the notifications plugin needs', () {
      final gradle = read('android/app/build.gradle.kts');
      expect(gradle, contains('isCoreLibraryDesugaringEnabled = true'));
      expect(gradle, contains('coreLibraryDesugaring('));
    });
  });

  group('keeping the phone in step', () {
    late DateTime now;
    late SettingsStore settings;
    late DailyChallengeStore daily;
    late FakeReminders phone;
    late ReminderService service;
    var opened = 0;

    Future<void> launch([Map<String, Object> saved = const {}]) async {
      SharedPreferences.setMockInitialValues(saved);
      SettingsStore.reset();
      settings = await SettingsStore.load();
      daily = DailyChallengeStore.memory(clock: () => now);
      service = ReminderService(
        settings: settings,
        daily: daily,
        scheduler: phone,
      );
      await service.start(onOpen: () => opened++);
    }

    setUp(() {
      now = DateTime(2026, 11, 11, 9, 30);
      phone = FakeReminders();
      opened = 0;
    });

    test('off until asked for; leftovers are cleared at start', () async {
      await launch();
      expect(settings.reminderOn, isFalse);
      expect(settings.reminderMinutes, 19 * 60);
      expect(phone.bookings, [isEmpty]);
      expect(phone.asked, 0, reason: 'no permission question out of the blue');
    });

    test('switching on asks for permission, then books two weeks', () async {
      await launch();
      expect(await service.enable(), isTrue);
      expect(phone.asked, 1);
      expect(settings.reminderOn, isTrue);
      expect(phone.booked, hasLength(14));
      expect(phone.booked.first.when, DateTime(2026, 11, 11, 19));
    });

    test('permission refused: stays off, nothing booked', () async {
      await launch();
      phone.permission = false;
      expect(await service.enable(), isFalse);
      expect(settings.reminderOn, isFalse);
      expect(phone.booked, isEmpty);
    });

    test('a new time moves every reminder', () async {
      await launch();
      await service.enable();
      await service.setTime(7 * 60 + 45);
      expect(settings.reminderMinutes, 7 * 60 + 45);
      // 07:45 today has passed (it is 09:30), so tomorrow comes first.
      expect(phone.booked.first.when, DateTime(2026, 11, 12, 7, 45));
      expect(phone.booked, hasLength(14));
    });

    test('finishing today\'s challenge drops today\'s reminder', () async {
      await launch();
      await service.enable();
      expect(phone.booked.first.when.day, 11);
      await daily.record(daily.todayKey, _result);
      await service.sync();
      expect(phone.booked.first.when, DateTime(2026, 11, 12, 19));
      expect(phone.booked.first.title, 'Keep your 1-day streak going');
    });

    test('an unchanged plan is not booked again', () async {
      await launch();
      await service.enable();
      final before = phone.bookings.length;
      daily.refresh(); // The app came back to the front; nothing changed.
      await service.sync();
      expect(phone.bookings, hasLength(before));

      // The next morning it is a new plan: booked again from that day.
      now = DateTime(2026, 11, 12, 8);
      daily.refresh();
      await service.sync();
      expect(phone.bookings, hasLength(before + 1));
      expect(phone.booked.first.when, DateTime(2026, 11, 12, 19));
      expect(phone.booked.last.when, DateTime(2026, 11, 25, 19));
    });

    test('switching off cancels everything', () async {
      await launch();
      await service.enable();
      await service.disable();
      expect(settings.reminderOn, isFalse);
      expect(phone.booked, isEmpty);
    });

    test('the choice and the time are remembered, and rebooked', () async {
      await launch();
      await service.enable();
      await service.setTime(20 * 60 + 30);

      phone = FakeReminders();
      await launch({
        'flutter.reminder_on': true,
        'flutter.reminder_time': 1230,
      });
      expect(settings.reminderOn, isTrue);
      expect(settings.reminderMinutes, 20 * 60 + 30);
      expect(phone.booked.first.when, DateTime(2026, 11, 11, 20, 30));
      expect(phone.asked, 0);
    });

    test('a damaged saved time falls back to 19:00', () async {
      await launch({
        'flutter.reminder_on': true,
        'flutter.reminder_time': 9999,
      });
      expect(settings.reminderMinutes, 19 * 60);
    });

    test('a phone that will not book is noticed, and tried again', () async {
      phone.broken = true;
      await launch();
      expect(await service.enable(), isTrue);
      expect(service.bookingFailed, isTrue);
      expect(phone.booked, isEmpty);

      phone.broken = false;
      daily.refresh(); // E.g. the app comes back to the front.
      await service.sync();
      expect(service.bookingFailed, isFalse);
      expect(phone.booked, hasLength(14));
    });

    test('arriving from a reminder is reported, now or at launch', () async {
      await launch();
      expect(opened, 0);
      phone.tap();
      expect(opened, 1);

      phone = FakeReminders()..launched = true;
      await launch();
      expect(opened, 2);
    });
  });

  group('in the app', () {
    late FakeReminders phone;
    late SettingsStore settings;
    late GlobalKey<NavigatorState> navigator;

    void screen(WidgetTester tester, {double width = 393, double scale = 1}) {
      tester.view.physicalSize = Size(width * 3, 851 * 3);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }

    Future<void> pumpApp(
      WidgetTester tester, {
      Map<String, Object> saved = const {},
      bool finishedToday = false,
    }) async {
      SharedPreferences.setMockInitialValues({'welcome_seen': true, ...saved});
      ProgressStore.reset();
      GameStore.reset();
      SettingsStore.reset();
      final clock = DateTime(2026, 11, 11, 9, 30);
      settings = await SettingsStore.load();
      final daily = DailyChallengeStore.memory(clock: () => clock);
      if (finishedToday) await daily.record(daily.todayKey, _result);
      final service = ReminderService(
        settings: settings,
        daily: daily,
        scheduler: phone,
      );
      await tester.pumpWidget(
        UpwiqApp(
          progress: await ProgressStore.load(),
          game: await GameStore.load(clock: () => clock),
          settings: settings,
          daily: daily,
          reminders: service,
          navigatorKey: navigator = GlobalKey<NavigatorState>(),
        ),
      );
      await service.start(
        onOpen: () => openDailyChallengeFromReminder(navigator),
      );
      await tester.pumpAndSettle();
    }

    Future<void> openSheet(WidgetTester tester) async {
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      final row = find.text('Daily reminder');
      await tester.scrollUntilVisible(row, 200);
      await Scrollable.ensureVisible(tester.element(row), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byType(ReminderSheet), findsOneWidget);
    }

    Finder inSheet(Finder finder) =>
        find.descendant(of: find.byType(ReminderSheet), matching: finder);

    setUp(() => phone = FakeReminders());

    testWidgets('switch it on from Account', (tester) async {
      screen(tester);
      await pumpApp(tester);
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Daily reminder'), 200);
      expect(find.text('Off'), findsOneWidget);
      expect(find.text('Soon'), findsNothing);

      await openSheet(tester);
      final toggle = find.byKey(const Key('reminder-switch'));
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      expect(
        tester.widget<ListTile>(find.byKey(const Key('reminder-time'))).enabled,
        isFalse,
        reason: 'no time to pick while it is off',
      );

      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(phone.asked, 1);
      expect(settings.reminderOn, isTrue);
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
      expect(phone.booked, hasLength(14));
      expect(inSheet(find.text('7:00 PM')), findsOneWidget);
      expect(find.text('Open phone settings'), findsNothing);

      // Close the sheet: the Account row now shows the time.
      Navigator.of(tester.element(find.byType(ReminderSheet))).pop();
      await tester.pumpAndSettle();
      expect(find.text('7:00 PM'), findsOneWidget);
      expect(find.text('Off'), findsNothing);
    });

    testWidgets('pick another time', (tester) async {
      screen(tester);
      await pumpApp(tester, saved: {'reminder_on': true});
      await openSheet(tester);
      await tester.tap(find.byKey(const Key('reminder-time')));
      await tester.pumpAndSettle();
      expect(find.text('Remind me at'), findsOneWidget);

      // Type the time instead of dragging the clock hands.
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '8');
      await tester.enterText(fields.at(1), '15');
      await tester.tap(find.text('AM'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(settings.reminderMinutes, 8 * 60 + 15);
      expect(inSheet(find.text('8:15 AM')), findsOneWidget);
      // 08:15 has passed today (it is 09:30): tomorrow is first.
      expect(phone.booked.first.when, DateTime(2026, 11, 12, 8, 15));
    });

    testWidgets('24-hour phones see 19:00', (tester) async {
      // Set first: the size and text-scale changes below make Flutter
      // re-read the phone's settings.
      tester.platformDispatcher.alwaysUse24HourFormatTestValue = true;
      addTearDown(tester.platformDispatcher.clearAlwaysUse24HourTestValue);
      screen(tester);
      await pumpApp(tester, saved: {'reminder_on': true});
      await openSheet(tester);
      expect(inSheet(find.text('19:00')), findsOneWidget);
      expect(find.text('19:00'), findsNWidgets(2), reason: 'Account row too');
    });

    testWidgets('permission refused: stays off and explains', (tester) async {
      screen(tester);
      phone.permission = false;
      await pumpApp(tester);
      await openSheet(tester);
      await tester.tap(find.byKey(const Key('reminder-switch')));
      await tester.pumpAndSettle();

      expect(settings.reminderOn, isFalse);
      expect(phone.booked, isEmpty);
      expect(find.textContaining('turned off on this phone'), findsOneWidget);
      await tester.tap(find.text('Open phone settings'));
      await tester.pumpAndSettle();
      expect(phone.settingsOpened, 1);

      // Allowed in the phone's settings, then back to the app.
      phone.permission = true;
      for (final state in const [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
      expect(find.textContaining('turned off on this phone'), findsNothing);
    });

    testWidgets('a booking that fails is not hidden', (tester) async {
      screen(tester);
      await pumpApp(tester);
      await openSheet(tester);
      expect(find.byKey(const Key('reminder-failed')), findsNothing);
      phone.broken = true;
      await tester.tap(find.byKey(const Key('reminder-switch')));
      await tester.pumpAndSettle();
      expect(settings.reminderOn, isTrue);
      expect(find.byKey(const Key('reminder-failed')), findsOneWidget);
      expect(find.textContaining('Leave feedback'), findsWidgets);
    });

    testWidgets('a tapped reminder opens the Daily Challenge', (tester) async {
      screen(tester);
      await pumpApp(tester, saved: {'reminder_on': true});
      expect(find.byType(DailyChallengeScreen), findsNothing);
      phone.tap();
      await tester.pumpAndSettle();
      expect(find.byType(DailyChallengeScreen), findsOneWidget);
      expect(
        find.textContaining(
          '#${DailyChallenge.forDate(DateTime(2026, 11, 11)).number}',
        ),
        findsWidgets,
      );

      // A second tap doesn't stack another copy on top.
      phone.tap();
      await tester.pumpAndSettle();
      expect(find.byType(DailyChallengeScreen), findsOneWidget);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.byType(DailyChallengeScreen), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('started by a reminder: straight to the Daily Challenge', (
      tester,
    ) async {
      screen(tester);
      phone.launched = true;
      await pumpApp(tester, saved: {'reminder_on': true});
      expect(find.byType(DailyChallengeScreen), findsOneWidget);
    });

    testWidgets('a reminder never interrupts a lesson', (tester) async {
      screen(tester);
      await pumpApp(tester, saved: {'reminder_on': true});
      Navigator.of(tester.element(find.byType(NavigationBar)))
          .pushNamed('/lesson/L0-01');
      await tester.pumpAndSettle();
      expect(find.byType(LessonPlayerScreen), findsOneWidget);
      phone.tap();
      await tester.pumpAndSettle();
      expect(find.byType(LessonPlayerScreen), findsOneWidget);
      expect(find.byType(DailyChallengeScreen), findsNothing);
    });

    for (final dark in [true, false]) {
      for (final width in [320.0, 393.0]) {
        for (final scale in [1.0, 1.3]) {
          testWidgets(
            'the sheet fits: ${dark ? 'dark' : 'light'}, ${width.toInt()}dp, '
            'text x$scale',
            (tester) async {
              screen(tester, width: width, scale: scale);
              phone.permission = false; // The fullest version of the sheet.
              await pumpApp(
                tester,
                saved: {
                  'reminder_on': true,
                  'theme_mode': dark ? 'dark' : 'light',
                },
              );
              await openSheet(tester);
              expect(find.text('Open phone settings'), findsOneWidget);
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  });
}
