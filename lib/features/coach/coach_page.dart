import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/enums.dart';
import '../../data/models/food_entry.dart';
import '../../data/models/profile.dart';
import '../../data/models/workout_session.dart';
import '../../data/repositories/nutrition_repo.dart';
import '../../services/ai/ai_service.dart';
import '../../services/progress/streak_calc.dart';
import '../../services/workout/pr_tracker.dart';
import '../../state/providers.dart';
import '../../theme.dart';

class CoachPage extends ConsumerStatefulWidget {
  const CoachPage({super.key});

  @override
  ConsumerState<CoachPage> createState() => _CoachPageState();
}

class _CoachPageState extends ConsumerState<CoachPage> {
  final _ctl = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final List<CoachMessage> _messages = [];
  bool _sending = false;
  bool _reviewing = false;
  String? _weeklyReview;

  @override
  void dispose() {
    _ctl.dispose();
    _focus.dispose();
    _scroll.dispose();
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

  String _profileSummary(
    Profile profile,
    DailyTotals totals,
    int streak,
    int prCount,
    int sessionsThisWeek,
  ) {
    final goal = profile.goal.name;
    final focus = profile.bodyFocusNotes.trim();
    return [
      'Name: ${profile.displayName.isEmpty ? "user" : profile.displayName}',
      'Goal: $goal',
      if (profile.country.isNotEmpty) 'Country: ${profile.country}',
      'Diet: ${profile.dietPreference.name}',
      'Calorie target: ${profile.effectiveCalorieTarget} kcal',
      'Protein target: ${profile.effectiveProteinTarget}g',
      'Weight: ${profile.weightKg.toStringAsFixed(1)} kg',
      'Strength training: ${profile.trainingDaysPerWeek} days/week',
      'Cardio: ${profile.cardioSessionsPerWeek} sessions/week',
      if (focus.isNotEmpty) 'Body focus: $focus',
      if (profile.restDays.isNotEmpty)
        'Rest days: ${profile.restDays.join(",")}',
      if (profile.gymStartDate != null)
        'Gym experience: ${DateTime.now().difference(profile.gymStartDate!).inDays ~/ 30} months',
      if (profile.bodyFatPct != null)
        'Body fat: ${profile.bodyFatPct!.toStringAsFixed(0)}%',
      if (profile.healthFlags.isNotEmpty)
        'Health flags: ${profile.healthFlags.map((f) => f.name).join(", ")}',
      if (profile.gender == Gender.female &&
          profile.cyclePhase != CyclePhase.unknown)
        'Cycle phase: ${profile.cyclePhase.name}',
      'Today so far: ${totals.calories} kcal, ${totals.proteinG}g protein',
      'Current streak: $streak days',
      'PRs achieved: $prCount',
      'Workouts this week: $sessionsThisWeek',
    ].join('\n');
  }

  Future<void> _send(Profile profile, DailyTotals totals, int streak,
      int prCount, int sessionsWeek) async {
    final text = _ctl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _messages.add(CoachMessage(
          fromUser: true, text: text, timestamp: DateTime.now()));
      _ctl.clear();
      _sending = true;
    });
    _scrollToBottom();
    try {
      final reply = await ref.read(aiServiceProvider).coachChat(
            userContext: _profileSummary(
                profile, totals, streak, prCount, sessionsWeek),
            history: List.of(_messages..removeLast()),
            latestUserMessage: text,
          );
      if (!mounted) return;
      setState(() {
        _messages.add(CoachMessage(
            fromUser: true, text: text, timestamp: DateTime.now()));
        _messages.add(CoachMessage(
            fromUser: false, text: reply, timestamp: DateTime.now()));
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(CoachMessage(
            fromUser: true, text: text, timestamp: DateTime.now()));
      });
      _toast(e is AiException ? e.message : 'Coach request failed.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  static const _cacheKey = 'coachPage.weeklyReviewText';
  static const _cacheTsKey = 'coachPage.weeklyReviewAt';

  Future<bool> _serveFromCacheIfFresh() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_cacheTsKey);
    final cached = prefs.getString(_cacheKey);
    if (ts == null || cached == null || cached.isEmpty) return false;
    final age = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(ts));
    if (age.inHours >= 24) return false;
    if (!mounted) return false;
    setState(() => _weeklyReview = cached);
    return true;
  }

  Future<void> _runWeeklyReview(
    Profile profile,
    List<FoodEntry> foods,
    List<WorkoutSession> sessions, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && await _serveFromCacheIfFresh()) return;
    setState(() => _reviewing = true);
    try {
      final now = DateTime.now();
      final since = now.subtract(const Duration(days: 7));
      final weekFoods =
          foods.where((f) => f.timestamp.isAfter(since)).toList();
      final weekSessions =
          sessions.where((s) => s.startedAt.isAfter(since)).toList();
      final byDay = <String, List<FoodEntry>>{};
      for (final f in weekFoods) {
        byDay.putIfAbsent(f.dateKey, () => []).add(f);
      }
      final daysLogged = byDay.length;
      final avgKcal = byDay.isEmpty
          ? 0
          : (byDay.values
                      .map((day) => day.fold<int>(
                          0, (s, e) => s + e.calories))
                      .reduce((a, b) => a + b) /
                  byDay.length)
              .round();
      final prs = PrTracker.personalRecords(sessions);
      final summary = [
        'Goal: ${profile.goal.name}',
        if (profile.country.isNotEmpty) 'Country: ${profile.country}',
        'Diet: ${profile.dietPreference.name}',
        if (profile.bodyFocusNotes.isNotEmpty)
          'Body focus: ${profile.bodyFocusNotes}',
        'Calorie target: ${profile.effectiveCalorieTarget} kcal',
        'Protein target: ${profile.effectiveProteinTarget}g',
        'Days with food logs this week: $daysLogged',
        'Avg calories on logged days: $avgKcal',
        'Workouts completed this week: ${weekSessions.where((s) => s.completedAt != null).length}',
        'Total PRs ever: ${prs.length}',
      ].join('\n');
      final review = await ref
          .read(aiServiceProvider)
          .weeklyReview(contextSummary: summary);
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, review);
      await prefs.setInt(
          _cacheTsKey, DateTime.now().millisecondsSinceEpoch);
      if (!mounted) return;
      setState(() => _weeklyReview = review);
    } catch (e) {
      if (!mounted) return;
      _toast(e is AiException ? e.message : 'Could not load review.');
    } finally {
      if (mounted) setState(() => _reviewing = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileStreamProvider);
    final totals = ref.watch(todayTotalsProvider);
    final foods = ref.watch(allFoodEntriesProvider).valueOrNull ?? const [];
    final sessions =
        ref.watch(allSessionsProvider).valueOrNull ?? const <WorkoutSession>[];
    final streak = StreakCalc.currentStreak(
      foodEntries: foods,
      sessions: sessions,
      today: DateTime.now(),
    );
    final prCount = PrTracker.personalRecords(sessions).length;
    final weekSessions = sessions
        .where((s) => s.startedAt.isAfter(
            DateTime.now().subtract(const Duration(days: 7))))
        .length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text('Coach', style: AppText.sectionTitle),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: profileAsync.when(
        loading: () => Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2.2, color: AppColors.accent),
          ),
        ),
        error: (_, _) => const SizedBox.shrink(),
        data: (profile) {
          if (profile == null) return const SizedBox.shrink();
          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    children: [
                      _WeeklyReviewCard(
                        review: _weeklyReview,
                        busy: _reviewing,
                        onRun: () =>
                            _runWeeklyReview(profile, foods, sessions),
                      ),
                      const SizedBox(height: 20),
                      if (_messages.isEmpty) _Suggestions(onTap: (s) {
                        _ctl.text = s;
                        _focus.requestFocus();
                      }),
                      for (final m in _messages) ...[
                        const SizedBox(height: 10),
                        _Bubble(message: m),
                      ],
                      if (_sending) ...[
                        const SizedBox(height: 10),
                        _TypingIndicator(),
                      ],
                    ],
                  ),
                ),
                _Composer(
                  controller: _ctl,
                  focusNode: _focus,
                  busy: _sending,
                  onSend: () => _send(profile, totals, streak, prCount,
                      weekSessions),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WeeklyReviewCard extends StatelessWidget {
  final String? review;
  final bool busy;
  final VoidCallback onRun;
  const _WeeklyReviewCard({
    required this.review,
    required this.busy,
    required this.onRun,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_view_week_rounded,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('WEEKLY REVIEW', style: AppText.label),
            ],
          ),
          const SizedBox(height: 10),
          if (review == null && !busy)
            Text(
              'Get a short, no-pressure read on your week.',
              style: AppText.body.copyWith(fontSize: 13),
            )
          else if (busy)
            Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.accent),
                ),
                const SizedBox(width: 10),
                Text('Reading your week…', style: AppText.body),
              ],
            )
          else
            Text(review!,
                style: AppText.body.copyWith(
                    color: AppColors.textPrimary, fontSize: 13)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: busy ? null : onRun,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    review == null
                        ? Icons.auto_awesome_rounded
                        : Icons.refresh_rounded,
                    size: 13,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    review == null ? 'Get review' : 'Refresh',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  final void Function(String) onTap;
  const _Suggestions({required this.onTap});

  static const _items = [
    'How can I hit my protein target?',
    'My weight isn\'t moving — what should I tweak?',
    'Swap an exercise on my leg day',
    'Why am I always sore after squats?',
    'What\'s a quick post-workout meal?',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ask anything', style: AppText.sectionTitle.copyWith(fontSize: 16)),
        const SizedBox(height: 6),
        Text(
          'Beginner-aware, supportive, no judgment.',
          style: AppText.body.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 16),
        for (final s in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => onTap(s),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 14, color: AppColors.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s,
                          style: AppText.body.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 13)),
                    ),
                    Icon(Icons.north_east_rounded,
                        size: 14, color: AppColors.textTertiary),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final CoachMessage message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final fromUser = message.fromUser;
    return Row(
      mainAxisAlignment:
          fromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!fromUser) ...[
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.auto_awesome_rounded,
                size: 14, color: AppColors.accent),
          ),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              color: fromUser ? AppColors.accent : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(fromUser ? 16 : 4),
                bottomRight: Radius.circular(fromUser ? 4 : 16),
              ),
              border: fromUser
                  ? null
                  : Border.all(color: AppColors.stroke),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: fromUser ? Colors.black : AppColors.textPrimary,
                fontSize: 14,
                height: 1.35,
                fontWeight:
                    fromUser ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.auto_awesome_rounded,
              size: 14, color: AppColors.accent),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.stroke),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.accent),
              ),
              const SizedBox(width: 8),
              Text('Thinking…',
                  style: AppText.body.copyWith(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool busy;
  final VoidCallback onSend;
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.busy,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.stroke)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.stroke),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 4,
                enabled: !busy,
                textInputAction: TextInputAction.newline,
                cursorColor: AppColors.accent,
                onSubmitted: (_) => onSend(),
                style: AppText.body.copyWith(
                    color: AppColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  hintText: 'Ask your coach…',
                  hintStyle: AppText.body.copyWith(
                      color: AppColors.textTertiary, fontSize: 15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: busy ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: busy
                    ? AppColors.accent.withValues(alpha: 0.5)
                    : AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_upward_rounded,
                  color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
