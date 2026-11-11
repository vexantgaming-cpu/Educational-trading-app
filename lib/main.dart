import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'daily/daily_challenge_screen.dart';
import 'daily/daily_challenge_store.dart';
import 'data/curriculum.dart';
import 'exercises/place_trade_exercise.dart';
import 'game/game_scope.dart';
import 'game/game_store.dart';
import 'game/league_screen.dart';
import 'game/session_launcher.dart';
import 'game/session_summary_screen.dart';
import 'game/trading_session_screen.dart';
import 'lessons/lesson_player.dart';
import 'progress/progress_scope.dart';
import 'progress/progress_store.dart';
import 'reminders/local_notification_scheduler.dart';
import 'reminders/reminder_scheduler.dart';
import 'reminders/reminder_service.dart';

import 'package:market_sim/market_sim.dart';

import 'screens/feedback_screen.dart';
import 'screens/learn_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/account_screen.dart';
import 'screens/welcome_screen.dart';
import 'settings/settings_store.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  // The trading screens are designed for an upright phone: sideways there is
  // no room left for the chart. (Tablets may still rotate; they have space.)
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final progress = await ProgressStore.load();
  final game = await GameStore.load();
  final settings = await SettingsStore.load();
  final daily = await DailyChallengeStore.load();
  final reminders = ReminderService(
    settings: settings,
    daily: daily,
    scheduler: deviceReminderScheduler(),
  );
  final navigator = GlobalKey<NavigatorState>();
  runApp(
    UpwiqApp(
      progress: progress,
      game: game,
      settings: settings,
      daily: daily,
      reminders: reminders,
      navigatorKey: navigator,
    ),
  );
  // Not awaited: the app is usable before the phone's reminders are booked.
  unawaited(
    reminders.start(onOpen: () => openDailyChallengeFromReminder(navigator)),
  );
}

/// A tapped reminder leads to the Daily Challenge, unless the person is in
/// the middle of something (a lesson, a trading session, a dialog): then
/// the app is simply brought to the front.
void openDailyChallengeFromReminder(GlobalKey<NavigatorState> key) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final navigator = key.currentState;
    if (navigator == null) return;
    var atHome = false;
    navigator.popUntil((route) {
      atHome = route.isFirst;
      return true; // Only looking at the top route; nothing is popped.
    });
    if (atHome) navigator.pushNamed(dailyChallengeRoute);
  });
  WidgetsBinding.instance.ensureVisualUpdate();
}

class UpwiqApp extends StatelessWidget {
  const UpwiqApp({
    super.key,
    required this.progress,
    required this.game,
    required this.settings,
    this.daily,
    this.reminders,
    this.navigatorKey,
  });

  final ProgressStore progress;
  final GameStore game;
  final SettingsStore settings;

  /// Daily Challenge history; in memory when not given (tests, previews).
  final DailyChallengeStore? daily;
  static final _memoryDaily = DailyChallengeStore.memory();

  /// The daily reminder; one that books nothing when not given.
  final ReminderService? reminders;

  /// Lets a tapped reminder open a screen from outside the widget tree.
  final GlobalKey<NavigatorState>? navigatorKey;

  static final _light = buildAppTheme(AppPalette.light);
  static final _dark = buildAppTheme(AppPalette.dark);

  @override
  Widget build(BuildContext context) {
    final daily = this.daily ?? _memoryDaily;
    return ReminderScope(
      service:
          reminders ??
          ReminderService(
            settings: settings,
            daily: daily,
            scheduler: const NoReminders(),
          ),
      child: _stores(daily),
    );
  }

