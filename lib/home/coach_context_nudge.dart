import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/profile.dart';
import '../features/settings/profile_edit_page.dart';
import '../state/providers.dart';
import '../theme.dart';

/// Tiny dashboard card that surfaces high-value Profile fields the user
/// hasn't filled in yet. Coach accuracy hinges on these. Dismissable —
/// the user is in charge.
class CoachContextNudge extends ConsumerStatefulWidget {
  const CoachContextNudge({super.key});

  @override
  ConsumerState<CoachContextNudge> createState() =>
      _CoachContextNudgeState();
}

class _CoachContextNudgeState extends ConsumerState<CoachContextNudge> {
  static const _dismissedKey = 'coachContextNudge.dismissedAt';
  bool _dismissedThisWeek = false;

  @override
  void initState() {
    super.initState();
    _loadDismissed();
  }

  Future<void> _loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_dismissedKey);
    if (ts == null) return;
    final age = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(ts));
    if (age.inDays < 7 && mounted) {
      setState(() => _dismissedThisWeek = true);
    }
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _dismissedKey, DateTime.now().millisecondsSinceEpoch);
    if (mounted) setState(() => _dismissedThisWeek = true);
  }

  List<String> _missing(Profile p) {
    final out = <String>[];
    if (p.bodyFatPct == null) out.add('body fat %');
    if (p.restDays.isEmpty) out.add('rest days');
    if (p.goesGym && p.gymStartDate == null) out.add('gym experience');
    if (p.weighInCadence.name == 'weekly' && p.weighInWeekday == null) {
      out.add('weigh-in day');
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissedThisWeek) return const SizedBox.shrink();
    final profile = ref.watch(profileStreamProvider).valueOrNull;
    if (profile == null) return const SizedBox.shrink();
    final missing = _missing(profile);
    if (missing.length < 2) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Coach can do better',
                    style: AppText.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
              GestureDetector(
                onTap: _dismiss,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(Icons.close_rounded,
                      size: 16, color: AppColors.textTertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'You haven\'t set ${missing.join(", ")}. Adding these makes targets and AI suggestions more accurate.',
            style: AppText.body.copyWith(fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const ProfileEditPage()),
            ),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(Icons.arrow_forward_rounded,
                    size: 14, color: AppColors.accent),
                const SizedBox(width: 6),
                Text('Improve accuracy',
                    style: AppText.label.copyWith(
                        color: AppColors.accent,
                        letterSpacing: 0.6,
                        fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
