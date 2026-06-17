import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/enums.dart';
import '../../data/models/exercise.dart';
import '../../data/models/routine.dart';
import '../../state/providers.dart';
import '../../theme.dart';

class RoutineBuilderPage extends ConsumerStatefulWidget {
  final Routine? edit;
  const RoutineBuilderPage({super.key, this.edit});

  @override
  ConsumerState<RoutineBuilderPage> createState() => _RoutineBuilderPageState();
}

class _RoutineBuilderPageState extends ConsumerState<RoutineBuilderPage> {
  late final TextEditingController _name;
  late final List<RoutineDay> _days;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.edit;
    _name = TextEditingController(text: r?.name ?? 'My Routine');
    _days = r == null
        ? <RoutineDay>[
            RoutineDay()
              ..name = 'Day 1'
              ..weekday = 0
              ..items = []
          ]
        : r.days.map(_cloneDay).toList();
  }

  RoutineDay _cloneDay(RoutineDay d) {
    final copy = RoutineDay()
      ..name = d.name
      ..weekday = d.weekday
      ..isRest = d.isRest
      ..items = d.items
          .map((i) => RoutinePlanItem()
            ..exerciseId = i.exerciseId
            ..exerciseName = i.exerciseName
            ..targetSets = i.targetSets
            ..targetRepsLow = i.targetRepsLow
            ..targetRepsHigh = i.targetRepsHigh
            ..targetWeightKg = i.targetWeightKg
            ..restSeconds = i.restSeconds
            ..notes = i.notes)
          .toList();
    return copy;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
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

  void _addDay() {
    setState(() {
      _days.add(RoutineDay()
        ..name = 'Day ${_days.length + 1}'
        ..weekday = 0
        ..items = []);
    });
  }

  void _removeDay(int index) {
    setState(() => _days.removeAt(index));
  }

  Future<void> _editDayName(int index) async {
    final d = _days[index];
    final ctl = TextEditingController(text: d.name);
    final newName = await showDialog<String>(
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
              Text('Day name',
                  style: AppText.sectionTitle.copyWith(fontSize: 17)),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.stroke),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: ctl,
                  autofocus: true,
                  cursorColor: AppColors.accent,
                  style: AppText.body.copyWith(
                      color: AppColors.textPrimary, fontSize: 15),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                    hintText: 'e.g. Push Day',
                  ),
                ),
              ),
              const SizedBox(height: 18),
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
                    onPressed: () =>
                        Navigator.of(ctx).pop(ctl.text.trim()),
                    child: Text('Save',
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
    ctl.dispose();
    if (newName == null || newName.isEmpty) return;
    setState(() => d.name = newName);
  }

  void _pickWeekday(int dayIndex) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.stroke,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Assign weekday', style: AppText.sectionTitle),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var w = 0; w <= 7; w++)
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx, w),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.stroke),
                        ),
                        child: Text(
                          w == 0 ? 'Any day' : _weekdayLabel(w),
                          style: AppText.body.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null) return;
    setState(() => _days[dayIndex].weekday = selected);
  }

  Future<void> _addExerciseToDay(int dayIndex) async {
    final picked = await showModalBottomSheet<_PickedExercise>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => const _ExercisePickerSheet(),
    );
    if (picked == null) return;
    final item = RoutinePlanItem()
      ..exerciseId = picked.exerciseId ?? 0
      ..exerciseName = picked.name
      ..targetSets = 3
      ..targetRepsLow = 8
      ..targetRepsHigh = 12
      ..restSeconds = picked.restSeconds;
    setState(() => _days[dayIndex].items.add(item));
  }

  void _removeExercise(int dayIndex, int exIndex) {
    setState(() => _days[dayIndex].items.removeAt(exIndex));
  }

  Future<void> _editExercise(int dayIndex, int exIndex) async {
    final item = _days[dayIndex].items[exIndex];
    final sets = TextEditingController(text: item.targetSets.toString());
    final low = TextEditingController(text: item.targetRepsLow.toString());
    final high = TextEditingController(text: item.targetRepsHigh.toString());
    final rest = TextEditingController(text: item.restSeconds.toString());
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.stroke,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(item.exerciseName,
                    style: AppText.sectionTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 14),
                Text('SETS', style: AppText.label),
                const SizedBox(height: 6),
                _NumberField(controller: sets),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('REPS (LOW)', style: AppText.label),
                          const SizedBox(height: 6),
                          _NumberField(controller: low),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('REPS (HIGH)', style: AppText.label),
                          const SizedBox(height: 6),
                          _NumberField(controller: high),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('REST (SECONDS)', style: AppText.label),
                const SizedBox(height: 6),
                _NumberField(controller: rest),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(true),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: const Text('Save',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              )),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok == true) {
      setState(() {
        item.targetSets =
            (int.tryParse(sets.text.trim()) ?? item.targetSets).clamp(1, 12);
        item.targetRepsLow =
            (int.tryParse(low.text.trim()) ?? item.targetRepsLow).clamp(1, 60);
        item.targetRepsHigh = (int.tryParse(high.text.trim()) ?? item.targetRepsHigh)
            .clamp(item.targetRepsLow, 100);
        item.restSeconds =
            (int.tryParse(rest.text.trim()) ?? item.restSeconds).clamp(0, 600);
      });
    }
    sets.dispose();
    low.dispose();
    high.dispose();
    rest.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _toast('Name your routine first.');
      return;
    }
    if (_days.every((d) => d.isRest || d.items.isEmpty)) {
      _toast('Add at least one exercise.');
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(workoutRepoProvider);
      final r = widget.edit ?? Routine();
      r
        ..name = name
        ..days = _days;
      final saved = await repo.saveRoutine(r);
      await repo.activateRoutine(saved.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _toast('Could not save routine.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static String _weekdayLabel(int w) {
    const names = [
      '—',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    if (w < 1 || w > 7) return 'Any day';
    return names[w];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text(widget.edit == null ? 'New routine' : 'Edit routine',
            style: AppText.sectionTitle),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(
              _saving ? '…' : 'Save',
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text('ROUTINE NAME', style: AppText.label),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.stroke),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: _name,
                cursorColor: AppColors.accent,
                style: AppText.body.copyWith(
                    color: AppColors.textPrimary, fontSize: 15),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                  hintText: 'e.g. PPL — Beginner',
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text('DAYS', style: AppText.label),
            const SizedBox(height: 10),
            for (var i = 0; i < _days.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DayEditor(
                  day: _days[i],
                  onRename: () => _editDayName(i),
                  onWeekday: () => _pickWeekday(i),
                  onAddExercise: () => _addExerciseToDay(i),
                  onEditExercise: (j) => _editExercise(i, j),
                  onRemoveExercise: (j) => _removeExercise(i, j),
                  onToggleRest: () => setState(() {
                    _days[i].isRest = !_days[i].isRest;
                    if (_days[i].isRest) _days[i].items.clear();
                  }),
                  onDelete:
                      _days.length > 1 ? () => _removeDay(i) : null,
                ),
              ),
            GestureDetector(
              onTap: _addDay,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.stroke,
                      style: BorderStyle.solid,
                      width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded,
                        size: 18, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text('Add day',
                        style: AppText.body.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayEditor extends StatelessWidget {
  final RoutineDay day;
  final VoidCallback onRename;
  final VoidCallback onWeekday;
  final VoidCallback onAddExercise;
  final void Function(int) onEditExercise;
  final void Function(int) onRemoveExercise;
  final VoidCallback onToggleRest;
  final VoidCallback? onDelete;
  const _DayEditor({
    required this.day,
    required this.onRename,
    required this.onWeekday,
    required this.onAddExercise,
    required this.onEditExercise,
    required this.onRemoveExercise,
    required this.onToggleRest,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final weekday = day.weekday;
    final weekdayLabel =
        weekday == 0 ? 'Any day' : _RoutineBuilderPageState._weekdayLabel(weekday);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onRename,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(day.name,
                            style: AppText.sectionTitle.copyWith(
                                fontSize: 15)),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: onWeekday,
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 12,
                                  color: AppColors.textTertiary),
                              const SizedBox(width: 4),
                              Text(weekdayLabel,
                                  style: AppText.meta
                                      .copyWith(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onToggleRest,
                  icon: Icon(
                    day.isRest
                        ? Icons.self_improvement_rounded
                        : Icons.fitness_center_rounded,
                    size: 18,
                    color: day.isRest ? AppColors.water : AppColors.accent,
                  ),
                  tooltip: day.isRest ? 'Mark as training' : 'Mark as rest',
                ),
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 18, color: const Color(0xFFFF6B6B)),
                  ),
              ],
            ),
          ),
          if (!day.isRest) ...[
            const Divider(height: 1),
            for (var j = 0; j < day.items.length; j++) ...[
              if (j > 0) const Divider(height: 1),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                title: Text(day.items[j].exerciseName,
                    style: AppText.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                subtitle: Text(
                    '${day.items[j].targetSets} × ${day.items[j].targetRepsLow}–${day.items[j].targetRepsHigh} · ${day.items[j].restSeconds}s rest',
                    style: AppText.meta.copyWith(fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => onEditExercise(j),
                      icon: Icon(Icons.edit_rounded,
                          size: 16, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      onPressed: () => onRemoveExercise(j),
                      icon: Icon(Icons.close_rounded,
                          size: 16, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(10),
              child: GestureDetector(
                onTap: onAddExercise,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded,
                          size: 16, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Text('Add exercise',
                          style: AppText.body.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  const _NumberField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.stroke),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        cursorColor: AppColors.accent,
        style:
            AppText.body.copyWith(color: AppColors.textPrimary, fontSize: 15),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _PickedExercise {
  final String name;
  final int? exerciseId;
  final int restSeconds;
  const _PickedExercise(
      {required this.name,
      required this.exerciseId,
      required this.restSeconds});
}

class _ExercisePickerSheet extends ConsumerStatefulWidget {
  const _ExercisePickerSheet();

  @override
  ConsumerState<_ExercisePickerSheet> createState() =>
      _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<_ExercisePickerSheet> {
  final _search = TextEditingController();
  String _query = '';
  bool _customMode = false;
  final _custom = TextEditingController();
  MuscleGroup? _filter;

  @override
  void dispose() {
    _search.dispose();
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(exercisesProvider).valueOrNull ?? const [];
    final filtered = _filterLibrary(library);
    final h = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: h * 0.78,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.stroke,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                        child: Text('Pick an exercise',
                            style: AppText.sectionTitle)),
                    if (!_customMode)
                      GestureDetector(
                        onTap: () => setState(() => _customMode = true),
                        child: Row(
                          children: [
                            Icon(Icons.add_rounded,
                                size: 14, color: AppColors.accent),
                            const SizedBox(width: 2),
                            Text('Custom',
                                style: AppText.label.copyWith(
                                    color: AppColors.accent,
                                    letterSpacing: 0.4)),
                          ],
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () => setState(() => _customMode = false),
                        child: Text('Cancel',
                            style: AppText.label.copyWith(
                                color: AppColors.textTertiary,
                                letterSpacing: 0.4)),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_customMode) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.stroke),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: _custom,
                      autofocus: true,
                      cursorColor: AppColors.accent,
                      style: AppText.body.copyWith(
                          color: AppColors.textPrimary, fontSize: 15),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                        hintText: 'Exercise name',
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () {
                      final name = _custom.text.trim();
                      if (name.isEmpty) return;
                      Navigator.of(context).pop(_PickedExercise(
                          name: name, exerciseId: null, restSeconds: 90));
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: const Text('Add this exercise',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          )),
                    ),
                  ),
                ] else ...[
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.stroke),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded,
                            size: 18, color: AppColors.textTertiary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _search,
                            cursorColor: AppColors.accent,
                            onChanged: (v) => setState(() => _query = v),
                            style: AppText.body.copyWith(
                                color: AppColors.textPrimary, fontSize: 15),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isCollapsed: true,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 14),
                              hintText: 'Search exercises…',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _Chip(
                          label: 'All',
                          selected: _filter == null,
                          onTap: () => setState(() => _filter = null),
                        ),
                        for (final g in [
                          MuscleGroup.chest,
                          MuscleGroup.back,
                          MuscleGroup.shoulders,
                          MuscleGroup.biceps,
                          MuscleGroup.triceps,
                          MuscleGroup.quads,
                          MuscleGroup.hamstrings,
                          MuscleGroup.glutes,
                          MuscleGroup.core,
                          MuscleGroup.cardio,
                        ])
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _Chip(
                              label: _muscleLabel(g),
                              selected: _filter == g,
                              onTap: () => setState(
                                  () => _filter = _filter == g ? null : g),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text('No matches.', style: AppText.body))
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 6),
                            itemBuilder: (_, i) {
                              final e = filtered[i];
                              return _ExerciseRow(
                                exercise: e,
                                onTap: () => Navigator.of(context).pop(
                                    _PickedExercise(
                                        name: e.name,
                                        exerciseId: e.id,
                                        restSeconds: e.defaultRestSeconds)),
                              );
                            },
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Exercise> _filterLibrary(List<Exercise> all) {
    final q = _query.toLowerCase().trim();
    return all.where((e) {
      if (q.isNotEmpty && !e.name.toLowerCase().contains(q)) return false;
      if (_filter != null && !e.muscleGroups.contains(_filter)) return false;
      return true;
    }).toList();
  }

  String _muscleLabel(MuscleGroup g) {
    final n = g.name;
    return n[0].toUpperCase() + n.substring(1);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.accent : AppColors.stroke),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;
  const _ExerciseRow({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise.name,
                      style: AppText.body.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    [
                      ...exercise.muscleGroups.map((m) => m.name),
                      exercise.equipment.name,
                    ].join(' · '),
                    style: AppText.meta.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.add_rounded, size: 18, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}
