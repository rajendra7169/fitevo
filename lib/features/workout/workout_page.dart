import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/enums.dart';
import '../../data/models/profile.dart';
import '../../data/models/routine.dart';
import '../../data/models/workout_session.dart';
import '../../services/ai/ai_service.dart';
import '../../services/workout/volume_calc.dart';
import '../../state/providers.dart';
import '../../theme.dart';
import 'pr_page.dart';
import 'routine_builder_page.dart';
import 'workout_logger_page.dart';
import 'workout_photos.dart';

class WorkoutPage extends ConsumerWidget {
  const WorkoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routineAsync = ref.watch(activeRoutineProvider);
    final profileAsync = ref.watch(profileStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: profileAsync.when(
        loading: () => _busy(),
        error: (_, _) => _busy(),
        data: (profile) {
          if (profile == null) return _busy();
          return routineAsync.when(
            loading: () => _busy(),
            error: (_, _) => _busy(),
            data: (routine) => routine == null
                ? _EmptyState(profile: profile)
                : _RoutineView(routine: routine, profile: profile),
          );
        },
      ),
    );
  }

  Widget _busy() => Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
              strokeWidth: 2.2, color: AppColors.accent),
        ),
      );
}

// ===========================================================================
// EMPTY STATE — no routine yet
// ===========================================================================

class _EmptyState extends ConsumerStatefulWidget {
  final Profile profile;
  const _EmptyState({required this.profile});

