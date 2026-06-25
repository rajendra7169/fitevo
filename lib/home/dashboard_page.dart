import 'dart:io';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../core/health_math.dart';
import '../core/workout_math.dart';
import '../data/models/food_entry.dart';
import '../data/models/profile.dart';
import '../data/models/workout_session.dart';
import '../data/repositories/nutrition_repo.dart';
import '../features/account/account_page.dart';
import '../features/food/meal_actions_sheet.dart';
import '../features/food/nutrient_detail_page.dart';
import '../features/food/water_detail_page.dart';
import '../features/food/todays_food_page.dart';
import '../features/workout/workout_logger_page.dart';
import '../features/workout/workout_page.dart';
import '../services/ai/ai_service.dart';
import '../services/hero_greeting.dart';
import 'adaptive_nudge_card.dart';
import 'coach_context_nudge.dart';
import 'quick_weigh_in_card.dart';
import 'todays_activity_card.dart';
import 'weekly_recap_card.dart';
import '../services/progress/streak_calc.dart';
import '../state/providers.dart';
import '../theme.dart';

class DashboardPage extends ConsumerWidget {
  /// Bumped by HomeShell every time the user re-enters the Home tab.
  /// Threaded into the calorie ring's ValueKey so the fill animation
  /// restarts on tab return (the ring widget remounts; the rest of
  /// the dashboard stays as-is so other state isn't lost).
  final int homeReentryGen;
  const DashboardPage({super.key, this.homeReentryGen = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileStreamProvider).valueOrNull;
    final totals = ref.watch(todayTotalsProvider);
    final entries = ref.watch(todayEntriesProvider).valueOrNull ?? const [];
    final todayLog = ref.watch(todayLogProvider).valueOrNull;

    if (profile == null) {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
              strokeWidth: 2.2, color: AppColors.accent),
        ),
      );
    }

    Widget section(int i, Widget child) {
      return child.animate(delay: Duration(milliseconds: 50 * i)).fadeIn(
            duration: 320.ms,
            curve: Curves.easeOutCubic,
          ).slideY(begin: 0.06, end: 0, duration: 320.ms, curve: Curves.easeOutCubic);
    }

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            section(0, _Header(profile: profile, totals: totals)),
            const SizedBox(height: 22),
            section(1, const _AiInputBar()),
            const SizedBox(height: 28),
            section(
                2,
                _CalorieRing(
                  // ValueKey changes on Home re-entry so Flutter remounts
                  // the ring and its TweenAnimationBuilders animate fresh
                  // from 0 to current value, instead of just sitting.
                  key: ValueKey('ring-$homeReentryGen'),
                  consumed: totals.calories,
                  target: TodaysActivityMath.effectiveTodayCalorieTarget(
                    profile: profile,
                    log: todayLog,
                  ),
                )),
            const SizedBox(height: 28),
            section(3, _MacrosRow(profile: profile, totals: totals)),
            const SizedBox(height: 16),
            section(4, _WaterFiberChips(profile: profile, totals: totals)),
            const SizedBox(height: 22),
            section(5, TodaysActivityCard(profile: profile)),
            const SizedBox(height: 10),
            section(6, const QuickWeighInCard()),
            const SizedBox(height: 10),
            section(7, const CoachContextNudge()),
            const SizedBox(height: 22),
            section(8, const AdaptiveNudgeCard()),
            const SizedBox(height: 22),
            section(9, const _WorkoutCard()),
            const SizedBox(height: 22),
            section(10, const WeeklyRecapCard()),
            const SizedBox(height: 22),
            section(11, _RecentMealsShelf(entries: entries)),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final Profile profile;
  final DailyTotals totals;
  const _Header({required this.profile, required this.totals});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final user = FirebaseAuth.instance.currentUser;
    final name = _resolveName(profile, user);

    final foods = ref.watch(allFoodEntriesProvider).valueOrNull ?? const [];
    final sessions =
        ref.watch(allSessionsProvider).valueOrNull ?? const <WorkoutSession>[];
    final streak = StreakCalc.currentStreak(
      foodEntries: foods.whereType<FoodEntry>().toList(),
      sessions: sessions,
      today: now,
    );
    final todayKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final workoutDone = sessions.any(
      (s) => s.dateKey == todayKey && s.completedAt != null,
    );

    final hero = HeroGreeting.build(
      now: now,
      caloriesConsumed: totals.calories,
      calorieTarget: profile.effectiveCalorieTarget,
      streakDays: streak,
      workoutCompletedToday: workoutDone,
    );

    final phraseStyle = AppText.greeting.copyWith(
      fontSize: 24,
      letterSpacing: -0.4,
      color: hero.emphasiseStreak ? AppColors.streak : AppColors.textPrimary,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hero.phrase,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: phraseStyle,
              ),
              const SizedBox(height: 4),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.meta.copyWith(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _UserAvatar(name: name, photoUrl: user?.photoURL),
      ],
    );
  }

  static String _resolveName(Profile profile, User? user) {
    if (profile.displayName.trim().isNotEmpty) return profile.displayName.trim();
    final dn = user?.displayName?.trim();
    if (dn != null && dn.isNotEmpty) return dn;
    final email = user?.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'there';
  }
}

