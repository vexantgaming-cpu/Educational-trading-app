import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/curriculum.dart';
import 'exercises/place_trade_exercise.dart';
import 'lessons/lesson_player.dart';
import 'progress/progress_scope.dart';
import 'progress/progress_store.dart';
import 'screens/learn_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/account_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  final progress = await ProgressStore.load();
  runApp(TradingAcademyApp(progress: progress));
}

class TradingAcademyApp extends StatelessWidget {
  const TradingAcademyApp({super.key, required this.progress});

  final ProgressStore progress;

  @override
  Widget build(BuildContext context) {
    return ProgressScope(
      store: progress,
      child: MaterialApp(
        title: 'Trading Academy',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routes: {
          '/': (_) => const HomeShell(),
          '/practice': (_) => const HomeShell(initialTab: 1),
          '/account': (_) => const HomeShell(initialTab: 2),
          placeTradeRoute: (_) => const PlaceTradeExercise(),
        },
        onGenerateRoute: _lessonRoute,
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

  static const _screens = [LearnScreen(), PracticeScreen(), AccountScreen()];

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
/// non-release builds `?step=N` jumps to a step, for previews and QA.
Route<void>? _lessonRoute(RouteSettings settings) {
  final uri = Uri.parse(settings.name ?? '');
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
