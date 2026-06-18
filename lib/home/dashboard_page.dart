import 'dart:io';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../core/health_math.dart';
import '../data/models/food_entry.dart';
import '../data/models/profile.dart';
import '../data/models/workout_session.dart';
import '../data/repositories/nutrition_repo.dart';
import '../features/account/account_page.dart';
import '../features/food/meal_actions_sheet.dart';
import '../features/food/meal_suggestions_sheet.dart';
import '../features/food/nutrient_detail_page.dart';
import '../features/food/todays_food_page.dart';
import '../features/workout/workout_logger_page.dart';
import '../features/workout/workout_page.dart';
import '../services/ai/ai_service.dart';
import '../services/hero_greeting.dart';
import '../services/progress/streak_calc.dart';
import '../state/providers.dart';
import '../theme.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileStreamProvider).valueOrNull;
    final totals = ref.watch(todayTotalsProvider);
    final entries = ref.watch(todayEntriesProvider).valueOrNull ?? const [];

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
                  consumed: totals.calories,
                  target: profile.effectiveCalorieTarget,
                )),
            const SizedBox(height: 28),
            section(3, _MacrosRow(profile: profile, totals: totals)),
            const SizedBox(height: 16),
            section(4, _WaterFiberChips(profile: profile, totals: totals)),
            const SizedBox(height: 22),
            section(5, _WhatsLeftStrip(profile: profile, totals: totals)),
            const SizedBox(height: 22),
            section(6, const _WorkoutCard()),
            const SizedBox(height: 22),
            section(7, _RecentMealsShelf(entries: entries)),
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
          color: enabled ? Colors.black : AppColors.textTertiary,
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
  const _CalorieRing({required this.consumed, required this.target});

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

    final fg = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [AppColors.calorieFrom, AppColors.calorieTo],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, fg);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _MacrosRow extends StatelessWidget {
  final Profile profile;
  final DailyTotals totals;
  const _MacrosRow({required this.profile, required this.totals});

  void _openDetail(BuildContext context, NutrientType type) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NutrientDetailPage(nutrient: type)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MacroBar(
            label: 'Protein',
            consumed: totals.proteinG,
            target: profile.effectiveProteinTarget,
            color: AppColors.protein,
            onTap: () => _openDetail(context, NutrientType.protein),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MacroBar(
            label: 'Carbs',
            consumed: totals.carbsG,
            target: profile.effectiveCarbTarget,
            color: AppColors.carbs,
            onTap: () => _openDetail(context, NutrientType.carbs),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MacroBar(
            label: 'Fat',
            consumed: totals.fatG,
            target: profile.effectiveFatTarget,
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
          child: _StatChip(
            icon: Icons.water_drop_rounded,
            label: 'Water',
            value: (totals.waterMl / 1000).toStringAsFixed(1),
            of: '${(waterTargetMl / 1000).toStringAsFixed(1)}L',
            progress: waterProgress.clamp(0.0, 1.0),
            color: AppColors.water,
            isAddAction: true,
            onTap: () async {
              final today = ref.read(todayProvider);
              await ref.read(nutritionRepoProvider).addWater(today, 250);
            },
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String of;
  final double progress;
  final Color color;
  final VoidCallback? onTap;
  final bool isAddAction;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.of,
    required this.progress,
    required this.color,
    this.onTap,
    this.isAddAction = false,
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
                    isAddAction
                        ? Icons.add_rounded
                        : Icons.chevron_right_rounded,
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

class _WhatsLeftStrip extends ConsumerWidget {
  final Profile profile;
  final DailyTotals totals;
  const _WhatsLeftStrip({required this.profile, required this.totals});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calLeft =
        math.max(0, profile.effectiveCalorieTarget - totals.calories);
    final pLeft =
        math.max(0, profile.effectiveProteinTarget - totals.proteinG);
    final wLeftMl =
        math.max(0, profile.effectiveWaterTarget - totals.waterMl);
    final fLeft = math.max(0, profile.effectiveFiberTarget - totals.fiberG);

    final parts = <(String, Color)>[];
    if (pLeft > 0) parts.add(('${pLeft}g protein', AppColors.protein));
    if (wLeftMl > 0) {
      parts.add((
        '${(wLeftMl / 1000).toStringAsFixed(1)}L water',
        AppColors.water,
      ));
    }
    if (fLeft > 0) parts.add(('${fLeft}g fiber', AppColors.fiber));

    Widget strip;
    if (parts.isEmpty) {
      strip = Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.18), width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColors.accent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text('All daily targets met. Nicely done.',
                  style: AppText.body.copyWith(color: AppColors.textPrimary)),
            ),
          ],
        ),
      );
    } else {
      final spans = <InlineSpan>[const TextSpan(text: 'You still need ')];
      for (var i = 0; i < parts.length; i++) {
        spans.add(TextSpan(
          text: parts[i].$1,
          style: AppText.body.copyWith(
            color: parts[i].$2,
            fontWeight: FontWeight.w700,
          ),
        ));
        if (i < parts.length - 2) {
          spans.add(const TextSpan(text: ', '));
        } else if (i == parts.length - 2) {
          spans.add(const TextSpan(text: ' and '));
        }
      }
      spans.add(const TextSpan(text: '.'));

      strip = Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.18), width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.flag_rounded, color: AppColors.accent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: AppText.body.copyWith(color: AppColors.textPrimary),
                  children: spans,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        strip,
        if (calLeft > 0) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => MealSuggestionsSheet.show(
              context,
              profile: profile,
              totals: totals,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      size: 14, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text('What should I eat?',
                      style: AppText.body.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const Spacer(),
                  Icon(Icons.arrow_forward_rounded,
                      size: 14, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _WorkoutCard extends ConsumerWidget {
  const _WorkoutCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routineAsync = ref.watch(activeRoutineProvider);
    final dayAsync = ref.watch(todaysRoutineDayProvider);

    final routine = routineAsync.valueOrNull;
    final day = dayAsync.valueOrNull;

    if (routine == null) {
      return _WorkoutCardShell(
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
    }

    if (day == null || day.isRest) {
      return _WorkoutCardShell(
        icon: Icons.self_improvement_rounded,
        accent: AppColors.water,
        label: 'TODAY',
        title: 'Rest day',
        subtitle: 'Recovery matters as much as training.',
      );
    }

    return _WorkoutCardShell(
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
                  style: const TextStyle(
                    color: Colors.black,
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