class _UserAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  const _UserAvatar({required this.name, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '·';
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AccountPage()),
        );
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.stroke, width: 1),
          image: photoUrl != null && photoUrl!.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(photoUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        alignment: Alignment.center,
        child: photoUrl == null || photoUrl!.isEmpty
            ? Text(
                initial,
                style: AppText.sectionTitle.copyWith(fontSize: 16),
              )
            : null,
      ),
    );
  }
}

class _AiInputBar extends ConsumerStatefulWidget {
  const _AiInputBar();

  @override
  ConsumerState<_AiInputBar> createState() => _AiInputBarState();
}

class _AiInputBarState extends ConsumerState<_AiInputBar> {
  final _ctl = TextEditingController();
  final _focus = FocusNode();
  bool _submitting = false;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _ctl.addListener(_onChange);
    _focus.addListener(_onChange);
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _speech.cancel();
    _ctl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    _focus.unfocus();

    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          if (mounted && _isListening) {
            setState(() => _isListening = false);
          }
        }
      },
      onError: (error) {
        if (mounted) setState(() => _isListening = false);
        _toast('Speech error: ${error.errorMsg}');
      },
    );

    if (available) {
      if (mounted) setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          if (mounted) {
            _ctl.text = result.recognizedWords;
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
        ),
      );
    } else {
      _toast('Speech recognition not available or permission denied.');
    }
  }

  Future<void> _submit() async {
    final text = _ctl.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      final logger = ref.read(foodLoggerProvider);
      final result = await logger.logFromText(text);
      if (!mounted) return;
      _ctl.clear();
      _focus.unfocus();
      final msg = result.hasLowConfidence
          ? 'Logged · estimates may vary'
          : 'Logged · ${result.totalCalories} kcal';
      _toast(msg);
    } catch (e) {
      if (!mounted) return;
      final msg = e is AiException ? e.message : 'Something went wrong.';
      _toast(msg);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _onCameraTap() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
              const SizedBox(height: 16),
              Text('Log from a photo', style: AppText.sectionTitle),
              const SizedBox(height: 4),
              Text('AI estimates nutrition from the food in your photo.',
                  style: AppText.body),
              const SizedBox(height: 18),
              _SheetTile(
                icon: Icons.photo_camera_rounded,
                label: 'Take a photo',
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              const SizedBox(height: 10),
              _SheetTile(
                icon: Icons.photo_library_rounded,
                label: 'Choose from gallery',
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;
    await _pickAndLogPhoto(source);
  }

  Future<void> _pickAndLogPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (file == null) return;
      if (!mounted) return;
      setState(() => _submitting = true);
      final bytes = await File(file.path).readAsBytes();
      final hint = _ctl.text.trim();
      final logger = ref.read(foodLoggerProvider);
      final result = await logger.logFromPhoto(
        bytes,
        hint: hint.isEmpty ? null : hint,
        photoPath: file.path,
      );
      if (!mounted) return;
      _ctl.clear();
      _focus.unfocus();
      _toast(result.hasLowConfidence
          ? 'Logged · estimates may vary'
          : 'Logged · ${result.totalCalories} kcal');
    } catch (e) {
      if (!mounted) return;
      _toast(e is AiException ? e.message : 'Could not log from photo.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        backgroundColor: AppColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Text(
          message,
          style: AppText.body.copyWith(color: AppColors.textPrimary),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _ctl.text.trim().isNotEmpty;
    final showSubmit = hasText || _focus.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isAiConfigured) ...[
          const _ApiKeyHint(),
          const SizedBox(height: 10),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _focus.hasFocus
                  ? AppColors.accent
                  : AppColors.stroke,
              width: _focus.hasFocus ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(18, 4, 8, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                child: Icon(Icons.auto_awesome_rounded,
                    size: 18, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _ctl,
                  focusNode: _focus,
                  minLines: 1,
                  maxLines: 3,
                  enabled: !_submitting,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                  cursorColor: AppColors.accent,
                  style: AppText.body.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                    hintText: 'What did you eat?',
                    hintStyle: AppText.body.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              if (_submitting)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.accent,
                    ),
                  ),
                )
              else if (_isListening)
                GestureDetector(
                  onTap: _toggleListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.calorieFrom.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.mic_rounded, size: 17, color: AppColors.calorieFrom),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.15, duration: 600.ms),
                )
              else if (showSubmit) ...[
                _RoundIconButton(
                  icon: Icons.close_rounded,
                  onTap: () {
                    _ctl.clear();
                    _focus.unfocus();
                  },
                ),
                const SizedBox(width: 6),
                _SubmitButton(enabled: hasText, onTap: _submit),
              ]
              else ...[
                _RoundIconButton(icon: Icons.mic_rounded, onTap: _toggleListening),
                const SizedBox(width: 6),
                _RoundIconButton(
                    icon: Icons.camera_alt_rounded, onTap: _onCameraTap),
                const SizedBox(width: 4),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _SubmitButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: enabled ? AppColors.accent : AppColors.surfaceHigh,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_upward_rounded,
          size: 18,
          color: enabled ? AppColors.onAccent : AppColors.textTertiary,
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SheetTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: AppText.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700)),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _ApiKeyHint extends StatelessWidget {
  const _ApiKeyHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Add your free Groq (or Gemini) API key to enable AI logging.',
              style: AppText.meta.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 17, color: AppColors.textPrimary),
      ),
    );
  }
}

