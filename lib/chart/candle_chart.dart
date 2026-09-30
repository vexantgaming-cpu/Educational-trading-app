import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:market_sim/market_sim.dart';

import 'chart_models.dart';

/// Interactive candlestick chart used by lessons and exercises.
///
/// Shows the last [visibleBars] candles plus [futureSlots] empty slots on the
/// right (room for price to move into during a replay). Draggable
/// [PriceLine]s report moves through [onLineDragged]; taps report the bar and
/// price under the finger through [onTapPrice] (used by "Spot it" exercises).
class CandleChart extends StatefulWidget {
  const CandleChart({
    super.key,
    required this.candles,
    this.visibleBars = 70,
    this.futureSlots = 10,
    this.lines = const [],
    this.zones = const [],
    this.markers = const [],
    this.movingAverage,
    this.priceDecimals = 2,
    this.showVolume = true,
    this.onLineDragged,
    this.onTapPrice,
  });

  final List<Candle> candles;
  final int visibleBars;
  final int futureSlots;
  final List<PriceLine> lines;
  final List<ChartZone> zones;
  final List<ChartMarker> markers;

  /// Values aligned with [candles]; nulls are skipped.
  final List<double?>? movingAverage;
  final int priceDecimals;
  final bool showVolume;
  final void Function(String lineId, double price)? onLineDragged;
  final void Function(int index, double price)? onTapPrice;

  @override
  State<CandleChart> createState() => _CandleChartState();
}

class _CandleChartState extends State<CandleChart> {
  String? _draggingId;
  ChartGeometry? _geometry;

  /// Price range held still while a line is dragged, so the axis doesn't
  /// rescale under the finger.
  (double, double)? _frozenRange;

  @override
  Widget build(BuildContext context) {
    final colors = ChartColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        var geometry = ChartGeometry.fit(
          size: constraints.biggest,
          candles: widget.candles,
          visibleBars: widget.visibleBars,
          futureSlots: widget.futureSlots,
          showVolume: widget.showVolume,
          fixedLines: [for (final l in widget.lines) l.price],
        );
        final frozen = _frozenRange;
        if (_draggingId != null && frozen != null) {
          geometry = ChartGeometry(
            size: geometry.size,
            startIndex: geometry.startIndex,
            slots: geometry.slots,
            minPrice: frozen.$1,
            maxPrice: frozen.$2,
            showVolume: geometry.showVolume,
          );
        }
        _geometry = geometry;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: widget.onTapPrice == null
              ? null
              : (details) {
                  final p = details.localPosition;
                  if (p.dx > geometry.plotWidth || p.dy > geometry.plotHeight) {
                    return;
                  }
                  widget.onTapPrice!(
                    geometry.indexAt(p.dx),
                    geometry.priceAt(p.dy),
                  );
                },
          onVerticalDragStart: widget.onLineDragged == null ? null : _dragStart,
          onVerticalDragUpdate: widget.onLineDragged == null
              ? null
              : _dragUpdate,
          onVerticalDragEnd: (_) => setState(() {
            _draggingId = null;
            _frozenRange = null;
          }),
          child: CustomPaint(
            size: constraints.biggest,
            painter: _CandlePainter(
              geometry: geometry,
              candles: widget.candles,
              lines: widget.lines,
              zones: widget.zones,
              markers: widget.markers,
              movingAverage: widget.movingAverage,
              decimals: widget.priceDecimals,
              colors: colors,
              activeLineId: _draggingId,
            ),
          ),
        );
      },
    );
  }

  void _dragStart(DragStartDetails details) {
    final geometry = _geometry;
    if (geometry == null) return;
    PriceLine? nearest;
    var best = 28.0; // finger-friendly grab distance in pixels
    for (final line in widget.lines.where((l) => l.draggable)) {
      final distance = (geometry.y(line.price) - details.localPosition.dy)
          .abs();
      if (distance < best) {
        best = distance;
        nearest = line;
      }
    }
    setState(() {
      _draggingId = nearest?.id;
      _frozenRange = nearest == null
          ? null
          : (geometry.minPrice, geometry.maxPrice);
    });
  }

  void _dragUpdate(DragUpdateDetails details) {
    final geometry = _geometry;
    final id = _draggingId;
    if (geometry == null || id == null) return;
    final dy = details.localPosition.dy.clamp(0.0, geometry.plotHeight);
    widget.onLineDragged!(id, geometry.priceAt(dy));
  }
}

/// Maps bars and prices to pixels. Public so tests and exercises can reason
/// about positions.
class ChartGeometry {
  ChartGeometry({
    required this.size,
    required this.startIndex,
    required this.slots,
    required this.minPrice,
    required this.maxPrice,
    required this.showVolume,
  });

