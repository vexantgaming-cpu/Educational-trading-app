import 'reminder_plan.dart';

/// The phone's notification system, as far as reminders need it. The real
/// one is `LocalNotificationScheduler`; tests use a fake.
abstract class ReminderScheduler {
  /// Gets the notification system ready. [onOpen] is called when a reminder
  /// is tapped while the app is running.
  Future<void> init({required void Function() onOpen});

  /// Whether the app was started by tapping a reminder.
  Future<bool> openedFromReminder();

  /// Whether the phone currently lets Upwiq show notifications.
  Future<bool> allowed();

  /// Asks for permission to show notifications (Android 13 and later show
  /// the system's question). Returns whether it was given.
  Future<bool> requestPermission();

  /// Opens the phone's notification settings for Upwiq.
  Future<void> openSettings();

  /// Books [reminders] in place of everything booked before. Throws when
  /// the phone would not book them.
  Future<void> replaceAll(List<PlannedReminder> reminders);
}

/// Does nothing, and says yes: for the web preview and for platforms where
/// reminders are not set up yet.
class NoReminders implements ReminderScheduler {
  const NoReminders();

  @override
  Future<void> init({required void Function() onOpen}) async {}

  @override
  Future<bool> openedFromReminder() async => false;

  @override
  Future<bool> allowed() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> openSettings() async {}

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async {}
}
