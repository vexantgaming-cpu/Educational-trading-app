import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Completed lessons and XP, saved on the device.
class ProgressStore extends ChangeNotifier {
  ProgressStore._(this._prefs)
    : _completed = {...?_prefs?.getStringList(_completedKey)},
      _xp = _prefs?.getInt(_xpKey) ?? 0;

  static const _completedKey = 'completed_lessons';
  static const _xpKey = 'xp';

  static ProgressStore? _instance;

  /// The shared store; falls back to memory-only if storage is unavailable.
  static Future<ProgressStore> load() async {
    if (_instance != null) return _instance!;
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      prefs = null;
    }
    return _instance = ProgressStore._(prefs);
  }

  @visibleForTesting
  static void reset() => _instance = null;

  final SharedPreferences? _prefs;
  final Set<String> _completed;
  int _xp;

  int get xp => _xp;
  int get completedCount => _completed.length;
  bool isCompleted(String lessonId) => _completed.contains(lessonId);

  /// Records a finished lesson. XP is only awarded the first time.
  Future<int> complete(String lessonId, {required int correctAnswers}) async {
    if (_completed.contains(lessonId)) return 0;
    final earned = 10 + 5 * correctAnswers;
    _completed.add(lessonId);
    _xp += earned;
    notifyListeners();
    await _prefs?.setStringList(_completedKey, _completed.toList());
    await _prefs?.setInt(_xpKey, _xp);
    return earned;
  }
}
