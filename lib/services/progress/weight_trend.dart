import 'dart:math' as math;

import '../../data/models/body_measurement.dart';
import '../../data/models/enums.dart';

/// Linear-fit weight trend over the most-recent window of weigh-ins.
/// Used by the AI coach context — when the model can see the user's
/// actual trajectory (vs the goal direction), it stops giving generic
/// answers and starts calling out misalignment.
class WeightTrend {
  /// Number of measurements considered for the fit.
  final int sampleCount;

  /// Span the samples covered, in days. `null` when there's only one
  /// measurement (no slope possible).
  final int? spanDays;

  /// Best-fit linear slope in kg/week. Positive = gaining; negative =
  /// losing. `null` when there's < 2 measurements or the span is 0.
  final double? kgPerWeek;

  /// Latest weight observed.
  final double? latestKg;

  /// First (oldest in window) weight observed.
  final double? earliestKg;

  /// Total delta latest minus earliest, in kg. `null` when < 2 samples.
  final double? totalDeltaKg;

  /// Verdict against the user's stated goal — used as a single-line
  /// summary the AI can quote verbatim. Empty when there's no fit yet
  /// or the goal doesn't have an opinion about weight direction.
  final String verdict;

  const WeightTrend({
    required this.sampleCount,
    required this.spanDays,
    required this.kgPerWeek,
    required this.latestKg,
    required this.earliestKg,
    required this.totalDeltaKg,
    required this.verdict,
  });

  /// Compute the trend over the most-recent [windowDays] window (clamped
  /// to whatever measurements actually exist). Caller is responsible
  /// for ordering — we sort defensively just in case.
  static WeightTrend compute(
    List<BodyMeasurement> all,
    FitnessGoal goal, {
    int windowDays = 28,
  }) {
    if (all.isEmpty) {
      return const WeightTrend(
        sampleCount: 0,
        spanDays: null,
        kgPerWeek: null,
        latestKg: null,
        earliestKg: null,
        totalDeltaKg: null,
        verdict: '',
      );
    }
    final sorted = List<BodyMeasurement>.of(all)
      ..sort((a, b) => a.date.compareTo(b.date));
    final cutoff =
        DateTime.now().subtract(Duration(days: windowDays));
    final inWindow =
        sorted.where((m) => !m.date.isBefore(cutoff)).toList();
    // Always include the most recent point even if it's slightly past
    // the cutoff so very sparse loggers still get a "latest weight" line.
    if (inWindow.isEmpty) inWindow.add(sorted.last);

    final latest = inWindow.last.weightKg;
    final earliest = inWindow.first.weightKg;

    if (inWindow.length < 2) {
      return WeightTrend(
        sampleCount: inWindow.length,
        spanDays: null,
        kgPerWeek: null,
        latestKg: latest,
        earliestKg: earliest,
        totalDeltaKg: null,
        verdict: _verdictForSingle(goal),
      );
    }

    final spanDays =
        inWindow.last.date.difference(inWindow.first.date).inDays;
    double? kgPerWeek;
    if (spanDays > 0) {
      // Simple ordinary least squares on (days since first, kg).
      final t0 = inWindow.first.date;
      double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
      final n = inWindow.length;
      for (final m in inWindow) {
        final x = m.date.difference(t0).inDays.toDouble();
        final y = m.weightKg;
        sumX += x;
        sumY += y;
        sumXY += x * y;
        sumX2 += x * x;
      }
      final denom = n * sumX2 - sumX * sumX;
      if (denom != 0) {
        final slopePerDay = (n * sumXY - sumX * sumY) / denom;
        kgPerWeek = slopePerDay * 7;
      }
    }

    final total = latest - earliest;
    final verdict = _verdict(goal: goal, kgPerWeek: kgPerWeek);

    return WeightTrend(
      sampleCount: inWindow.length,
      spanDays: spanDays,
      kgPerWeek: kgPerWeek,
      latestKg: latest,
      earliestKg: earliest,
      totalDeltaKg: total,
      verdict: verdict,
    );
  }

