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
import 'workout_photos.dart';

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

enum _LoggerView { focus, list }

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

  // ---- Focus-mode state -----------------------------------------------------
  // Focus mode is the new sporty per-set view (one big screen at a time).
  // List mode is the original "scoreboard" — every exercise + every set
  // visible at once. Defaults to focus; users can switch in the app bar.
  _LoggerView _view = _LoggerView.focus;
  // Cursor into widget.day.items + that exercise's set rows.
  int _focusExerciseIdx = 0;
  int _focusSetIdx = 0;
  // When this set was first shown — drives the per-set elapsed timer.
  DateTime? _focusSetStartedAt;
  // PR sparkle gate — set true momentarily after a PR set logs.
  bool _focusPrPulse = false;

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
      _focusSetStartedAt = DateTime.now();
    });
  }

  /// Advances the focus cursor to the next not-done set in the day,
  /// or to the next exercise's set 1 when the current exercise is done.
  /// When the entire day is complete, leaves the cursor at the last set
  /// so the focus screen can show a "you're done — finish" state.
  void _advanceFocusCursor() {
    final items = widget.day.items;
    if (items.isEmpty) return;
    // Walk forward from current position; first not-done set wins.
    final total = items.length;
    var ex = _focusExerciseIdx;
    var st = _focusSetIdx + 1;
    while (ex < total) {
      final rows = _rowsByExercise[items[ex].exerciseId];
      if (rows != null) {
        while (st < rows.length) {
          if (!rows[st].done) {
            _focusExerciseIdx = ex;
            _focusSetIdx = st;
            _focusSetStartedAt = DateTime.now();
            return;
          }
          st++;
        }
      }
      ex++;
      st = 0;
    }
    // Fell through — nothing left. Keep cursor at last position; the
    // focus screen renders a "workout complete" state when every row
    // in widget.day.items is done.
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
      // Trigger a brief sparkle on the focus screen's weight number.
      setState(() => _focusPrPulse = true);
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted) setState(() => _focusPrPulse = false);
      });
    } else {
      HapticFeedback.lightImpact();
    }
    // Move the focus cursor forward only when we're in focus mode; the
    // list view advances naturally by user tap on the next row's "+".
    if (_view == _LoggerView.focus) _advanceFocusCursor();
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
            Icon(Icons.emoji_events_rounded,
                color: AppColors.onAccent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'New PR · $name · est. $fmt kg',
                style: TextStyle(
                  color: AppColors.onAccent,
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
    // Snapshot before save so we can count PRs achieved this session.
    final prsBefore = _prsBeforeSession();
    await ref.read(workoutRepoProvider).completeSession(session.id);
    if (!mounted) return;
    _showSessionSummary(session, prsBefore);
    Navigator.of(context).pop();
  }

  Map<String, double> _prsBeforeSession() {
    final allSessions =
        ref.read(allSessionsProvider).valueOrNull ?? const <WorkoutSession>[];
    final current = _session;
    final prior = allSessions.where((s) => s.id != current?.id).toList();
    final best = <String, double>{};
    for (final s in prior) {
      for (final set in s.sets) {
        if (set.isWarmup || set.weightKg <= 0 || set.reps <= 0) continue;
        final e = set.weightKg * (1 + set.reps / 30.0);
        final cur = best[set.exerciseName] ?? 0;
        if (e > cur) best[set.exerciseName] = e;
      }
    }
    return best;
  }

  void _showSessionSummary(
      WorkoutSession session, Map<String, double> prsBefore) {
    var prsThisSession = 0;
    double tonnage = 0;
    var workingSets = 0;
    for (final set in session.sets) {
      if (set.isWarmup || set.weightKg <= 0 || set.reps <= 0) continue;
      workingSets++;
      tonnage += set.weightKg * set.reps;
      final e = set.weightKg * (1 + set.reps / 30.0);
      final prior = prsBefore[set.exerciseName] ?? 0;
      if (e > prior + 0.5) {
        prsThisSession++;
        prsBefore[set.exerciseName] = e;
      }
    }
    if (workingSets == 0) return;
    final prText = prsThisSession == 0
        ? 'Session done.'
        : '$prsThisSession PR${prsThisSession == 1 ? '' : 's'} this session.';
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        backgroundColor: prsThisSession > 0
            ? AppColors.accent
            : AppColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Icon(
                prsThisSession > 0
                    ? Icons.emoji_events_rounded
                    : Icons.check_circle_rounded,
                color: prsThisSession > 0
                    ? AppColors.onAccent
                    : AppColors.textPrimary,
                size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$prText  •  $workingSets sets · ${tonnage.toStringAsFixed(0)} kg total',
                style: TextStyle(
                  color: prsThisSession > 0
                      ? AppColors.onAccent
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ));
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
        // In focus mode let the gym photo bleed behind the app bar.
        extendBodyBehindAppBar:
            _view == _LoggerView.focus && !_starting,
        appBar: AppBar(
          backgroundColor: _view == _LoggerView.focus && !_starting
              ? Colors.transparent
              : AppColors.bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            widget.day.name,
            style: AppText.sectionTitle.copyWith(
              color: _view == _LoggerView.focus && !_starting
                  ? Colors.white
                  : AppColors.textPrimary,
            ),
          ),
          iconTheme: IconThemeData(
            color: _view == _LoggerView.focus && !_starting
                ? Colors.white
                : AppColors.textPrimary,
          ),
          actions: [
            // Focus ↔ list toggle.
            IconButton(
              onPressed: () {
                setState(() {
                  _view = _view == _LoggerView.focus
                      ? _LoggerView.list
                      : _LoggerView.focus;
                  if (_view == _LoggerView.focus) {
                    _focusSetStartedAt = DateTime.now();
                  }
                });
              },
              icon: Icon(
                _view == _LoggerView.focus
                    ? Icons.view_agenda_outlined
                    : Icons.crop_square_rounded,
              ),
              tooltip: _view == _LoggerView.focus
                  ? 'Show full list'
                  : 'Show focus view',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
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
                          size: 18, color: AppColors.danger),
                      const SizedBox(width: 10),
                      Text('Discard workout',
                          style: AppText.body.copyWith(
                              color: AppColors.danger,
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
            : Stack(
                children: [
                  // Photo backdrop in focus mode only — gives the screen
                  // a Strava/Whoop-style "you are training right now"
                  // feel. List mode keeps the flat bg so dense rows stay
                  // readable. Falls back to a gradient if no asset.
                  if (_view == _LoggerView.focus &&
                      widget.day.items.isNotEmpty)
                    Positioned.fill(
                      child: WorkoutPhotoBackground(
                        dayName: widget.day.name,
                        overlayStrength: 0.78,
                        child: const SizedBox.shrink(),
                      ),
                    ),
                  SafeArea(
                    child: _view == _LoggerView.focus
                        ? _buildFocusBody()
                        : _buildListBody(),
                  ),
                  if (_restStart != null)
                    _RestOverlay(
                      remaining: _restRemaining,
                      total: _restSeconds,
                      onSkip: _skipRest,
                      onAdd: (delta) {
                        if (_restStart == null) return;
                        setState(() {
                          _restSeconds =
                              (_restSeconds + delta).clamp(0, 3600).toInt();
                          _restRemaining =
                              (_restRemaining + delta).clamp(0, 3600).toInt();
                        });
                      },
                    ),
                ],
              ),
      ),
    );
  }

  static String _fmtWeight(double w) {
    if (w == w.roundToDouble()) return w.toInt().toString();
    return w.toStringAsFixed(1);
  }

  // ---- View builders --------------------------------------------------------

  /// Original "scoreboard" — every exercise + every set visible at once.
  /// Useful for power users who want to type values directly. Kept as a
  /// secondary view; toggled from the app bar.
  Widget _buildListBody() {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            itemCount: widget.day.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
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
                onShowGuide: () => ExerciseGuideSheet.show(
                  context,
                  exerciseId: item.exerciseId,
                  fallbackName: item.exerciseName,
                ),
                onLog: (rowIndex) => _logSet(item, rowIndex),
              );
            },
          ),
        ),
        _FinishButton(onTap: _finish),
      ],
    );
  }

  /// New per-set focus view. Big number for weight, huge tappable rep
  /// counter, ±2.5/±5 chips, ghost row with last session's data, and a
  /// full-width Complete Set button that triggers the rest overlay.
  Widget _buildFocusBody() {
    final items = widget.day.items;
    if (items.isEmpty) return const SizedBox.shrink();
    // Clamp cursor in case the routine shrank or all sets are done.
    final exIdx = _focusExerciseIdx.clamp(0, items.length - 1);
    final item = items[exIdx];
    final rows = _rowsByExercise[item.exerciseId] ?? const <_SetRowState>[];
    if (rows.isEmpty) return const SizedBox.shrink();
    final setIdx = _focusSetIdx.clamp(0, rows.length - 1);
    final row = rows[setIdx];
    final prev = _previousByExercise[item.exerciseId] ?? const <SetEntry>[];
    final prevSet = setIdx < prev.length ? prev[setIdx] : null;
    final priorBest = _previousBestE1RM[item.exerciseId] ?? 0;

    final allDone = items.every((it) {
      final rs = _rowsByExercise[it.exerciseId];
      return rs == null || rs.every((r) => r.done);
    });

    // Overload coaching for the next-set call. Same advisor the list
    // view uses — heuristic, no AI cost, runs every rebuild cheaply.
    final overload = OverloadAdvisor.hintFor(
      item: item,
      previousSets: prev,
      upColor: AppColors.accent,
      holdColor: AppColors.textSecondary,
      downColor: AppColors.water,
    );

    return _FocusSetView(
      item: item,
      setIndex: setIdx,
      totalSets: rows.length,
      rowState: row,
      previousSet: prevSet,
      priorBestE1RM: priorBest,
      overloadHint: overload,
      setStartedAt: _focusSetStartedAt,
      prPulse: _focusPrPulse,
      onLog: () => _logSet(item, setIdx),
      onPrev: () {
        setState(() {
          if (_focusSetIdx > 0) {
            _focusSetIdx--;
          } else if (_focusExerciseIdx > 0) {
            _focusExerciseIdx--;
            final pr = _rowsByExercise[items[_focusExerciseIdx].exerciseId];
            _focusSetIdx = pr == null ? 0 : pr.length - 1;
          }
          _focusSetStartedAt = DateTime.now();
        });
      },
      onNext: () {
        setState(() {
          final maxSet = rows.length - 1;
          if (_focusSetIdx < maxSet) {
            _focusSetIdx++;
          } else if (_focusExerciseIdx < items.length - 1) {
            _focusExerciseIdx++;
            _focusSetIdx = 0;
          }
          _focusSetStartedAt = DateTime.now();
        });
      },
      onFinish: _finish,
      finishVisible: allDone,
      onShowGuide: () => ExerciseGuideSheet.show(
        context,
        exerciseId: item.exerciseId,
        fallbackName: item.exerciseName,
      ),
    );
  }
}

