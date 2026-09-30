import 'dart:math' as math;

import 'instrument.dart';
import 'risk.dart';

/// What a well-planned trade looks like in a given exercise.
class ProcessRules {
  const ProcessRules({this.minRewardRisk = 1.5, this.maxRiskPct = 1.0});

  final double minRewardRisk;
  final double maxRiskPct;
}

class ProcessCheck {
  const ProcessCheck({
    required this.id,
    required this.label,
    required this.points,
    required this.maxPoints,
    required this.feedback,
  });

  final String id;
  final String label;
  final int points;
  final int maxPoints;

  /// One or two sentences for the learner.
  final String feedback;

  bool get passed => points == maxPoints;
}

class ProcessScore {
  const ProcessScore(this.checks);

  final List<ProcessCheck> checks;

  int get score => checks.fold(0, (a, c) => a + c.points);
  int get maxScore => checks.fold(0, (a, c) => a + c.maxPoints);

  String get grade {
    final pct = maxScore == 0 ? 0 : score / maxScore * 100;
    if (pct >= 90) return 'Excellent plan';
    if (pct >= 70) return 'Good plan';
    if (pct >= 40) return 'Needs work';
    return 'Risky plan';
  }
}

/// Scores how a trade was *planned*, independent of how it turned out.
/// A well-planned loss scores higher than a lucky, unprotected win.
ProcessScore scoreTradePlan({
  required Side side,
  required double entry,
  required double quantity,
  required double balance,
  required InstrumentSpec spec,
  double? stop,
  double? target,
  ProcessRules rules = const ProcessRules(),
}) {
  final validStop = stop != null && (entry - stop) * side.sign > 0;
  final checks = <ProcessCheck>[];

  checks.add(validStop
      ? const ProcessCheck(
          id: 'stop',
          label: 'Stop-loss placed',
          points: 40,
          maxPoints: 40,
          feedback: 'You decided in advance where your idea is wrong.',
        )
      : const ProcessCheck(
          id: 'stop',
          label: 'Stop-loss placed',
          points: 0,
          maxPoints: 40,
          feedback: 'No stop-loss. One bad move could take a big bite out of '
              'your account. Always decide where you are wrong before you enter.',
        ));

  final rr = Risk.rewardRisk(side: side, entry: entry, stop: stop, target: target);
  final min = rules.minRewardRisk;
  if (!validStop) {
    checks.add(const ProcessCheck(
      id: 'reward_risk',
      label: 'Reward vs risk',
      points: 0,
      maxPoints: 30,
      feedback: 'Without a stop, reward-to-risk can\'t be measured.',
    ));
  } else if (rr == null) {
    checks.add(const ProcessCheck(
      id: 'reward_risk',
      label: 'Reward vs risk',
      points: 0,
      maxPoints: 30,
      feedback: 'No valid take-profit. Plan your exit before you enter.',
    ));
  } else if (rr >= min) {
    checks.add(ProcessCheck(
      id: 'reward_risk',
      label: 'Reward vs risk',
      points: 30,
      maxPoints: 30,
      feedback: 'Your target is ${rr.toStringAsFixed(1)}× your risk. '
          'Good trades pay more when right than they cost when wrong.',
    ));
  } else if (rr >= 1) {
    checks.add(ProcessCheck(
      id: 'reward_risk',
      label: 'Reward vs risk',
      points: 15,
      maxPoints: 30,
      feedback: 'Your target is only ${rr.toStringAsFixed(1)}× your risk. '
          'Aim for at least ${min.toStringAsFixed(1)}×.',
    ));
  } else {
    checks.add(ProcessCheck(
      id: 'reward_risk',
      label: 'Reward vs risk',
      points: 0,
      maxPoints: 30,
      feedback: 'You risk more than you can make (${rr.toStringAsFixed(1)}×). '
          'You would need to be right most of the time just to break even.',
    ));
  }

  if (!validStop) {
    checks.add(const ProcessCheck(
      id: 'risk_size',
      label: 'Position size',
      points: 0,
      maxPoints: 30,
      feedback: 'Without a stop your possible loss has no limit.',
    ));
  } else {
    final riskPct =
        (entry - stop).abs() * quantity * spec.contractSize / balance * 100;
    final fiveLosses = (1 - math.pow(1 - riskPct / 100, 5)) * 100;
    final maxPct = rules.maxRiskPct;
    final label = 'Position size';
    final riskText = riskPct.toStringAsFixed(1);
    if (riskPct <= maxPct + 1e-9) {
      checks.add(ProcessCheck(
        id: 'risk_size',
        label: label,
        points: 30,
        maxPoints: 30,
        feedback: 'You risked $riskText% of your account. '
            'Small risk keeps you in the game through losing streaks.',
      ));
    } else if (riskPct <= maxPct * 2) {
      checks.add(ProcessCheck(
        id: 'risk_size',
        label: label,
        points: 10,
        maxPoints: 30,
        feedback: 'You risked $riskText%. While learning, keep it at '
            '${maxPct.toStringAsFixed(0)}% or less.',
      ));
    } else {
      checks.add(ProcessCheck(
        id: 'risk_size',
        label: label,
        points: 0,
        maxPoints: 30,
        feedback: 'You risked $riskText%. Five losses like this in a row '
            'would cost ${fiveLosses.toStringAsFixed(0)}% of your account.',
      ));
    }
  }

  return ProcessScore(checks);
}
