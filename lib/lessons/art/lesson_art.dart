import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../lesson_model.dart';

part 'foundation_scenes.dart';
part 'mind_scenes.dart';
part 'risk_scenes.dart';
part 'structure_scenes.dart';

/// Lesson illustrations: one picture per idea, shown above an explain step
/// (`"art": "<name>"` in the lesson JSON).
///
/// Same style as the tab art: flat vector, soft gradients, one glow, two or
/// three palette colours, drawn in code so it follows the light/dark theme.
/// Scenes live in part files by level: foundations (Level 0), market
/// structure (Level 1), risk (Level 2) and psychology (Level 7).
class LessonArtPanel extends StatelessWidget {
  const LessonArtPanel(this.art, {super.key});

  final LessonArt art;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      image: true,
      label: art.description,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          gradient: palette.heroGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(
          size: Size.infinite,
          painter: LessonArtPainter(art, palette),
        ),
      ),
    );
  }
}

extension LessonArtDescription on LessonArt {
  /// What the picture shows, for screen readers.
  String get description => switch (this) {
    // Level 0
    LessonArt.buyersSellers =>
      'Buyers on one side and sellers on the other, meeting at a price.',
    LessonArt.otherSide =>
      'A buy order and a sell order matched into one trade.',
    LessonArt.bidAsk =>
      'Two prices: the bid you can sell at and the higher ask you can buy '
          'at, with the spread between them.',
    LessonArt.spreadCost =>
      'A new trade starting slightly negative because of the spread.',
    LessonArt.spreadWiden =>
      'The gap between bid and ask widening sharply around a news release.',
    LessonArt.marketFamilies =>
      'Five market families: stocks, forex, crypto, commodities and indices.',
    LessonArt.tradingHours =>
      'A 24-hour clock: crypto trades around the clock, a stock exchange only '
          'during its session.',
    LessonArt.leverage =>
      'A lever: a small deposit on one side lifting a much larger position.',
    LessonArt.longShort =>
      'Long profits when price rises; short profits when price falls.',
    LessonArt.marketOrder =>
      'A market order filled straight away at the current price.',
    LessonArt.limitOrder =>
      'A limit order waiting below the price, filled when price dips to it.',
    LessonArt.stopOrder =>
      'A stop order below the price, triggered when price falls through it.',
    LessonArt.candleColours =>
      'A green candle closing above its open next to a red candle closing '
          'below it.',
    LessonArt.candleShapes =>
      'Three candle shapes: a strong body, a long lower wick and a doji.',
    LessonArt.timeframeZoom =>
      'Several small hourly candles combining into one daily candle.',
    LessonArt.liquidity =>
      'A deep market with many orders at each price next to a thin one.',
    // Level 1
    LessonArt.trendStructure =>
      'An uptrend zigzag labelled with higher highs and higher lows.',
    LessonArt.rangeBox =>
      'Price bouncing between a floor of support and a ceiling of '
          'resistance.',
    LessonArt.swingPoints =>
      'A zigzag with its swing highs and swing lows marked.',
    LessonArt.roleReversal =>
      'Old resistance breaking and then holding as new support.',
    LessonArt.trendChannel =>
      'A rising trendline under the lows and a parallel channel line above.',
    LessonArt.fakeout =>
      'Price pokes above resistance, then falls back below it: a fakeout.',
    LessonArt.pullback =>
      'A rise, a pullback into the middle of the move, then the next leg up.',
    LessonArt.multiTimeframe =>
      'A magnifying glass showing a small dip inside a big uptrend.',
    // Level 2
    LessonArt.beginnerMistakes =>
      'Three common mistakes: no stop-loss, trades that are too big, and '
          'chasing losses.',
    LessonArt.onePercent =>
      'Ten losses in a row: risking 1% leaves about 90% of the account, '
          'risking 10% leaves about 35%.',
    LessonArt.stopPlacement =>
      'A stop-loss just beyond the support zone, with room for normal '
          'wiggles.',
    LessonArt.rewardRisk =>
      'A stop one unit of risk below the entry and a target two units above.',
    LessonArt.expectancy =>
      'The win rate needed to break even: 50% at 1:1, 33% at 2:1, 25% at 3:1.',
    LessonArt.positionSize =>
      'Position size equals the money you risk divided by your stop '
          'distance.',
    LessonArt.marginLevel =>
      'A margin gauge: positions are closed automatically at 50%.',
    LessonArt.drawdown =>
      'Recovering from losses: down 10% needs +11%, down 25% needs +33%, '
          'down 50% needs +100%.',
    LessonArt.tradingCosts =>
      'Three costs of a trade: spread, commission and slippage.',
    LessonArt.slippage =>
      'A stop-loss filled below its level after price gapped through it.',
    // Level 7
    LessonArt.stress => 'A pounding heart and a racing pulse line.',
    LessonArt.fearGreed =>
      'A balance scale with fear on one side and a stack of coins, greed, '
          'on the other.',
    LessonArt.lossAversion =>
      'A loss of 100 dollars drawn twice as large as a win of 100 dollars.',
    LessonArt.calmPlan => 'A checked trading plan next to calm waves.',
    LessonArt.nameIt =>
      'A head with a calm wave and two labels: anxious and excited.',
    LessonArt.lossesNormal =>
      'Four winning and six losing trades, with the account still rising.',
    LessonArt.goodBadLoss =>
      'A small loss stopped at its stop-loss, ticked, next to a large loss '
          'that broke through it, crossed.',
    LessonArt.reset => 'Three steps: pause, review, reset.',
    LessonArt.lossLimit =>
      'A falling account line reaching the daily loss limit and a stop sign.',
    LessonArt.tilt => 'A gauge with its needle in the red tilt zone.',
    LessonArt.rest => 'A nearly empty battery under a crescent moon.',
    LessonArt.warningSigns => 'A warning sign.',
    LessonArt.support => 'A chat bubble with a heart, and a reply on its way.',
    LessonArt.safePractice => 'A shield with a tick in front of a coin.',
  };
}

