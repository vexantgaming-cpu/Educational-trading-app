import 'dart:math' as math;

/// Seeded pseudo-random generator (Mulberry32).
///
/// Uses only 32-bit integer maths so the same seed gives the same sequence on
/// the Dart VM, on the web, and in the JavaScript reference implementation.
/// That lets a scenario be regenerated anywhere from its seed.
class SeededRandom {
  SeededRandom(int seed) : _state = seed & 0xffffffff;

  int _state;
  double? _spareGaussian;

  int nextUint32() {
    _state = (_state + 0x6D2B79F5) & 0xffffffff;
    var t = _state;
    t = mul32(t ^ (t >> 15), t | 1);
    t = (t ^ ((t + mul32(t ^ (t >> 7), t | 61)) & 0xffffffff)) & 0xffffffff;
    return (t ^ (t >> 14)) & 0xffffffff;
  }

  /// Uniform double in [0, 1).
  double nextDouble() => nextUint32() / 4294967296.0;

  /// Uniform double in [min, max).
  double nextRange(double min, double max) => min + (max - min) * nextDouble();

  /// Uniform int in [0, max).
  int nextInt(int max) => (nextDouble() * max).floor();

  bool nextBool([double probability = 0.5]) => nextDouble() < probability;

  /// Standard normal sample (Box–Muller).
  double nextGaussian() {
    final spare = _spareGaussian;
    if (spare != null) {
      _spareGaussian = null;
      return spare;
    }
    double u1;
    do {
      u1 = nextDouble();
    } while (u1 <= 1e-12);
    final u2 = nextDouble();
    final radius = math.sqrt(-2 * math.log(u1));
    _spareGaussian = radius * math.sin(2 * math.pi * u2);
    return radius * math.cos(2 * math.pi * u2);
  }
}

/// 32-bit multiply (like JavaScript's Math.imul), exact on the Dart VM and on
/// the web, where ints above 2^53 lose precision.
int mul32(int a, int b) {
  final al = a & 0xffff, ah = (a >> 16) & 0xffff;
  final bl = b & 0xffff, bh = (b >> 16) & 0xffff;
  return (al * bl + (((ah * bl + al * bh) & 0xffff) << 16)) & 0xffffffff;
}