  factory ChartGeometry.fit({
    required Size size,
    required List<Candle> candles,
    required int visibleBars,
    required int futureSlots,
    required bool showVolume,
    List<double> fixedLines = const [],
  }) {
    final start = math.max(0, candles.length - visibleBars);
    var low = double.infinity, high = -double.infinity;
    for (var i = start; i < candles.length; i++) {
      low = math.min(low, candles[i].low);
      high = math.max(high, candles[i].high);
    }
    for (final p in fixedLines) {
      low = math.min(low, p);
      high = math.max(high, p);
    }
    if (!low.isFinite) {
      low = 0;
      high = 1;
    }
    // Headroom so price (and dragged levels) can move beyond recent extremes.
    final pad = math.max((high - low) * 0.18, high.abs() * 0.001);
    return ChartGeometry(
      size: size,
      startIndex: start,
      slots: visibleBars + futureSlots,
      minPrice: low - pad,
      maxPrice: high + pad,
      showVolume: showVolume,
    );
  }

  static const axisWidth = 62.0;

  final Size size;
  final int startIndex;
  final int slots;
  final double minPrice;
  final double maxPrice;
  final bool showVolume;

  double get plotWidth => math.max(0, size.width - axisWidth);
  double get volumeHeight => showVolume ? size.height * 0.15 : 0;
  double get plotHeight => math.max(1, size.height - volumeHeight - 6);
  double get slotWidth => plotWidth / slots;

  double x(int index) => (index - startIndex + 0.5) * slotWidth;
  double y(double price) =>
      (maxPrice - price) / (maxPrice - minPrice) * plotHeight;
  double priceAt(double dy) =>
      maxPrice - dy / plotHeight * (maxPrice - minPrice);
  int indexAt(double dx) => startIndex + (dx / slotWidth).floor();
}

class _CandlePainter extends CustomPainter {
  _CandlePainter({
    required this.geometry,
    required this.candles,
    required this.lines,
    required this.zones,
    required this.markers,
    required this.movingAverage,
    required this.decimals,
    required this.colors,
    required this.activeLineId,
  });

