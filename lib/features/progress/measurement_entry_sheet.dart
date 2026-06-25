import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/body_measurement.dart';
import '../../state/providers.dart';
import '../../theme.dart';

class MeasurementEntrySheet extends ConsumerStatefulWidget {
  final BodyMeasurement? edit;
  const MeasurementEntrySheet({super.key, this.edit});

  static Future<bool?> show(BuildContext context,
      {BodyMeasurement? edit}) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => MeasurementEntrySheet(edit: edit),
    );
  }

  @override
  ConsumerState<MeasurementEntrySheet> createState() =>
      _MeasurementEntrySheetState();
}

class _MeasurementEntrySheetState extends ConsumerState<MeasurementEntrySheet> {
  late final TextEditingController _weight;
  late final TextEditingController _bodyFat;
  late final TextEditingController _waist;
  late final TextEditingController _chest;
  late final TextEditingController _arm;
  late final TextEditingController _thigh;
  late final TextEditingController _note;
  String? _photoPath;
  bool _busy = false;
  bool _showOptional = false;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _weight = TextEditingController(text: e?.weightKg.toStringAsFixed(1) ?? '');
    _bodyFat =
        TextEditingController(text: e?.bodyFatPct?.toStringAsFixed(1) ?? '');
    _waist = TextEditingController(text: e?.waistCm?.toStringAsFixed(1) ?? '');
    _chest = TextEditingController(text: e?.chestCm?.toStringAsFixed(1) ?? '');
    _arm = TextEditingController(text: e?.armCm?.toStringAsFixed(1) ?? '');
    _thigh = TextEditingController(text: e?.thighCm?.toStringAsFixed(1) ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _photoPath = e?.photoPath;
    if (e != null && (e.bodyFatPct != null || e.waistCm != null)) {
      _showOptional = true;
    }
  }

  @override
  void dispose() {
    _weight.dispose();
    _bodyFat.dispose();
    _waist.dispose();
    _chest.dispose();
    _arm.dispose();
    _thigh.dispose();
    _note.dispose();
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

  Future<void> _addPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (file == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final progressDir = Directory('${dir.path}/progress_photos');
      if (!progressDir.existsSync()) progressDir.createSync();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final dest = '${progressDir.path}/photo_$ts.jpg';
      await File(file.path).copy(dest);
      if (!mounted) return;
      setState(() => _photoPath = dest);
    } catch (_) {
      if (mounted) _toast('Could not attach photo.');
    }
  }

  Future<void> _pickPhotoSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add progress photo',
                  style: AppText.sectionTitle.copyWith(fontSize: 15)),
              const SizedBox(height: 6),
              Text('Stays on this device — never uploaded.',
                  style: AppText.meta.copyWith(fontSize: 12)),
              const SizedBox(height: 14),
              _SimpleAction(
                icon: Icons.photo_camera_rounded,
                label: 'Take a photo',
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              const SizedBox(height: 8),
              _SimpleAction(
                icon: Icons.photo_library_rounded,
                label: 'Choose from gallery',
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source != null) await _addPhoto(source);
  }

  Future<void> _save() async {
    final w = double.tryParse(_weight.text.trim());
    if (w == null || w <= 0) {
      _toast('Enter a valid weight.');
      return;
    }
    setState(() => _busy = true);
    try {
      final m = widget.edit ?? BodyMeasurement();
      m
        ..date = widget.edit?.date ?? DateTime.now()
        ..weightKg = w
        ..bodyFatPct = _maybeD(_bodyFat)
        ..waistCm = _maybeD(_waist)
        ..chestCm = _maybeD(_chest)
        ..armCm = _maybeD(_arm)
        ..thighCm = _maybeD(_thigh)
        ..note = _note.text.trim().isEmpty ? null : _note.text.trim()
        ..photoPath = _photoPath;
      await ref.read(measurementRepoProvider).save(m);
      // Recompute targets from new weight trend.
      await ref.read(adaptiveTargetsProvider).recomputeFromWeightTrend();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) _toast('Could not save.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  double? _maybeD(TextEditingController c) {
    final v = double.tryParse(c.text.trim());
    if (v == null || v <= 0) return null;
    return v;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
              Text(widget.edit == null ? 'Log measurement' : 'Edit measurement',
                  style: AppText.sectionTitle.copyWith(fontSize: 17)),
              const SizedBox(height: 14),
              Text('WEIGHT (KG)', style: AppText.label),
              const SizedBox(height: 8),
              _Field(
                controller: _weight,
                hint: 'e.g. 68.5',
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () =>
                    setState(() => _showOptional = !_showOptional),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Icon(
                      _showOptional
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(_showOptional ? 'Hide more' : 'Add more details',
                        style: AppText.label.copyWith(
                            color: AppColors.accent,
                            letterSpacing: 0.6)),
                  ],
                ),
              ),
              if (_showOptional) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _LabeledField(
                            label: 'BODY FAT %', controller: _bodyFat)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _LabeledField(
                            label: 'WAIST (CM)', controller: _waist)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _LabeledField(
                            label: 'CHEST (CM)', controller: _chest)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _LabeledField(
                            label: 'ARM (CM)', controller: _arm)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _LabeledField(
                            label: 'THIGH (CM)', controller: _thigh)),
                  ],
                ),
                const SizedBox(height: 12),
                Text('NOTE (OPTIONAL)', style: AppText.label),
                const SizedBox(height: 8),
                _Field(
                  controller: _note,
                  hint: 'Anything you want to remember',
                  maxLines: 2,
                ),
              ],
              const SizedBox(height: 16),
              Text('PROGRESS PHOTO (PRIVATE)', style: AppText.label),
              const SizedBox(height: 6),
              Text('Stays on this device. Never synced.',
                  style: AppText.meta
                      .copyWith(fontSize: 11, color: AppColors.textTertiary)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickPhotoSource,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.stroke),
                    image: _photoPath != null
                        ? DecorationImage(
                            image: FileImage(File(_photoPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: _photoPath != null
                      ? null
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_rounded,
                                size: 18, color: AppColors.accent),
                            const SizedBox(width: 8),
                            Text('Attach a photo',
                                style: AppText.body.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ],
                        ),
                ),
              ),
              if (_photoPath != null) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => setState(() => _photoPath = null),
                  child: Text('Remove photo',
                      style: AppText.label.copyWith(
                          color: AppColors.danger,
                          letterSpacing: 0.4)),
                ),
              ],
              const SizedBox(height: 22),
              GestureDetector(
                onTap: _busy ? null : _save,
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
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppColors.onAccent))
                      : Text(
                          'Save',
                          style: TextStyle(
                            color: AppColors.onAccent,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
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
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  const _Field({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
  });

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
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
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

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _LabeledField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label.copyWith(fontSize: 10)),
        const SizedBox(height: 6),
        _Field(
          controller: controller,
          hint: '—',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
          ],
        ),
      ],
    );
  }
}

class _SimpleAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SimpleAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textPrimary),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: AppText.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700))),
          ],
        ),
      ),
    );
  }
}
