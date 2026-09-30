import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'data/curriculum.dart';
import 'exercises/place_trade_exercise.dart';
import 'lessons/lesson_player.dart';
import 'progress/progress_scope.dart';
import 'progress/progress_store.dart';
import 'screens/learn_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final progress = await ProgressStore.load();
  runApp(TradingAcademyApp(progress: progress));
}

class TradingAcademyApp extends StatelessWidget {
  const TradingAcademyApp({super.key, required this.progress});

  final ProgressStore progress;

  static const _seed = Color(0xFF1E6FD9);

  @override
  Widget build(BuildContext context) {
    return ProgressScope(
      store: progress,
      child: MaterialApp(
        title: 'Trading Academy',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: _seed),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: _seed,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        routes: {
          '/': (_) => const HomeShell(),
          placeTradeRoute: (_) => const PlaceTradeExercise(),
        },
        onGenerateRoute: _lessonRoute,
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _tab = 0;

  static const _screens = [LearnScreen(), PracticeScreen(), ProfileScreen()];

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
            label: 'Profile',
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
