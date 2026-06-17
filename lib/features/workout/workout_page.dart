import 'package:flutter/material.dart';
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

class WorkoutPage extends ConsumerWidget {
  const WorkoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routineAsync = ref.watch(activeRoutineProvider);
    final profileAsync = ref.watch(profileStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text('Workout', style: AppText.sectionTitle),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: profileAsync.when(
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(msg,
            style: AppText.body.copyWith(color: AppColors.textPrimary)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(Icons.fitness_center_rounded,
                size: 32, color: AppColors.accent),
          ),
          const SizedBox(height: 22),
          Text('Let\'s build\nyour routine.',
              style: AppText.giantNumber.copyWith(
                fontSize: 32,
                height: 1.1,
                letterSpacing: -0.8,
              )),
          const SizedBox(height: 12),
          Text(
            'Based on your goal (${_goalLabel(widget.profile.goal)}) and ${widget.profile.trainingDaysPerWeek} training days a week, AI will draft a starter split. You can edit it.',
            style: AppText.body.copyWith(fontSize: 14),
          ),
          const Spacer(flex: 2),
          GestureDetector(
            onTap: _busy ? null : _generate,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 54,
              decoration: BoxDecoration(
                color: _busy
                    ? AppColors.accent.withValues(alpha: 0.5)
                    : AppColors.accent,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.black))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome_rounded,
                            color: Colors.black, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Generate my routine',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _busy
                ? null
                : () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const RoutineBuilderPage())),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.stroke),
              ),
              alignment: Alignment.center,
              child: Text(
                'Or build your own →',
                style: AppText.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _goalLabel(Object goal) {
    return goal.toString().split('.').last;
  }
}

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
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          sliver: SliverList.list(children: [
            Text('TODAY', style: AppText.label),
            const SizedBox(height: 10),
            todayAsync.when(
              loading: () => const SizedBox(height: 80),
              error: (_, _) => const SizedBox.shrink(),
              data: (day) => _TodayCard(routine: routine, day: day),
            ),
            const SizedBox(height: 22),
            _WeeklyVolumeCard(
              allSessions: allSessionsAsync.valueOrNull ?? const [],
              exercises: exercisesAsync.valueOrNull ?? const [],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(child: Text('THIS WEEK', style: AppText.label)),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) =>
                            RoutineBuilderPage(edit: routine)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded,
                          size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text('Edit',
                          style: AppText.label.copyWith(
                              color: AppColors.accent,
                              letterSpacing: 0.6)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: () => _confirmReplace(context, ref),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text('Regenerate',
                          style: AppText.label.copyWith(
                              color: AppColors.accent,
                              letterSpacing: 0.6)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ]),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          sliver: SliverList.builder(
            itemCount: routine.days.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DayRow(day: routine.days[i]),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverList.list(children: [
            Row(
              children: [
                Expanded(
                    child: Text('RECENT SESSIONS', style: AppText.label)),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PrPage()),
                  ),
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
            const SizedBox(height: 10),
            if (sessions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.stroke),
                ),
                child:
                    Text('No workouts logged yet.', style: AppText.body),
              ),
          ]),
        ),
        if (sessions.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
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
          )
        else
          const SliverPadding(padding: EdgeInsets.only(bottom: 28)),
      ],
    );
  }

  Future<void> _confirmReplace(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Replace this routine?',
                  style: AppText.sectionTitle.copyWith(fontSize: 17)),
              const SizedBox(height: 8),
              Text(
                  'AI will draft a new split. Your past sessions are kept.',
                  style: AppText.body),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text('Cancel',
                        style: AppText.body
                            .copyWith(color: AppColors.textPrimary)),
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
            e is AiException ? e.message : 'Could not regenerate routine.',
            style: AppText.body.copyWith(color: AppColors.textPrimary)),
      ));
    }
  }
}

class _TodayCard extends StatelessWidget {
  final Routine routine;
  final RoutineDay? day;
  const _TodayCard({required this.routine, required this.day});