/// Level 7's own gradient, used as the accent of the psychology art.
const _pink = Color(0xFFFB7185);
const _pinkDeep = Color(0xFFBE185D);

class LessonArtPainter extends CustomPainter {
  LessonArtPainter(this.art, this.palette);

  final LessonArt art;
  final AppPalette palette;

  /// Every scene is drawn on a 300 × 150 grid, scaled to fit and centred.
  static const _grid = Size(300, 150);

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / _grid.width, size.height / _grid.height);
    canvas.save();
    canvas.translate(
      (size.width - _grid.width * s) / 2,
      (size.height - _grid.height * s) / 2,
    );
    canvas.scale(s);
    final c = canvas;
    switch (art) {
      case LessonArt.buyersSellers:
        _buyersSellers(c);
      case LessonArt.otherSide:
        _otherSide(c);
      case LessonArt.bidAsk:
        _bidAsk(c);
      case LessonArt.spreadCost:
        _spreadCost(c);
      case LessonArt.spreadWiden:
        _spreadWiden(c);
      case LessonArt.marketFamilies:
        _marketFamilies(c);
      case LessonArt.tradingHours:
        _tradingHours(c);
      case LessonArt.leverage:
        _leverage(c);
      case LessonArt.longShort:
        _longShort(c);
      case LessonArt.marketOrder:
        _marketOrder(c);
      case LessonArt.limitOrder:
        _limitOrder(c);
      case LessonArt.stopOrder:
        _stopOrder(c);
      case LessonArt.candleColours:
        _candleColours(c);
      case LessonArt.candleShapes:
        _candleShapes(c);
      case LessonArt.timeframeZoom:
        _timeframeZoom(c);
      case LessonArt.liquidity:
        _liquidity(c);
      case LessonArt.trendStructure:
        _trendStructure(c);
      case LessonArt.rangeBox:
        _rangeBox(c);
      case LessonArt.swingPoints:
        _swingPoints(c);
      case LessonArt.roleReversal:
        _roleReversal(c);
      case LessonArt.trendChannel:
        _trendChannel(c);
      case LessonArt.fakeout:
        _fakeout(c);
      case LessonArt.pullback:
        _pullback(c);
      case LessonArt.multiTimeframe:
        _multiTimeframe(c);
      case LessonArt.beginnerMistakes:
        _beginnerMistakes(c);
      case LessonArt.onePercent:
        _onePercent(c);
      case LessonArt.stopPlacement:
        _stopPlacement(c);
      case LessonArt.rewardRisk:
        _rewardRisk(c);
      case LessonArt.expectancy:
        _expectancy(c);
      case LessonArt.positionSize:
        _positionSize(c);
      case LessonArt.marginLevel:
        _marginLevel(c);
      case LessonArt.drawdown:
        _drawdown(c);
      case LessonArt.tradingCosts:
        _tradingCosts(c);
      case LessonArt.slippage:
        _slippage(c);
      case LessonArt.stress:
        _stress(c);
      case LessonArt.fearGreed:
        _fearGreed(c);
      case LessonArt.lossAversion:
        _lossAversion(c);
      case LessonArt.calmPlan:
        _calmPlan(c);
      case LessonArt.nameIt:
        _nameIt(c);
      case LessonArt.lossesNormal:
        _lossesNormal(c);
      case LessonArt.goodBadLoss:
        _goodBadLoss(c);
      case LessonArt.reset:
        _reset(c);
      case LessonArt.lossLimit:
        _lossLimit(c);
      case LessonArt.tilt:
        _tilt(c);
      case LessonArt.rest:
        _rest(c);
      case LessonArt.warningSigns:
        _warningSigns(c);
      case LessonArt.support:
        _support(c);
      case LessonArt.safePractice:
        _safePractice(c);
    }
    canvas.restore();
  }

  /// The scene's one soft glow, a little stronger on dark backgrounds.
  void _glow(Canvas c, Offset center, double radius, Color color) {
    final alpha = palette.isDark ? 0.30 : 0.20;
    c.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  /// A rounded tile on the hero background (cards, panels, screens).
  void _card(Canvas c, Rect r, {double radius = 14, Color? fill}) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
    c.drawRRect(rr, Paint()..color = fill ?? palette.surface);
    c.drawRRect(rr, _stroke(palette.outline, 1.5));
  }

  /// A candle on the art grid: y grows downwards, so "open" and "close" are
  /// screen positions.
  void _candle(
    Canvas c,
    double x,
    double open,
    double close,
    double high,
    double low, {
    double width = 14,
    Color? color,
  }) {
    final paint = Paint()
      ..color = color ?? (close <= open ? palette.up : palette.down);
    c.drawRRect(
      RRect.fromLTRBR(x - 1.4, high, x + 1.4, low, const Radius.circular(1.4)),
      paint,
    );
    final top = math.min(open, close), bottom = math.max(open, close);
    c.drawRRect(
      RRect.fromLTRBR(
        x - width / 2,
        top,
        x + width / 2,
        math.max(bottom, top + 2),
        const Radius.circular(3),
      ),
      paint,
    );
  }

  /// A gold coin with a dollar sign.
  void _coin(Canvas c, Offset center, double r) {
    _dot(c, center, r, AppColors.gradientGold, gradient: true);
    c.drawCircle(
      center,
      r * 0.76,
      _stroke(AppColors.onGold.withValues(alpha: 0.22), r * 0.09),
    );
    _label(
      c,
      '\$',
      center,
      AppColors.onGold.withValues(alpha: 0.75),
      size: r * 0.95,
      spacing: 0,
    );
  }

  /// A small rounded label with text.
  void _chip(
    Canvas c,
    Offset center,
    String text,
    Color color, {
    double size = 10,
    bool filled = false,
  }) {
    final tp = _textPainter(text, size, FontWeight.w700, 0.6, color);
    final rect = Rect.fromCenter(
      center: center,
      width: tp.width + size * 1.4,
      height: tp.height + size * 0.8,
    );
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2));
    c.drawRRect(
      rr,
      Paint()..color = filled ? color : color.withValues(alpha: 0.14),
    );
    final textColor = filled
        ? (color.computeLuminance() > 0.5 ? AppColors.onGold : Colors.white)
        : color;
    _label(c, text, center, textColor, size: size, spacing: 0.6);
  }

  @override
  bool shouldRepaint(LessonArtPainter old) =>
      old.art != art || old.palette != palette;
}