  static String _verdictForSingle(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.buildMuscle:
        return 'Only 1 weigh-in in window — log a few more so we can tell '
            'if the surplus is actually landing.';
      case FitnessGoal.loseFat:
        return 'Only 1 weigh-in in window — log a few more so we can tell '
            'if the deficit is actually landing.';
      case FitnessGoal.recomp:
      case FitnessGoal.generalFitness:
        return 'Only 1 weigh-in in window — log more for a trend.';
    }
  }

  /// Generate a one-line verdict the AI can quote without rewording.
  /// Compares trend direction + magnitude to the stated goal's
  /// expected band.
  static String _verdict({
    required FitnessGoal goal,
    required double? kgPerWeek,
  }) {
    if (kgPerWeek == null) return '';
    final mag = kgPerWeek.abs();
    final formatted = mag.toStringAsFixed(2);
    final direction = kgPerWeek > 0 ? 'gaining' : 'losing';
    switch (goal) {
      case FitnessGoal.buildMuscle:
        if (kgPerWeek <= 0) {
          return 'Goal is build muscle but trending $direction '
              '$formatted kg/week. Surplus isn\'t landing.';
        }
        if (kgPerWeek < 0.15) {
          return 'Gaining $formatted kg/week — too slow for a real '
              'build phase. Bump the surplus or check logging gaps.';
        }
        if (kgPerWeek > 0.5) {
          return 'Gaining $formatted kg/week — that\'s fat-gain territory. '
              'Pull the surplus back to ~0.25 kg/week.';
        }
        return 'Gaining $formatted kg/week — that\'s the right band for a '
            'lean build.';
      case FitnessGoal.loseFat:
        if (kgPerWeek >= 0) {
          return 'Goal is fat loss but trending $direction $formatted '
              'kg/week. Deficit isn\'t landing — likely a logging gap.';
        }
        final loss = mag;
        if (loss < 0.15) {
          return 'Losing $formatted kg/week — too slow to feel like '
              'progress. Tighten the deficit or audit logging.';
        }
        if (loss > 0.75) {
          return 'Losing $formatted kg/week — aggressive. Risk muscle '
              'loss. Soften the deficit.';
        }
        return 'Losing $formatted kg/week — clean band for sustainable '
            'fat loss.';
      case FitnessGoal.recomp:
      case FitnessGoal.generalFitness:
        if (mag < 0.10) {
          return 'Holding within $formatted kg/week — that\'s the '
              'maintenance band you\'d expect.';
        }
        return 'Trending $direction $formatted kg/week.';
    }
  }

  /// Multi-line block to drop into the coach context. Designed so the
  /// AI can quote individual lines verbatim. Empty when there's no
  /// data at all.
  String toContextLines() {
    if (sampleCount == 0) {
      return 'Weight trend: no weigh-ins logged yet — encourage the user '
          'to log a weight so the AI can read trajectory.';
    }
    final out = <String>[];
    out.add('Weight latest: ${latestKg!.toStringAsFixed(1)} kg');
    if (kgPerWeek != null && totalDeltaKg != null && spanDays != null) {
      final dir = totalDeltaKg! >= 0 ? '+' : '';
      out.add('Trend (last $spanDays days, $sampleCount weigh-ins): '
          '$dir${totalDeltaKg!.toStringAsFixed(1)} kg total · '
          '${kgPerWeek! >= 0 ? '+' : ''}${kgPerWeek!.toStringAsFixed(2)} kg/week');
    }
    if (verdict.isNotEmpty) out.add('Goal-vs-trend: $verdict');
    return out.join('\n');
  }

  /// Compact, single-line summary — used when context budget matters.
  String toShortLine() {
    if (sampleCount == 0) return 'No weight data yet.';
    if (kgPerWeek == null) {
      return '${latestKg!.toStringAsFixed(1)} kg latest · need more weigh-ins for trend';
    }
    final sign = kgPerWeek! >= 0 ? '+' : '';
    return '${latestKg!.toStringAsFixed(1)} kg · '
        '$sign${kgPerWeek!.toStringAsFixed(2)} kg/wk over '
        '${spanDays ?? 0}d';
  }

  /// Useful for `math` imports linter (no-op).
  // ignore: unused_element
  static double _ln2() => math.ln2;
}
