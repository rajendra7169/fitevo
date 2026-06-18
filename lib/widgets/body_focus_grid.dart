import 'package:flutter/material.dart';

import '../theme.dart';

/// Shared list of preset body-focus chips used in onboarding and the
/// settings → profile page. Tuple = (label, short description).
const List<(String, String)> focusPresets = [
  ('Skinny arms', 'Weak upper body, need more muscle'),
  ('Belly fat', 'Carry weight around the waist'),
  ('Skinny fat', 'Average weight but low muscle tone'),
  ('Lower body heavy', 'Wider hips / thighs, slim upper'),
  ('Upper body heavy', 'Broad shoulders, slim lower body'),
  ('Athletic', 'Already toned, want maintenance'),
  ('Overall lean', 'Want to gain muscle everywhere'),
  ('Skinny legs', 'Thin legs, need lower-body strength'),
];

/// Two-column grid of selectable body-focus chips.
class BodyFocusGrid extends StatelessWidget {
  final Set<String> selected;
  final void Function(String label) onToggle;
  const BodyFocusGrid({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < focusPresets.length; i += 2) {
      final left = focusPresets[i];
      final right = i + 1 < focusPresets.length ? focusPresets[i + 1] : null;
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _FocusChip(
                label: left.$1,
                description: left.$2,
                selected: selected.contains(left.$1),
                onTap: () => onToggle(left.$1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: right == null
                  ? const SizedBox.shrink()
                  : _FocusChip(
                      label: right.$1,
                      description: right.$2,
                      selected: selected.contains(right.$1),
                      onTap: () => onToggle(right.$1),
                    ),
            ),
          ],
        ),
      ));
      if (i + 2 < focusPresets.length) rows.add(const SizedBox(height: 8));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows,
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
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.18)
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.stroke,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline_rounded,
                  size: 12,
                  color: selected
                      ? AppColors.accent
                      : AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? AppColors.accent
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: -0.1,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.meta.copyWith(
                fontSize: 10,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helpers for converting between the canonical preset labels and the
/// comma-separated string we persist in Profile.bodyFocusNotes.
class FocusNotesUtil {
  static Set<String> selectedPresets(String notes) {
    final tokens = notes
        .split(RegExp(r'[,;\n]'))
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toSet();
    return focusPresets
        .where((p) => tokens.contains(p.$1.toLowerCase()))
        .map((p) => p.$1)
        .toSet();
  }

  static String togglePreset(String notes, String label) {
    final selected = selectedPresets(notes);
    final tokens = notes
        .split(RegExp(r'[,;\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (selected.contains(label)) {
      tokens.removeWhere((t) => t.toLowerCase() == label.toLowerCase());
    } else {
      tokens.add(label);
    }
    return tokens.join(', ');
  }
}
