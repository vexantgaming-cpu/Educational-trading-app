import 'package:flutter/widgets.dart';

import 'game_store.dart';

class GameScope extends InheritedNotifier<GameStore> {
  const GameScope({super.key, required GameStore store, required super.child})
    : super(notifier: store);

  static GameStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GameScope>()!.notifier!;
}
