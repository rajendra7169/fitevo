import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/enums.dart';
import '../data/models/period_log.dart';
import '../data/repositories/period_repo.dart';
import '../state/providers.dart';
import '../theme.dart';

/// One-tap period day log. Shown on the dashboard only for users whose
/// profile gender == female. Tapping the card opens a sheet to set
/// flow + symptoms + notes for today (or update an existing entry).
class PeriodLogCard extends ConsumerWidget {
  const PeriodLogCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayPeriodLogProvider).valueOrNull;
    final insight = ref.watch(cycleInsightProvider);
    final loggedToday =
        today != null && today.flow != MenstrualFlow.none;

    return GestureDetector(
      onTap: () => _openSheet(context, ref, existing: today),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: loggedToday
              ? AppColors.period.withValues(alpha: 0.10)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: loggedToday
                  ? AppColors.period.withValues(alpha: 0.35)
                  : AppColors.stroke),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.period.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.water_drop_outlined,
                  size: 16, color: AppColors.period),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _headline(loggedToday, today, insight),
                    style: AppText.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtext(loggedToday, today, insight),
                    style: AppText.meta.copyWith(fontSize: 11.5),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: loggedToday
                    ? AppColors.surfaceHigh
                    : AppColors.period,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                loggedToday ? 'Edit' : 'Log',
                style: TextStyle(
                  color: loggedToday
                      ? AppColors.textPrimary
                      : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _headline(
      bool loggedToday, PeriodLog? today, CycleInsight insight) {
    if (loggedToday) {
      final flow = _flowLabel(today!.flow);
      final day = insight.currentPeriodDay;
      if (day != null) return 'Period · day $day · $flow';
      return 'Period · $flow';
    }
    if (insight.daysSinceLastFlow != null && insight.daysSinceLastFlow! > 0) {
      return 'Cycle day ${insight.daysSinceLastFlow! + 1}';
    }
    return 'Log period';
  }

  String _subtext(
      bool loggedToday, PeriodLog? today, CycleInsight insight) {
    if (loggedToday) {
      final symptoms = today!.symptoms;
      if (symptoms.isEmpty) return 'Tap to add symptoms or notes';
      return symptoms.take(3).map(_symptomLabel).join(' · ');
    }
    if (insight.estimatedCycleLength != null) {
      return 'Est. ${insight.estimatedCycleLength}-day cycle · tap to log today';
    }
    return 'Track flow + symptoms — feeds the coach';
  }
}

Future<void> _openSheet(BuildContext context, WidgetRef ref,
    {PeriodLog? existing}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => _PeriodSheet(existing: existing),
  );
}

class _PeriodSheet extends ConsumerStatefulWidget {
  final PeriodLog? existing;
  const _PeriodSheet({this.existing});

  @override
  ConsumerState<_PeriodSheet> createState() => _PeriodSheetState();
}

