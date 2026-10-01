import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App preferences saved on the device (currently the appearance).
class SettingsStore extends ChangeNotifier {
  SettingsStore._(this._prefs)
    : _themeMode = _parse(_prefs?.getString(_themeKey));

  static const _themeKey = 'theme_mode';

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
