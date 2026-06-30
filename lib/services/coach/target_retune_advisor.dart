import '../../data/models/enums.dart';
import '../../data/models/profile.dart';
import '../../services/progress/weight_trend.dart';

/// Result of "should we suggest re-tuning the user's calorie target?"
/// When [shouldShow] is true, the home/coach screen surfaces an AI
/// advisory card. [suggestedKcalDelta] is the directional hint that
/// gets handed to the AI as part of the context so the model agrees
/// with the math rather than picking a random number.
class RetuneCheck {
  /// Whether the conditions for surfacing the advisory are met.
  final bool shouldShow;

  /// Direction we believe the kcal target should move. Positive means
  /// raise it (user is losing too fast / not building); negative means
  /// drop it. Null when we don't have an opinion (data still loading
  /// or trajectory matches goal).
  final int? suggestedKcalDelta;

  /// One-line plain-English reason for the AI to expand on.
  final String reason;

  /// Fingerprint for caching — re-uses the same AI reply when nothing
  /// has materially changed since last surface.
  final String fingerprint;

  const RetuneCheck({
    required this.shouldShow,
    required this.suggestedKcalDelta,
    required this.reason,
    required this.fingerprint,
  });

  static const empty = RetuneCheck(
    shouldShow: false,
    suggestedKcalDelta: null,
    reason: '',
    fingerprint: '',
  );
}

/// Decides whether to surface a calorie-target re-tune advisory, and
/// what direction to suggest. Conservative — only fires after 14 days
/// of weigh-ins so the trend is real, and only when actual rate is
/// >= 25% off the expected band for the user's goal.
class TargetRetuneAdvisor {
  /// Expected weekly weight rate (kg/week) per goal — used to compute
  /// whether the user's actual trend is far enough off-band to warrant
  /// retuning. Build muscle ≈ +0.25 kg/wk, fat loss ≈ -0.5 kg/wk.
  static double _expectedKgPerWeek(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.buildMuscle:
        return 0.25;
      case FitnessGoal.loseFat:
        return -0.5;
      case FitnessGoal.recomp:
      case FitnessGoal.generalFitness:
        return 0.0;
    }
  }

  static RetuneCheck evaluate({
    required Profile profile,
    required WeightTrend trend,
  }) {
    // Need ≥ 14-day window + ≥ 3 weigh-ins for a usable fit.
    if (trend.sampleCount < 3 ||
        (trend.spanDays ?? 0) < 14 ||
        trend.kgPerWeek == null) {
      return RetuneCheck.empty;
    }
    final goal = profile.goal;
    if (goal == FitnessGoal.recomp || goal == FitnessGoal.generalFitness) {
      // Recomp / general fitness don't have a directional target to
      // adjust against; skip until the user picks a sharper goal.
      return RetuneCheck.empty;
    }
    final expected = _expectedKgPerWeek(goal);
    final actual = trend.kgPerWeek!;
    final delta = actual - expected; // positive = too high vs expected
    final off = delta.abs();
    if (off < 0.10) return RetuneCheck.empty; // within band, leave alone

    // Translate the kg/week gap into a calorie-target adjustment.
    // 1 kg fat ≈ 7700 kcal. Spread across 7 days → ~1100 kcal/day per
    // 1 kg/week. We cap the suggestion at ±300 kcal/day so the user
    // doesn't get swung wildly off the formula's anchor.
    final rawDelta = (-delta * 1100).round();
    final suggested = rawDelta.clamp(-300, 300);

    String reason;
    if (goal == FitnessGoal.buildMuscle) {
      if (actual <= 0) {
        reason = 'Goal is build muscle but the scale is flat or trending '
            'down at ${actual.toStringAsFixed(2)} kg/week. '
            'Calorie target likely too low.';
      } else if (actual < 0.10) {
        reason = 'Gaining ${actual.toStringAsFixed(2)} kg/week — too '
            'slow for a real build phase. Bump the target up.';
      } else if (actual > 0.5) {
        reason = 'Gaining ${actual.toStringAsFixed(2)} kg/week — that\'s '
            'too fast and likely fat-heavy. Pull the target back.';
      } else {
        return RetuneCheck.empty;
      }
    } else {
      // loseFat
      if (actual >= 0) {
        reason = 'Goal is fat loss but trending +${actual.toStringAsFixed(2)} '
            'kg/week. Either the kitchen scale is off or the deficit '
            'isn\'t actually landing — most likely the target is too high.';
      } else if (actual.abs() < 0.20) {
        reason = 'Losing ${actual.abs().toStringAsFixed(2)} kg/week — too '
            'slow to feel like progress. Tighten the target.';
      } else if (actual.abs() > 0.85) {
        reason = 'Losing ${actual.abs().toStringAsFixed(2)} kg/week — '
            'aggressive. High muscle-loss risk. Soften the target.';
      } else {
        return RetuneCheck.empty;
      }
    }

    // Fingerprint: goal + direction sign + magnitude bucket. The
    // bucket means small day-to-day jiggle in the fit doesn't bust
    // the cache.
    final sign = suggested >= 0 ? '+' : '-';
    final bucket = (suggested.abs() / 50).round() * 50;
    final fp = 'retune-${goal.name}-$sign$bucket-d${trend.spanDays}';

    return RetuneCheck(
      shouldShow: true,
      suggestedKcalDelta: suggested,
      reason: reason,
      fingerprint: fp,
    );
  }

  /// Build the user-context block the AI sees for the advisory call.
  static String buildContext({
    required Profile profile,
    required RetuneCheck check,
    required WeightTrend trend,
  }) {
    return [
      'Name: ${profile.displayName.isEmpty ? "user" : profile.displayName}',
      'Goal: ${profile.goal.name}',
      'Diet: ${profile.dietPreference.name}',
      'Current calorie target: ${profile.effectiveCalorieTarget} kcal '
          '(base — does not include daily activity bonus)',
      'Current protein target: ${profile.effectiveProteinTarget}g',
      trend.toContextLines(),
      'Re-tune signal: ${check.reason}',
      if (check.suggestedKcalDelta != null)
        'Suggested kcal delta: ${check.suggestedKcalDelta! >= 0 ? '+' : ''}${check.suggestedKcalDelta} kcal/day. '
            'Translate to a new target ≈ '
            '${profile.effectiveCalorieTarget + check.suggestedKcalDelta!} kcal/day.',
    ].join('\n');
  }

  static const String userInstruction =
      'Write 1–2 short sentences explaining the re-tune. State the new '
      'suggested target, the reason (using actual numbers from the '
      'context), and whether the user should accept it or weigh in '
      'another week first. No markdown.';
}
