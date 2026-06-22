import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/enums.dart';
import '../../data/models/profile.dart';
import '../../data/repositories/nutrition_repo.dart';
import '../../services/ai/ai_service.dart';
import '../../state/providers.dart';
import '../../theme.dart';

class MealSuggestionsSheet extends ConsumerStatefulWidget {
  final Profile profile;
  final DailyTotals totals;
  const MealSuggestionsSheet({
    super.key,
    required this.profile,
    required this.totals,
  });

  static Future<void> show(
    BuildContext context, {
    required Profile profile,
    required DailyTotals totals,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) =>
          MealSuggestionsSheet(profile: profile, totals: totals),
    );
  }

  @override
  ConsumerState<MealSuggestionsSheet> createState() =>
      _MealSuggestionsSheetState();
}

class _MealSuggestionsSheetState
    extends ConsumerState<MealSuggestionsSheet> {
  List<MealSuggestion>? _suggestions;
  bool _loading = true;
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
      final p = widget.profile;
      final t = widget.totals;
      final calLeft = (p.effectiveCalorieTarget - t.calories).clamp(0, 9999);
      final pLeft = (p.effectiveProteinTarget - t.proteinG).clamp(0, 999);
      final cLeft = (p.effectiveCarbTarget - t.carbsG).clamp(0, 999);
      final fLeft = (p.effectiveFatTarget - t.fatG).clamp(0, 999);
      final cuisine = _cuisineHintFromProfile(p);
      final list = await ref.read(aiServiceProvider).suggestMeals(
            caloriesRemaining: calLeft,
            proteinGRemaining: pLeft,
            carbsGRemaining: cLeft,
            fatGRemaining: fLeft,
            cuisineHint: cuisine,
          );
      if (!mounted) return;
      setState(() {
        _suggestions = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is AiException ? e.message : 'Could not load suggestions.';
        _loading = false;
      });
    }
  }

  /// Compose a free-text cuisine hint from country + diet preference.
  /// Returns null when neither is set so the AI can fall back to its
  /// generic suggestions instead of being pinned to a non-existent
  /// region. Examples:
  ///   - "Nepali, vegetarian"
  ///   - "Indian, vegan"
  ///   - "vegan" (no country)
  String? _cuisineHintFromProfile(Profile p) {
    final parts = <String>[];
    final countryName = _countryLabel(p.country);
    if (countryName != null) parts.add(countryName);
    if (p.dietPreference != DietPreference.omnivore) {
      parts.add(p.dietPreference.name);
    }
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  String? _countryLabel(String code) {
    switch (code.toUpperCase()) {
      case 'NP':
        return 'Nepali';
      case 'IN':
        return 'Indian';
      case 'BD':
        return 'Bangladeshi';
      case 'PK':
        return 'Pakistani';
      case 'LK':
        return 'Sri Lankan';
      case 'CN':
        return 'Chinese';
      case 'JP':
        return 'Japanese';
      case 'KR':
        return 'Korean';
      case 'TH':
        return 'Thai';
      case 'VN':
        return 'Vietnamese';
      case 'ID':
        return 'Indonesian';
      case 'PH':
        return 'Filipino';
      case 'MY':
        return 'Malaysian';
      case 'SG':
        return 'Singaporean';
      case 'TR':
        return 'Turkish';
      case 'IT':
        return 'Italian';
      case 'FR':
        return 'French';
      case 'DE':
        return 'German';
      case 'MX':
        return 'Mexican';
      case 'BR':
        return 'Brazilian';
      case 'US':
        return 'American';
      case 'UK':
        return 'British';
      case 'CA':
        return 'Canadian';
      case 'AU':
        return 'Australian';
      default:
        return null;
    }
  }

  Future<void> _logSuggestion(MealSuggestion s) async {
    try {
      await ref.read(foodLoggerProvider).logFromText(
            '${s.portion ?? ""} ${s.name}'.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        content: Text('Logged ${s.name}',
            style: AppText.body.copyWith(color: AppColors.textPrimary)),
      ));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return SizedBox(
      height: h * 0.75,
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
                  Icon(Icons.auto_awesome_rounded,
                      size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text('What should I eat?',
                      style: AppText.sectionTitle.copyWith(fontSize: 17)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Suggestions that fit your remaining macros for today.',
                style: AppText.body.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 14),
              Expanded(child: _content()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.2, color: AppColors.accent),
            ),
            const SizedBox(height: 12),
            Text('Cooking up some ideas…',
                style: AppText.body.copyWith(fontSize: 13)),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!,
                textAlign: TextAlign.center, style: AppText.body),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Try again',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    )),
              ),
            ),
          ],
        ),
      );
    }
    final list = _suggestions ?? const [];
    if (list.isEmpty) {
      return Center(child: Text('No ideas right now.', style: AppText.body));
    }
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final s = list[i];
        return GestureDetector(
          onTap: () => _logSuggestion(s),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name,
                          style: AppText.body.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        '${s.portion ?? '1 serving'} · ~${s.calories} kcal · ${s.proteinG}g protein',
                        style: AppText.meta.copyWith(fontSize: 12),
                      ),
                      if (s.note != null) ...[
                        const SizedBox(height: 4),
                        Text(s.note!,
                            style: AppText.meta.copyWith(
                                fontSize: 11,
                                color: AppColors.textTertiary)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Log',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
