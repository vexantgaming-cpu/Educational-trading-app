import 'package:flutter/widgets.dart';

import '../daily/daily_challenge_store.dart';
import '../settings/settings_store.dart';
import 'reminder_plan.dart';
import 'reminder_scheduler.dart';

/// Keeps the reminders booked on the phone in line with the reminder
/// setting and the Daily Challenge: on, off, a new time, a challenge just
/// finished (so today's reminder is dropped), a new day.
class ReminderService {
  ReminderService({
    required this.settings,
    required this.daily,
    required this.scheduler,
  });

  final SettingsStore settings;
  final DailyChallengeStore daily;
  final ReminderScheduler scheduler;

  /// What is booked right now, so an unchanged plan isn't booked twice.
  String? _booked;

  /// Whether the phone refused the last booking. The reminder sheet says so:
  /// a reminder that silently never arrives would be worse.
  bool get bookingFailed => _bookingFailed;
  bool _bookingFailed = false;
  Future<void> _queue = Future.value();

  /// Call once when the app starts. [onOpen] is called when the person
  /// arrives by tapping a reminder, now or later.
  Future<void> start({required void Function() onOpen}) async {
    await scheduler.init(onOpen: onOpen);
    daily.addListener(sync);
    await sync();
    if (await scheduler.openedFromReminder()) onOpen();
  }

  /// Books the reminders that should exist right now. Calls are run one
  /// after another, never interleaved.
  Future<void> sync() => _queue = _queue.then((_) => _sync());

  Future<void> _sync() async {
    final plan = settings.reminderOn
        ? planReminders(
            now: daily.now,
            minuteOfDay: settings.reminderMinutes,
            doneToday: daily.todayResult != null,
            streak: daily.streak,
          )
        : const <PlannedReminder>[];
    final signature = plan.join('\n');
    if (signature == _booked) return;
    try {
      await scheduler.replaceAll(plan);
      _booked = signature;
      _bookingFailed = false;
    } catch (_) {
      // Tried again at the next change; reminders never break the app.
      _bookingFailed = true;
    }
  }

  /// Turns reminders on, asking the phone for permission first. Returns
  /// false, leaving them off, when permission is refused.
  Future<bool> enable() async {
    if (!await scheduler.requestPermission()) return false;
    await settings.setReminder(on: true);
    await sync();
    return true;
  }

  Future<void> disable() async {
    await settings.setReminder(on: false);
    await sync();
  }

  /// Moves the reminder to [minuteOfDay], minutes after midnight.
  Future<void> setTime(int minuteOfDay) async {
    await settings.setReminder(minutes: minuteOfDay);
    await sync();
  }
}

class ReminderScope extends InheritedWidget {
  const ReminderScope({super.key, required this.service, required super.child});

  final ReminderService service;

  static ReminderService of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ReminderScope>()!.service;

  @override
  bool updateShouldNotify(ReminderScope oldWidget) =>
      service != oldWidget.service;
}