  final ChartGeometry geometry;
  final List<Candle> candles;
  final List<PriceLine> lines;
  final List<ChartZone> zones;
  final List<ChartMarker> markers;
  final List<double?>? movingAverage;
  final int decimals;
  final ChartColors colors;
  final String? activeLineId;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _paintGrid(canvas, size);
    _paintZones(canvas);
    if (g.showVolume) _paintVolume(canvas, size);
    _paintCandles(canvas);
    _paintMovingAverage(canvas);
    _paintZoneLabels(canvas);
    _paintMarkers(canvas);
    _paintLastPrice(canvas);
    _paintLines(canvas);
    canvas.restore();
  }

  void _paintGrid(Canvas canvas, Size size) {
    final g = geometry;
    final grid = Paint()
      ..color = colors.grid
      ..strokeWidth = 1;
    final step = _niceStep((g.maxPrice - g.minPrice) / 5);
    var price = (g.minPrice / step).ceil() * step;
    while (price <= g.maxPrice) {
      final y = g.y(price);
      canvas.drawLine(Offset(0, y), Offset(g.plotWidth, y), grid);
      _text(
        canvas,
        price.toStringAsFixed(decimals),
        Offset(g.plotWidth + 6, y - 7),
        colors.text,
      );
      price += step;
    }
    canvas.drawLine(
      Offset(g.plotWidth, 0),
      Offset(g.plotWidth, size.height),
      grid,
    );
  }

  void _paintZones(Canvas canvas) {
    final g = geometry;
    for (final zone in zones) {
      final left = math.max(0.0, g.x(zone.fromIndex) - g.slotWidth / 2);
      final right = math.min(g.plotWidth, g.x(zone.toIndex) + g.slotWidth / 2);
      if (right <= left) continue;
      final rect = Rect.fromLTRB(left, g.y(zone.high), right, g.y(zone.low));
      canvas.drawRect(
        rect,
        Paint()..color = zone.color.withValues(alpha: 0.18),
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = zone.color.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  /// Drawn after the candles so labels stay readable.
  void _paintZoneLabels(Canvas canvas) {
    final g = geometry;
    for (final zone in zones) {
      if (zone.label == null) continue;
      final left = math.max(0.0, g.x(zone.fromIndex) - g.slotWidth / 2);
      _text(
        canvas,
        zone.label!,
        Offset(left + 4, g.y(zone.high) - 15),
        zone.color,
        bold: true,
        background: colors.background,
      );
    }
  }

  void _paintVolume(Canvas canvas, Size size) {
    final g = geometry;
    var maxVolume = 0.0;
    for (var i = g.startIndex; i < candles.length; i++) {
      maxVolume = math.max(maxVolume, candles[i].volume);
    }
    if (maxVolume <= 0) return;
    final bottom = size.height;
    final width = math.max(1.0, g.slotWidth * 0.65);
    for (var i = g.startIndex; i < candles.length; i++) {
      final c = candles[i];
      final h = c.volume / maxVolume * g.volumeHeight * 0.9;
      canvas.drawRect(
        Rect.fromLTWH(g.x(i) - width / 2, bottom - h, width, h),
        Paint()
          ..color = (c.isBullish ? colors.up : colors.down).withValues(
            alpha: 0.35,
          ),
      );
    }
  }

  void _paintCandles(Canvas canvas) {
    final g = geometry;
    final bodyWidth = math.max(1.0, g.slotWidth * 0.65);
    final wickWidth = math.max(1.0, g.slotWidth * 0.12);
    for (var i = g.startIndex; i < candles.length; i++) {
      final c = candles[i];
      final paint = Paint()..color = c.isBullish ? colors.up : colors.down;
      final x = g.x(i);
      canvas.drawRect(
        Rect.fromLTRB(
          x - wickWidth / 2,
          g.y(c.high),
          x + wickWidth / 2,
          g.y(c.low),
        ),
        paint,
      );
      final top = g.y(math.max(c.open, c.close));
      final bottom = math.max(top + 1, g.y(math.min(c.open, c.close)));
      canvas.drawRect(
        Rect.fromLTRB(x - bodyWidth / 2, top, x + bodyWidth / 2, bottom),
        paint,
      );
    }
  }

  void _paintMovingAverage(Canvas canvas) {
    final values = movingAverage;
    if (values == null) return;
    final g = geometry;
    final path = Path();
    var started = false;
    for (var i = g.startIndex; i < candles.length && i < values.length; i++) {
      final v = values[i];
      if (v == null) continue;
      final point = Offset(g.x(i), g.y(v));
      if (started) {
        path.lineTo(point.dx, point.dy);
      } else {
        path.moveTo(point.dx, point.dy);
        started = true;
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = colors.movingAverage
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  void _paintMarkers(Canvas canvas) {
    final g = geometry;
    for (final m in markers) {
      if (m.index < g.startIndex) continue;
      final x = g.x(m.index);
      final y = g.y(m.price);
      final size = math.max(6.0, math.min(10.0, g.slotWidth));
      final path = Path();
      if (m.pointsUp) {
        path
          ..moveTo(x, y + 4)
          ..lineTo(x - size / 2, y + 4 + size)
          ..lineTo(x + size / 2, y + 4 + size);
      } else {
        path
          ..moveTo(x, y - 4)
          ..lineTo(x - size / 2, y - 4 - size)
          ..lineTo(x + size / 2, y - 4 - size);
      }
      canvas.drawPath(path..close(), Paint()..color = m.color);
    }
  }

  void _paintLastPrice(Canvas canvas) {
    if (candles.isEmpty) return;
    final g = geometry;
    final last = candles.last;
    final y = g.y(last.close);
    final coveredByLine = lines.any((l) => (g.y(l.price) - y).abs() < 10);
    if (coveredByLine) return;
    _tag(
      canvas,
      y,
      last.close.toStringAsFixed(decimals),
      last.isBullish ? colors.up : colors.down,
    );
  }

  void _paintLines(Canvas canvas) {
    final g = geometry;
    for (final line in lines) {
      final y = g.y(line.price);
      final active = line.id == activeLineId;
      final paint = Paint()
        ..color = line.color
        ..strokeWidth = active ? 2.5 : 1.5;
      if (line.dashed) {
        for (var x = 0.0; x < g.plotWidth; x += 9) {
          canvas.drawLine(
            Offset(x, y),
            Offset(math.min(x + 5, g.plotWidth), y),
            paint,
          );
        }
      } else {
        canvas.drawLine(Offset(0, y), Offset(g.plotWidth, y), paint);
      }
      _tag(canvas, y, line.price.toStringAsFixed(decimals), line.color);
      _text(
        canvas,
        line.label,
        Offset(6, y - 16),
        line.color,
        bold: true,
        background: colors.background,
      );
      if (line.draggable) {
        final handle = Offset(g.plotWidth - 22, y);
        canvas.drawCircle(
          handle,
          active ? 13 : 11,
          Paint()..color = line.color,
        );
        final grip = Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5;
        for (final dy in [-3.0, 0.0, 3.0]) {
          canvas.drawLine(
            handle + Offset(-5, dy),
            handle + Offset(5, dy),
            grip,
          );
        }
      }
    }
  }

  void _tag(Canvas canvas, double y, String text, Color color) {
    final g = geometry;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(g.plotWidth + 2, y - 9, ChartGeometry.axisWidth - 4, 18),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, Paint()..color = color);
    _text(
      canvas,
      text,
      Offset(g.plotWidth + 6, y - 7),
      Colors.white,
      bold: true,
    );
  }

  void _text(
    Canvas canvas,
    String text,
    Offset offset,
    Color color, {
    bool bold = false,
    Color? background,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    if (background != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            offset.dx - 3,
            offset.dy - 1,
            painter.width + 6,
            painter.height + 2,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = background.withValues(alpha: 0.85),
      );
    }
    painter.paint(canvas, offset);
  }

  static double _niceStep(double raw) {
    if (raw <= 0) return 1;
    final magnitude = math
        .pow(10, (math.log(raw) / math.ln10).floor())
        .toDouble();
    final normalized = raw / magnitude;
    final nice = normalized < 1.5
        ? 1
        : normalized < 3
        ? 2
        : normalized < 7
        ? 5
        : 10;
    return nice * magnitude;
  }

  @override
  bool shouldRepaint(covariant _CandlePainter old) => true;
}