  @override
  Widget build(BuildContext context) {
    if (day == null || day!.isRest) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
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
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('REST DAY', style: AppText.label),
                  const SizedBox(height: 4),
                  Text('Recovery matters.', style: AppText.sectionTitle),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final d = day!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.fitness_center_rounded,
                    color: AppColors.accent, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.name.toUpperCase(), style: AppText.label),
                    const SizedBox(height: 4),
                    Text(routine.name,
                        style: AppText.sectionTitle.copyWith(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(
                      '${d.items.length} exercises · ~${_estimateMinutes(d)} min',
                      style: AppText.meta.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (d.items.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: d.items.take(4).map((i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(i.exerciseName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.body.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 13)),
                        ),
                        Text(
                          '${i.targetSets}×${i.targetRepsLow}–${i.targetRepsHigh}',
                          style: AppText.meta.copyWith(
                              fontSize: 12,
                              color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  );
                }).toList()
                  ..addAll([
                    if (d.items.length > 4)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 16),
                        child: Text('+ ${d.items.length - 4} more',
                            style: AppText.meta.copyWith(fontSize: 11)),
                      ),
                  ]),
              ),
            ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WorkoutLoggerPage(
                    routineName: routine.name,
                    day: d,
                  ),
                ),
              );
            },
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded,
                      color: Colors.black, size: 22),
                  const SizedBox(width: 4),
                  Text(
                    'Start workout',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _estimateMinutes(RoutineDay d) {
    // Rough: 4 min per working set including rest.
    final sets = d.items.fold<int>(0, (s, i) => s + i.targetSets);
    return (sets * 4).clamp(20, 120);
  }
}

class _DayRow extends StatelessWidget {
  final RoutineDay day;
  const _DayRow({required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: day.isRest
                  ? AppColors.water.withValues(alpha: 0.14)
                  : AppColors.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              _weekdayLabel(day.weekday),
              style: TextStyle(
                color: day.isRest ? AppColors.water : AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(day.name,
                style: AppText.body.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ),
          Text(
            day.isRest ? 'Rest' : '${day.items.length} exercises',
            style: AppText.meta.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _weekdayLabel(int w) {
    const names = ['—', 'M', 'T', 'W', 'T', 'F', 'S', 'S'];
    if (w < 1 || w > 7) return '—';
    return names[w];
  }
}

class _SessionRow extends StatelessWidget {
  final WorkoutSession session;
  final double bodyWeightKg;
  const _SessionRow({required this.session, required this.bodyWeightKg});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, h:mm a').format(session.startedAt);
    final durMin = session.duration.inMinutes;
    final kcal = VolumeCalc.sessionCalories(
      bodyWeightKg: bodyWeightKg,
      duration: session.duration,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded,
              size: 18,
              color: session.completedAt != null
                  ? AppColors.protein
                  : AppColors.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.routineDayName,
                    style: AppText.body.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(date, style: AppText.meta.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${session.sets.length} sets',
                  style: AppText.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
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

class _WeeklyVolumeCard extends StatelessWidget {
  final List<WorkoutSession> allSessions;
  final List<dynamic> exercises; // List<Exercise>; typed as dynamic to keep import lean
  const _WeeklyVolumeCard({
    required this.allSessions,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    if (allSessions.isEmpty || exercises.isEmpty) {
      return const SizedBox.shrink();
    }
    final since = DateTime.now().subtract(const Duration(days: 7));
    final recent =
        allSessions.where((s) => s.startedAt.isAfter(since)).toList();
    if (recent.isEmpty) return const SizedBox.shrink();
    final lookup = <int, List<MuscleGroup>>{
      for (final e in exercises) (e.id as int): (e.muscleGroups as List<MuscleGroup>)
    };
    final volume = VolumeCalc.setsByMuscleGroup(
      sessions: recent,
      exerciseMuscleGroups: lookup,
    );
    if (volume.isEmpty) return const SizedBox.shrink();

    final entries = volume.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: 6),
              Text('LAST 7 DAYS', style: AppText.label),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in entries)
                _VolumeChip(
                  label: _label(e.key),
                  sets: e.value,
                  color: _muscleColor(e.key),
                ),
            ],
          ),
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

class _VolumeChip extends StatelessWidget {
  final String label;
  final int sets;
  final Color color;
  const _VolumeChip({
    required this.label,
    required this.sets,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$sets',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
