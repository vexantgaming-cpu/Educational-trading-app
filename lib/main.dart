import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/curriculum.dart';
import 'exercises/place_trade_exercise.dart';
import 'game/game_scope.dart';
import 'game/game_store.dart';
import 'game/league_screen.dart';
import 'game/session_summary_screen.dart';
import 'game/trading_session_screen.dart';
import 'lessons/lesson_player.dart';
import 'progress/progress_scope.dart';
import 'progress/progress_store.dart';

import 'package:market_sim/market_sim.dart';

import 'screens/feedback_screen.dart';
import 'screens/learn_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/account_screen.dart';
import 'settings/settings_store.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  final progress = await ProgressStore.load();
  final game = await GameStore.load();
  final settings = await SettingsStore.load();
  runApp(UpwiqApp(progress: progress, game: game, settings: settings));
}

class UpwiqApp extends StatelessWidget {
  const UpwiqApp({
    super.key,
    required this.progress,
    required this.game,
    required this.settings,
  });

  final ProgressStore progress;
  final GameStore game;
  final SettingsStore settings;

  static final _light = buildAppTheme(AppPalette.light);
  static final _dark = buildAppTheme(AppPalette.dark);

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      store: settings,
      child: ProgressScope(
        store: progress,
        child: GameScope(
          store: game,
          child: ListenableBuilder(
            listenable: settings,
            builder: (context, _) => MaterialApp(
              title: 'Upwiq',
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
                '/': (_) => const HomeShell(),
                '/practice': (_) => const HomeShell(initialTab: 1),
                '/league': (_) => const HomeShell(initialTab: 2),
                '/account': (_) => const HomeShell(initialTab: 3),
                '/feedback': (_) => const FeedbackScreen(),
                placeTradeRoute: (_) => const PlaceTradeExercise(),
              },
              onGenerateRoute: _generateRoute,
            ),
          ),
        ),
      ),
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
