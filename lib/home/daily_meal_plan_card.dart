import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/daily_log.dart';
import '../data/models/enums.dart';
import '../data/models/food_entry.dart';
import '../services/ai/ai_service.dart';
import '../services/coach/daily_meal_plan.dart';
import '../state/providers.dart';
import '../theme.dart';

/// Home-screen card that drafts 3 meals for the day's macros and lets
/// the user accept (= log it instantly), regenerate, or dismiss. Caches
/// per-day so the same plan persists across restarts.
class DailyMealPlanCard extends ConsumerStatefulWidget {
  const DailyMealPlanCard({super.key});

  @override
  ConsumerState<DailyMealPlanCard> createState() =>
      _DailyMealPlanCardState();
}

class _DailyMealPlanCardState extends ConsumerState<DailyMealPlanCard> {
  DailyMealPlan? _plan;
  bool _loading = false;
  bool _dismissedToday = false;
  /// Collapsed = just the meal-name capsules in a horizontal scroll.
  /// Expanded = full per-meal detail with macros + log buttons.
  /// Persisted across restarts so the user's preference sticks.
  bool _collapsed = false;
  static const _collapsedKey = 'home.dailyMealPlan.collapsed';
  final Set<int> _loggedIndices = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
  }

  Future<void> _hydrate() async {
    final cached = await DailyMealPlanService.loadForToday();
    final prefs = await SharedPreferences.getInstance();
    final wasCollapsed = prefs.getBool(_collapsedKey) ?? false;
    if (!mounted) return;
    setState(() {
      _plan = cached;
      _collapsed = wasCollapsed;
    });
  }

  Future<void> _toggleCollapsed() async {
    setState(() => _collapsed = !_collapsed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_collapsedKey, _collapsed);
  }

  Future<void> _generate() async {
    if (_loading) return;
    final profile = ref.read(profileStreamProvider).valueOrNull;
    final todayLog = ref.read(todayLogProvider).valueOrNull;
    if (profile == null) return;
    setState(() => _loading = true);
    try {
      final ai = ref.read(aiServiceProvider);
      // Pass the user's actual food history so the AI builds meals
      // from what they already eat (not generic Western defaults).
      final allFoods = ref.read(allFoodEntriesProvider).valueOrNull ??
          const <FoodEntry>[];
      final plan = await DailyMealPlanService.generate(
        ai: ai,
        profile: profile,
        todayLog: todayLog,
        allFoods: allFoods,
      );
      if (mounted) {
        setState(() {
          _plan = plan;
          _loggedIndices.clear();
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          backgroundColor: AppColors.surfaceHigh,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          content: Text(
              e is AiException ? e.message : 'Could not draft meal plan.',
              style:
                  AppText.body.copyWith(color: AppColors.textPrimary)),
        ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logMeal(int index, MealSuggestion m) async {
    if (_loggedIndices.contains(index)) return;
    final repo = ref.read(nutritionRepoProvider);
    final now = DateTime.now();
    final desc =
        m.name.isEmpty ? (m.portion ?? 'Meal') : m.name;
    final entry = FoodEntry()
      ..timestamp = now
      ..dateKey = DailyLog.keyFor(now)
      ..rawInput = '${DailyMealPlan.slots[index]}: $desc'
      ..description = desc
      ..quantity = m.portion ?? ''
      ..unit = ''
      ..calories = m.calories
      ..proteinG = m.proteinG
      // Full macros now come back from the AI (newer prompts) — fall
      // back to 0 only for legacy responses. User can still edit later.
      ..carbsG = m.carbsG ?? 0
      ..fatG = m.fatG ?? 0
      ..fiberG = m.fiberG ?? 0
      ..sodiumMg = 0
      ..source = FoodSource.aiText
      ..confidence = EstimateConfidence.medium;
    await repo.addFoodEntry(entry);
    if (!mounted) return;
    setState(() => _loggedIndices.add(index));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        backgroundColor: AppColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        content: Text('Logged $desc · ${m.calories} kcal',
            style: AppText.body.copyWith(color: AppColors.textPrimary)),
      ));
  }

  void _dismiss() {
    setState(() => _dismissedToday = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissedToday) return const SizedBox.shrink();
    final plan = _plan;
    if (plan == null) {
      // First-visit state — small "draft my day" prompt. Hidden when
      // there's no profile yet to avoid flashing on cold start.
      final profile = ref.watch(profileStreamProvider).valueOrNull;
      if (profile == null) return const SizedBox.shrink();
      return GestureDetector(
        onTap: _loading ? null : _generate,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.restaurant_menu_rounded,
                    size: 16, color: AppColors.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TODAY\'S MEAL PLAN',
                        style: AppText.label.copyWith(fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      _loading
                          ? 'Drafting 3 meals for your macros…'
                          : 'Draft 3 meals that hit today\'s targets',
                      style: AppText.body.copyWith(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              if (_loading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.accent),
                )
              else
                Icon(Icons.auto_awesome_rounded,
                    size: 18, color: AppColors.accent),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_menu_rounded,
                  size: 14, color: AppColors.accent),
              const SizedBox(width: 6),
              Text('TODAY\'S MEAL PLAN',
                  style: AppText.label.copyWith(fontSize: 11)),
              const Spacer(),
              IconButton(
                onPressed: _toggleCollapsed,
                icon: Icon(
                  _collapsed
                      ? Icons.unfold_more_rounded
                      : Icons.unfold_less_rounded,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
                tooltip: _collapsed ? 'Expand' : 'Collapse',
              ),
              IconButton(
                onPressed: _loading ? null : _generate,
                icon: Icon(Icons.refresh_rounded,
                    size: 16, color: AppColors.textTertiary),
                tooltip: 'Regenerate',
              ),
              IconButton(
                onPressed: _dismiss,
                icon: Icon(Icons.close_rounded,
                    size: 16, color: AppColors.textTertiary),
                tooltip: 'Dismiss for today',
              ),
            ],
          ),
          // Collapsed mode — single horizontally-scrollable strip of
          // meal name capsules. Tap a capsule to expand the card and
          // jump straight to that meal's detail (or just expand).
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _collapsed && plan.meals.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      // Bleed past the card padding so the last
                      // capsule has a comfortable scroll runway.
                      padding: const EdgeInsets.only(right: 4),
                      child: Row(
                        children: [
                          for (var i = 0; i < plan.meals.length; i++) ...[
                            _MealCapsule(
                              slot: i < DailyMealPlan.slots.length
                                  ? DailyMealPlan.slots[i]
                                  : 'Meal ${i + 1}',
                              meal: plan.meals[i],
                              logged: _loggedIndices.contains(i),
                              onTap: _toggleCollapsed,
                            ),
                            if (i < plan.meals.length - 1)
                              const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          // Full meal rows only when expanded. Empty-plan message
          // mirrored here so it's visible in either state.
          if (!_collapsed) ...[
            if (plan.meals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'AI returned an empty plan — tap refresh.',
                  style: AppText.body.copyWith(fontSize: 13),
                ),
              )
            else
              for (var i = 0; i < plan.meals.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _MealRow(
                    index: i,
                    slot: i < DailyMealPlan.slots.length
                        ? DailyMealPlan.slots[i]
                        : 'Meal ${i + 1}',
                    meal: plan.meals[i],
                    logged: _loggedIndices.contains(i),
                    onLog: () => _logMeal(i, plan.meals[i]),
                  ).animate(delay: Duration(milliseconds: i * 80))
                      .fadeIn(duration: 240.ms)
                      .slideY(begin: 0.04, end: 0),
                ),
          ],
        ],
      ),
    );
  }
}

class _MealRow extends StatefulWidget {
  final int index;
  final String slot;
  final MealSuggestion meal;
  final bool logged;
  final VoidCallback onLog;
  const _MealRow({
    required this.index,
    required this.slot,
    required this.meal,
    required this.logged,
    required this.onLog,
  });

  @override
  State<_MealRow> createState() => _MealRowState();
}

class _MealRowState extends State<_MealRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.meal;
    final portion = m.portion?.trim() ?? '';
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: widget.logged
              ? AppColors.protein.withValues(alpha: 0.10)
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: widget.logged
                  ? AppColors.protein.withValues(alpha: 0.4)
                  : AppColors.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(widget.slot[0],
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      )),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(widget.slot.toUpperCase(),
                              style: AppText.label.copyWith(
                                  fontSize: 9, letterSpacing: 0.8)),
                          const SizedBox(width: 6),
                          Text('${m.calories} kcal · ${m.proteinG}g P',
                              style: AppText.meta.copyWith(
                                  fontSize: 10.5,
                                  color: AppColors.textTertiary)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        m.name.isEmpty ? '(unnamed)' : m.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body.copyWith(
                            fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.logged ? null : widget.onLog,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      color: widget.logged
                          ? AppColors.protein.withValues(alpha: 0.15)
                          : AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.logged
                              ? Icons.check_rounded
                              : Icons.add_rounded,
                          size: 14,
                          color: widget.logged
                              ? AppColors.protein
                              : AppColors.onAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(widget.logged ? 'Logged' : 'Log',
                            style: TextStyle(
                              color: widget.logged
                                  ? AppColors.protein
                                  : AppColors.onAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Expanded view — gram breakdown + full macros. Always
            // available on tap because the user explicitly asked to
            // see full details.
            if (_expanded) ...[
              const SizedBox(height: 10),
              if (portion.isNotEmpty) ...[
                Text('PORTION',
                    style: AppText.label.copyWith(fontSize: 9)),
                const SizedBox(height: 2),
                Text(
                  portion,
                  style: AppText.body.copyWith(
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
              ],
              Text('MACROS',
                  style: AppText.label.copyWith(fontSize: 9)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _MacroChip(
                      label: 'P',
                      value: '${m.proteinG}g',
                      color: AppColors.protein),
                  if (m.carbsG != null)
                    _MacroChip(
                        label: 'C',
                        value: '${m.carbsG}g',
                        color: AppColors.carbs),
                  if (m.fatG != null)
                    _MacroChip(
                        label: 'F',
                        value: '${m.fatG}g',
                        color: AppColors.fat),
                  if (m.fiberG != null && m.fiberG! > 0)
                    _MacroChip(
                        label: 'Fiber',
                        value: '${m.fiberG}g',
                        color: AppColors.fiber),
                  _MacroChip(
                      label: 'kcal',
                      value: '${m.calories}',
                      color: AppColors.accent),
                ],
              ),
              if ((m.note ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  m.note!,
                  style: AppText.meta.copyWith(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact pill for the collapsed view — slot letter + meal name +
/// calories. Always single-line (ellipsis cuts overflow); the row of
/// these scrolls horizontally so the user can see all 3 (or N) meals
/// at a glance without unfolding the full card.
class _MealCapsule extends StatelessWidget {
  final String slot;
  final MealSuggestion meal;
  final bool logged;
  final VoidCallback onTap;
  const _MealCapsule({
    required this.slot,
    required this.meal,
    required this.logged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = meal.name.isEmpty ? slot : meal.name;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: logged
              ? AppColors.protein.withValues(alpha: 0.14)
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: logged
                ? AppColors.protein.withValues(alpha: 0.4)
                : AppColors.stroke,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: logged
                    ? AppColors.protein.withValues(alpha: 0.25)
                    : AppColors.accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                slot[0],
                style: TextStyle(
                  color: logged ? AppColors.protein : AppColors.accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 7),
            // Bound the name so a long meal name doesn't stretch the
            // capsule past the screen — capped at a reasonable width
            // with ellipsis, full name lives in the expanded row.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${meal.calories}',
              style: AppText.meta.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textTertiary,
              ),
            ),
            if (logged) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_rounded,
                  size: 12, color: AppColors.protein),
            ],
          ],
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

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
