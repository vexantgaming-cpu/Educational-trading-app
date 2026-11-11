import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'reminder_plan.dart';
import 'reminder_scheduler.dart';

/// The scheduler for this device: real notifications on Android, nothing
/// elsewhere (the web preview; iOS needs its own setup first).
ReminderScheduler deviceReminderScheduler() =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android
    ? LocalNotificationScheduler()
    : const NoReminders();

/// Reminders as Android notifications, booked with the phone's alarm
/// service so they arrive while the app is closed.
///
/// Nothing here may get in the way of using the app: questions to the phone
/// that fail are answered "no", and a booking that fails is reported to
/// `ReminderService`, which shows a note in the reminder sheet.
class LocalNotificationScheduler implements ReminderScheduler {
  LocalNotificationScheduler([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// The status-bar icon: `res/drawable/ic_stat_upwiq.xml`, kept in release
  /// builds by `res/raw/keep.xml`.
  static const _icon = 'ic_stat_upwiq';
  static const _payload = 'daily';

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_reminder',
      'Daily reminder',
      channelDescription: 'One reminder a day to practise',
      category: AndroidNotificationCategory.reminder,
      color: Color(0xFFFFB627),
    ),
  );

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> init({required void Function() onOpen}) async {
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(_icon),
        ),
        onDidReceiveNotificationResponse: (response) {
          if (response.payload == _payload) onOpen();
        },
      );
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  @override
  Future<bool> openedFromReminder() async {
    if (!_ready) return false;
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      return (details?.didNotificationLaunchApp ?? false) &&
          details?.notificationResponse?.payload == _payload;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> allowed() async {
    try {
      return await _android?.areNotificationsEnabled() ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      return await _android?.requestNotificationsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> openSettings() async {
    try {
      await _android?.openAppNotificationSettings();
    } catch (_) {
      // Nothing to fall back to; the sheet tells the person where to look.
    }
  }

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async {
    if (!_ready) throw StateError('Notifications could not be set up');
    await _plugin.cancelAll();
    var booked = 0;
    Object? problem;
    for (final reminder in reminders) {
      try {
        await _plugin.zonedSchedule(
          id: reminder.id,
          title: reminder.title,
          body: reminder.body,
          // The exact moment, so no time-zone database is needed: the phone
          // already turned "19:00 here" into this instant.
          scheduledDate: tz.TZDateTime.from(reminder.when, tz.UTC),
          notificationDetails: _details,
          // "Around this time" is enough for a reminder, and needs no
          // special alarm permission.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: _payload,
        );
        booked++;
      } catch (error) {
        // One can fail harmlessly (its time passed while booking).
        problem = error;
      }
    }
    // None at all means something is wrong with the phone or the setup.
    if (problem != null && booked == 0) throw problem;
  }
}
