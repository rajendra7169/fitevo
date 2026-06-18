import '../data/models/body_measurement.dart';
import '../data/models/enums.dart';
import '../data/models/profile.dart';

/// Recommendation from the adaptive engine: should we nudge the calorie
/// target, by how much, and why? `kcalDelta = 0` means "hold steady".
class AdaptiveSuggestion {
  final int kcalDelta;
  final String reason;
  final double weightDeltaPerWeek; // kg/wk inferred from the trend
  final int sampleSize;
  const AdaptiveSuggestion({
    required this.kcalDelta,
    required this.reason,
    required this.weightDeltaPerWeek,
    required this.sampleSize,
  });

  bool get isHold => kcalDelta == 0;
}

/// Macrofactor-style adaptive calorie targeting. Takes recent body
/// measurements + the user's goal and proposes a ±50/100 kcal nudge if
/// the weight trend is off-track.
///
/// Math: fit a simple least-squares slope to the last [windowDays] of
/// weight points (kg vs days). Compare to the goal-appropriate target:
///   - loseFat:   target = -0.50% bodyweight per week
///   - buildMuscle: target = +0.30% bodyweight per week
///   - recomp:    target = 0 ±0.15% bw/wk band
///   - generalFitness: target = 0 ±0.30% bw/wk band
/// If actual is outside the band, nudge in the corrective direction
/// (capped at ±100 kcal/wk so adjustments stay gentle).
class AdaptiveTargeting {
  static const int _windowDays = 14;
  static const int _minSamples = 4;

  /// Linear regression slope (kg per day) over the window. Returns null
  /// when there isn't enough data to be meaningful.
  static double? _slopeKgPerDay(List<BodyMeasurement> samples) {
    if (samples.length < _minSamples) return null;
    // x = days since first sample, y = weight.
    final first = samples.first.date;
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
    final n = samples.length;
    for (final m in samples) {
      final x = m.date.difference(first).inDays.toDouble();
      sumX += x;
      sumY += m.weightKg;
      sumXY += x * m.weightKg;
      sumXX += x * x;
    }
    final denom = n * sumXX - sumX * sumX;
    if (denom == 0) return null;
    return (n * sumXY - sumX * sumY) / denom;
  }

  static (double targetPerWeekFractionLow, double targetPerWeekFractionHigh)
      _bandForGoal(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.loseFat:
        return (-0.0075, -0.0025); // -0.75% to -0.25% per week
      case FitnessGoal.buildMuscle:
        return (0.0015, 0.0050); // +0.15% to +0.50% per week
      case FitnessGoal.recomp:
        return (-0.0015, 0.0015); // ±0.15% per week
      case FitnessGoal.generalFitness:
        return (-0.0030, 0.0030); // ±0.30% per week
    }
  }

  static AdaptiveSuggestion suggest({
    required Profile profile,
    required List<BodyMeasurement> measurements,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final cutoff = t.subtract(const Duration(days: _windowDays));

    // Use measurements within the window, sorted oldest-first.
    final samples = measurements
        .where((m) => m.date.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (samples.length < _minSamples) {
      return AdaptiveSuggestion(
        kcalDelta: 0,
        reason:
            'Log weight at least ${_minSamples - samples.length} more time${_minSamples - samples.length == 1 ? '' : 's'} this week to enable adaptive targeting.',
        weightDeltaPerWeek: 0,
        sampleSize: samples.length,
      );
    }

    final slopePerDay = _slopeKgPerDay(samples) ?? 0;
    final slopePerWeek = slopePerDay * 7.0;
    final fractionPerWeek = slopePerWeek / profile.weightKg;
    final (lowFrac, highFrac) = _bandForGoal(profile.goal);

    // Above the band → eating too much for the goal → reduce calories.
    // Below the band → eating too little → increase calories.
    if (fractionPerWeek > highFrac) {
      // 50 kcal nudge unless we're 2x outside the band, then 100.
      final magnitude =
          (fractionPerWeek - highFrac).abs() > (highFrac - lowFrac).abs()
              ? -100
              : -50;
      return AdaptiveSuggestion(
        kcalDelta: magnitude,
        reason: _reasonForOverGoal(profile.goal, slopePerWeek),
        weightDeltaPerWeek: slopePerWeek,
        sampleSize: samples.length,
      );
    }
    if (fractionPerWeek < lowFrac) {
      final magnitude =
          (lowFrac - fractionPerWeek).abs() > (highFrac - lowFrac).abs()
              ? 100
              : 50;
      return AdaptiveSuggestion(
        kcalDelta: magnitude,
        reason: _reasonForUnderGoal(profile.goal, slopePerWeek),
        weightDeltaPerWeek: slopePerWeek,
        sampleSize: samples.length,
      );
    }
    return AdaptiveSuggestion(
      kcalDelta: 0,
      reason: 'On track. Hold your target for another week.',
      weightDeltaPerWeek: slopePerWeek,
      sampleSize: samples.length,
    );
  }

  static String _reasonForOverGoal(FitnessGoal goal, double slopePerWeek) {
    final kg = slopePerWeek.toStringAsFixed(2);
    switch (goal) {
      case FitnessGoal.loseFat:
        return 'Weight is up ${kg}kg/wk — drop calories to get back into the deficit.';
      case FitnessGoal.buildMuscle:
        return 'Gaining ${kg}kg/wk — that\'s past lean-bulk territory and starts adding fat. Pull back slightly.';
      case FitnessGoal.recomp:
        return 'Trending up ${kg}kg/wk — too far above maintenance for recomp.';
      case FitnessGoal.generalFitness:
        return 'Weight drifting up ${kg}kg/wk — small calorie pull-back if you want to hold.';
    }
  }

  static String _reasonForUnderGoal(FitnessGoal goal, double slopePerWeek) {
    final kg = slopePerWeek.abs().toStringAsFixed(2);
    switch (goal) {
      case FitnessGoal.loseFat:
        return 'Losing ${kg}kg/wk — faster than ideal. Add calories to protect muscle.';
      case FitnessGoal.buildMuscle:
        return 'Not gaining (${kg}kg/wk loss) — build calories up to support muscle growth.';
      case FitnessGoal.recomp:
        return 'Trending down ${kg}kg/wk — past recomp band, eat a bit more.';
      case FitnessGoal.generalFitness:
        return 'Dropping ${kg}kg/wk — add calories if maintaining is the goal.';
    }
  }
}