class _PeriodSheetState extends ConsumerState<_PeriodSheet> {
  late MenstrualFlow _flow =
      widget.existing?.flow ?? MenstrualFlow.medium;
  late final Set<PeriodSymptom> _symptoms =
      {...?widget.existing?.symptoms};
  late final TextEditingController _notesCtl =
      TextEditingController(text: widget.existing?.notes ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _notesCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(periodRepoProvider).setEntry(
            ref.read(todayProvider),
            flow: _flow,
            symptoms: _symptoms.toList(),
            notes: _notesCtl.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clear() async {
    setState(() => _saving = true);
    try {
      await ref.read(periodRepoProvider).clear(ref.read(todayProvider));
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
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
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.period.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.water_drop_outlined,
                      size: 16, color: AppColors.period),
                ),
                const SizedBox(width: 10),
                Text(widget.existing == null ? 'Log period day' : 'Edit period day',
                    style: AppText.sectionTitle.copyWith(fontSize: 17)),
              ],
            ),
            const SizedBox(height: 16),
            Text('FLOW', style: AppText.label.copyWith(fontSize: 11)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in MenstrualFlow.values)
                  _FlowChip(
                    flow: f,
                    active: _flow == f,
                    onTap: () => setState(() => _flow = f),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text('SYMPTOMS', style: AppText.label.copyWith(fontSize: 11)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in PeriodSymptom.values)
                  _SymptomChip(
                    symptom: s,
                    active: _symptoms.contains(s),
                    onTap: () => setState(() {
                      if (_symptoms.contains(s)) {
                        _symptoms.remove(s);
                      } else {
                        _symptoms.add(s);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text('NOTES', style: AppText.label.copyWith(fontSize: 11)),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.stroke),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: _notesCtl,
                cursorColor: AppColors.period,
                maxLines: 2,
                style: AppText.body.copyWith(fontSize: 14),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14),
                  hintText: 'Anything to remember…',
                  hintStyle: AppText.body.copyWith(
                      color: AppColors.textTertiary, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                if (widget.existing != null)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _saving ? null : _clear,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.danger
                                  .withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 16, color: AppColors.danger),
                            const SizedBox(width: 6),
                            Text('Clear',
                                style: AppText.body.copyWith(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (widget.existing != null) const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _saving ? null : _save,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.period,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text('Save',
                                style: AppText.body.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowChip extends StatelessWidget {
  final MenstrualFlow flow;
  final bool active;
  final VoidCallback onTap;
  const _FlowChip(
      {required this.flow, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active
              ? AppColors.period.withValues(alpha: 0.15)
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? AppColors.period
                : AppColors.stroke,
            width: active ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FlowDots(flow: flow, color: AppColors.period),
            const SizedBox(width: 8),
            Text(
              _flowLabel(flow),
              style: AppText.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowDots extends StatelessWidget {
  final MenstrualFlow flow;
  final Color color;
  const _FlowDots({required this.flow, required this.color});

  @override
  Widget build(BuildContext context) {
    final intensity = switch (flow) {
      MenstrualFlow.none => 0,
      MenstrualFlow.spotting => 1,
      MenstrualFlow.light => 1,
      MenstrualFlow.medium => 2,
      MenstrualFlow.heavy => 3,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final on = i < intensity;
        return Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(
            color: on ? color : color.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class _SymptomChip extends StatelessWidget {
  final PeriodSymptom symptom;
  final bool active;
  final VoidCallback onTap;
  const _SymptomChip(
      {required this.symptom,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.accent.withValues(alpha: 0.14)
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppColors.accent : AppColors.stroke,
            width: active ? 1.4 : 1,
          ),
        ),
        child: Text(
          _symptomLabel(symptom),
          style: AppText.body.copyWith(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      )
          .animate(target: active ? 1 : 0)
          .scaleXY(begin: 1, end: 1.02, duration: 140.ms),
    );
  }
}

String _flowLabel(MenstrualFlow f) => switch (f) {
      MenstrualFlow.none => 'None',
      MenstrualFlow.spotting => 'Spotting',
      MenstrualFlow.light => 'Light',
      MenstrualFlow.medium => 'Medium',
      MenstrualFlow.heavy => 'Heavy',
    };

String _symptomLabel(PeriodSymptom s) => switch (s) {
      PeriodSymptom.cramps => 'Cramps',
      PeriodSymptom.headache => 'Headache',
      PeriodSymptom.bloating => 'Bloating',
      PeriodSymptom.fatigue => 'Fatigue',
      PeriodSymptom.moodSwings => 'Mood swings',
      PeriodSymptom.backPain => 'Back pain',
      PeriodSymptom.breastTenderness => 'Breast tenderness',
      PeriodSymptom.nausea => 'Nausea',
      PeriodSymptom.acne => 'Acne',
      PeriodSymptom.cravings => 'Cravings',
      PeriodSymptom.insomnia => 'Insomnia',
    };
