/// One reminder notification, due at a moment in the phone's local time.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
  });

  final int id;
  final DateTime when;
  final String title;
  final String body;

  @override
  String toString() => '$id @ $when: $title';
}

/// How many days ahead reminders are booked. Every time the app is opened
/// they are booked afresh, so they only run out for someone who has been
/// away this long, and then they stop instead of nagging.
const reminderDaysAhead = 14;

/// A reminder is not booked for a time closer than this: the phone refuses
/// times that have just passed.
const _minimumNotice = Duration(minutes: 1);

/// The reminders to book: one a day at [minuteOfDay] (minutes after local
/// midnight), starting today if that time is still ahead and today's Daily
/// Challenge isn't finished ([doneToday]), otherwise tomorrow.
///
/// [streak] is the current Daily Challenge streak (it counts today when
/// today is done). Only the first reminder can mention it truthfully: any
/// later one is only seen by someone who skipped a day.
List<PlannedReminder> planReminders({
  required DateTime now,
  required int minuteOfDay,
  required bool doneToday,
  required int streak,
  int days = reminderDaysAhead,
}) {
  DateTime at(int dayOffset) => DateTime(
    now.year,
    now.month,
    // Calendar arithmetic, not 24 hours: the time of day survives clock
    // changes.
    now.day + dayOffset,
    minuteOfDay ~/ 60,
    minuteOfDay % 60,
  );

  final today = !doneToday && at(0).isAfter(now.add(_minimumNotice));
  final first = today ? 0 : 1;
  // Tomorrow's streak is only safe if today's challenge is already done.
  final streakHolds = streak > 0 && (today || doneToday);

  return [
    for (var i = 0; i < days; i++)
      () {
        final (title, body) = switch (i) {
          0 when streakHolds => (
            'Keep your $streak-day streak going',
            'Today\'s Daily Challenge is ready: three quick rounds.',
          ),
          _ when i == days - 1 && days > 1 => (
            'Still want these reminders?',
            'This is the last one for now. Open Upwiq and they start again.',
          ),
          _ => _everyday[i % _everyday.length],
        };
        return PlannedReminder(
          id: _firstId + i,
          when: at(first + i),
          title: title,
          body: body,
        );
      }(),
  ];
}

const _firstId = 100;

const _everyday = [
  (
    'Today\'s Daily Challenge is ready',
    'Three quick rounds: read a chart, size a trade, plan a trade.',
  ),
  (
    'A few minutes of practice?',
    'A new chart, a sizing puzzle and a trade to plan are waiting.',
  ),
  (
    'New day, new chart',
    'Can you find today\'s level? The Daily Challenge is ready.',
  ),
  (
    'Practice makes the difference',
    'Today\'s three rounds are waiting. Virtual money, real practice.',
  ),
];
