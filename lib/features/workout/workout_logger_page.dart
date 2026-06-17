import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/routine.dart';
import '../../data/models/workout_session.dart';
import '../../services/workout/overload_advisor.dart';
import '../../services/workout/pr_tracker.dart';
import '../../state/providers.dart';
import '../../theme.dart';
import 'exercise_guide_sheet.dart';

class WorkoutLoggerPage extends ConsumerStatefulWidget {
  final String routineName;
  final RoutineDay day;
  const WorkoutLoggerPage({
    super.key,
    required this.routineName,
    required this.day,
  });

  @override
  ConsumerState<WorkoutLoggerPage> createState() => _WorkoutLoggerPageState();
}

class _WorkoutLoggerPageState extends ConsumerState<WorkoutLoggerPage> {
  WorkoutSession? _session;
  bool _starting = true;

  // Per-exercise UI state: list of set rows with controllers and `done` flag.
  final Map<int, List<_SetRowState>> _rowsByExercise = {};
  final Map<int, List<SetEntry>> _previousByExercise = {};
  // Best estimated-1RM per exercise BEFORE this session, used for PR
  // detection at log time.
  final Map<int, double> _previousBestE1RM = {};

  // Rest timer
  Timer? _restTimer;
  DateTime? _restStart;
  int _restSeconds = 0;
  int _restRemaining = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final repo = ref.read(workoutRepoProvider);
    final session = await repo.startSession(
      routineName: widget.routineName,
      routineDayName: widget.day.name,
    );
    final previous = <int, List<SetEntry>>{};
    final allSessions = await repo.sessionsSince(DateTime(1970));
    final bestE1RM = <int, double>{};
    for (final item in widget.day.items) {
      previous[item.exerciseId] =
          await repo.previousSetsFor(item.exerciseId);
      bestE1RM[item.exerciseId] = PrTracker.bestForExercise(
        allSessions,
        item.exerciseId,
        excludeSessionId: session.id,
      );
    }
    if (!mounted) return;
    setState(() {
      _session = session;
      _previousByExercise.addAll(previous);
      _previousBestE1RM.addAll(bestE1RM);
      for (final item in widget.day.items) {
        final prev = previous[item.exerciseId] ?? const [];
        final prevWeight = prev.isNotEmpty ? prev.first.weightKg : 0.0;
        final prevReps = prev.isNotEmpty ? prev.first.reps : item.targetRepsLow;
        _rowsByExercise[item.exerciseId] = List.generate(
          item.targetSets,
          (i) => _SetRowState(
            weight: TextEditingController(
                text: prevWeight > 0 ? _fmtWeight(prevWeight) : ''),
            reps: TextEditingController(
                text: prevReps > 0 ? prevReps.toString() : ''),
          ),
        );
      }
      _starting = false;
    });
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    for (final list in _rowsByExercise.values) {
      for (final r in list) {
        r.weight.dispose();
        r.reps.dispose();
      }
    }
    super.dispose();
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _restStart = DateTime.now();
      _restSeconds = seconds;
      _restRemaining = seconds;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      final elapsed = DateTime.now().difference(_restStart!).inSeconds;
      final remaining = _restSeconds - elapsed;
      if (remaining <= 0) {
        t.cancel();
        setState(() {
          _restRemaining = 0;
          _restStart = null;
        });
        HapticFeedback.mediumImpact();
      } else {
        setState(() => _restRemaining = remaining);
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() {
      _restStart = null;
      _restRemaining = 0;
    });
  }

  Future<void> _logSet(RoutinePlanItem item, int rowIndex) async {
    final row = _rowsByExercise[item.exerciseId]![rowIndex];
    if (row.done) return;
    final weight = double.tryParse(row.weight.text.trim()) ?? 0;
    final reps = int.tryParse(row.reps.text.trim()) ?? 0;
    if (reps <= 0) return;

    final session = _session;
    if (session == null) return;

    final entry = SetEntry()
      ..exerciseId = item.exerciseId
      ..exerciseName = item.exerciseName
      ..setNumber = rowIndex + 1
      ..weightKg = weight
      ..reps = reps
      ..completedAt = DateTime.now();
    session.sets.add(entry);
    await ref.read(workoutRepoProvider).updateSession(session);

    // PR detection
    final newE1RM = PrTracker.estimated1RM(weight, reps);
    final priorBest = _previousBestE1RM[item.exerciseId] ?? 0;
    final isPr = priorBest > 0 && newE1RM > priorBest;
    if (isPr) {
      _previousBestE1RM[item.exerciseId] = newE1RM;
    }

    if (!mounted) return;
    setState(() {
      row.done = true;
      // Pre-fill next set with the same values
      final nextIdx = rowIndex + 1;
      final rows = _rowsByExercise[item.exerciseId]!;
      if (nextIdx < rows.length) {
        final next = rows[nextIdx];
        if (next.weight.text.trim().isEmpty) {
          next.weight.text = row.weight.text;
        }
        if (next.reps.text.trim().isEmpty) {
          next.reps.text = row.reps.text;
        }
      }
    });
    if (isPr) {
      HapticFeedback.heavyImpact();
      _prToast(item.exerciseName, newE1RM);
    } else {
      HapticFeedback.lightImpact();
    }
    if (item.restSeconds > 0) _startRest(item.restSeconds);
  }

  void _prToast(String name, double newBest) {
    final fmt = newBest == newBest.roundToDouble()
        ? newBest.toInt().toString()
        : newBest.toStringAsFixed(1);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(Icons.emoji_events_rounded,
                color: Colors.black, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'New PR · $name · est. $fmt kg',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ));
  }

  Future<void> _finish() async {
    final session = _session;
    if (session == null) return;
    final ok = await _confirmFinish(session.sets.isEmpty);
    if (!ok) return;
    await ref.read(workoutRepoProvider).completeSession(session.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<bool> _confirmFinish(bool empty) async {
    if (!empty) return true;
    final res = await showDialog<bool>(
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
              Text('Finish without logging?',
                  style: AppText.sectionTitle.copyWith(fontSize: 17)),
              const SizedBox(height: 6),
              Text(
                  'You haven\'t logged any sets. The session will be saved empty.',
                  style: AppText.body),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text('Keep going',
                        style: AppText.body
                            .copyWith(color: AppColors.textPrimary)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text('Finish',
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
    return res ?? false;
  }

  Future<void> _discardWorkout() async {
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
              Text('Discard workout?',
                  style: AppText.sectionTitle.copyWith(fontSize: 17)),
              const SizedBox(height: 6),
              Text(
                  'All logged sets in this session will be deleted. This can\'t be undone.',
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
                    child: Text('Discard',
                        style: AppText.body.copyWith(
                            color: const Color(0xFFFF6B6B),
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
    final session = _session;
    if (session == null) return;
    if (!mounted) return;
    final navigator = Navigator.of(context);
    await ref.read(workoutRepoProvider).deleteSession(session.id);
    if (mounted) navigator.pop();
  }

  Future<bool> _confirmExit() async {
    final session = _session;
    if (session == null) return true;
    if (session.sets.isEmpty) {
      // Drop the empty session
      await ref.read(workoutRepoProvider).deleteSession(session.id);
      return true;
    }
    final res = await showDialog<bool>(
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
              Text('Leave workout?',
                  style: AppText.sectionTitle.copyWith(fontSize: 17)),
              const SizedBox(height: 6),
              Text(
                  'Your sets are saved. You can come back and continue from the workout tab.',
                  style: AppText.body),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text('Stay',
                        style: AppText.body
                            .copyWith(color: AppColors.textPrimary)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text('Leave',
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
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmExit()) {
          if (mounted) navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          elevation: 0,
          title: Text(widget.day.name, style: AppText.sectionTitle),
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded,
                  color: AppColors.textPrimary),
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppColors.stroke),
              ),
              onSelected: (v) {
                if (v == 'discard') _discardWorkout();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'discard',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 18, color: const Color(0xFFFF6B6B)),
                      const SizedBox(width: 10),
                      Text('Discard workout',
                          style: AppText.body.copyWith(
                              color: const Color(0xFFFF6B6B),
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _starting
            ? Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.2, color: AppColors.accent),
                ),
              )
            : SafeArea(
                child: Column(
                  children: [
                    if (_restStart != null) _RestBanner(
                      remaining: _restRemaining,
                      total: _restSeconds,
                      onSkip: _skipRest,
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        itemCount: widget.day.items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 14),
                        itemBuilder: (_, i) {
                          final item = widget.day.items[i];
                          final prev =
                              _previousByExercise[item.exerciseId] ?? const [];
                          return _ExerciseCard(
                            item: item,
                            rows: _rowsByExercise[item.exerciseId]!,
                            previous: prev,
                            overloadHint: OverloadAdvisor.hintFor(
                              item: item,
                              previousSets: prev,
                              upColor: AppColors.accent,
                              holdColor: AppColors.textSecondary,
                              downColor: AppColors.water,
                            ),
                            onShowGuide: () =>
                                ExerciseGuideSheet.show(
                                  context,
                                  exerciseId: item.exerciseId,
                                  fallbackName: item.exerciseName,
                                ),
                            onLog: (rowIndex) => _logSet(item, rowIndex),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: GestureDetector(
                        onTap: _finish,
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Finish workout',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  static String _fmtWeight(double w) {
    if (w == w.roundToDouble()) return w.toInt().toString();
    return w.toStringAsFixed(1);
  }
}

class _SetRowState {
  final TextEditingController weight;
  final TextEditingController reps;
  bool done = false;
  _SetRowState({required this.weight, required this.reps});
}

class _RestBanner extends StatelessWidget {
  final int remaining;
  final int total;
  final VoidCallback onSkip;
  const _RestBanner({
    required this.remaining,
    required this.total,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final mins = remaining ~/ 60;
    final secs = remaining % 60;
    final progress = total == 0 ? 0.0 : remaining / total;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 18, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Rest',
                        style: AppText.body.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(
                        '${mins.toString().padLeft(1, '0')}:${secs.toString().padLeft(2, '0')}',
                        style: AppText.bigNumber.copyWith(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: AppColors.surfaceHigh,
                    valueColor: AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onSkip,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Text('Skip',
                  style: AppText.meta.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final RoutinePlanItem item;
  final List<_SetRowState> rows;
  final List<SetEntry> previous;
  final OverloadHint? overloadHint;
  final VoidCallback onShowGuide;
  final void Function(int rowIndex) onLog;
  const _ExerciseCard({
    required this.item,
    required this.rows,
    required this.previous,
    required this.overloadHint,
    required this.onShowGuide,
    required this.onLog,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
              Expanded(
                child: GestureDetector(
                  onTap: onShowGuide,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(item.exerciseName,
                                style: AppText.sectionTitle
                                    .copyWith(fontSize: 16)),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.info_outline_rounded,
                              size: 14, color: AppColors.textTertiary),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.targetSets} × ${item.targetRepsLow}–${item.targetRepsHigh} reps',
                        style: AppText.meta.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (overloadHint != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: overloadHint!.color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: overloadHint!.color.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(overloadHint!.icon,
                      size: 13, color: overloadHint!.color),
                  const SizedBox(width: 6),
                  Text(
                    overloadHint!.message,
                    style: TextStyle(
                      color: overloadHint!.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          for (var i = 0; i < rows.length; i++) ...[
            _SetRow(
              setNumber: i + 1,
              state: rows[i],
              previous: i < previous.length ? previous[i] : null,
              onLog: () => onLog(i),
            ),
            if (i < rows.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

String _fmtPrev(SetEntry s) {
  final w = s.weightKg;
  final wStr =
      w == w.roundToDouble() ? w.toInt().toString() : w.toStringAsFixed(1);
  return w > 0 ? '$wStr kg × ${s.reps}' : '${s.reps} reps';
}

class _SetRow extends StatelessWidget {
  final int setNumber;
  final _SetRowState state;
  final SetEntry? previous;
  final VoidCallback onLog;
  const _SetRow({
    required this.setNumber,
    required this.state,
    required this.previous,
    required this.onLog,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: state.done
            ? AppColors.protein.withValues(alpha: 0.08)
            : AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: state.done
              ? AppColors.protein.withValues(alpha: 0.3)
              : AppColors.stroke,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                alignment: Alignment.center,
                child: Text('$setNumber',
                    style: AppText.body.copyWith(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    )),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _NumField(
                  controller: state.weight,
                  hint: 'kg',
                  enabled: !state.done,
                  allowDecimal: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('×',
                    style: AppText.meta.copyWith(
                        color: AppColors.textTertiary, fontSize: 14)),
              ),
              Expanded(
                child: _NumField(
                  controller: state.reps,
                  hint: 'reps',
                  enabled: !state.done,
                  allowDecimal: false,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: state.done ? null : onLog,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color:
                        state.done ? AppColors.protein : AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    state.done ? Icons.check_rounded : Icons.add_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          if (previous != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 4, 0, 0),
              child: Text(
                'Last: ${_fmtPrev(previous!)}',
                style: AppText.meta.copyWith(
                    fontSize: 11, color: AppColors.textTertiary),
              ),
            ),
        ],
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool enabled;
  final bool allowDecimal;
  const _NumField({
    required this.controller,
    required this.hint,
    required this.enabled,
    required this.allowDecimal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.stroke),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: allowDecimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        inputFormatters: allowDecimal
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
            : [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        cursorColor: AppColors.accent,
        style: AppText.bigNumber.copyWith(
          fontSize: 16,
          color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          hintText: hint,
          hintStyle: AppText.meta.copyWith(
              color: AppColors.textTertiary, fontSize: 13),
        ),
      ),
    );
  }
}
