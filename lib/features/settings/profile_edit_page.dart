// ignore_for_file: use_null_aware_elements
// (isar_generator's bundled analyzer doesn't parse `'key': ?value` yet.)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/health_math.dart';
import '../../data/models/enums.dart';
import '../../data/models/profile.dart';
import '../../state/providers.dart';
import '../../theme.dart';

/// Curated body-focus presets. Each is a short tag + a one-line description
/// that helps the user understand what it covers. Tapping a chip toggles it
/// in the notes field (comma-joined). Users can also type their own.
const List<(String, String)> _focusPresets = [
  ('Skinny arms', 'Weak upper body, need more muscle'),
  ('Belly fat', 'Carry weight around the waist'),
  ('Skinny fat', 'Average weight but low muscle tone'),
  ('Lower body heavy', 'Wider hips / thighs, slim upper'),
  ('Upper body heavy', 'Broad shoulders, slim lower body'),
  ('Athletic', 'Already toned, want maintenance'),
  ('Overall lean', 'Want to gain muscle everywhere'),
];

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  late TextEditingController _name;
  late TextEditingController _age;
  late TextEditingController _heightCm;
  late TextEditingController _weightKg;
  late TextEditingController _trainingDays;
  late TextEditingController _cardioDays;
  late TextEditingController _focusNotes;

  late TextEditingController _calOverride;
  late TextEditingController _proteinOverride;
  late TextEditingController _carbOverride;
  late TextEditingController _fatOverride;
  late TextEditingController _fiberOverride;
  late TextEditingController _waterOverride;

  Gender _gender = Gender.male;
  ActivityLevel _activity = ActivityLevel.moderate;
  FitnessGoal _goal = FitnessGoal.generalFitness;
  Profile? _profile;
  bool _busy = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _age = TextEditingController();
    _heightCm = TextEditingController();
    _weightKg = TextEditingController();
    _trainingDays = TextEditingController();
    _cardioDays = TextEditingController();
    _focusNotes = TextEditingController();
    _calOverride = TextEditingController();
    _proteinOverride = TextEditingController();
    _carbOverride = TextEditingController();
    _fatOverride = TextEditingController();
    _fiberOverride = TextEditingController();
    _waterOverride = TextEditingController();
    _load();
  }

  /// Sanitises an int that may be Isar's "missing field" sentinel value
  /// for existing rows when a new int field was added to the schema.
  int _safeInt(int value, {int min = 0, int max = 14}) {
    if (value < min || value > max) return min;
    return value;
  }

  Future<void> _load() async {
    final p = await ref.read(profileRepoProvider).getCurrent();
    if (!mounted || p == null) return;
    _profile = p;
    _name.text = p.displayName;
    _age.text = p.age.toString();
    _heightCm.text = p.heightCm.toStringAsFixed(0);
    _weightKg.text = p.weightKg.toStringAsFixed(1);
    _trainingDays.text =
        _safeInt(p.trainingDaysPerWeek, min: 0, max: 7).toString();
    _cardioDays.text =
        _safeInt(p.cardioSessionsPerWeek, min: 0, max: 7).toString();
    _focusNotes.text = p.bodyFocusNotes;
    _gender = p.gender;
    _activity = p.activityLevel;
    _goal = p.goal;
    _calOverride.text = p.calorieOverride?.toString() ?? '';
    _proteinOverride.text = p.proteinOverride?.toString() ?? '';
    _carbOverride.text = p.carbOverride?.toString() ?? '';
    _fatOverride.text = p.fatOverride?.toString() ?? '';
    _fiberOverride.text = p.fiberOverride?.toString() ?? '';
    _waterOverride.text = p.waterOverride?.toString() ?? '';
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _heightCm.dispose();
    _weightKg.dispose();
    _trainingDays.dispose();
    _cardioDays.dispose();
    _focusNotes.dispose();
    _calOverride.dispose();
    _proteinOverride.dispose();
    _carbOverride.dispose();
    _fatOverride.dispose();
    _fiberOverride.dispose();
    _waterOverride.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        backgroundColor: AppColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        content: Text(msg,
            style: AppText.body.copyWith(color: AppColors.textPrimary)),
      ));
  }

  int? _maybeInt(TextEditingController c) {
    final v = c.text.trim();
    if (v.isEmpty) return null;
    return int.tryParse(v);
  }

  Set<String> _selectedPresets() {
    final tokens = _focusNotes.text
        .split(RegExp(r'[,;\n]'))
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toSet();
    return _focusPresets
        .where((p) => tokens.contains(p.$1.toLowerCase()))
        .map((p) => p.$1)
        .toSet();
  }

  void _togglePreset(String preset) {
    final selected = _selectedPresets();
    final tokens = _focusNotes.text
        .split(RegExp(r'[,;\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (selected.contains(preset)) {
      tokens.removeWhere((t) => t.toLowerCase() == preset.toLowerCase());
    } else {
      tokens.add(preset);
    }
    setState(() {
      _focusNotes.text = tokens.join(', ');
    });
  }

  Future<void> _save() async {
    final p = _profile;
    if (p == null) return;
    setState(() => _busy = true);
    try {
      final age = int.tryParse(_age.text.trim()) ?? p.age;
      final height = double.tryParse(_heightCm.text.trim()) ?? p.heightCm;
      final weight = double.tryParse(_weightKg.text.trim()) ?? p.weightKg;
      final days = _safeInt(
          int.tryParse(_trainingDays.text.trim()) ?? p.trainingDaysPerWeek,
          min: 0,
          max: 7);
      final cardio = _safeInt(
          int.tryParse(_cardioDays.text.trim()) ?? p.cardioSessionsPerWeek,
          min: 0,
          max: 7);

      final t = HealthMath.compute(
        gender: _gender,
        age: age,
        weightKg: weight,
        heightCm: height,
        activity: _activity,
        goal: _goal,
        cardioSessionsPerWeek: cardio,
      );

      p
        ..displayName = _name.text.trim()
        ..age = age
        ..gender = _gender
        ..heightCm = height
        ..weightKg = weight
        ..activityLevel = _activity
        ..goal = _goal
        ..trainingDaysPerWeek = days
        ..cardioSessionsPerWeek = cardio
        ..bodyFocusNotes = _focusNotes.text.trim()
        ..bmr = t.bmr
        ..tdee = t.tdee
        ..calorieTarget = t.calorieTarget
        ..proteinTargetG = t.proteinG
        ..carbTargetG = t.carbG
        ..fatTargetG = t.fatG
        ..fiberTargetG = t.fiberG
        ..waterTargetMl = t.waterMl
        ..bmi = t.bmi
        ..calorieOverride = _maybeInt(_calOverride)
        ..proteinOverride = _maybeInt(_proteinOverride)
        ..carbOverride = _maybeInt(_carbOverride)
        ..fatOverride = _maybeInt(_fatOverride)
        ..fiberOverride = _maybeInt(_fiberOverride)
        ..waterOverride = _maybeInt(_waterOverride);
      await ref.read(profileRepoProvider).save(p);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) _toast('Could not save.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text('Profile & targets', style: AppText.sectionTitle),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        actions: [
          TextButton(
            onPressed: _busy || !_loaded ? null : _save,
            child: Text(_busy ? '…' : 'Save',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                )),
          ),
        ],
      ),
      body: !_loaded
          ? Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.2, color: AppColors.accent),
              ),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  // ----------------- ABOUT YOU -----------------
                  _Section(
                    title: 'About you',
                    subtitle: 'Basics we use to compute your targets.',
                    children: [
                      _Field(
                        label: 'NAME',
                        controller: _name,
                        hint: 'How should we greet you?',
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _Field(
                              label: 'AGE',
                              controller: _age,
                              hint: 'years',
                              digits: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('GENDER', style: AppText.label),
                                const SizedBox(height: 6),
                                _GenderSegment(
                                  value: _gender,
                                  onChanged: (g) =>
                                      setState(() => _gender = g),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _Field(
                              label: 'HEIGHT',
                              controller: _heightCm,
                              hint: 'cm',
                              digits: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _Field(
                              label: 'WEIGHT',
                              controller: _weightKg,
                              hint: 'kg',
                              decimals: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ----------------- ACTIVITY -----------------
                  _Section(
                    title: 'Activity',
                    subtitle:
                        'How active you are day-to-day, plus structured training.',
                    children: [
                      Text('ACTIVITY LEVEL', style: AppText.label),
                      const SizedBox(height: 8),
                      _ActivitySegment(
                        value: _activity,
                        onChanged: (a) => setState(() => _activity = a),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _Field(
                              label: 'STRENGTH DAYS / WEEK',
                              controller: _trainingDays,
                              hint: '0 – 7',
                              digits: true,
                              helper: 'Lifting / calisthenics',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _Field(
                              label: 'CARDIO DAYS / WEEK',
                              controller: _cardioDays,
                              hint: '0 – 7',
                              digits: true,
                              helper: 'Running, cycling, HIIT',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Each cardio session adds ~50 kcal/day to your target.',
                        style: AppText.meta.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ----------------- GOAL -----------------
                  _Section(
                    title: 'Goal',
                    subtitle: 'We tune calories and protein for this.',
                    children: [
                      _GoalSegment(
                        value: _goal,
                        onChanged: (g) => setState(() => _goal = g),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ----------------- BODY FOCUS -----------------
                  _Section(
                    title: 'Body focus (optional)',
                    subtitle:
                        'Tell the AI coach what you\'re working on. Tap any tag to add it, then add your own.',
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final p in _focusPresets)
                            _FocusChip(
                              label: p.$1,
                              description: p.$2,
                              selected:
                                  _selectedPresets().contains(p.$1),
                              onTap: () => _togglePreset(p.$1),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _Field(
                        label: 'NOTES',
                        controller: _focusNotes,
                        hint:
                            'e.g. Skinny arms, belly fat, average legs…',
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ----------------- OVERRIDES -----------------
                  _Section(
                    title: 'Override targets',
                    subtitle:
                        'Leave blank to use the auto-computed values.',
                    trailing: GestureDetector(
                      onTap: () {
                        setState(() {
                          _calOverride.clear();
                          _proteinOverride.clear();
                          _carbOverride.clear();
                          _fatOverride.clear();
                          _fiberOverride.clear();
                          _waterOverride.clear();
                        });
                      },
                      child: Text('Clear all',
                          style: AppText.label.copyWith(
                              color: AppColors.accent,
                              letterSpacing: 0.6)),
                    ),
                    children: [
                      _OverrideRow(
                          label: 'Calories (kcal)',
                          controller: _calOverride,
                          autoValue: _profile?.calorieTarget),
                      _OverrideRow(
                          label: 'Protein (g)',
                          controller: _proteinOverride,
                          autoValue: _profile?.proteinTargetG),
                      _OverrideRow(
                          label: 'Carbs (g)',
                          controller: _carbOverride,
                          autoValue: _profile?.carbTargetG),
                      _OverrideRow(
                          label: 'Fat (g)',
                          controller: _fatOverride,
                          autoValue: _profile?.fatTargetG),
                      _OverrideRow(
                          label: 'Fiber (g)',
                          controller: _fiberOverride,
                          autoValue: _profile?.fiberTargetG),
                      _OverrideRow(
                          label: 'Water (ml)',
                          controller: _waterOverride,
                          autoValue: _profile?.waterTargetMl),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

// ───────────────── Helpers / smaller widgets ─────────────────

class _Section extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;
  const _Section({
    required this.title,
    this.subtitle,
    this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                            AppText.sectionTitle.copyWith(fontSize: 18)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!,
                          style: AppText.meta.copyWith(fontSize: 12)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String? label;
  final TextEditingController controller;
  final String hint;
  final bool digits;
  final bool decimals;
  final int maxLines;
  final String? helper;
  const _Field({
    this.label,
    required this.controller,
    required this.hint,
    this.digits = false,
    this.decimals = false,
    this.maxLines = 1,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppText.label),
          const SizedBox(height: 6),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.stroke),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextField(
            controller: controller,
            keyboardType: decimals
                ? const TextInputType.numberWithOptions(decimal: true)
                : digits
                    ? TextInputType.number
                    : maxLines > 1
                        ? TextInputType.multiline
                        : TextInputType.text,
            inputFormatters: decimals
                ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
                : digits
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : null,
            cursorColor: AppColors.accent,
            maxLines: maxLines,
            style: AppText.body
                .copyWith(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              hintText: hint,
              hintStyle: AppText.body
                  .copyWith(color: AppColors.textTertiary, fontSize: 15),
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(helper!, style: AppText.meta.copyWith(fontSize: 11)),
        ],
      ],
    );
  }
}

class _FocusChip extends StatelessWidget {
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  const _FocusChip({
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        constraints: const BoxConstraints(maxWidth: 220),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.18)
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.stroke,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.check_circle_rounded,
                        size: 12, color: AppColors.accent),
                  ),
                Flexible(
                  child: Text(label,
                      style: TextStyle(
                        color: selected
                            ? AppColors.accent
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: -0.1,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(description,
                style: AppText.meta.copyWith(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                )),
          ],
        ),
      ),
    );
  }
}

class _GenderSegment extends StatelessWidget {
  final Gender value;
  final ValueChanged<Gender> onChanged;
  const _GenderSegment({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _RowSegment<Gender>(
      value: value,
      options: const [
        (Gender.male, 'Male'),
        (Gender.female, 'Female'),
        (Gender.other, 'Other'),
      ],
      onChanged: onChanged,
    );
  }
}

class _ActivitySegment extends StatelessWidget {
  final ActivityLevel value;
  final ValueChanged<ActivityLevel> onChanged;
  const _ActivitySegment({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _RowSegment<ActivityLevel>(
      value: value,
      options: const [
        (ActivityLevel.sedentary, 'Sed.'),
        (ActivityLevel.light, 'Light'),
        (ActivityLevel.moderate, 'Mod.'),
        (ActivityLevel.active, 'Active'),
        (ActivityLevel.veryActive, 'Athlete'),
      ],
      onChanged: onChanged,
    );
  }
}

class _GoalSegment extends StatelessWidget {
  final FitnessGoal value;
  final ValueChanged<FitnessGoal> onChanged;
  const _GoalSegment({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _RowSegment<FitnessGoal>(
      value: value,
      options: const [
        (FitnessGoal.buildMuscle, 'Build'),
        (FitnessGoal.loseFat, 'Lose'),
        (FitnessGoal.recomp, 'Recomp'),
        (FitnessGoal.generalFitness, 'General'),
      ],
      onChanged: onChanged,
    );
  }
}

class _RowSegment<T> extends StatelessWidget {
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  const _RowSegment({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: options.map((o) {
          final active = o.$1 == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(o.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  o.$2,
                  style: TextStyle(
                    color: active ? Colors.black : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _OverrideRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int? autoValue;
  const _OverrideRow({
    required this.label,
    required this.controller,
    required this.autoValue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Row(
                children: [
                  Expanded(
                      child: Text(label,
                          style: AppText.body.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13))),
                  if (autoValue != null)
                    Text('auto: $autoValue',
                        style: AppText.meta.copyWith(
                            color: AppColors.textTertiary, fontSize: 11)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.stroke),
              ),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                cursorColor: AppColors.accent,
                style: AppText.body.copyWith(
                    color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  hintText: '—',
                  hintStyle: AppText.body.copyWith(
                      color: AppColors.textTertiary, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
