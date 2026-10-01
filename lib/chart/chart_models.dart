import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A horizontal level drawn across the chart (entry, stop-loss, target...).
class PriceLine {
  const PriceLine({
    required this.id,
    required this.price,
    required this.color,
    required this.label,
    this.draggable = false,
    this.dashed = false,
  });

  final String id;
  final double price;
  final Color color;
  final String label;
  final bool draggable;
  final bool dashed;
}

/// A shaded price band, e.g. a support or resistance zone.
class ChartZone {
  const ChartZone({
    required this.low,
    required this.high,
    required this.fromIndex,
    required this.toIndex,
    required this.color,
    this.label,
  });

  final double low;
  final double high;
  final int fromIndex;
  final int toIndex;
  final Color color;
  final String? label;
}

/// A small arrow pointing at a bar (entry and exit points).
class ChartMarker {
  const ChartMarker({
    required this.index,
    required this.price,
    required this.pointsUp,
    required this.color,
  });

  final int index;
  final double price;
  final bool pointsUp;
  final Color color;
}

class ChartColors {
  const ChartColors({
    required this.up,
    required this.down,
    required this.grid,
    required this.text,
    required this.movingAverage,
    required this.background,
  });

  factory ChartColors.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ChartColors(
      up: context.palette.up,
      down: context.palette.down,
      grid: scheme.outlineVariant.withValues(alpha: 0.55),
      text: scheme.onSurfaceVariant,
      movingAverage: context.palette.gold,
      background: scheme.surface,
    );
  }

  final Color up;
  final Color down;
  final Color grid;
  final Color text;
  final Color movingAverage;
  final Color background;
}
