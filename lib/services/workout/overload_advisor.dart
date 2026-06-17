import 'package:flutter/material.dart';

import '../../data/models/routine.dart';
import '../../data/models/workout_session.dart';

class OverloadHint {
  final String message;
  final IconData icon;
  final Color color;
  const OverloadHint({
    required this.message,
    required this.icon,
    required this.color,
  });
}

class OverloadAdvisor {
  /// Looks at the previous session's sets for the given exercise and the
  /// planned rep range, and suggests how to load today.
  /// Returns null if there's nothing to suggest (no prior data).
  static OverloadHint? hintFor({
    required RoutinePlanItem item,
    required List<SetEntry> previousSets,
    required Color upColor,
    required Color holdColor,
    required Color downColor,
  }) {
    if (previousSets.isEmpty) return null;
    final reps = previousSets.map((s) => s.reps).toList();
    final avgReps = reps.reduce((a, b) => a + b) / reps.length;
    final lastWeight = previousSets.first.weightKg;

    final low = item.targetRepsLow;
    final high = item.targetRepsHigh;
    final hitTop = avgReps >= high - 0.5;
    final missedBottom = avgReps < low;

    if (lastWeight <= 0) {
      // Bodyweight movement
      if (hitTop) {
        return OverloadHint(
          message: 'Add a rep this session',
          icon: Icons.trending_up_rounded,
          color: upColor,
        );
      }
      return null;
    }

    if (hitTop) {
      final next = _nextStep(lastWeight);
      return OverloadHint(
        message: 'Try ${_fmt(next)} kg today',
        icon: Icons.trending_up_rounded,
        color: upColor,
      );
    }
    if (missedBottom) {
      final drop = lastWeight - 2.5;
      if (drop > 0) {
        return OverloadHint(
          message: 'Hold or drop to ${_fmt(drop)} kg',
          icon: Icons.trending_down_rounded,
          color: downColor,
        );
      }
    }
    return OverloadHint(
      message: 'Hold ${_fmt(lastWeight)} kg, aim higher reps',
      icon: Icons.trending_flat_rounded,
      color: holdColor,
    );
  }

  static double _nextStep(double w) {
    // Round up to the next 2.5 kg increment.
    final steps = (w / 2.5).floor() + 1;
    return steps * 2.5;
  }

  static String _fmt(double w) {
    if (w == w.roundToDouble()) return w.toInt().toString();
    return w.toStringAsFixed(1);
  }
}
