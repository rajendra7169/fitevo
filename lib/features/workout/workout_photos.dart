import 'package:flutter/material.dart';

import '../../theme.dart';

/// Maps a routine day name (e.g. "Push Day", "Chest & Triceps", "Leg
/// day") to an asset path under assets/images/workouts/. Falls back to
/// `default.jpg`. Files are user-supplied (see README in that folder).
class WorkoutPhotos {
  /// Returns the best-fit asset path for a given day name. Always
  /// returns *something*; the [WorkoutPhotoBackground] widget below
  /// gracefully handles missing files.
  static String forDayName(String name) {
    final n = name.toLowerCase();
    if (n.contains('chest') || n.contains('push')) return 'assets/images/workouts/chest.jpg';
    if (n.contains('back') || n.contains('pull')) return 'assets/images/workouts/back.jpg';
    if (n.contains('shoulder') || n.contains('delt')) return 'assets/images/workouts/shoulders.jpg';
    if (n.contains('arm') || n.contains('bicep') || n.contains('tricep')) return 'assets/images/workouts/arms.jpg';
    if (n.contains('leg') || n.contains('quad') || n.contains('hamstring')) return 'assets/images/workouts/legs.jpg';
    if (n.contains('glute') || n.contains('hip')) return 'assets/images/workouts/glutes.jpg';
    if (n.contains('core') || n.contains('abs')) return 'assets/images/workouts/core.jpg';
    if (n.contains('cardio') || n.contains('run')) return 'assets/images/workouts/cardio.jpg';
    if (n.contains('full') || n.contains('total')) return 'assets/images/workouts/default.jpg';
    return 'assets/images/workouts/default.jpg';
  }
}

/// Full-bleed photo background with a darkening gradient overlay so text
/// stays readable. Falls back to a flat surface color when the asset is
/// missing, so the app doesn't crash before you've dropped in photos.
class WorkoutPhotoBackground extends StatelessWidget {
  final String assetPath;
  /// 0 (no darkening) … 1 (solid). Default 0.55 keeps photo visible
  /// but lets white text pop. Bump higher for text-dense screens.
  final double overlayStrength;
  final Widget child;
  const WorkoutPhotoBackground({
    super.key,
    required this.assetPath,
    required this.child,
    this.overlayStrength = 0.55,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image first; errorBuilder swaps in a flat surface when the
        // asset isn't bundled yet so dev iterations don't break.
        Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surfaceHigh,
                  AppColors.surface,
                ],
              ),
            ),
          ),
        ),
        // Bottom-heavy darkening gradient — keeps the top brighter so
        // the athlete's face/torso reads, while the bottom (where labels
        // and CTAs typically live) stays legible.
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: overlayStrength * 0.35),
                Colors.black.withValues(alpha: overlayStrength),
                Colors.black.withValues(alpha: overlayStrength * 1.15),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        child,
      ],
    );
  }
}