  @override
  ConsumerState<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends ConsumerState<_EmptyState> {
  bool _busy = false;

  Future<void> _generate() async {
    setState(() => _busy = true);
    try {
      await ref.read(routineGeneratorProvider).generateAndActivate(
            goal: widget.profile.goal,
            trainingDaysPerWeek: widget.profile.trainingDaysPerWeek,
          );
    } catch (e) {
      if (!mounted) return;
      _toast(e is AiException ? e.message : 'Could not generate routine.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        backgroundColor: AppColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content:
            Text(msg, style: AppText.body.copyWith(color: AppColors.textPrimary)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Sporty dark background with diagonal gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D0D0D), Color(0xFF161616)],
            ),
          ),
        ),
        // Accent glow blobs — top-right + bottom-left
        Positioned(
          top: -100,
          right: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.07),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          left: -40,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.05),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 52),
                // Brand mark
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.fitness_center_rounded,
                          size: 16, color: AppColors.onAccent),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'WORKOUT',
                      style: AppText.label.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 2,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 60.ms, duration: 280.ms),

                const SizedBox(height: 32),

                // Big hero headline
                Text(
                  'BUILD\nYOUR\nROUTINE.',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -2.0,
                    height: 0.95,
                  ),
                ).animate().fadeIn(delay: 120.ms, duration: 300.ms).slideY(begin: 0.08, end: 0),

                const SizedBox(height: 16),

                Text(
                  'AI builds a smart split based on your goal and ${widget.profile.trainingDaysPerWeek} training days a week.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 180.ms, duration: 280.ms),

                const SizedBox(height: 28),

                // Feature pills
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FeaturePill(Icons.auto_awesome_rounded, 'AI POWERED'),
                    _FeaturePill(Icons.person_rounded, _goalLabel(widget.profile.goal)),
                    _FeaturePill(Icons.trending_up_rounded, 'PROGRESSIVE'),
                  ],
                ).animate().fadeIn(delay: 220.ms, duration: 280.ms),

                const Spacer(),

                // Generate button
                GestureDetector(
                  onTap: _busy ? null : _generate,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 62,
                    decoration: BoxDecoration(
                      color: _busy
                          ? AppColors.accent.withValues(alpha: 0.5)
                          : AppColors.accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: _busy
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: AppColors.onAccent))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome_rounded,
                                  color: AppColors.onAccent, size: 18),
                              const SizedBox(width: 10),
                              Text(
                                'GENERATE MY ROUTINE',
                                style: TextStyle(
                                  color: AppColors.onAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                  ),
                ).animate().fadeIn(delay: 280.ms, duration: 280.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 12),

                // Build-your-own ghost button
                GestureDetector(
                  onTap: _busy
                      ? null
                      : () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const RoutineBuilderPage())),
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.build_rounded,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.65)),
                        const SizedBox(width: 8),
                        Text(
                          'Build your own',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.45)),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 320.ms, duration: 280.ms),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _goalLabel(FitnessGoal g) {
    switch (g) {
      case FitnessGoal.buildMuscle:
        return 'BUILD MUSCLE';
      case FitnessGoal.loseFat:
        return 'LOSE FAT';
      case FitnessGoal.recomp:
        return 'RECOMP';
      case FitnessGoal.generalFitness:
        return 'FITNESS';
    }
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.accent.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// ROUTINE VIEW — has an active routine
// ===========================================================================

class _RoutineView extends ConsumerWidget {
  final Routine routine;
  final Profile profile;
  const _RoutineView({required this.routine, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todaysRoutineDayProvider);
    final sessionsAsync = ref.watch(recentSessionsProvider);
    final exercisesAsync = ref.watch(exercisesProvider);
    final allSessionsAsync = ref.watch(allSessionsProvider);
    final sessions = sessionsAsync.valueOrNull ?? const [];

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        // ── Sporty header ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _SportyHeader(
            routine: routine,
            onRegenerate: () => _confirmReplace(context, ref),
            onEdit: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => RoutineBuilderPage(edit: routine))),
            onDelete: () => _confirmDelete(context, ref, routine),
          ),
        ),

        // ── TODAY card ─────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          sliver: SliverToBoxAdapter(
            child: todayAsync.when(
              loading: () => const SizedBox(height: 200),
              error: (_, _) => const SizedBox.shrink(),
              data: (day) => _TodayCard(routine: routine, day: day),
            ),
          ),
        ),

        // ── Weekly volume chart ────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          sliver: SliverToBoxAdapter(
            child: _WeeklyVolumeCard(
              allSessions: allSessionsAsync.valueOrNull ?? const [],
              exercises: exercisesAsync.valueOrNull ?? const [],
            ),
          ),
        ),

        // ── THIS WEEK label + actions ──────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(child: Text('THIS WEEK', style: AppText.label)),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PrPage())),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events_rounded,
                          size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text('PRs',
                          style: AppText.label.copyWith(
                              color: AppColors.accent, letterSpacing: 0.6)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Day rows ──────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          sliver: SliverList.builder(
            itemCount: routine.days.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DayRow(day: routine.days[i]),
            ),
          ),
        ),

        // ── Recent sessions ───────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          sliver: SliverToBoxAdapter(
            child: Text('RECENT SESSIONS', style: AppText.label),
          ),
        ),

        if (sessions.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: Row(
                  children: [
                    Icon(Icons.fitness_center_rounded,
                        size: 20, color: AppColors.textTertiary),
                    const SizedBox(width: 12),
                    Text('No workouts logged yet — start today!',
                        style: AppText.body.copyWith(fontSize: 13)),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList.builder(
              itemCount: sessions.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SessionRow(
                  session: sessions[i],
                  bodyWeightKg: profile.weightKg,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmReplace(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Replace this routine?',
                  style: AppText.sectionTitle.copyWith(fontSize: 17)),
              const SizedBox(height: 8),
              Text('AI will draft a new split. Your past sessions are kept.',
                  style: AppText.body),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text('Cancel',
                        style:
                            AppText.body.copyWith(color: AppColors.textPrimary)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text('Regenerate',
                        style: AppText.body.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(workoutRepoProvider).deleteRoutine(routine.id);
      await ref.read(routineGeneratorProvider).generateAndActivate(
            goal: profile.goal,
            trainingDaysPerWeek: profile.trainingDaysPerWeek,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
            e is AiException ? e.message : 'Could not regenerate routine.',
            style: AppText.body.copyWith(color: AppColors.textPrimary)),
      ));
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Routine routine) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Delete this routine?',
                  style: AppText.sectionTitle.copyWith(fontSize: 17)),
              const SizedBox(height: 8),
              Text(
                  'All days in "${routine.name}" will be removed. Past sessions are kept.',
                  style: AppText.body),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text('Cancel',
                        style:
                            AppText.body.copyWith(color: AppColors.textPrimary)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text('Delete',
                        style: AppText.body.copyWith(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(workoutRepoProvider).deleteRoutine(routine.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text('Could not delete routine.',
            style: AppText.body.copyWith(color: AppColors.textPrimary)),
      ));
    }
  }
}

// ── Sporty page header ────────────────────────────────────────────────────

class _SportyHeader extends StatelessWidget {
  final Routine routine;
  final VoidCallback onRegenerate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SportyHeader({
    required this.routine,
    required this.onRegenerate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayName = DateFormat('EEEE').format(now);
    final dateName = DateFormat('MMM d').format(now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dayName, $dateName'.toUpperCase(),
                  style: AppText.label.copyWith(
                      fontSize: 10, color: AppColors.textTertiary, letterSpacing: 1.2),
                ),
                const SizedBox(height: 4),
                Text(
                  routine.name,
                  style: AppText.sectionTitle.copyWith(fontSize: 22),
                ),
              ],
            ),
          ),
          // Overflow menu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppColors.stroke),
            ),
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'regen') onRegenerate();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: _menuItem(Icons.edit_rounded, 'Edit routine', AppColors.textPrimary),
              ),
              PopupMenuItem(
                value: 'regen',
                child: _menuItem(Icons.auto_awesome_rounded, 'Regenerate with AI', AppColors.accent),
              ),
              PopupMenuItem(
                value: 'delete',
                child: _menuItem(Icons.delete_outline_rounded, 'Delete routine', AppColors.danger),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, Color color) => Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(label,
              style: AppText.body
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      );
}