// -----------------------------------------------------------------------------
// Shared drawing helpers

Path _polyline(List<Offset> points) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (final p in points.skip(1)) {
    path.lineTo(p.dx, p.dy);
  }
  return path;
}

/// An open arrow head at [tip], pointing along [angle] (radians).
void _arrowHead(Canvas c, Offset tip, double angle, double size, Paint paint) {
  Offset arm(double a) =>
      tip - Offset(math.cos(angle + a), math.sin(angle + a)) * size;
  final left = arm(0.55), right = arm(-0.55);
  c.drawPath(
    Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(right.dx, right.dy),
    paint,
  );
}

/// A line with an arrow head at its end.
void _arrow(Canvas c, Offset from, Offset to, Paint paint, {double head = 9}) {
  c.drawLine(from, to, paint);
  final d = to - from;
  _arrowHead(c, to, math.atan2(d.dy, d.dx), head, paint);
}

/// The head profile of the Level 7 badge, on its 24-unit grid.
Path _headPath() => Path()
  ..moveTo(9, 21)
  ..lineTo(9, 16.8)
  ..cubicTo(6.6, 15.5, 5, 13, 5, 10.2)
  ..cubicTo(5, 6.2, 8.2, 3, 12.2, 3)
  ..cubicTo(15.9, 3, 19, 5.9, 19, 9.6)
  ..lineTo(20.8, 12.7)
  ..cubicTo(21.0, 13.1, 20.8, 13.5, 20.3, 13.5)
  ..lineTo(19, 13.5)
  ..lineTo(19, 16.1)
  ..cubicTo(19, 17.2, 18.1, 18.0, 17.1, 18.0)
  ..lineTo(15.5, 18)
  ..lineTo(15.5, 21)
  ..close();

