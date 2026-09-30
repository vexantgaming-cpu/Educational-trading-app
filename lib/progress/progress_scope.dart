import 'package:flutter/widgets.dart';

import 'progress_store.dart';

/// Makes the [ProgressStore] available to the widget tree and rebuilds
/// dependents when progress changes.
class ProgressScope extends InheritedNotifier<ProgressStore> {
  const ProgressScope({
    super.key,
    required ProgressStore store,
    required super.child,
  }) : super(notifier: store);

  static ProgressStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ProgressScope>()!.notifier!;
}