class _CalorieRing extends StatelessWidget {
  final int consumed;
  final int target;
  const _CalorieRing({
    super.key,
    required this.consumed,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = math.max(0, target - consumed);
    final progress = target == 0 ? 0.0 : (consumed / target);

    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TodaysFoodPage()),
          );
        },
        child: SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
            // Soft glow behind the ring
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.10),
                    AppColors.accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => CustomPaint(
                size: const Size(230, 230),
                painter: _RingPainter(progress: v),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('CALORIES LEFT', style: AppText.label),
                const SizedBox(height: 12),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: remaining.toDouble()),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => ShaderMask(
                    shaderCallback: (rect) => LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.textPrimary,
                        AppColors.textPrimary.withValues(alpha: 0.85),
                      ],
                    ).createShader(rect),
                    child: Text('${v.round()}',
                        style: AppText.giantNumber.copyWith(fontSize: 68)),
                  ),
                ),
                const SizedBox(height: 10),
                Text('of $target target',
                    style: AppText.meta.copyWith(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('TAP FOR DETAILS',
                        style: AppText.label.copyWith(
                            fontSize: 9,
                            color: AppColors.textTertiary,
                            letterSpacing: 1.2)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded,
                        size: 11, color: AppColors.textTertiary),
                  ],
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 14.0;
    final rect = Offset(strokeWidth / 2, strokeWidth / 2) &
        Size(size.width - strokeWidth, size.height - strokeWidth);

    final bg = Paint()
      ..color = AppColors.surfaceHigh
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, bg);

    // Journey gradient: arc starts green (where you began the day) and
    // transitions through gold / saffron / red based on how far through
    // the day's consumption you've gotten. Each zone boundary is mapped
    // to its actual position on the visible arc, so a 60% ring shows
    // green near the 12 o'clock start and ends in gold-toward-saffron.
    final p = progress.clamp(0.0001, 2.0);
    final sweep = 2 * math.pi * p.clamp(0.0, 1.0);

    final colors = <Color>[AppColors.success];
    final stops = <double>[0.0];
    void addStop(double threshold, Color color) {
      if (p > threshold) {
        colors.add(color);
        stops.add(threshold / p);
      }
    }
    addStop(0.30, AppColors.success);
    addStop(0.60, AppColors.warning);
    addStop(0.85, AppColors.calorieFrom);
    addStop(1.0, AppColors.danger);
    // Final stop at 1.0 = the current zone color (computed by the
    // same _statusColor function so the end of the arc precisely matches
    // the user's current "where am I" status).
    colors.add(_statusColor(p));
    stops.add(1.0);

    final fg = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweep,
        colors: colors,
        stops: stops,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, sweep, false, fg);
  }

  /// Status color, tightened so the user sees the transition by the
  /// halfway mark instead of staying green until ~65%.
  ///   0 – 0.30   → solid leaf-green (lots of room)
  ///   0.30 – 0.60 → green lerping to gold (mid-day pacing)
  ///   0.60 – 0.85 → gold lerping to saffron (getting close)
  ///   0.85 – 1.0  → saffron lerping to berry-red (almost / hit target)
  ///   1.0+         → solid danger-red (over target)
  static Color _statusColor(double progress) {
    if (progress <= 0.30) return AppColors.success;
    if (progress <= 0.60) {
      return Color.lerp(AppColors.success, AppColors.warning,
          (progress - 0.30) / 0.30)!;
    }
    if (progress <= 0.85) {
      return Color.lerp(AppColors.warning, AppColors.calorieFrom,
          (progress - 0.60) / 0.25)!;
    }
    if (progress <= 1.0) {
      return Color.lerp(AppColors.calorieFrom, AppColors.danger,
          (progress - 0.85) / 0.15)!;
    }
    return AppColors.danger;
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _MacrosRow extends ConsumerWidget {
  final Profile profile;
  final DailyTotals totals;
  const _MacrosRow({required this.profile, required this.totals});

  void _openDetail(BuildContext context, NutrientType type) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NutrientDetailPage(nutrient: type)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(todayLogProvider).valueOrNull;
    final m = TodaysActivityMath.effectiveTodayMacros(
        profile: profile, log: log);
    return Row(
      children: [
        Expanded(
          child: _MacroBar(
            label: 'Protein',
            consumed: totals.proteinG,
            target: m.proteinG,
            color: AppColors.protein,
            onTap: () => _openDetail(context, NutrientType.protein),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MacroBar(
            label: 'Carbs',
            consumed: totals.carbsG,
            target: m.carbG,
            color: AppColors.carbs,
            onTap: () => _openDetail(context, NutrientType.carbs),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MacroBar(
            label: 'Fat',
            consumed: totals.fatG,
            target: m.fatG,
            color: AppColors.fat,
            onTap: () => _openDetail(context, NutrientType.fat),
          ),
        ),
      ],
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final int consumed;
  final int target;
  final Color color;
  final VoidCallback? onTap;

  const _MacroBar({
    required this.label,
    required this.consumed,
    required this.target,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final left = math.max(0, target - consumed);
    final progress =
        target == 0 ? 0.0 : (consumed / target).clamp(0.0, 1.0);
    final done = left == 0 && target > 0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: done ? AppColors.textTertiary : color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(label,
                  style: AppText.meta.copyWith(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('$left',
                    style: AppText.bigNumber.copyWith(
                      fontSize: 22,
                      color: done
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                    )),
                const SizedBox(width: 2),
                Text('g',
                    style: AppText.meta.copyWith(
                        fontSize: 12, color: AppColors.textTertiary)),
                const SizedBox(width: 4),
                Text(done ? 'done' : 'left',
                    style: AppText.meta.copyWith(
                        fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Container(height: 5, color: AppColors.surfaceHigh),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: done ? AppColors.textTertiary : color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _WaterFiberChips extends ConsumerWidget {
  final Profile profile;
  final DailyTotals totals;
  const _WaterFiberChips({required this.profile, required this.totals});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterTargetMl = profile.effectiveWaterTarget;
    final waterProgress =
        waterTargetMl == 0 ? 0.0 : totals.waterMl / waterTargetMl;
    final fiberTarget = profile.effectiveFiberTarget;
    final fiberProgress =
        fiberTarget == 0 ? 0.0 : totals.fiberG / fiberTarget;
    final sodiumLimit = HealthConstants.sodiumDailyLimitMg;
    final sodiumProgress = totals.sodiumMg / sodiumLimit;

    return Row(
      children: [
        Expanded(
          child: _WaterChip(
            consumedMl: totals.waterMl,
            targetMl: waterTargetMl,
            progress: waterProgress.clamp(0.0, 1.0),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatChip(
            icon: Icons.grass_rounded,
            label: 'Fiber',
            value: '${totals.fiberG}',
            of: '${fiberTarget}g',
            progress: fiberProgress.clamp(0.0, 1.0),
            color: AppColors.fiber,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const NutrientDetailPage(nutrient: NutrientType.fiber),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatChip(
            icon: Icons.scatter_plot_rounded,
            label: 'Sodium',
            value: (totals.sodiumMg / 1000).toStringAsFixed(1),
            of: '${(sodiumLimit / 1000).toStringAsFixed(1)}g',
            progress: sodiumProgress.clamp(0.0, 1.0),
            color: AppColors.calorieFrom,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const NutrientDetailPage(nutrient: NutrientType.sodium),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Water chip on the dashboard. Tap = quick-add 250 ml with a brief
/// pulse + a floating "+250 ml" hint. Long-press opens WaterDetailPage
/// with the timeline + smart reminders.
///
/// Visually identical to the Fiber/Sodium chips so the row stays clean.
/// The drama (animated wave, hero ring, etc.) lives on the detail page
/// where it has room to breathe.
class _WaterChip extends ConsumerStatefulWidget {
  final int consumedMl;
  final int targetMl;
  final double progress;
  const _WaterChip({
    required this.consumedMl,
    required this.targetMl,
    required this.progress,
  });

  @override
  ConsumerState<_WaterChip> createState() => _WaterChipState();
}

class _WaterChipState extends ConsumerState<_WaterChip>
    with TickerProviderStateMixin {
  late final AnimationController _tap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();
  // Tween the displayed water level toward widget.progress so the wave
  // rises smoothly when the user taps, rather than snapping to the new
  // value.
  late final AnimationController _levelCtl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  Animation<double>? _levelAnim;
  double _shownProgress = 0;
  final GlobalKey _chipKey = GlobalKey();
  // Set at mount by reading the persisted flag. Gates all celebration
  // triggers in this session so the burst can't fire twice on the same
  // calendar day, even if the async data-load chain detects a "false
  // crossing" (0 → real value > 1.0) right after restart.
  bool _alreadyCelebratedToday = false;

  @override
  void initState() {
    super.initState();
    _shownProgress = widget.progress;
    if (_shownProgress >= 1.0) _wave.stop();
    // Read the persisted "celebrated today" flag once on mount so we
    // can gate the burst without racing the async crossing detection.
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      final last = prefs.getString('waterCelebratedDate');
      if (last == _todayKey()) {
        setState(() => _alreadyCelebratedToday = true);
      }
    });
    _levelCtl.addListener(() {
      final v = _levelAnim?.value;
      if (v != null && v != _shownProgress) {
        setState(() => _shownProgress = v);
        // Pause the drift when the glass is full, resume when it isn't.
        if (v >= 1.0 && _wave.isAnimating) {
          _wave.stop();
        } else if (v < 1.0 && !_wave.isAnimating) {
          _wave.repeat();
        }
      }
    });
  }

  @override
  void didUpdateWidget(_WaterChip old) {
    super.didUpdateWidget(old);
    if (widget.progress != old.progress) {
      _levelAnim = Tween<double>(
        begin: _shownProgress,
        end: widget.progress,
      ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_levelCtl);
      _levelCtl
        ..reset()
        ..forward();
      // Goal-crossing celebration: only fires the moment progress moves
      // from below the target up to or past it AND only once per day.
      // The once-per-day check matters because totals load async — on
      // a fresh app open with the goal already hit, the chip rebuilds
      // from 0 → real value, which looks like a "crossing" to this
      // logic. Without the persisted flag, the user would see the
      // celebration every time they reopen the app.
      if (old.progress < 1.0 &&
          widget.progress >= 1.0 &&
          !_alreadyCelebratedToday) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _maybeCelebrate();
        });
      }
    }
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  /// Gated celebration trigger. Reads the last celebrated dateKey from
  /// SharedPreferences and only fires when it differs from today's
  /// key. This is what keeps the burst from re-firing every time the
  /// user reopens the app on a day they already hit the goal.
  Future<void> _maybeCelebrate() async {
    if (_alreadyCelebratedToday) return;
    const prefsKey = 'waterCelebratedDate';
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(prefsKey);
    final today = _todayKey();
    if (last == today) {
      // Flag was already written this calendar day. Just remember it
      // in memory so we don't re-check from disk later this session.
      if (mounted) setState(() => _alreadyCelebratedToday = true);
      return;
    }
    await prefs.setString(prefsKey, today);
    if (!mounted) return;
    setState(() => _alreadyCelebratedToday = true);
    _showCelebration();
  }

  void _showCelebration() {
    final ctx = _chipKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final origin = box.localToGlobal(box.size.center(Offset.zero));
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _WaterCelebration(
        origin: origin,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  @override
  void dispose() {
    _tap.dispose();
    _wave.dispose();
    _levelCtl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    _tap.forward(from: 0);
    await ref
        .read(nutritionRepoProvider)
        .addWater(ref.read(todayProvider), 250);
  }

  void _openDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WaterDetailPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _add,
      onLongPress: _openDetail,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_tap, _wave]),
        builder: (ctx, _) {
          final t = _tap.value;
          // Scale UP on tap (1.0 → 1.07 → 1.0) so the chip pops outward
          // and feels responsive. Curves.easeOutBack adds a tiny
          // overshoot at the peak for that satisfying snap.
          final pop = math.sin(t * math.pi).clamp(0.0, 1.0);
          final pulse = 1.0 + 0.07 * pop;
          return Transform.scale(
            scale: pulse,
            // Outer Stack lets the floating "+250 ml" hint escape the
            // chip's clipped bounds. Inner Container clips the wave
            // cleanly to the rounded radius.
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  key: _chipKey,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: _shownProgress >= 1.0
                            ? AppColors.water.withValues(alpha: 0.5)
                            : AppColors.stroke,
                        width: 1),
                  ),
                  // antiAlias clips the wave to the rounded shape so the
                  // bottom-left + bottom-right corners are filled cleanly.
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // Wave layer — clipped by the Container's rounded
                      // shape. Uses _shownProgress (tweened) so the water
                      // RISES smoothly to the new level after a tap.
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _WaterWavePainter(
                            progress: _shownProgress,
                            wavePhase: _wave.value * 2 * math.pi,
                            color: AppColors.water,
                            // Briefly amplify the wave during the tap
                            // pulse so the water visibly "sloshes" as
                            // the new sip is added. Returns to baseline.
                            amplitudeBoost: pop,
                          ),
                        ),
                      ),
                      // Content layer
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: AppColors.water
                                        .withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.water_drop_rounded,
                                      size: 14, color: AppColors.water),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Water',
                                    style: AppText.meta.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textTertiary,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                                Icon(Icons.add_rounded,
                                    size: 14, color: AppColors.water),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: (widget.consumedMl / 1000)
                                          .toStringAsFixed(1),
                                      style: AppText.bigNumber
                                          .copyWith(fontSize: 18),
                                    ),
                                    TextSpan(
                                      text:
                                          ' /${(widget.targetMl / 1000).toStringAsFixed(1)}L',
                                      style: AppText.meta.copyWith(
                                          fontSize: 11,
                                          color: AppColors.textTertiary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Floating "+250 ml" hint — rises above the chip on tap.
                if (t > 0 && t < 1)
                  Positioned(
                    right: 8,
                    top: -10 - (16 * t),
                    child: Opacity(
                      opacity: (1 - t).clamp(0.0, 1.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.water,
                          borderRadius: BorderRadius.circular(7),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.water.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '+250 ml',
                          style: TextStyle(
                            color: AppColors.onAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Animated water-level inside the chip. The water surface is a low-
/// amplitude sine wave that drifts continuously; height = progress.
/// The path extends slightly beyond the chip bounds horizontally so the
/// rounded corners are filled completely after the parent's clipping.
class _WaterWavePainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final Color color;
  // 0..1 — briefly amplifies the wave amplitude during a tap so the
  // water visibly sloshes when a new sip is added.
  final double amplitudeBoost;

  _WaterWavePainter({
    required this.progress,
    required this.wavePhase,
    required this.color,
    this.amplitudeBoost = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final clamped = progress.clamp(0.0, 1.5);

    // At-or-above target: render a clean solid fill — no sine wave,
    // no crest line. The glass is full; the water is still. Keep the
    // alphas matched to the wave's so text/icons stay readable.
    if (clamped >= 1.0) {
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.06),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(
          Rect.fromLTWH(-4, -4, size.width + 8, size.height + 8), fillPaint);
      return;
    }

    final progressClamped = clamped.clamp(0.0, 1.0);
    // Base 3px + up to +3px during a tap pulse for a "splash" feel.
    final amplitude = 3.0 + 3.0 * amplitudeBoost.clamp(0.0, 1.0);
    // Pull the water surface down by the wave amplitude so the highest
    // wave crest never exceeds the intended fill line. Also overdraw a
    // few px past the bottom + sides so the rounded corner clip fills
    // cleanly with no rendering seam.
    final waterLevel = size.height * (1 - progressClamped) + amplitude;

    final path = Path()..moveTo(-4, size.height + 4);
    path.lineTo(-4, waterLevel);
    for (var x = -4.0; x <= size.width + 4; x += 4) {
      final y = waterLevel +
          amplitude *
              math.sin((x / size.width) * 2 * math.pi + wavePhase);
      path.lineTo(x, y);
    }
    path.lineTo(size.width + 4, size.height + 4);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.18),
          color.withValues(alpha: 0.06),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);

    // Whisper-soft surface highlight so the wave crest reads as a line
    // without screaming. Earlier 0.40 was too loud per feedback.
    final crest = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = color.withValues(alpha: 0.18);
    final crestPath = Path()..moveTo(-4, waterLevel);
    for (var x = -4.0; x <= size.width + 4; x += 4) {
      final y = waterLevel +
          amplitude *
              math.sin((x / size.width) * 2 * math.pi + wavePhase);
      crestPath.lineTo(x, y);
    }
    canvas.drawPath(crestPath, crest);
  }

  @override
  bool shouldRepaint(_WaterWavePainter old) =>
      old.progress != progress ||
      old.wavePhase != wavePhase ||
      old.amplitudeBoost != amplitudeBoost ||
      old.color != color;
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String of;
  final double progress;
  final Color color;
  final VoidCallback? onTap;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.of,
    required this.progress,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.stroke, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: AppText.meta.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textTertiary,
                        letterSpacing: 0.6),
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: color,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                        text: value,
                        style: AppText.bigNumber.copyWith(fontSize: 18)),
                    TextSpan(
                        text: ' /$of',
                        style: AppText.meta.copyWith(
                            fontSize: 11,
                            color: AppColors.textTertiary)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutCard extends ConsumerWidget {
  const _WorkoutCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routineAsync = ref.watch(activeRoutineProvider);
    final dayAsync = ref.watch(todaysRoutineDayProvider);
    final sessions =
        ref.watch(allSessionsProvider).valueOrNull ?? const <WorkoutSession>[];

    final routine = routineAsync.valueOrNull;
    final day = dayAsync.valueOrNull;

    final plateaus = WorkoutMath.plateaus(sessions, staleWeeks: 3);
    final plateauHint = plateaus.isEmpty ? null : plateaus.first;

    Widget shell;
    if (routine == null) {
      shell = _WorkoutCardShell(
        icon: Icons.fitness_center_rounded,
        accent: AppColors.accent,
        label: 'WORKOUT',
        title: 'Set up your routine',
        subtitle: 'Tap to generate a starter split.',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const WorkoutPage()),
          );
        },
      );
    } else if (day == null || day.isRest) {
      shell = _WorkoutCardShell(
        icon: Icons.self_improvement_rounded,
        accent: AppColors.water,
        label: 'TODAY',
        title: 'Rest day',
        subtitle: 'Recovery matters as much as training.',
      );
    } else {
      shell = _WorkoutCardShell(
        icon: Icons.fitness_center_rounded,
        accent: AppColors.accent,
        label: 'TODAY',
        title: day.name,
        subtitle: '${day.items.length} exercises · ${routine.name}',
        action: 'Start',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WorkoutLoggerPage(
                routineName: routine.name,
                day: day,
              ),
            ),
          );
        },
      );
    }

    if (plateauHint == null) return shell;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        shell,
        const SizedBox(height: 8),
        _PlateauStrip(p: plateauHint),
      ],
    );
  }
}

class _PlateauStrip extends StatelessWidget {
  final PlateauSignal p;
  const _PlateauStrip({required this.p});

  String _suggestedJump() {
    // Add ~2.5kg for lifts above 40kg, ~1.25kg for accessories.
    final bump = p.topWeightKg >= 40 ? 2.5 : 1.25;
    return (p.topWeightKg + bump).toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 16, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${p.exerciseName} stuck ${p.weeksStale} weeks at ${p.topWeightKg.toStringAsFixed(1)}kg × ${p.topReps}. Try ${_suggestedJump()}kg today.',
              style: AppText.body.copyWith(fontSize: 12.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutCardShell extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String label;
  final String title;
  final String subtitle;
  final String? action;
  final VoidCallback? onTap;
  const _WorkoutCardShell({
    required this.icon,
    required this.accent,
    required this.label,
    required this.title,
    required this.subtitle,
    this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.stroke, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.label),
                  const SizedBox(height: 6),
                  Text(title, style: AppText.sectionTitle),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.meta.copyWith(fontSize: 12)),
                ],
              ),
            ),
            if (action != null && onTap != null) ...[
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  action!,
                  style: TextStyle(
                    color: AppColors.onAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentMealsShelf extends StatelessWidget {
  final List<FoodEntry> entries;
  const _RecentMealsShelf({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent meals', style: AppText.sectionTitle),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Column(
              children: [
                Text('No meals logged today',
                    style: AppText.body
                        .copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(
                    'Tap the AI bar above and tell us what you ate.',
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(fontSize: 12)),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Today\'s meals', style: AppText.sectionTitle),
            Text('${entries.length} logged',
                style: AppText.meta.copyWith(
                  fontSize: 12,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (_, i) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _MealCard(entry: entries[i]),
          ),
        ),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  final FoodEntry entry;
  const _MealCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('h:mm a').format(entry.timestamp);
    return GestureDetector(
      onTap: () => MealActionsSheet.show(context, entry),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.stroke, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(time,
                      style: AppText.meta.copyWith(
                          fontSize: 10, color: AppColors.textTertiary)),
                ),
                const Spacer(),
                if (entry.isFavorite)
                  Icon(Icons.star_rounded,
                      size: 14, color: AppColors.streak),
              ],
            ),
            Text(
              entry.description.isEmpty ? entry.rawInput : entry.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.meta.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            Text('${entry.calories} kcal',
                style: AppText.meta
                    .copyWith(fontSize: 12, color: AppColors.accent)),
          ],
        ),
      ),
    );
  }
}

// ─── water-goal celebration overlay ────────────────────────────────────────

/// Fires once when the user crosses the daily water target. Renders a
/// full-screen, ignore-pointer overlay: a soft water-tint flash, a
/// burst of water-drop particles emanating from [origin], a hero text
/// (💧 + "Hydration goal!"), and an auto-dismiss after ~2.4s.
class _WaterCelebration extends StatefulWidget {
  final Offset origin;
  final VoidCallback onDone;
  const _WaterCelebration({required this.origin, required this.onDone});

  @override
  State<_WaterCelebration> createState() => _WaterCelebrationState();
}

class _WaterCelebrationState extends State<_WaterCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late final List<_WaterParticle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    _particles = List.generate(44, (_) {
      final angle = rng.nextDouble() * 2 * math.pi;
      // Bias velocity upward so droplets shoot up + outward then fall.
      final speed = 140 + rng.nextDouble() * 220;
      return _WaterParticle(
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - 100,
        size: 4 + rng.nextDouble() * 7,
        spin: (rng.nextDouble() - 0.5) * 12,
        alphaBase: 0.7 + rng.nextDouble() * 0.3,
      );
    });
    _ctl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
    _ctl.forward();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctl,
        builder: (ctx, _) {
          final t = _ctl.value;
          // Backdrop flash: rise to 0.10 alpha then fade out.
          final backdrop =
              0.10 * math.sin(t * math.pi).clamp(0.0, 1.0);
          // Hero text: pop in over the first 600ms, hold, then fade.
          final textIn = (t / 0.25).clamp(0.0, 1.0);
          final textScale = Curves.elasticOut.transform(textIn);
          final textOut = ((t - 0.75) / 0.25).clamp(0.0, 1.0);
          final textOpacity = (1 - textOut).clamp(0.0, 1.0);
          return Stack(
            children: [
              // Soft water-tint full-screen flash
              Positioned.fill(
                child: ColoredBox(
                  color: AppColors.water.withValues(alpha: backdrop),
                ),
              ),
              // Particle burst from the chip's origin
              Positioned.fill(
                child: CustomPaint(
                  painter: _WaterParticlePainter(
                    particles: _particles,
                    origin: widget.origin,
                    t: t,
                    color: AppColors.water,
                  ),
                ),
              ),
              // Hero card near the center of the screen.
              // Material wrapper + explicit `decoration: TextDecoration.none`
              // because the OverlayEntry sits outside Material, otherwise
              // Flutter shows the debug-yellow text underlines.
              Center(
                child: Material(
                  type: MaterialType.transparency,
                  child: Opacity(
                    opacity: textOpacity,
                    child: Transform.scale(
                      scale: textScale,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.water.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.water.withValues(alpha: 0.25),
                              blurRadius: 28,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Cluster of water drops. Main one in the
                            // center, three smaller satellites at varied
                            // heights for a playful "splash" feel.
                            SizedBox(
                              width: 110,
                              height: 58,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned(
                                    left: 10,
                                    top: 22,
                                    child: Icon(Icons.water_drop_rounded,
                                        size: 14,
                                        color: AppColors.water
                                            .withValues(alpha: 0.55)),
                                  ),
                                  Positioned(
                                    right: 8,
                                    top: 10,
                                    child: Icon(Icons.water_drop_rounded,
                                        size: 18,
                                        color: AppColors.water
                                            .withValues(alpha: 0.70)),
                                  ),
                                  Positioned(
                                    right: 22,
                                    bottom: 6,
                                    child: Icon(Icons.water_drop_rounded,
                                        size: 11,
                                        color: AppColors.water
                                            .withValues(alpha: 0.50)),
                                  ),
                                  Icon(Icons.water_drop_rounded,
                                      size: 44,
                                      color: AppColors.water),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Hydration goal!',
                              style: AppText.giantNumber.copyWith(
                                fontSize: 26,
                                color: AppColors.water,
                                letterSpacing: -0.6,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Great job — keep flowing.',
                              style: AppText.body.copyWith(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WaterParticle {
  final double vx;
  final double vy;
  final double size;
  final double spin;
  final double alphaBase;
  _WaterParticle({
    required this.vx,
    required this.vy,
    required this.size,
    required this.spin,
    required this.alphaBase,
  });
}

class _WaterParticlePainter extends CustomPainter {
  final List<_WaterParticle> particles;
  final Offset origin;
  final double t; // 0..1
  final Color color;
  _WaterParticlePainter({
    required this.particles,
    required this.origin,
    required this.t,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Convert global origin to local. The overlay's RenderObject is at
    // (0,0) global so this is effectively identity, but we use the
    // origin directly for the position math.
    const gravity = 700.0; // px/s^2 — drop pulls particles back down
    final opacity = math.max(0.0, 1 - t);
    for (final p in particles) {
      // Position = origin + v*t + 0.5*g*t^2 (gravity on Y only)
      final x = origin.dx + p.vx * t;
      final y = origin.dy + p.vy * t + 0.5 * gravity * t * t;
      final paint = Paint()
        ..color = color.withValues(alpha: p.alphaBase * opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);
      // Teardrop shape — narrow top, rounded bottom
      final s = p.size * (1 + 0.2 * math.sin(t * math.pi));
      final path = Path()
        ..moveTo(0, -s)
        ..quadraticBezierTo(s * 0.7, -s * 0.3, s * 0.5, s * 0.35)
        ..quadraticBezierTo(0, s, -s * 0.5, s * 0.35)
        ..quadraticBezierTo(-s * 0.7, -s * 0.3, 0, -s)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_WaterParticlePainter old) =>
      old.t != t || old.origin != origin;
}
