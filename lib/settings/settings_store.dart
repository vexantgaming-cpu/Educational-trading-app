import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App preferences saved on the device: appearance, the daily reminder and
/// whether the first-run welcome has been shown.
class SettingsStore extends ChangeNotifier {
  SettingsStore._(this._prefs)
    : _themeMode = _parse(_prefs?.getString(_themeKey)),
      _welcomeSeen = _prefs?.getBool(_welcomeKey) ?? false,
      _reminderOn = _prefs?.getBool(_reminderOnKey) ?? false,
      _reminderMinutes = _validMinutes(_prefs?.getInt(_reminderTimeKey));

  static const _themeKey = 'theme_mode';
  static const _welcomeKey = 'welcome_seen';
  static const _reminderOnKey = 'reminder_on';
  static const _reminderTimeKey = 'reminder_time';

  /// 19:00: after work or school for most people.
  static const defaultReminderMinutes = 19 * 60;

  static SettingsStore? _instance;

  static Future<SettingsStore> load() async {
    if (_instance != null) return _instance!;
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      prefs = null;
    }
    return _instance = SettingsStore._(prefs);
  }

  @visibleForTesting
  static void reset() => _instance = null;

  final SharedPreferences? _prefs;
  ThemeMode _themeMode;

  /// Dark by default: the brand's signature look.
  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _prefs?.setString(_themeKey, mode.name);
  }

  /// Whether the first-run welcome was finished or skipped.
  bool get welcomeSeen => _welcomeSeen;
  bool _welcomeSeen;

  Future<void> setWelcomeSeen() async {
    if (_welcomeSeen) return;
    _welcomeSeen = true;
    notifyListeners();
    await _prefs?.setBool(_welcomeKey, true);
  }

  /// Whether the daily reminder notification is switched on. Off until the
  /// person asks for it.
  bool get reminderOn => _reminderOn;
  bool _reminderOn;

  /// When the reminder arrives, in minutes after midnight (local time).
  int get reminderMinutes => _reminderMinutes;
  int _reminderMinutes;

  Future<void> setReminder({bool? on, int? minutes}) async {
    final newOn = on ?? _reminderOn;
    final newMinutes = minutes == null
        ? _reminderMinutes
        : _validMinutes(minutes);
    if (newOn == _reminderOn && newMinutes == _reminderMinutes) return;
    _reminderOn = newOn;
    _reminderMinutes = newMinutes;
    notifyListeners();
    await _prefs?.setBool(_reminderOnKey, newOn);
    await _prefs?.setInt(_reminderTimeKey, newMinutes);
  }

  static int _validMinutes(int? value) =>
      value != null && value >= 0 && value < 24 * 60
      ? value
      : defaultReminderMinutes;

  static ThemeMode _parse(String? value) => ThemeMode.values.firstWhere(
    (m) => m.name == value,
    orElse: () => ThemeMode.dark,
  );
}

class SettingsScope extends InheritedNotifier<SettingsStore> {
  const SettingsScope({
    super.key,
    required SettingsStore store,
    required super.child,
  }) : super(notifier: store);

  static SettingsStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
}
