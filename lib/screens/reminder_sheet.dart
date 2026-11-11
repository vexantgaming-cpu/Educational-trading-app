import 'package:flutter/material.dart';

import '../reminders/reminder_service.dart';
import '../settings/settings_store.dart';
import '../theme/app_colors.dart';

/// "19:00" or "7:00 PM", following the phone's 12/24-hour setting.
String reminderTimeText(BuildContext context, int minuteOfDay) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: minuteOfDay ~/ 60, minute: minuteOfDay % 60),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

Future<void> showReminderSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const ReminderSheet(),
    );

/// Switches the daily reminder on and off and picks its time.
class ReminderSheet extends StatefulWidget {
  const ReminderSheet({super.key});

  @override
  State<ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<ReminderSheet> {
  /// Whether the phone lets Upwiq show notifications; null until checked.
  bool? _allowed;
  bool _busy = false;

  /// Coming back from the phone's settings, look again.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    if (!mounted) return;
    final allowed = await ReminderScope.of(context).scheduler.allowed();
    if (mounted) setState(() => _allowed = allowed);
  }

  Future<void> _toggle(bool on) async {
    final service = ReminderScope.of(context);
    setState(() => _busy = true);
    if (on) {
      final granted = await service.enable();
      if (mounted) setState(() => _allowed = granted);
    } else {
      await service.disable();
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _pickTime() async {
    final service = ReminderScope.of(context);
    final minutes = service.settings.reminderMinutes;
    final picked = await showTimePicker(
      context: context,
      helpText: 'Remind me at',
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked != null) await service.setTime(picked.hour * 60 + picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final settings = SettingsScope.of(context);
    final on = settings.reminderOn;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Daily reminder', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'One notification a day to keep your practice going. It is '
              'skipped on days you have already finished the Daily Challenge.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Material(
              color: palette.surfaceHigh,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    key: const Key('reminder-switch'),
                    title: const Text('Remind me every day'),
                    value: on,
                    onChanged: _busy ? null : _toggle,
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    key: const Key('reminder-time'),
                    enabled: on,
                    title: const Text('Time'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          reminderTimeText(context, settings.reminderMinutes),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: on ? palette.gold : palette.textMuted,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, color: palette.textMuted),
                      ],
                    ),
                    onTap: _pickTime,
                  ),
                ],
              ),
            ),
            if (_allowed == false) ...[
              const SizedBox(height: 12),
              _BlockedNote(
                onOpenSettings: () =>
                    ReminderScope.of(context).scheduler.openSettings(),
              ),
            ],
            if (on && ReminderScope.of(context).bookingFailed) ...[
              const SizedBox(height: 12),
              Text(
                'Something went wrong setting the reminder on this phone, so '
                'it may not arrive. Please tell us through Leave feedback.',
                key: const Key('reminder-failed'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.down,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'The reminder arrives around the time you pick; your phone may '
              'delay it by a few minutes to save battery. If you don\'t open '
              'Upwiq for two weeks, reminders stop by themselves.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the phone doesn't let Upwiq show notifications.
class _BlockedNote extends StatelessWidget {
  const _BlockedNote({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: palette.down.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.down.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.notifications_off_outlined, color: palette.down),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Notifications for Upwiq are turned off on this phone, so '
                  'reminders can\'t appear. You can allow them in your '
                  'phone\'s settings.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onOpenSettings,
              child: const Text('Open phone settings'),
            ),
          ),
        ],
      ),
    );
  }
}
