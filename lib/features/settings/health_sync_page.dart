import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../state/providers.dart';
import '../../theme.dart';

class HealthSyncPage extends ConsumerStatefulWidget {
  const HealthSyncPage({super.key});

  @override
  ConsumerState<HealthSyncPage> createState() => _HealthSyncPageState();
}

class _HealthSyncPageState extends ConsumerState<HealthSyncPage> {
  final _steps = TextEditingController();
  final _hr = TextEditingController();
  final _sleepH = TextEditingController();
  final _sleepM = TextEditingController();
  DateTime _date = DateTime.now();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadForDate(_date);
  }

  Future<void> _loadForDate(DateTime d) async {
    final repo = ref.read(nutritionRepoProvider);
    final log = await repo.dailyLogFor(d);
    if (!mounted) return;
    setState(() {
      _steps.text = log?.steps?.toString() ?? '';
      _hr.text = log?.heartRateAvg?.toString() ?? '';
      final sleep = log?.sleepMinutes ?? 0;
      _sleepH.text = sleep > 0 ? (sleep ~/ 60).toString() : '';
      _sleepM.text = sleep > 0 ? (sleep % 60).toString() : '';
    });
  }

  @override
  void dispose() {
    _steps.dispose();
    _hr.dispose();
    _sleepH.dispose();
    _sleepM.dispose();
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

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final steps = int.tryParse(_steps.text.trim());
      final hr = int.tryParse(_hr.text.trim());
      final h = int.tryParse(_sleepH.text.trim()) ?? 0;
      final m = int.tryParse(_sleepM.text.trim()) ?? 0;
      final sleep = (h * 60) + m;
      await ref.read(nutritionRepoProvider).upsertDailyLog(
            _date,
            steps: steps,
            heartRateAvg: hr,
            sleepMinutes: sleep > 0 ? sleep : null,
          );
      if (!mounted) return;
      _toast('Saved for ${DateFormat('MMM d').format(_date)}.');
    } catch (_) {
      if (mounted) _toast('Could not save.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
                  primary: AppColors.accent,
                  onPrimary: Colors.black,
                  surface: AppColors.surface,
                  onSurface: AppColors.textPrimary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() => _date = picked);
    await _loadForDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEEE, MMM d').format(_date);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text('Health sync', style: AppText.sectionTitle),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        actions: [
          TextButton(
            onPressed: _busy ? null : _save,
            child: Text(
              _busy ? '…' : 'Save',
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
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Copy steps, HR, and sleep from your band\'s app. Used for trend display.',
                      style: AppText.meta.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('DATE', style: AppText.label),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding:
                    const EdgeInsets.fromLTRB(14, 14, 14, 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 16, color: AppColors.accent),
                    const SizedBox(width: 10),
                    Text(dateLabel,
                        style: AppText.body.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppColors.textTertiary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('STEPS', style: AppText.label),
            const SizedBox(height: 8),
            _IntField(controller: _steps, hint: 'e.g. 8420'),
            const SizedBox(height: 14),
            Text('AVG HEART RATE (BPM)', style: AppText.label),
            const SizedBox(height: 8),
            _IntField(controller: _hr, hint: 'e.g. 72'),
            const SizedBox(height: 14),
            Text('SLEEP', style: AppText.label),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _IntField(controller: _sleepH, hint: 'hours')),
                const SizedBox(width: 10),
                Expanded(
                    child: _IntField(controller: _sleepM, hint: 'minutes')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IntField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _IntField({required this.controller, required this.hint});

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
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        cursorColor: AppColors.accent,
        style:
            AppText.body.copyWith(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          hintText: hint,
          hintStyle: AppText.body.copyWith(
              color: AppColors.textTertiary, fontSize: 15),
        ),
      ),
    );
  }
}