  Widget _stores(DailyChallengeStore daily) {
    return SettingsScope(
      store: settings,
      child: ProgressScope(
        store: progress,
        child: GameScope(
          store: game,
          child: DailyScope(
            store: daily,
            child: ListenableBuilder(
              listenable: settings,
              builder: (context, _) => MaterialApp(
                title: 'Upwiq',
                navigatorKey: navigatorKey,
                debugShowCheckedModeBanner: false,
                theme: _light,
                darkTheme: _dark,
                themeMode: settings.themeMode,
                // Status bar icons follow the theme on screens without an app bar.
                builder: (context, child) =>
                    AnnotatedRegion<SystemUiOverlayStyle>(
                      value: Theme.of(context).brightness == Brightness.dark
                          ? SystemUiOverlayStyle.light
                          : SystemUiOverlayStyle.dark,
                      child: child!,
                    ),
                routes: {
                  '/': (_) => const _Home(),
                  '/practice': (_) => const HomeShell(initialTab: 1),
                  '/league': (_) => const HomeShell(initialTab: 2),
                  '/account': (_) => const HomeShell(initialTab: 3),
                  '/feedback': (_) => const FeedbackScreen(),
                  dailyChallengeRoute: (_) => const DailyChallengeScreen(),
                  placeTradeRoute: (_) =>
                      PlaceTradeExercise(seed: freshPracticeSeed()),
                },
                onGenerateRoute: _generateRoute,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The app's first screen: a short welcome for a newcomer, the tabs for
/// everyone else.
class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final progress = ProgressScope.of(context);
    // Someone who already has progress doesn't need the introduction.
    final newcomer =
        !settings.welcomeSeen &&
        progress.xp == 0 &&
        progress.completedCount == 0;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: newcomer
          ? WelcomeScreen(
              onExplore: settings.setWelcomeSeen,
              onStartLearning: () {
                final navigator = Navigator.of(context);
                final first = nextLesson((_) => false);
                settings.setWelcomeSeen();
                if (first == null) return;
                navigator.push(
                  MaterialPageRoute<bool>(
                    builder: (_) =>
                        LessonPlayerScreen(lessonId: first.lesson.id!),
                  ),
                );
              },
            )
          : const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late var _tab = widget.initialTab;

  /// When the app comes back to the front it may be a new day (new Daily
  /// Challenge, new ranked session) or a new league week.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerResume());
  }

  /// Once per launch: if a ranked session was left unfinished (the phone
  /// closed the app, or it was paused), offer to pick it up.
  Future<void> _offerResume() async {
    if (!mounted) return;
    final saved = GameScope.of(context).rankedSession;
    if (saved == null) return;
    final resume = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resume your ranked session?'),
        content: Text(
          '${describeSavedSession(saved)}. Your trades and orders are saved, '
          'and the market waits for you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resume'),
          ),
        ],
      ),
    );
    if ((resume ?? false) && mounted) await resumeRankedSession(context);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    GameScope.of(context).refresh();
    DailyScope.of(context).refresh();
  }

  static const _screens = [
    LearnScreen(),
    PracticeScreen(),
    LeagueScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _screens[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(Icons.candlestick_chart_outlined),
            selectedIcon: Icon(Icons.candlestick_chart),
            label: 'Practice',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'League',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

/// `/lesson/<id>` opens a lesson directly (deep links, reminders). In
/// non-release builds `?step=N` jumps to a step, and `/play/<SYMBOL>?day=N`
/// opens an unranked session, for previews and QA.
Route<void>? _generateRoute(RouteSettings settings) {
  final uri = Uri.parse(settings.name ?? '');
  if (!kReleaseMode &&
      uri.pathSegments.length == 2 &&
      uri.pathSegments.first == 'play') {
    final market = GameMarkets.bySymbol(uri.pathSegments[1]);
    if (market == null) return null;
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => TradingSessionScreen(
        market: market,
        dayNumber: int.tryParse(uri.queryParameters['day'] ?? '') ?? 272,
        ranked: false,
        startingBalance: LeagueRules.startingBalance,
        onComplete: (result) async => SessionSummaryScreen(result: result),
      ),
    );
  }
  // Previews of a Daily Challenge trade round: /daily/trade?date=2026-10-03
  if (!kReleaseMode && uri.path == '/daily/trade') {
    final date = DateTime.tryParse(uri.queryParameters['date'] ?? '');
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => PlaceTradeExercise(
        challenge: DailyChallenge.forDate(date ?? DateTime.now()).trade,
      ),
    );
  }
  if (uri.pathSegments.length != 2 || uri.pathSegments.first != 'lesson') {
    return null;
  }
  final step = kReleaseMode
      ? 0
      : int.tryParse(uri.queryParameters['step'] ?? '') ?? 0;
  return MaterialPageRoute(
    settings: settings,
    builder: (_) =>
        LessonPlayerScreen(lessonId: uri.pathSegments[1], initialStep: step),
  );
}

/// The bundled fonts are under the SIL Open Font License; list them on the
/// licences page.
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final font in ['Poppins', 'Inter']) {
      final text = await rootBundle.loadString('assets/fonts/$font-OFL.txt');
      yield LicenseEntryWithLineBreaks([font], text);
    }
  });
}