// ── Today card ────────────────────────────────────────────────────────────

class _TodayCard extends StatelessWidget {
  final Routine routine;
  final RoutineDay? day;
  const _TodayCard({required this.routine, required this.day});

  @override
  Widget build(BuildContext context) {
    if (day == null || day!.isRest) return _RestDayCard();
    final d = day!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 230,
        child: WorkoutPhotoBackground(
          dayName: d.name,
          overlayStrength: 0.70,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: TODAY badge + time estimate
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'TODAY',
                        style: TextStyle(
                          color: AppColors.onAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer_rounded,
                              size: 12, color: Colors.white.withValues(alpha: 0.8)),
                          const SizedBox(width: 4),
                          Text(
                            '~${_estimateMinutes(d)} MIN',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Day name
                Text(
                  d.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                // Exercise preview
                if (d.items.isNotEmpty)
                  Text(
                    d.items.take(3).map((e) => e.exerciseName).join(' · ') +
                        (d.items.length > 3 ? ' +${d.items.length - 3}' : ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.60),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 14),
                // Start button
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WorkoutLoggerPage(
                        routineName: routine.name,
                        day: d,
                      ),
                    ),
                  ),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'START WORKOUT',
                          style: TextStyle(
                            color: AppColors.onAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded,
                            color: AppColors.onAccent, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _estimateMinutes(RoutineDay d) {
    final sets = d.items.fold<int>(0, (s, i) => s + i.targetSets);
    return (sets * 4).clamp(20, 120);
  }
}

class _RestDayCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.water.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.self_improvement_rounded,
                color: AppColors.water, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REST DAY',
                  style: AppText.label
                      .copyWith(color: AppColors.water, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text('Recovery is where gains happen.',
                  style: AppText.sectionTitle.copyWith(fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Day row ───────────────────────────────────────────────────────────────

class _DayRow extends StatelessWidget {
  final RoutineDay day;
  const _DayRow({required this.day});

  @override
  Widget build(BuildContext context) {
    final isRest = day.isRest;
    final accentColor = isRest ? AppColors.water : AppColors.accent;

    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.stroke),
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        children: [
          // Left accent bar
          Container(
            width: 4,
            color: accentColor.withValues(alpha: 0.8),
          ),
          // Weekday chip
          SizedBox(
            width: 48,
            child: Center(
              child: Text(
                _weekdayLabel(day.weekday),
                style: TextStyle(
                  color: accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.stroke),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  isRest ? 'Rest & recover' : '${day.items.length} exercises',
                  style: AppText.meta.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          if (!isRest)
            Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  String _weekdayLabel(int w) {
    const names = ['—', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    if (w < 1 || w > 7) return '—';
    return names[w];
  }
}

// ── Weekly volume horizontal bar chart ───────────────────────────────────

class _WeeklyVolumeCard extends StatelessWidget {
  final List<WorkoutSession> allSessions;
  final List<dynamic> exercises;

  const _WeeklyVolumeCard({
    required this.allSessions,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    if (allSessions.isEmpty || exercises.isEmpty) return const SizedBox.shrink();
    final since = DateTime.now().subtract(const Duration(days: 7));
    final recent =
        allSessions.where((s) => s.startedAt.isAfter(since)).toList();
    if (recent.isEmpty) return const SizedBox.shrink();

    final lookup = <int, List<MuscleGroup>>{
      for (final e in exercises)
        (e.id as int): (e.muscleGroups as List<MuscleGroup>)
    };
    final volume = VolumeCalc.setsByMuscleGroup(
      sessions: recent,
      exerciseMuscleGroups: lookup,
    );
    if (volume.isEmpty) return const SizedBox.shrink();

    final entries = volume.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxSets = entries.first.value;
    final top = entries.take(6).toList();

    // Total working sets this week
    final totalSets = recent.fold<int>(
        0, (sum, s) => sum + s.sets.where((e) => !e.isWarmup).length);
    final totalMins =
        recent.fold<int>(0, (sum, s) => sum + s.duration.inMinutes);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, size: 16, color: AppColors.accent),
              const SizedBox(width: 6),
              Text('WEEKLY VOLUME', style: AppText.label),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$totalSets sets · ${totalMins}m',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bar rows
          ...top.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _VolumeBar(
                  label: _label(e.key),
                  sets: e.value,
                  maxSets: maxSets,
                  color: _muscleColor(e.key),
                ),
              )),
        ],
      ),
    );
  }

  String _label(MuscleGroup g) {
    final n = g.name;
    return n[0].toUpperCase() + n.substring(1);
  }

  Color _muscleColor(MuscleGroup g) {
    switch (g) {
      case MuscleGroup.chest:
      case MuscleGroup.triceps:
      case MuscleGroup.shoulders:
        return AppColors.fat;
      case MuscleGroup.back:
      case MuscleGroup.biceps:
      case MuscleGroup.forearms:
        return AppColors.protein;
      case MuscleGroup.quads:
      case MuscleGroup.hamstrings:
      case MuscleGroup.glutes:
      case MuscleGroup.calves:
        return AppColors.water;
      case MuscleGroup.core:
        return AppColors.fiber;
      case MuscleGroup.cardio:
      case MuscleGroup.fullBody:
        return AppColors.streak;
    }
  }
}

class _VolumeBar extends StatelessWidget {
  final String label;
  final int sets;
  final int maxSets;
  final Color color;

  const _VolumeBar({
    required this.label,
    required this.sets,
    required this.maxSets,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxSets == 0 ? 0.0 : (sets / maxSets).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: AppText.meta.copyWith(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: LayoutBuilder(builder: (_, c) {
            return Stack(
              children: [
                // Track
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Fill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  height: 8,
                  width: c.maxWidth * fraction,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            );
          }),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 24,
          child: Text(
            '$sets',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Session row ───────────────────────────────────────────────────────────

class _SessionRow extends StatelessWidget {
  final WorkoutSession session;
  final double bodyWeightKg;
  const _SessionRow({required this.session, required this.bodyWeightKg});

  @override
  Widget build(BuildContext context) {
    final isComplete = session.completedAt != null;
    final durMin = session.duration.inMinutes;
    final kcal = VolumeCalc.sessionCalories(
      bodyWeightKg: bodyWeightKg,
      duration: session.duration,
    );
    final workSets = session.sets.where((s) => !s.isWarmup).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isComplete
              ? AppColors.protein.withValues(alpha: 0.25)
              : AppColors.stroke,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isComplete
                  ? AppColors.protein.withValues(alpha: 0.12)
                  : AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isComplete ? Icons.check_rounded : Icons.timer_rounded,
              color: isComplete ? AppColors.protein : AppColors.textTertiary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.routineDayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d · h:mm a').format(session.startedAt),
                  style: AppText.meta.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$workSets sets',
                style: AppText.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                kcal > 0 ? '$durMin min · ~$kcal kcal' : '$durMin min',
                style: AppText.meta.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