Path _heartPath(Offset c, double w) {
  final h = w * 0.9;
  return Path()
    ..moveTo(c.dx, c.dy + h * 0.45)
    ..cubicTo(
      c.dx - w * 0.62,
      c.dy + h * 0.02,
      c.dx - w * 0.5,
      c.dy - h * 0.58,
      c.dx,
      c.dy - h * 0.22,
    )
    ..cubicTo(
      c.dx + w * 0.5,
      c.dy - h * 0.58,
      c.dx + w * 0.62,
      c.dy + h * 0.02,
      c.dx,
      c.dy + h * 0.45,
    )
    ..close();
}

Path _wave(double x0, double x1, double y, double amp, int periods) {
  final path = Path()..moveTo(x0, y);
  const steps = 48;
  for (var i = 1; i <= steps; i++) {
    final t = i / steps;
    path.lineTo(
      x0 + (x1 - x0) * t,
      y - amp * math.sin(t * periods * 2 * math.pi),
    );
  }
  return path;
}

void _dot(
  Canvas c,
  Offset center,
  double r,
  Color color, {
  bool gradient = false,
}) {
  final rect = Rect.fromCircle(center: center, radius: r);
  c.drawCircle(
    center,
    r,
    gradient
        ? _gradFill(
            color == AppColors.gradientGold
                ? const [AppColors.gradientGold, AppColors.gradientOrange]
                : [_lighten(color, 0.2), color],
            rect,
          )
        : (Paint()..color = color),
  );
}

void _tick(Canvas c, Offset center, double r, Color color, double width) {
  c.drawPath(
    Path()
      ..moveTo(center.dx - r, center.dy)
      ..lineTo(center.dx - r * 0.25, center.dy + r * 0.75)
      ..lineTo(center.dx + r, center.dy - r * 0.7),
    _stroke(color, width),
  );
}

void _cross(Canvas c, Offset center, double r, Color color, double width) {
  final paint = _stroke(color, width);
  c.drawLine(center + Offset(-r, -r), center + Offset(r, r), paint);
  c.drawLine(center + Offset(r, -r), center + Offset(-r, r), paint);
}

void _sparkle(Canvas c, Offset p, double r, Color color) {
  final path = Path()
    ..moveTo(p.dx, p.dy - r)
    ..quadraticBezierTo(p.dx, p.dy, p.dx + r, p.dy)
    ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + r)
    ..quadraticBezierTo(p.dx, p.dy, p.dx - r, p.dy)
    ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - r)
    ..close();
  c.drawPath(path, Paint()..color = color);
}

void _dashed(Canvas c, Offset a, Offset b, Color color, double width) {
  final paint = _stroke(color, width);
  final length = (b - a).distance;
  final dir = (b - a) / length;
  for (var d = 0.0; d < length; d += 12) {
    c.drawLine(a + dir * d, a + dir * math.min(d + 6, length), paint);
  }
}

TextPainter _textPainter(
  String text,
  double size,
  FontWeight weight,
  double spacing,
  Color color,
) => TextPainter(
  text: TextSpan(
    text: text,
    style: TextStyle(
      fontFamily: 'Poppins',
      fontSize: size,
      fontWeight: weight,
      letterSpacing: spacing,
      color: color,
      height: 1,
    ),
  ),
  textDirection: TextDirection.ltr,
  maxLines: 1,
)..layout();

/// Text centred on [center].
void _label(
  Canvas c,
  String text,
  Offset center,
  Color color, {
  double size = 10,
  double spacing = 1.2,
  FontWeight weight = FontWeight.w700,
}) {
  final tp = _textPainter(text, size, weight, spacing, color);
  tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
}

Paint _stroke(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

Paint _gradStroke(List<Color> colors, Rect bounds, double width) =>
    _gradFill(colors, bounds)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

Paint _gradFill(List<Color> colors, Rect bounds) => Paint()
  ..shader = LinearGradient(
    colors: colors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ).createShader(bounds);

Color _lighten(Color c, double t) => Color.lerp(c, Colors.white, t)!;

const _brand = [AppColors.gradientGold, AppColors.gradientOrange];
