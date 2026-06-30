import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Maps a routine day name to a themed network image URL (Unsplash CDN)
/// and a per-muscle-group gradient for offline / fallback use.
class WorkoutPhotos {
  /// Returns the local asset path for [name]. Used as a secondary fallback
  /// if the network image also fails (e.g. the user dropped in their own
  /// photos under assets/images/workouts/).
  static String assetFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('chest') || n.contains('push')) return 'assets/images/workouts/chest.jpg';
    if (n.contains('back') || n.contains('pull')) return 'assets/images/workouts/back.jpg';
    if (n.contains('shoulder') || n.contains('delt')) return 'assets/images/workouts/shoulders.jpg';
    if (n.contains('arm') || n.contains('bicep') || n.contains('tricep')) return 'assets/images/workouts/arms.jpg';
    if (n.contains('leg') || n.contains('quad') || n.contains('hamstring')) return 'assets/images/workouts/legs.jpg';
    if (n.contains('glute') || n.contains('hip')) return 'assets/images/workouts/glutes.jpg';
    if (n.contains('core') || n.contains('abs')) return 'assets/images/workouts/core.jpg';
    if (n.contains('cardio') || n.contains('run')) return 'assets/images/workouts/cardio.jpg';
    return 'assets/images/workouts/default.jpg';
  }

  /// Returns a stable Unsplash CDN URL for a gym photo matching [name].
  /// URLs point to specific photo IDs so they never rotate or break.
  /// Gradient fallback renders instantly while the image loads.
  static String networkUrlFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('chest') || n.contains('push')) {
      return 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800&q=70&fit=crop';
    }
    if (n.contains('back') || n.contains('pull')) {
      return 'https://images.unsplash.com/photo-1603287681836-b174ce5074c2?w=800&q=70&fit=crop';
    }
    if (n.contains('shoulder') || n.contains('delt')) {
      return 'https://images.unsplash.com/photo-1532029837206-abbe2b7620e3?w=800&q=70&fit=crop';
    }
    if (n.contains('arm') || n.contains('bicep') || n.contains('tricep')) {
      return 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=800&q=70&fit=crop';
    }
    if (n.contains('leg') || n.contains('quad') || n.contains('hamstring')) {
      return 'https://images.unsplash.com/photo-1574680178050-55c6a6a96e0a?w=800&q=70&fit=crop';
    }
    if (n.contains('glute') || n.contains('hip')) {
      return 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=70&fit=crop';
    }
    if (n.contains('core') || n.contains('abs')) {
      return 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&q=70&fit=crop';
    }
    if (n.contains('cardio') || n.contains('run')) {
      return 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=800&q=70&fit=crop';
    }
    return 'https://images.unsplash.com/photo-1534438097545-a2c22c57f2ad?w=800&q=70&fit=crop';
  }

  /// Per-muscle-group gradient for when the network image hasn't loaded yet
  /// or the device is offline. Always renders instantly.
  static LinearGradient gradientFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('chest') || n.contains('push')) {
      return const LinearGradient(colors: [Color(0xFF1A0F0A), Color(0xFF3A1F10)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    }
    if (n.contains('back') || n.contains('pull')) {
      return const LinearGradient(colors: [Color(0xFF0A101A), Color(0xFF10203A)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    }
    if (n.contains('shoulder') || n.contains('delt')) {
      return const LinearGradient(colors: [Color(0xFF0F0A1A), Color(0xFF201535)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    }
    if (n.contains('arm') || n.contains('bicep') || n.contains('tricep')) {
      return const LinearGradient(colors: [Color(0xFF1A100A), Color(0xFF381F10)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    }
    if (n.contains('leg') || n.contains('quad') || n.contains('hamstring')) {
      return const LinearGradient(colors: [Color(0xFF0A1510), Color(0xFF102A1E)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    }
    if (n.contains('core') || n.contains('abs')) {
      return const LinearGradient(colors: [Color(0xFF100A1A), Color(0xFF1E1030)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    }
    if (n.contains('cardio') || n.contains('run')) {
      return const LinearGradient(colors: [Color(0xFF0A1A10), Color(0xFF103020)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    }
    return const LinearGradient(colors: [Color(0xFF111111), Color(0xFF1E1E1E)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  }
}

/// Full-bleed gym photo background. Tries network image first (cached),
/// falls back to the per-muscle gradient so the card always looks great.
/// Renders the gradient immediately as placeholder — no blank flash.
class WorkoutPhotoBackground extends StatelessWidget {
  final String dayName;
  final double overlayStrength;
  final Widget child;

  const WorkoutPhotoBackground({
    super.key,
    required this.dayName,
    required this.child,
    this.overlayStrength = 0.72,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = WorkoutPhotos.gradientFor(dayName);
    final url = WorkoutPhotos.networkUrlFor(dayName);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient renders first — no blank flash while network loads.
        Container(decoration: BoxDecoration(gradient: gradient)),
        // Network image fades in on top once cached.
        CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 400),
          placeholder: (_, _) => const SizedBox.shrink(),
          errorWidget: (_, _, _) => const SizedBox.shrink(),
        ),
        // Bottom-heavy darkening gradient — face/torso visible at top,
        // labels and CTAs legible at the bottom.
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: overlayStrength * 0.30),
                Colors.black.withValues(alpha: overlayStrength),
                Colors.black.withValues(alpha: overlayStrength * 1.10),
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
