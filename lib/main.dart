import 'package:flutter/material.dart';

import 'data/curriculum.dart';
import 'exercises/place_trade_exercise.dart';
import 'screens/learn_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/profile_screen.dart';

void main() => runApp(const TradingAcademyApp());

class TradingAcademyApp extends StatelessWidget {
  const TradingAcademyApp({super.key});

  static const _seed = Color(0xFF1E6FD9);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trading Academy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _seed),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      routes: {
        '/': (_) => const HomeShell(),
        placeTradeRoute: (_) => const PlaceTradeExercise(),
      },
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
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Learn'),
          NavigationDestination(icon: Icon(Icons.candlestick_chart_outlined), selectedIcon: Icon(Icons.candlestick_chart), label: 'Practice'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