class _SetRowState {
  final TextEditingController weight;
  final TextEditingController reps;
  bool done = false;
  _SetRowState({required this.weight, required this.reps});
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
                    color: AppColors.onAccent,
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

// ===========================================================================
// FOCUS MODE WIDGETS
// ===========================================================================

class _FinishButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FinishButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: Text(
            'Finish workout',
            style: TextStyle(
              color: AppColors.onAccent,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Per-set focus screen — big weight, tappable rep counter, ghost row,
/// elapsed set timer, full-width Complete Set button. Pure presentation:
/// all state lives on _WorkoutLoggerPageState and is mutated via the
/// passed-in callbacks.
class _FocusSetView extends StatefulWidget {
  final RoutinePlanItem item;
  final int setIndex;
  final int totalSets;
  final _SetRowState rowState;
  final SetEntry? previousSet;
  final double priorBestE1RM;
  /// Heuristic coaching call for the next set ("Try 67.5 kg today" /
  /// "Add a rep this session"). Null when there's no history to base
  /// it on.
  final OverloadHint? overloadHint;
  final DateTime? setStartedAt;
  final bool prPulse;
  final VoidCallback onLog;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onFinish;
  final bool finishVisible;
  final VoidCallback onShowGuide;

  const _FocusSetView({
    required this.item,
    required this.setIndex,
    required this.totalSets,
    required this.rowState,
    required this.previousSet,
    required this.priorBestE1RM,
    required this.overloadHint,
    required this.setStartedAt,
    required this.prPulse,
    required this.onLog,
    required this.onPrev,
    required this.onNext,
    required this.onFinish,
    required this.finishVisible,
    required this.onShowGuide,
  });

  @override
  State<_FocusSetView> createState() => _FocusSetViewState();
}

class _FocusSetViewState extends State<_FocusSetView> {
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    // Repaint the elapsed-set-timer once a second.
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  double _weight() => double.tryParse(widget.rowState.weight.text.trim()) ?? 0;
  int _reps() => int.tryParse(widget.rowState.reps.text.trim()) ?? 0;

  void _setWeight(double v) {
    final clamped = v < 0 ? 0.0 : v;
    final s = clamped == clamped.roundToDouble()
        ? clamped.toInt().toString()
        : clamped.toStringAsFixed(1);
    widget.rowState.weight.text = s;
    setState(() {});
  }

  /// Apply a coaching call to the inputs. Parses the suggested weight
  /// out of the hint string when present (e.g. "Try 67.5 kg today")
  /// and pre-fills it; otherwise just nudges reps up by one. The
  /// underlying `OverloadAdvisor` already encodes the policy — we
  /// just translate its text into a button.
  void _acceptOverloadHint(OverloadHint hint) {
    final match = RegExp(r'(\d+(?:\.\d+)?)\s*kg').firstMatch(hint.message);
    if (match != null) {
      final v = double.tryParse(match.group(1)!);
      if (v != null) {
        _setWeight(v);
        HapticFeedback.selectionClick();
        return;
      }
    }
    // No weight in the suggestion (e.g. "Add a rep this session") —
    // bump reps by one from the previous set's count.
    final prev = widget.previousSet;
    if (prev != null && prev.reps > 0) {
      widget.rowState.reps.text = '${prev.reps + 1}';
      HapticFeedback.selectionClick();
      setState(() {});
    }
  }

  void _bumpReps(int delta) {
    final next = (_reps() + delta).clamp(0, 999);
    widget.rowState.reps.text = next.toString();
    HapticFeedback.lightImpact();
    setState(() {});
  }

  String _fmtSetTimer() {
    if (widget.setStartedAt == null) return '00:00';
    final s = DateTime.now().difference(widget.setStartedAt!).inSeconds;
    final m = s ~/ 60;
    final ss = s % 60;
    return '${m.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
  }

  String _ghostText() {
    final p = widget.previousSet;
    if (p == null || (p.weightKg <= 0 && p.reps <= 0)) {
      return 'No history yet — set the bar.';
    }
    final w = p.weightKg;
    final wStr = w == w.roundToDouble()
        ? w.toInt().toString()
        : w.toStringAsFixed(1);
    final pieces = <String>[];
    if (w > 0) {
      pieces.add('Last: $wStr kg × ${p.reps}');
    } else {
      pieces.add('Last: ${p.reps} reps');
    }
    if (widget.priorBestE1RM > 0) {
      final b = widget.priorBestE1RM;
      final bStr = b == b.roundToDouble()
          ? b.toInt().toString()
          : b.toStringAsFixed(1);
      pieces.add('e1RM $bStr kg');
    }
    return pieces.join('  ·  ');
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.rowState.done;
    final wt = _weight();
    final reps = _reps();
    final wtDisplay = wt == 0
        ? '0'
        : (wt == wt.roundToDouble()
            ? wt.toInt().toString()
            : wt.toStringAsFixed(1));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // -- Header: exercise + set position + guide button -------------
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: widget.onShowGuide,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.item.exerciseName,
                          style: AppText.sectionTitle.copyWith(fontSize: 20),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.info_outline_rounded,
                          size: 14, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: Text(
                  'SET ${widget.setIndex + 1} / ${widget.totalSets}',
                  style: AppText.label.copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _ghostText(),
            style: AppText.meta.copyWith(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
          // Next-set coaching call. Surfaces above the weight number
          // so the user reads "Try 67.5 kg today" before they touch
          // the chips. Tap to load that weight into the input.
          if (widget.overloadHint != null && !widget.rowState.done) ...[
            const SizedBox(height: 10),
            _OverloadBanner(
              hint: widget.overloadHint!,
              onAccept: () => _acceptOverloadHint(widget.overloadHint!),
            ),
          ],
          const SizedBox(height: 22),

          // -- WEIGHT block ---------------------------------------------
          Center(
            child: Column(
              children: [
                Text('WEIGHT', style: AppText.label.copyWith(fontSize: 11)),
                const SizedBox(height: 6),
                AnimatedScale(
                  scale: widget.prPulse ? 1.06 : 1.0,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  child: GestureDetector(
                    onTap: done
                        ? null
                        : () => _showWeightInputDialog(context),
                    child: ShaderMask(
                      shaderCallback: (rect) => LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: widget.prPulse
                            ? [AppColors.accent, AppColors.calorieFrom]
                            : [
                                AppColors.textPrimary,
                                AppColors.textPrimary.withValues(alpha: 0.85),
                              ],
                      ).createShader(rect),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            wtDisplay,
                            style: AppText.giantNumber.copyWith(fontSize: 80),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              'kg',
                              style: AppText.meta.copyWith(
                                fontSize: 18,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StepChip(
                      label: '-5',
                      onTap: done ? null : () => _setWeight(wt - 5),
                    ),
                    const SizedBox(width: 8),
                    _StepChip(
                      label: '-2.5',
                      onTap: done ? null : () => _setWeight(wt - 2.5),
                    ),
                    const SizedBox(width: 8),
                    _StepChip(
                      label: '+2.5',
                      primary: true,
                      onTap: done ? null : () => _setWeight(wt + 2.5),
                    ),
                    const SizedBox(width: 8),
                    _StepChip(
                      label: '+5',
                      primary: true,
                      onTap: done ? null : () => _setWeight(wt + 5),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // -- REP counter ----------------------------------------------
          Center(
            child: Column(
              children: [
                Text('REPS · tap to count',
                    style: AppText.label.copyWith(fontSize: 11)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: done ? null : () => _bumpReps(1),
                  onVerticalDragEnd: (d) {
                    if (done) return;
                    if (d.primaryVelocity != null &&
                        d.primaryVelocity! > 200) {
                      _bumpReps(-1);
                    }
                  },
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.35),
                          width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$reps',
                      style: AppText.giantNumber.copyWith(
                        fontSize: 96,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StepChip(
                      label: '-1',
                      onTap: done ? null : () => _bumpReps(-1),
                    ),
                    const SizedBox(width: 8),
                    _StepChip(
                      label: 'tap above to +1',
                      onTap: null,
                    ),
                    const SizedBox(width: 8),
                    _StepChip(
                      label: '+1',
                      primary: true,
                      onTap: done ? null : () => _bumpReps(1),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // -- Set timer + nav arrows -----------------------------------
          Row(
            children: [
              IconButton(
                onPressed: widget.onPrev,
                icon: Icon(Icons.chevron_left_rounded,
                    color: AppColors.textSecondary),
              ),
              const Spacer(),
              Icon(Icons.timer_outlined,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(_fmtSetTimer(),
                  style: AppText.bigNumber.copyWith(
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  )),
              const Spacer(),
              IconButton(
                onPressed: widget.onNext,
                icon: Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // -- Complete Set button --------------------------------------
          GestureDetector(
            onTap: done || reps <= 0 ? null : widget.onLog,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 60,
              decoration: BoxDecoration(
                color: done
                    ? AppColors.protein.withValues(alpha: 0.15)
                    : reps <= 0
                        ? AppColors.surfaceHigh
                        : AppColors.accent,
                borderRadius: BorderRadius.circular(20),
                border: done
                    ? Border.all(
                        color: AppColors.protein.withValues(alpha: 0.4))
                    : null,
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    done
                        ? Icons.check_circle_rounded
                        : Icons.flash_on_rounded,
                    color: done
                        ? AppColors.protein
                        : reps <= 0
                            ? AppColors.textTertiary
                            : AppColors.onAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    done ? 'Set logged' : 'Complete set',
                    style: TextStyle(
                      color: done
                          ? AppColors.protein
                          : reps <= 0
                              ? AppColors.textTertiary
                              : AppColors.onAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (widget.finishVisible) ...[
            const SizedBox(height: 12),
            _FinishButton(onTap: widget.onFinish),
          ],
        ],
      ),
    );
  }

  Future<void> _showWeightInputDialog(BuildContext context) async {
    final ctl = TextEditingController(text: widget.rowState.weight.text);
    final v = await showDialog<double>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Set weight',
                  style: AppText.sectionTitle.copyWith(fontSize: 17)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.stroke),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ctl,
                        autofocus: true,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        cursorColor: AppColors.accent,
                        style: AppText.bigNumber.copyWith(fontSize: 22),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                      ),
                    ),
                    Text('kg',
                        style: AppText.meta.copyWith(
                            fontSize: 13, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Cancel',
                        style: AppText.body
                            .copyWith(color: AppColors.textPrimary)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(ctx)
                        .pop(double.tryParse(ctl.text.trim())),
                    child: Text('Set',
                        style: AppText.body.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (v != null && v >= 0) _setWeight(v);
  }
}

/// Compact "next-set call" banner shown above the weight number in
/// the focus view. Tap = pre-fill the suggestion into the inputs.
class _OverloadBanner extends StatelessWidget {
  final OverloadHint hint;
  final VoidCallback onAccept;
  const _OverloadBanner({required this.hint, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAccept,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: hint.color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hint.color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: hint.color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(hint.icon, size: 14, color: hint.color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NEXT-SET CALL',
                      style: AppText.label.copyWith(
                          fontSize: 10,
                          color: hint.color,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 1),
                  Text(
                    hint.message,
                    style: AppText.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: hint.color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Apply',
                  style: TextStyle(
                      color: AppColors.onAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  const _StepChip({required this.label, required this.onTap, this.primary = false});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: disabled
              ? AppColors.surfaceHigh
              : primary
                  ? AppColors.accent.withValues(alpha: 0.14)
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: disabled
                ? AppColors.stroke
                : primary
                    ? AppColors.accent.withValues(alpha: 0.45)
                    : AppColors.stroke,
          ),
        ),
        child: Text(
          label,
          style: AppText.body.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: disabled
                ? AppColors.textTertiary
                : primary
                    ? AppColors.accent
                    : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Full-screen rest countdown that takes over after a set logs. Big
/// circular ring, breathing digits, ±15 s buttons, Skip at bottom.
class _RestOverlay extends StatelessWidget {
  final int remaining;
  final int total;
  final VoidCallback onSkip;
  final ValueChanged<int> onAdd;
  const _RestOverlay({
    required this.remaining,
    required this.total,
    required this.onSkip,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final m = remaining ~/ 60;
    final s = remaining % 60;
    final progress = total == 0 ? 0.0 : remaining / total;
    return Positioned.fill(
      child: Container(
        color: AppColors.bg.withValues(alpha: 0.96),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('REST', style: AppText.label.copyWith(fontSize: 12)),
                    const Spacer(),
                    GestureDetector(
                      onTap: onSkip,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.stroke),
                        ),
                        child: Text('Skip',
                            style: AppText.body.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            )),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Track
                      SizedBox(
                        width: 260,
                        height: 260,
                        child: CircularProgressIndicator(
                          value: 1,
                          strokeWidth: 12,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation(
                              AppColors.surfaceHigh),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      // Progress (counts down)
                      SizedBox(
                        width: 260,
                        height: 260,
                        child: CircularProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          strokeWidth: 12,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation(AppColors.accent),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
                              key: ValueKey(remaining),
                              style: AppText.giantNumber.copyWith(
                                fontSize: 64,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('seconds left',
                              style: AppText.meta.copyWith(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StepChip(label: '-15s', onTap: () => onAdd(-15)),
                    const SizedBox(width: 10),
                    _StepChip(
                      label: '+15s',
                      primary: true,
                      onTap: () => onAdd(15),
                    ),
                    const SizedBox(width: 10),
                    _StepChip(
                      label: '+30s',
                      primary: true,
                      onTap: () => onAdd(30),
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
