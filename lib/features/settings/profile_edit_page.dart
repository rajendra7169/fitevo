import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/health_math.dart';
import '../../data/models/enums.dart';
import '../../data/models/profile.dart';
import '../../state/providers.dart';
import '../../theme.dart';

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

  // overrides
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
    _calOverride = TextEditingController();
    _proteinOverride = TextEditingController();
    _carbOverride = TextEditingController();
    _fatOverride = TextEditingController();
    _fiberOverride = TextEditingController();
    _waterOverride = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final p = await ref.read(profileRepoProvider).getCurrent();
    if (!mounted || p == null) return;
    _profile = p;
    _name.text = p.displayName;
    _age.text = p.age.toString();
    _heightCm.text = p.heightCm.toStringAsFixed(0);
    _weightKg.text = p.weightKg.toStringAsFixed(1);
    _trainingDays.text = p.trainingDaysPerWeek.toString();
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

  Future<void> _save() async {
    final p = _profile;
    if (p == null) return;
    setState(() => _busy = true);
    try {
      final age = int.tryParse(_age.text.trim()) ?? p.age;
      final height = double.tryParse(_heightCm.text.trim()) ?? p.heightCm;
      final weight = double.tryParse(_weightKg.text.trim()) ?? p.weightKg;
      final days = int.tryParse(_trainingDays.text.trim()) ??
          p.trainingDaysPerWeek;

      final t = HealthMath.compute(
        gender: _gender,
        age: age,
        weightKg: weight,
        heightCm: height,
        activity: _activity,
        goal: _goal,
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
                  Text('YOU', style: AppText.label),
                  const SizedBox(height: 8),
                  _F(controller: _name, hint: 'Name'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _F(controller: _age, hint: 'Age', digits: true)),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: _GenderSegment(
                          value: _gender,
                          onChanged: (g) => setState(() => _gender = g),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: _F(
                              controller: _heightCm,
                              hint: 'Height (cm)',
                              digits: true)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _F(
                              controller: _weightKg,
                              hint: 'Weight (kg)',
                              decimals: true)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('ACTIVITY', style: AppText.label),
                  const SizedBox(height: 8),
                  _ActivitySegment(
                    value: _activity,
                    onChanged: (a) => setState(() => _activity = a),
                  ),
                  const SizedBox(height: 18),
                  Text('GOAL', style: AppText.label),
                  const SizedBox(height: 8),
                  _GoalSegment(
                    value: _goal,
                    onChanged: (g) => setState(() => _goal = g),
                  ),
                  const SizedBox(height: 10),
                  _F(
                    controller: _trainingDays,
                    hint: 'Training days / week',
                    digits: true,
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                          child: Text('OVERRIDE TARGETS', style: AppText.label)),
                      GestureDetector(
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
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Leave blank to use the values auto-computed from your profile.',
                    style: AppText.meta.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 10),
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
            ),
    );
  }
}

class _F extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool digits;
  final bool decimals;
  const _F({
    required this.controller,
    required this.hint,
    this.digits = false,
    this.decimals = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.stroke),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        keyboardType: decimals
            ? const TextInputType.numberWithOptions(decimal: true)
            : digits
                ? TextInputType.number
                : TextInputType.text,
        inputFormatters: decimals
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
            : digits
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
        cursorColor: AppColors.accent,
        style:
            AppText.body.copyWith(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          hintText: hint,
          hintStyle:
              AppText.body.copyWith(color: AppColors.textTertiary, fontSize: 15),
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
        color: AppColors.surface,
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
                    fontWeight: FontWeight.w700,
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
              padding: const EdgeInsets.symmetric(horizontal: 14),
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
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
                color: AppColors.surfaceHigh,
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
