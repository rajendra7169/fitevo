import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/food_entry.dart';
import '../../data/models/profile.dart';
import '../../data/repositories/nutrition_repo.dart';
import '../../home/todays_activity_card.dart' show TodaysActivityMath;
import '../../services/ai/ai_service.dart';
import '../../state/providers.dart';
import '../../theme.dart';

/// Bottom-sheet entry point — call from anywhere to surface 3 meal
/// ideas that fit the user's remaining macros for today. Respects diet
/// preference + country via the AI prompt already.
Future<void> showMealIdeasSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => const _MealIdeasSheet(),
  );
}

class _MealIdeasSheet extends ConsumerStatefulWidget {
  const _MealIdeasSheet();

  @override
  ConsumerState<_MealIdeasSheet> createState() => _MealIdeasSheetState();
}

class _MealIdeasSheetState extends ConsumerState<_MealIdeasSheet> {
  List<MealSuggestion>? _suggestions;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = ref.read(profileStreamProvider).valueOrNull;
      final totals = ref.read(todayTotalsProvider);
      final todayLog = ref.read(todayLogProvider).valueOrNull;
      if (profile == null) {
        setState(() => _error = 'Profile still loading.');
        return;
      }
      // Use today's activity-adjusted targets so suggestions respect
      // the bonus earned from running/walking. Otherwise the sheet
      // would suggest a 600 kcal meal on a day where the user has
      // 1100 kcal of headroom.
      final calT = TodaysActivityMath.effectiveTodayCalorieTarget(
          profile: profile, log: todayLog);
      final macros = TodaysActivityMath.effectiveTodayMacros(
          profile: profile, log: todayLog);
      final calLeft = (calT - totals.calories).clamp(0, 9999);
      final pLeft = (macros.proteinG - totals.proteinG).clamp(0, 999);
      final cLeft = (macros.carbG - totals.carbsG).clamp(0, 999);
      final fLeft = (macros.fatG - totals.fatG).clamp(0, 999);

      final ai = ref.read(aiServiceProvider);
      // History anchoring — pass the user's most-eaten foods so the
      // AI builds from what they actually eat (dal-bhat, paneer, etc.)
      // instead of suggesting generic Western options.
      final allFoods = ref.read(allFoodEntriesProvider).valueOrNull ??
          const <FoodEntry>[];
      final vocab = NutritionRepo.recentFoodVocabulary(allFoods);
      final result = await ai.suggestMeals(
        caloriesRemaining: calLeft,
        proteinGRemaining: pLeft,
        carbsGRemaining: cLeft,
        fatGRemaining: fLeft,
        cuisineHint: profile.country.isEmpty ? null : profile.country,
        recentFoodHistory: vocab,
        dietPreference: profile.dietPreference.name,
      );
      if (!mounted) return;
      setState(() => _suggestions = result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is AiException ? e.message : 'Could not load ideas.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileStreamProvider).valueOrNull;
    final totals = ref.watch(todayTotalsProvider);
    final todayLog = ref.watch(todayLogProvider).valueOrNull;
    final remaining = _remainingLabel(profile, totals, todayLog);
    final maxH = MediaQuery.of(context).size.height * 0.75;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
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
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text('Meal ideas',
                      style: AppText.sectionTitle.copyWith(fontSize: 17)),
                  const Spacer(),
                  IconButton(
                    onPressed: _loading ? null : _load,
                    icon: Icon(Icons.refresh_rounded,
                        size: 18, color: AppColors.textTertiary),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              if (remaining.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    remaining,
                    style: AppText.meta.copyWith(fontSize: 12),
                  ),
                ),
              const SizedBox(height: 14),
              if (_loading && _suggestions == null) const _LoadingState(),
              if (_error != null) _ErrorState(message: _error!, onRetry: _load),
              if (_suggestions != null)
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _suggestions!.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _SuggestionTile(
                      s: _suggestions![i],
                    ).animate(delay: Duration(milliseconds: i * 80))
                        .fadeIn(duration: 220.ms)
                        .slideY(begin: 0.05, end: 0),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _remainingLabel(
      Profile? profile, DailyTotals totals, dynamic todayLog) {
    if (profile == null) return '';
    final calT = TodaysActivityMath.effectiveTodayCalorieTarget(
        profile: profile, log: todayLog);
    final macros = TodaysActivityMath.effectiveTodayMacros(
        profile: profile, log: todayLog);
    final cl = (calT - totals.calories).clamp(0, 9999);
    final pl = (macros.proteinG - totals.proteinG).clamp(0, 999);
    return '$cl kcal · ${pl}g protein left for today';
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.accent),
          ),
          const SizedBox(width: 10),
          Text('Drafting ideas that fit your remaining macros…',
              style: AppText.body.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message,
              style: AppText.body.copyWith(
                  color: AppColors.textPrimary, fontSize: 13)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onRetry,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
              ),
              child: Text('Try again',
                  style: AppText.body.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final MealSuggestion s;
  const _SuggestionTile({required this.s});

  @override
  Widget build(BuildContext context) {
    final portion = s.portion?.trim() ?? '';
    final note = s.note?.trim() ?? '';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(s.name,
                    style: AppText.sectionTitle.copyWith(fontSize: 15)),
              ),
              const SizedBox(width: 8),
              Text('${s.calories} kcal',
                  style: AppText.body.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ],
          ),
          if (portion.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(portion,
                style: AppText.body.copyWith(
                  fontSize: 12.5,
                  height: 1.4,
                  color: AppColors.textPrimary,
                )),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _MacroPill(
                  label: 'P',
                  value: '${s.proteinG}g',
                  color: AppColors.protein),
              if (s.carbsG != null)
                _MacroPill(
                    label: 'C',
                    value: '${s.carbsG}g',
                    color: AppColors.carbs),
              if (s.fatG != null)
                _MacroPill(
                    label: 'F',
                    value: '${s.fatG}g',
                    color: AppColors.fat),
              if (s.fiberG != null && s.fiberG! > 0)
                _MacroPill(
                    label: 'Fiber',
                    value: '${s.fiberG}g',
                    color: AppColors.fiber),
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(note,
                style: AppText.meta.copyWith(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MacroPill(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
