import 'package:market_sim/market_sim.dart';
import 'package:test/test.dart';

void main() {
  test('matches the JavaScript Mulberry32 reference output', () {
    // Generated with the canonical JS implementation (Math.imul based).
    const expected = {
      1: [2693262067, 11749833, 2265367787, 4213581821, 4159151403],
      42: [2581720956, 1925393290, 3661312704, 2876485805, 750819978],
      123456789: [1107202814, 4169434471, 3372958138, 885470128, 1301683845],
    };
    expected.forEach((seed, values) {
      final rng = SeededRandom(seed);
      expect([for (var i = 0; i < 5; i++) rng.nextUint32()], values,
          reason: 'seed $seed');
    });
  });

  test('doubles stay in [0, 1) and gaussians look standard normal', () {
    final rng = SeededRandom(7);
    var sum = 0.0, sumSq = 0.0;
    const n = 20000;
    for (var i = 0; i < n; i++) {
      final d = rng.nextDouble();
      expect(d, inInclusiveRange(0, 0.9999999999));
      final g = rng.nextGaussian();
      sum += g;
      sumSq += g * g;
    }
    final mean = sum / n;
    expect(mean.abs(), lessThan(0.05));
    expect(sumSq / n - mean * mean, closeTo(1, 0.05));
  });
}
