import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

enum KmUnit { perDay, perWeek }

/// A km input that lets the user pick whether they're entering km/day or
/// km/week. Always emits the value in [canonicalUnit] via [onChanged].
///
/// Example: a walking field whose canonical unit is per-day. If the user
/// flips the toggle to "Week" and types 35, [onChanged] still fires with
/// `5.0` (35 / 7). The Profile model stays simple — single field per
/// activity, single unit.
class KmInputField extends StatefulWidget {
  final String label;
  final double initialCanonicalValue;
  final KmUnit canonicalUnit;
  final void Function(double valueInCanonicalUnit) onChanged;
  final double maxPerWeek;

  const KmInputField({
    super.key,
    required this.label,
    required this.initialCanonicalValue,
    required this.canonicalUnit,
    required this.onChanged,
    this.maxPerWeek = 200,
  });

  @override
  State<KmInputField> createState() => _KmInputFieldState();
}

class _KmInputFieldState extends State<KmInputField> {
  late final TextEditingController _ctl;
  late KmUnit _displayUnit;

  @override
  void initState() {
    super.initState();
    _displayUnit = widget.canonicalUnit;
    _ctl = TextEditingController(
      text: _format(widget.initialCanonicalValue),
    );
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  String _format(double v) {
    if (v <= 0) return '';
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  double _toCanonical(double displayed) {
    if (_displayUnit == widget.canonicalUnit) return displayed;
    // displayUnit != canonicalUnit, so convert
    if (widget.canonicalUnit == KmUnit.perDay) {
      // displayed is per-week, convert to per-day
      return displayed / 7.0;
    } else {
      // canonical is per-week, displayed is per-day
      return displayed * 7.0;
    }
  }

  void _switchUnit(KmUnit u) {
    if (u == _displayUnit) return;
    final raw = double.tryParse(_ctl.text.trim()) ?? 0;
    // raw is in current _displayUnit. Convert to the new unit's view.
    double newDisplayed;
    if (_displayUnit == KmUnit.perDay && u == KmUnit.perWeek) {
      newDisplayed = raw * 7;
    } else if (_displayUnit == KmUnit.perWeek && u == KmUnit.perDay) {
      newDisplayed = raw / 7;
    } else {
      newDisplayed = raw;
    }
    setState(() {
      _displayUnit = u;
      _ctl.text = _format(newDisplayed);
    });
  }

  void _onTextChanged(String v) {
    final displayed = double.tryParse(v.trim()) ?? 0;
    widget.onChanged(_toCanonical(displayed));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(widget.label,
                  style: AppText.label.copyWith(fontSize: 11)),
            ),
            _UnitToggle(
              value: _displayUnit,
              onChanged: _switchUnit,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.stroke),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  cursorColor: AppColors.accent,
                  onChanged: _onTextChanged,
                  style: AppText.body.copyWith(
                      color: AppColors.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                    hintText: '0',
                    hintStyle: AppText.body.copyWith(
                        color: AppColors.textTertiary, fontSize: 15),
                  ),
                ),
              ),
              Text(
                _displayUnit == KmUnit.perDay ? 'km / day' : 'km / week',
                style: AppText.meta.copyWith(
                    fontSize: 12, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UnitToggle extends StatelessWidget {
  final KmUnit value;
  final ValueChanged<KmUnit> onChanged;
  const _UnitToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _opt(label: 'Day', selected: value == KmUnit.perDay, onTap: () => onChanged(KmUnit.perDay)),
          _opt(
              label: 'Week',
              selected: value == KmUnit.perWeek,
              onTap: () => onChanged(KmUnit.perWeek)),
        ],
      ),
    );
  }

  Widget _opt({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
