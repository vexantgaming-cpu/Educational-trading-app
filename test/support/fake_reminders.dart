import 'package:upwiq/reminders/reminder_plan.dart';
import 'package:upwiq/reminders/reminder_scheduler.dart';

/// Stands in for the phone's notification system and records what the app
/// asks of it.
class FakeReminders implements ReminderScheduler {
  /// What the phone answers when asked whether notifications are allowed.
  bool permission = true;

  /// Whether the app was started by tapping a reminder.
  bool launched = false;

  /// Whether the phone refuses to book anything.
  bool broken = false;

  int asked = 0;
  int settingsOpened = 0;

  /// Every booking made, in order; each replaces the one before.
  final bookings = <List<PlannedReminder>>[];
  List<PlannedReminder> get booked =>
      bookings.isEmpty ? const [] : bookings.last;

  void Function()? _onOpen;

  /// The person taps a reminder while the app is running.
  void tap() => _onOpen!();

  @override
  Future<void> init({required void Function() onOpen}) async =>
      _onOpen = onOpen;

  @override
  Future<bool> openedFromReminder() async => launched;

  @override
  Future<bool> allowed() async => permission;

  @override
  Future<bool> requestPermission() async {
    asked++;
    return permission;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async {
    if (broken) throw StateError('The phone would not book the reminders');
    bookings.add(List.of(reminders));
  }
}
