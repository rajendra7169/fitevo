import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/daily_log.dart';
import '../../data/models/food_entry.dart';
import '../../data/models/profile.dart';
import '../../data/models/workout_session.dart';
import '../../core/health_math.dart' show HealthConstants;
import '../../data/repositories/nutrition_repo.dart';
import '../../home/todays_activity_card.dart' show TodaysActivityMath;
import '../../services/ai/ai_service.dart';
import '../../state/providers.dart';
import '../../theme.dart';

enum _ReportMode { food, workout }

/// Full-day report page: pick a day from a week strip, switch between
/// food and workout, see an AI-generated summary, and drill into the
/// raw entries / sessions for that day.
class DailyReportPage extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  const DailyReportPage({super.key, this.initialDate});

  @override
  ConsumerState<DailyReportPage> createState() => _DailyReportPageState();
}

class _DailyReportPageState extends ConsumerState<DailyReportPage> {
  late DateTime _selectedDate;
  _ReportMode _mode = _ReportMode.food;
  String? _aiSummary;
  bool _summaryLoading = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initialDate ?? DateTime.now();
    _selectedDate = DateTime(d.year, d.month, d.day);
    _loadCachedSummary();
  }

  String get _summaryCacheKey =>
      'dailyReport.summary.${_mode.name}.${DailyLog.keyFor(_selectedDate)}';

  Future<void> _loadCachedSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_summaryCacheKey);
    if (!mounted) return;
    setState(() => _aiSummary = cached);
  }

  void _selectDate(DateTime d) {
    final norm = DateTime(d.year, d.month, d.day);
    if (norm == _selectedDate) return;
    setState(() {
      _selectedDate = norm;
      _aiSummary = null;
    });
    _loadCachedSummary();
  }

  void _switchMode(_ReportMode m) {
    if (_mode == m) return;
    setState(() {
      _mode = m;
      _aiSummary = null;
    });
    _loadCachedSummary();
  }

  Future<void> _generateSummary({
    required Profile profile,
    required DailyTotals totals,
    required List<FoodEntry> dayFoods,
    required List<WorkoutSession> daySessions,
    DailyLog? dayLog,
  }) async {
    if (_summaryLoading) return;
    setState(() => _summaryLoading = true);
    try {
      final ai = ref.read(aiServiceProvider);
      final dateLabel = DateFormat('EEEE, MMM d, y').format(_selectedDate);
      final ctx = _mode == _ReportMode.food
          ? _foodContext(profile, totals, dayFoods, dayLog: dayLog)
          : _workoutContext(profile, daySessions);
      final text = await ai.coachChat(
        userContext: 'Date: $dateLabel\n$ctx',
        history: const [],
        latestUserMessage: 'Give me a brief 2-3 sentence ${_mode.name} '
            'report for $dateLabel. Highlight one win and one thing to '
            'improve. Be specific with numbers. Keep it warm and direct.',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_summaryCacheKey, text);
      if (!mounted) return;
      setState(() => _aiSummary = text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.surfaceHigh,
        content: Text(
          e is AiException ? e.message : 'AI summary failed.',
          style: AppText.body.copyWith(color: AppColors.textPrimary),
        ),
      ));
    } finally {
      if (mounted) setState(() => _summaryLoading = false);
    }
  }

  String _foodContext(
      Profile profile, DailyTotals totals, List<FoodEntry> foods,
      {DailyLog? dayLog}) {
    // Today-adjusted target so the AI doesn't say "you're over" when
    // the user logged a 5 km run that earned them 350 extra kcal.
    final calTarget = TodaysActivityMath.effectiveTodayCalorieTarget(
        profile: profile, log: dayLog);
    final macros = TodaysActivityMath.effectiveTodayMacros(
        profile: profile, log: dayLog);
    final calBalance = calTarget - totals.calories;
    final mealsList = foods
        .map((f) => '- ${f.description.isEmpty ? f.rawInput : f.description}'
            ' (${f.calories} kcal)')
        .join('\n');
    // Activity line — only included when the user actually logged
    // something, so a quiet day doesn't get a misleading 0-km entry.
    String? activityLine;
    if (dayLog != null) {
      final pieces = <String>[];
      if (dayLog.walkingKmToday > 0) {
        pieces.add('${dayLog.walkingKmToday.toStringAsFixed(1)} km walked');
      }
      if (dayLog.runningKmToday > 0) {
        pieces.add('${dayLog.runningKmToday.toStringAsFixed(1)} km run');
      }
      if (dayLog.otherCardioMinutes > 0) {
        pieces.add('${dayLog.otherCardioMinutes} min other cardio');
      }
      if (pieces.isNotEmpty) {
        final bonus = calTarget - profile.effectiveCalorieTarget;
        activityLine = 'Activity today: ${pieces.join(' · ')}'
            '${bonus > 0 ? ' (+$bonus kcal to target)' : ''}';
      }
    }
    return [
      'Goal: ${profile.goal.name}',
      'Diet: ${profile.dietPreference.name}',
      'Targets (activity-adjusted): $calTarget kcal · '
          '${macros.proteinG}g P · ${macros.carbG}g C · ${macros.fatG}g F',
      'Consumed: ${totals.calories} kcal · ${totals.proteinG}g P · '
          '${totals.carbsG}g C · ${totals.fatG}g F · ${totals.fiberG}g fiber',
      'Calorie balance: '
          '${calBalance >= 0 ? '$calBalance kcal left' : '${-calBalance} kcal over'}',
      ?activityLine,
      'Meals: ${totals.entryCount}',
      if (mealsList.isNotEmpty) 'Items:\n$mealsList',
    ].join('\n');
  }

  Future<void> _sharePdf({
    required Profile profile,
    required DailyTotals totals,
    required List<FoodEntry> dayFoods,
    required List<WorkoutSession> daySessions,
    DailyLog? dayLog,
  }) async {
    try {
      final doc = await _buildPdf(
        profile: profile,
        totals: totals,
        dayFoods: dayFoods,
        daySessions: daySessions,
        dayLog: dayLog,
      );
      final bytes = await doc.save();
      final dir = await getTemporaryDirectory();
      final dateLabel = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final file = File('${dir.path}/fitevo_report_${_mode.name}_$dateLabel.pdf');
      await file.writeAsBytes(bytes);
      final title = 'Fitevo · ${_mode.name} report · '
          '${DateFormat('MMM d, y').format(_selectedDate)}';
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: title,
        text: title,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.surfaceHigh,
        content: Text(
          'Could not share PDF: $e',
          style: AppText.body.copyWith(color: AppColors.textPrimary),
        ),
      ));
    }
  }

  Future<pw.Document> _buildPdf({
    required Profile profile,
    required DailyTotals totals,
    required List<FoodEntry> dayFoods,
    required List<WorkoutSession> daySessions,
    DailyLog? dayLog,
  }) async {
    final doc = pw.Document();
    final dateLabel = DateFormat('EEEE, MMM d, y').format(_selectedDate);
    final accent = PdfColor.fromInt(0xFFE8702C);
    final muted = PdfColor.fromInt(0xFF7A7367);
    final groups = _groupFoodsForPdf(dayFoods);
    final hasContent = _mode == _ReportMode.food
        ? dayFoods.isNotEmpty
        : daySessions.isNotEmpty;
    final aiText = _aiSummary?.trim();

    // Load the app logo from assets and embed as PdfImage.
    pw.MemoryImage? logo;
    try {
      final bytes = await rootBundle.load('assets/logo/logo.png');
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      logo = null; // PDF still renders without the logo.
    }

    final genTs =
        DateFormat('MMM d, y · h:mm a').format(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 36),
        // Footer on every page: timestamp on the left, signature on
        // the right with a heart glyph that renders in standard fonts.
        footer: (ctx) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('Generated by Fitevo · $genTs',
                  style: pw.TextStyle(fontSize: 8, color: muted)),
              // Inline "Made with [heart] by Rajendra Pandey" — the
              // heart is an SVG path so it renders cleanly even when
              // the PDF's default font (Helvetica) has no heart glyph.
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('Made with ',
                      style: pw.TextStyle(fontSize: 8, color: muted)),
                  pw.SizedBox(
                    width: 10,
                    height: 10,
                    child: pw.SvgImage(
                      svg:
                          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
                          '<path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 '
                          '2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 '
                          '14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 '
                          '6.86-8.55 11.54L12 21.35z" fill="#E83E40"/>'
                          '</svg>',
                    ),
                  ),
                  pw.Text(' by Rajendra Pandey',
                      style: pw.TextStyle(fontSize: 8, color: muted)),
                ],
              ),
            ],
          ),
        ),
        build: (ctx) => [
          // Header with logo + title block
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logo != null) ...[
                pw.ClipRRect(
                  horizontalRadius: 8,
                  verticalRadius: 8,
                  child: pw.Image(logo, width: 48, height: 48),
                ),
                pw.SizedBox(width: 12),
              ],
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('FITEVO · DAILY REPORT',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: accent,
                          letterSpacing: 0.8,
                          fontWeight: pw.FontWeight.bold,
                        )),
                    pw.SizedBox(height: 4),
                    pw.Text(dateLabel,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        )),
                    pw.SizedBox(height: 2),
                    pw.Text(
                        _mode == _ReportMode.food
                            ? 'Food summary'
                            : 'Workout summary',
                        style:
                            pw.TextStyle(fontSize: 12, color: muted)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Container(height: 1, color: muted),
          pw.SizedBox(height: 14),

          // Stats summary — rings (cal/carbs/fat) + bars (water/sodium/fiber)
          // for food; horizontal tiles for workout.
          if (_mode == _ReportMode.food)
            _pdfFoodStatsRingsBars(profile, totals, dayLog, accent, muted)
          else
            _pdfWorkoutStats(daySessions, accent, muted),

          pw.SizedBox(height: 18),

          // AI summary block — only when a non-empty summary exists.
          if (aiText != null && aiText.isNotEmpty) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFFFF6EE),
                borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: accent, width: 0.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('AI REPORT',
                      style: pw.TextStyle(
                        fontSize: 9,
                        letterSpacing: 0.6,
                        color: accent,
                        fontWeight: pw.FontWeight.bold,
                      )),
                  pw.SizedBox(height: 6),
                  pw.Text(aiText,
                      style: pw.TextStyle(fontSize: 11, lineSpacing: 2)),
                ],
              ),
            ),
            pw.SizedBox(height: 18),
          ],

          // Section heading
          pw.Text(
              _mode == _ReportMode.food
                  ? 'MEALS · ${dayFoods.length} ${dayFoods.length == 1 ? 'item' : 'items'}'
                  : 'SESSIONS · ${daySessions.length}',
              style: pw.TextStyle(
                fontSize: 9,
                letterSpacing: 0.8,
                color: muted,
                fontWeight: pw.FontWeight.bold,
              )),
          pw.SizedBox(height: 8),

          // Body: cards OR a single inline "nothing logged" line.
          if (hasContent) ...[
            if (_mode == _ReportMode.food)
              ..._pdfMealCards(groups, accent, muted)
            else
              ..._pdfSessionCards(daySessions, accent, muted),
          ] else
            pw.Text(
                _mode == _ReportMode.food
                    ? 'No food was logged on this day.'
                    : 'No workout was logged on this day.',
                style: pw.TextStyle(color: muted, fontSize: 11)),
        ],
      ),
    );
    return doc;
  }

  List<List<FoodEntry>> _groupFoodsForPdf(List<FoodEntry> entries) {
    if (entries.isEmpty) return const [];
    final groups = <List<FoodEntry>>[];
    for (final e in entries) {
      if (groups.isNotEmpty) {
        final last = groups.last.last;
        final sameInput =
            last.rawInput.isNotEmpty && last.rawInput == e.rawInput;
        final closeInTime = last.timestamp
                .difference(e.timestamp)
                .abs() <
            const Duration(minutes: 2);
        if (sameInput && closeInTime) {
          groups.last.add(e);
          continue;
        }
      }
      groups.add([e]);
    }
    return groups;
  }

  /// Build a single SVG ring (track + progress arc, plus a second
  /// overflow arc when [progress] > 1). Mirrors the in-app
  /// _RingPainter behaviour so the PDF doesn't lie about overeating.
  String _svgRing({
    required double progress,
    required String color,
    double size = 80,
    double stroke = 9,
  }) {
    final r = (size - stroke) / 2;
    final cx = size / 2;
    final cy = size / 2;
    // Track full circle — always rendered so a 0 day still reads.
    final track = '<circle cx="$cx" cy="$cy" r="$r" '
        'fill="none" stroke="$color" stroke-opacity="0.18" '
        'stroke-width="$stroke" />';
    if (progress <= 0) {
      return '<svg xmlns="http://www.w3.org/2000/svg" '
          'viewBox="0 0 $size $size">$track</svg>';
    }

    String arcPath(double fraction, String strokeColor) {
      final theta = fraction * 2 * math.pi;
      final endX = cx + r * math.sin(theta);
      final endY = cy - r * math.cos(theta);
      final largeArc = fraction > 0.5 ? 1 : 0;
      // Full lap special case: SVG's arc path can't draw a full 360°
      // in a single A command. Fall back to two semicircles via a
      // single circle stroke clip.
      if (fraction >= 0.9999) {
        return '<circle cx="$cx" cy="$cy" r="$r" '
            'fill="none" stroke="$strokeColor" '
            'stroke-width="$stroke" stroke-linecap="round" />';
      }
      final path = 'M $cx ${cy - r} A $r $r 0 $largeArc 1 $endX $endY';
      return '<path d="$path" fill="none" stroke="$strokeColor" '
          'stroke-width="$stroke" stroke-linecap="round" />';
    }

    // Primary arc — clamped to 1 lap.
    final primary = math.min(progress, 1.0);
    final primaryArc = arcPath(primary, color);

    // Overflow arc — second pass darker so the user sees they exceeded
    // the target. Capped at one extra lap so a 250% day doesn't
    // attempt absurd geometry.
    String overflowArc = '';
    if (progress > 1.0) {
      final over = (progress - 1.0).clamp(0.0, 1.0);
      // Darken the colour by mixing with black ~35% — matches the
      // in-app painter's Color.lerp(color, black, 0.35).
      final darker = _darkenHex(color, 0.35);
      overflowArc = arcPath(over, darker);
    }

    return '<svg xmlns="http://www.w3.org/2000/svg" '
        'viewBox="0 0 $size $size">$track$primaryArc$overflowArc</svg>';
  }

  /// Cheap colour-darken: shift each RGB channel toward 0 by [amount]
  /// (0..1). Used to render the PDF ring's overflow lap a shade darker
  /// than the primary lap.
  String _darkenHex(String hex, double amount) {
    final raw = hex.startsWith('#') ? hex.substring(1) : hex;
    final r = int.parse(raw.substring(0, 2), radix: 16);
    final g = int.parse(raw.substring(2, 4), radix: 16);
    final b = int.parse(raw.substring(4, 6), radix: 16);
    int blend(int c) => (c * (1 - amount)).round().clamp(0, 255);
    String hh(int c) => c.toRadixString(16).padLeft(2, '0');
    return '#${hh(blend(r))}${hh(blend(g))}${hh(blend(b))}';
  }

  pw.Widget _pdfRingRow({
    required String label,
    required String value,
    required String target,
    required double progress,
    required String colorHex,
    required PdfColor muted,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(
          width: 38,
          height: 38,
          child: pw.SvgImage(svg: _svgRing(
            progress: progress,
            color: colorHex,
            size: 80,
            stroke: 11,
          )),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: muted,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.6,
                  )),
              pw.SizedBox(height: 2),
              pw.RichText(
                text: pw.TextSpan(children: [
                  pw.TextSpan(
                      text: value,
                      style: pw.TextStyle(
                          fontSize: 13, fontWeight: pw.FontWeight.bold)),
                  pw.TextSpan(
                      text: ' $target',
                      style: pw.TextStyle(fontSize: 8, color: muted)),
                ]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfBarRow({
    required String label,
    required String value,
    required String target,
    required double progress,
    required String colorHex,
    required PdfColor muted,
  }) {
    final isOver = progress > 1.0;
    final p = progress.clamp(0.0, 1.0);
    final color = PdfColor.fromInt(int.parse(colorHex.substring(1), radix: 16) |
        0xFF000000);
    // For overflow we render a darker second segment on top of the
    // first (capped at +1 lap) so the user sees a "stacked" bar — same
    // intent as the in-app ring overflow.
    final overFraction = isOver ? (progress - 1.0).clamp(0.0, 1.0) : 0.0;
    final darkerHex = _darkenHex(colorHex, 0.35);
    final darker = PdfColor.fromInt(
        int.parse(darkerHex.substring(1), radix: 16) | 0xFF000000);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Text(label,
                style: pw.TextStyle(
                  fontSize: 8,
                  color: muted,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 0.6,
                )),
            pw.Spacer(),
            pw.RichText(
              text: pw.TextSpan(children: [
                pw.TextSpan(
                    text: value,
                    style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: isOver ? color : null)),
                pw.TextSpan(
                    text: ' / $target',
                    style: pw.TextStyle(fontSize: 8, color: muted)),
                if (isOver)
                  pw.TextSpan(
                    text: '  ↑ over',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: color,
                    ),
                  ),
              ]),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        // Single-row bar — primary fill clamped to 100%, overflow lap
        // layered on top via a Stack so the bar visually "stacks" the
        // overage in place instead of growing a second row underneath.
        pw.ClipRRect(
          horizontalRadius: 3,
          verticalRadius: 3,
          child: pw.SizedBox(
            height: 6,
            child: pw.Stack(
              children: [
                // Track underneath
                pw.Positioned.fill(
                  child: pw.Container(
                    color: PdfColor.fromInt(
                        (color.toInt() & 0x00FFFFFF) | 0x2A000000),
                  ),
                ),
                // Primary lap row (Expanded flex fakes FractionallySizedBox)
                pw.Positioned.fill(
                  child: pw.Row(children: [
                    if (p > 0)
                      pw.Expanded(
                        flex: (p * 1000).round(),
                        child: pw.Container(color: color),
                      ),
                    if (p < 1)
                      pw.Expanded(
                        flex: ((1 - p) * 1000).round(),
                        child: pw.Container(),
                      ),
                  ]),
                ),
                // Overflow lap layered on top of the primary fill
                if (isOver)
                  pw.Positioned.fill(
                    child: pw.Row(children: [
                      pw.Expanded(
                        flex: (overFraction * 1000).round(),
                        child: pw.Container(color: darker),
                      ),
                      if (overFraction < 1)
                        pw.Expanded(
                          flex: ((1 - overFraction) * 1000).round(),
                          child: pw.Container(),
                        ),
                    ]),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfFoodStatsRingsBars(
    Profile profile,
    DailyTotals totals,
    DailyLog? dayLog,
    PdfColor accent,
    PdfColor muted,
  ) {
    // Use the activity-adjusted targets so the PDF matches what the
    // user saw on the day in the app.
    final calT = TodaysActivityMath.effectiveTodayCalorieTarget(
        profile: profile, log: dayLog);
    final macros = TodaysActivityMath.effectiveTodayMacros(
        profile: profile, log: dayLog);
    final waterTarget = profile.effectiveWaterTarget;
    final fiberTarget = profile.effectiveFiberTarget;
    final sodiumLimit = HealthConstants.sodiumDailyLimitMg;

    // Hex colors picked to match the in-app palette (rendered in SVG).
    const calColor = '#E8702C';   // saffron
    const carbColor = '#C9A64A';  // gold
    const fatColor = '#B5697A';   // berry
    const waterColor = '#6B86C9';
    const fiberColor = '#B48BCF';
    const sodiumColor = '#E8702C';

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: muted, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left: rings (Calories, Carbs, Fat)
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _pdfRingRow(
                  label: 'CALORIES',
                  value: '${totals.calories}',
                  target: '/ $calT kcal',
                  progress: calT == 0 ? 0 : totals.calories / calT,
                  colorHex: calColor,
                  muted: muted,
                ),
                pw.SizedBox(height: 8),
                _pdfRingRow(
                  label: 'CARBS',
                  value: '${totals.carbsG}',
                  target: '/ ${macros.carbG}g',
                  progress: macros.carbG == 0 ? 0 : totals.carbsG / macros.carbG,
                  colorHex: carbColor,
                  muted: muted,
                ),
                pw.SizedBox(height: 8),
                _pdfRingRow(
                  label: 'FAT',
                  value: '${totals.fatG}',
                  target: '/ ${macros.fatG}g',
                  progress: macros.fatG == 0 ? 0 : totals.fatG / macros.fatG,
                  colorHex: fatColor,
                  muted: muted,
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Container(width: 0.5, color: muted, height: 130),
          pw.SizedBox(width: 16),
          // Right: bars (Water, Sodium, Fiber)
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _pdfBarRow(
                  label: 'WATER',
                  value: (totals.waterMl / 1000).toStringAsFixed(1),
                  target: '${(waterTarget / 1000).toStringAsFixed(1)}L',
                  progress: waterTarget == 0 ? 0 : totals.waterMl / waterTarget,
                  colorHex: waterColor,
                  muted: muted,
                ),
                pw.SizedBox(height: 12),
                _pdfBarRow(
                  label: 'SODIUM',
                  value: (totals.sodiumMg / 1000).toStringAsFixed(1),
                  target: '${(sodiumLimit / 1000).toStringAsFixed(1)}g',
                  progress:
                      sodiumLimit == 0 ? 0 : totals.sodiumMg / sodiumLimit,
                  colorHex: sodiumColor,
                  muted: muted,
                ),
                pw.SizedBox(height: 12),
                _pdfBarRow(
                  label: 'FIBER',
                  value: '${totals.fiberG}',
                  target: '${fiberTarget}g',
                  progress: fiberTarget == 0 ? 0 : totals.fiberG / fiberTarget,
                  colorHex: fiberColor,
                  muted: muted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfWorkoutStats(
      List<WorkoutSession> sessions, PdfColor accent, PdfColor muted) {
    final totalMin =
        sessions.fold<int>(0, (s, w) => s + w.duration.inMinutes);
    final totalSets =
        sessions.fold<int>(0, (s, w) => s + w.sets.length);
    final totalVolume = sessions.fold<double>(
        0, (s, w) => s + w.sets.fold(0.0, (a, b) => a + b.weightKg * b.reps));
    final exCount = sessions
        .expand((s) => s.sets.map((x) => x.exerciseName))
        .toSet()
        .length;

    pw.Widget tile(String label, String value, String unit) {
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: muted, width: 0.5),
            borderRadius:
                const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label,
                  style: pw.TextStyle(
                    fontSize: 8,
                    letterSpacing: 0.6,
                    color: muted,
                    fontWeight: pw.FontWeight.bold,
                  )),
              pw.SizedBox(height: 4),
              pw.RichText(
                text: pw.TextSpan(children: [
                  pw.TextSpan(
                      text: value,
                      style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold)),
                  pw.TextSpan(
                      text: ' $unit',
                      style: pw.TextStyle(fontSize: 9, color: muted)),
                ]),
              ),
            ],
          ),
        ),
      );
    }

    return pw.Row(children: [
      tile('DURATION', '$totalMin', 'min'),
      pw.SizedBox(width: 8),
      tile('SETS', '$totalSets', ''),
      pw.SizedBox(width: 8),
      tile('EXERCISES', '$exCount', ''),
      pw.SizedBox(width: 8),
      tile('VOLUME', totalVolume.toStringAsFixed(0), 'kg'),
    ]);
  }

  List<pw.Widget> _pdfMealCards(
      List<List<FoodEntry>> groups, PdfColor accent, PdfColor muted) {
    final out = <pw.Widget>[];
    for (final g in groups) {
      final time = DateFormat('h:mm a').format(g.first.timestamp);
      final totalKcal = g.fold<int>(0, (s, e) => s + e.calories);
      final totalP = g.fold<int>(0, (s, e) => s + e.proteinG);
      final totalC = g.fold<int>(0, (s, e) => s + e.carbsG);
      final totalF = g.fold<int>(0, (s, e) => s + e.fatG);
      final raw = g.first.rawInput;

      out.add(pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 8),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: muted, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Text(time,
                    style: pw.TextStyle(
                        fontSize: 10,
                        color: muted,
                        fontWeight: pw.FontWeight.bold)),
                if (g.length > 1) ...[
                  pw.SizedBox(width: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFFFEEDF),
                      borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(4)),
                    ),
                    child: pw.Text('MEAL · ${g.length} ITEMS',
                        style: pw.TextStyle(
                          color: accent,
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.4,
                        )),
                  ),
                ],
                pw.Spacer(),
                pw.Text('$totalKcal kcal',
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            if (raw.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.RichText(
                text: pw.TextSpan(children: [
                  pw.TextSpan(
                      text: '"$raw"  ',
                      style: pw.TextStyle(
                          fontSize: 10,
                          color: muted,
                          fontStyle: pw.FontStyle.italic)),
                  pw.TextSpan(
                      text:
                          'P ${totalP}g · C ${totalC}g · F ${totalF}g',
                      style: pw.TextStyle(
                          fontSize: 8,
                          color: muted,
                          fontWeight: pw.FontWeight.bold)),
                ]),
              ),
            ],
            if (g.length > 1) ...[
              pw.SizedBox(height: 6),
              pw.Container(height: 0.5, color: muted),
              pw.SizedBox(height: 6),
              for (var i = 0; i < g.length; i++)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Row(children: [
                    pw.SizedBox(
                      width: 18,
                      child: pw.Text('${i + 1}.',
                          style: pw.TextStyle(
                              fontSize: 9, color: muted)),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                          g[i].description.isEmpty
                              ? g[i].rawInput
                              : g[i].description,
                          style: pw.TextStyle(fontSize: 9),
                          maxLines: 1,
                          overflow: pw.TextOverflow.clip),
                    ),
                    pw.Text('${g[i].calories} kcal',
                        style: pw.TextStyle(fontSize: 9, color: muted)),
                  ]),
                ),
            ],
          ],
        ),
      ));
    }
    return out;
  }

  List<pw.Widget> _pdfSessionCards(
      List<WorkoutSession> sessions, PdfColor accent, PdfColor muted) {
    final out = <pw.Widget>[];
    for (final s in sessions) {
      final start = DateFormat('h:mm a').format(s.startedAt);
      final dur = s.duration.inMinutes;
      final volume = s.sets
          .fold<double>(0, (a, b) => a + b.weightKg * b.reps)
          .toStringAsFixed(0);
      out.add(pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 8),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: muted, width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text(
                      s.routineDayName.isEmpty
                          ? (s.routineName.isEmpty
                              ? 'Workout'
                              : s.routineName)
                          : '${s.routineName} · ${s.routineDayName}',
                      style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold)),
                ),
                pw.Text('$dur min',
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 3),
            pw.Text(
                '$start  ·  ${s.sets.length} sets  ·  $volume kg total',
                style: pw.TextStyle(fontSize: 9, color: muted)),
          ],
        ),
      ));
    }
    return out;
  }

  String _workoutContext(Profile profile, List<WorkoutSession> sessions) {
    if (sessions.isEmpty) return 'No workout was logged on this day.';
    final totalMin =
        sessions.fold<int>(0, (s, w) => s + w.duration.inMinutes);
    final totalSets = sessions.fold<int>(0, (s, w) => s + w.sets.length);
    final totalVolume = sessions.fold<double>(
        0, (s, w) => s + w.sets.fold(0.0, (a, b) => a + b.weightKg * b.reps));
    final exercises = sessions
        .expand((s) => s.sets.map((x) => x.exerciseName))
        .toSet()
        .join(', ');
    return [
      'Goal: ${profile.goal.name}',
      'Sessions: ${sessions.length}',
      'Total duration: $totalMin min',
      'Total sets: $totalSets',
      'Total volume: ${totalVolume.toStringAsFixed(0)} kg',
      if (exercises.isNotEmpty) 'Exercises: $exercises',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileStreamProvider).valueOrNull;
    final allFoods =
        ref.watch(allFoodEntriesProvider).valueOrNull ?? const <FoodEntry>[];
    final allSessions = ref.watch(allSessionsProvider).valueOrNull ??
        const <WorkoutSession>[];
    final allLogs = ref.watch(allDailyLogsProvider).valueOrNull ??
        const <DailyLog>[];
    final dayKey = DailyLog.keyFor(_selectedDate);
    final dayFoods = allFoods.where((e) => e.dateKey == dayKey).toList();
    final daySessions =
        allSessions.where((s) => s.dateKey == dayKey).toList();
    // Per-day DailyLog lookup so each day's calorie ring uses the
    // activity-adjusted target (running/walking/cardio + sleep) instead
    // of the static weekly-average profile target.
    final logsByDay = <String, DailyLog>{
      for (final l in allLogs) l.dateKey: l,
    };
    final dayLog = logsByDay[dayKey];
    final totals = NutritionRepo.sumEntries(dayFoods,
        waterMl: dayLog?.waterMl ?? 0);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text('Daily Report', style: AppText.sectionTitle),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.ios_share_rounded, color: AppColors.accent),
            tooltip: 'Share as PDF',
            onPressed: profile == null
                ? null
                : () => _sharePdf(
                      profile: profile,
                      totals: totals,
                      dayFoods: dayFoods,
                      daySessions: daySessions,
                      dayLog: dayLog,
                    ),
          ),
        ],
      ),
      body: SafeArea(
        child: profile == null
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    sliver: SliverList.list(children: [
                      _DateHeader(date: _selectedDate),
                      const SizedBox(height: 14),
                      _WeekStrip(
                        selected: _selectedDate,
                        onPick: _selectDate,
                        mode: _mode,
                        profile: profile,
                        foods: allFoods,
                        sessions: allSessions,
                        logsByDay: logsByDay,
                      ),
                      const SizedBox(height: 18),
                      _ModeToggle(mode: _mode, onChange: _switchMode),
                      const SizedBox(height: 22),
                      if (_mode == _ReportMode.food) ...[
                        _FoodRings(
                          profile: profile,
                          totals: totals,
                          dayLog: dayLog,
                        ),
                        const SizedBox(height: 10),
                        _ExtrasBarsCard(
                          profile: profile,
                          totals: totals,
                        ),
                      ] else ...[
                        _WorkoutRings(sessions: daySessions),
                      ],
                      // Walking/running/cardio always visible regardless of
                      // tab — walking adjusts the calorie target on the food
                      // tab and is equally relevant on the workout tab.
                      if (dayLog != null &&
                          (dayLog.walkingKmToday > 0 ||
                              dayLog.runningKmToday > 0 ||
                              dayLog.otherCardioMinutes > 0)) ...[
                        const SizedBox(height: 10),
                        _ActivityKmCard(log: dayLog),
                      ],
                      const SizedBox(height: 18),
                      _SummaryCard(
                        loading: _summaryLoading,
                        text: _aiSummary,
                        onGenerate: () => _generateSummary(
                          profile: profile,
                          totals: totals,
                          dayFoods: dayFoods,
                          daySessions: daySessions,
                          dayLog: dayLog,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_mode == _ReportMode.food)
                        _FoodList(entries: dayFoods)
                      else
                        _WorkoutList(sessions: daySessions),
                    ]),
                  ),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Date header
// ---------------------------------------------------------------------

class _DateHeader extends StatelessWidget {
  final DateTime date;
  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('EEEE, MMM d, y').format(date);
    return Center(
      child: Text(label,
          style: AppText.sectionTitle.copyWith(
            fontSize: 15,
            color: AppColors.textSecondary,
          )),
    );
  }
}

// ---------------------------------------------------------------------
// Week strip — 7 day chips, tap to switch. Defaults to current week.
// Chevrons step ±7 days.
// ---------------------------------------------------------------------

class _WeekStrip extends StatefulWidget {
  final DateTime selected;
  final void Function(DateTime) onPick;
  final _ReportMode mode;
  final Profile profile;
  final List<FoodEntry> foods;
  final List<WorkoutSession> sessions;
  /// Day's DailyLog by dateKey — used to adjust per-day calorie target
  /// for running/walking/cardio bonus instead of using the static
  /// profile target on every day's mini ring.
  final Map<String, DailyLog> logsByDay;
  const _WeekStrip({
    required this.selected,
    required this.onPick,
    required this.mode,
    required this.profile,
    required this.foods,
    required this.sessions,
    required this.logsByDay,
  });

  @override
  State<_WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<_WeekStrip> {
  late DateTime _weekStart; // Monday of the displayed week

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(widget.selected);
  }

  @override
  void didUpdateWidget(covariant _WeekStrip old) {
    super.didUpdateWidget(old);
    // Keep the visible week containing the selected day.
    if (widget.selected != old.selected) {
      _weekStart = _mondayOf(widget.selected);
    }
  }

  DateTime _mondayOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  void _step(int days) {
    setState(() => _weekStart = _weekStart.add(Duration(days: days)));
  }

  /// Pre-group foods + sessions by dateKey so the per-day mini-ring
  /// computation is O(N) per day rather than scanning every day.
  Map<String, List<FoodEntry>> _foodsByDay() {
    final m = <String, List<FoodEntry>>{};
    for (final e in widget.foods) {
      (m[e.dateKey] ??= <FoodEntry>[]).add(e);
    }
    return m;
  }

  Map<String, List<WorkoutSession>> _sessionsByDay() {
    final m = <String, List<WorkoutSession>>{};
    for (final s in widget.sessions) {
      (m[s.dateKey] ??= <WorkoutSession>[]).add(s);
    }
    return m;
  }

  _DayRingValues _ringsForDay(
      DateTime day,
      Map<String, List<FoodEntry>> foodsByDay,
      Map<String, List<WorkoutSession>> sessionsByDay) {
    final key = DailyLog.keyFor(day);
    if (widget.mode == _ReportMode.food) {
      final dayFoods = foodsByDay[key] ?? const <FoodEntry>[];
      final t = NutritionRepo.sumEntries(dayFoods);
      // Per-day target — bumps for running/walking/cardio bonus and
      // sleep-debt softener so a day with a 6 km run doesn't read as
      // "over target" against the weekly average.
      final dayLog = widget.logsByDay[key];
      final calT = TodaysActivityMath.effectiveTodayCalorieTarget(
        profile: widget.profile,
        log: dayLog,
      );
      final macros = TodaysActivityMath.effectiveTodayMacros(
        profile: widget.profile,
        log: dayLog,
      );
      return _DayRingValues(
        outer: calT == 0 ? 0 : t.calories / calT,
        middle: macros.proteinG == 0 ? 0 : t.proteinG / macros.proteinG,
        inner: macros.carbG == 0 ? 0 : t.carbsG / macros.carbG,
        outerColor: AppColors.calorieFrom,
        middleColor: AppColors.protein,
        innerColor: AppColors.carbs,
      );
    } else {
      final daySessions =
          sessionsByDay[key] ?? const <WorkoutSession>[];
      final totalMin = daySessions.fold<int>(
          0, (s, w) => s + w.duration.inMinutes);
      final totalSets =
          daySessions.fold<int>(0, (s, w) => s + w.sets.length);
      final exCount = daySessions
          .expand((s) => s.sets.map((x) => x.exerciseName))
          .toSet()
          .length;
      return _DayRingValues(
        outer: totalMin / 30,
        middle: totalSets / 12,
        inner: exCount / 4,
        outerColor: AppColors.danger,
        middleColor: AppColors.warning,
        innerColor: AppColors.water,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final foodsByDay = _foodsByDay();
    final sessionsByDay = _sessionsByDay();
    return Row(
      children: [
        _ChevronButton(
          icon: Icons.chevron_left_rounded,
          onTap: () => _step(-7),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final day = _weekStart.add(Duration(days: i));
              final isSelected = day == widget.selected;
              final isFuture = day.isAfter(todayKey);
              final isToday = day == todayKey;
              final rings = _ringsForDay(day, foodsByDay, sessionsByDay);
              return _DayChip(
                date: day,
                selected: isSelected,
                disabled: isFuture,
                today: isToday,
                rings: rings,
                onTap: () => widget.onPick(day),
              );
            }),
          ),
        ),
        _ChevronButton(
          icon: Icons.chevron_right_rounded,
          onTap: () => _step(7),
        ),
      ],
    );
  }
}

class _DayRingValues {
  final double outer;
  final double middle;
  final double inner;
  final Color outerColor;
  final Color middleColor;
  final Color innerColor;
  const _DayRingValues({
    required this.outer,
    required this.middle,
    required this.inner,
    required this.outerColor,
    required this.middleColor,
    required this.innerColor,
  });
}

class _ChevronButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ChevronButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, color: AppColors.textTertiary, size: 22),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final DateTime date;
  final bool selected;
  final bool disabled;
  final bool today;
  final _DayRingValues rings;
  final VoidCallback onTap;
  const _DayChip({
    required this.date,
    required this.selected,
    required this.disabled,
    required this.today,
    required this.rings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final wd = DateFormat('E').format(date).substring(0, 3).toUpperCase();
    final num = '${date.day}';
    final labelColor = disabled
        ? AppColors.textTertiary.withValues(alpha: 0.4)
        : AppColors.textTertiary;
    final dayColor = selected
        ? AppColors.onAccent
        : disabled
            ? AppColors.textTertiary.withValues(alpha: 0.4)
            : AppColors.textPrimary;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(wd,
              style: AppText.label.copyWith(
                fontSize: 10,
                letterSpacing: 0.6,
                color: labelColor,
              )),
          const SizedBox(height: 6),
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.accent : Colors.transparent,
              border: !selected && today
                  ? Border.all(color: AppColors.accent, width: 1.2)
                  : null,
            ),
            child: Text(num,
                style: AppText.bigNumber.copyWith(
                  fontSize: 14,
                  color: dayColor,
                  fontWeight: FontWeight.w700,
                )),
          ),
          const SizedBox(height: 6),
          // Future dates still render the three ring tracks so the
          // strip stays visually rhythmic (matches the dim day-of-week
          // + day-of-month treatment above). Was previously hard-dimmed
          // to 0.3 which made the tracks effectively invisible.
          Opacity(
            opacity: disabled ? 0.55 : 1,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CustomPaint(
                painter: _TripleRingPainter(
                  outerProgress: rings.outer,
                  middleProgress: rings.middle,
                  innerProgress: rings.inner,
                  outerColor: rings.outerColor,
                  middleColor: rings.middleColor,
                  innerColor: rings.innerColor,
                  strokeWidth: 2.6,
                  gap: 0.8,
                  // Strip tracks need to read at a 24×24 thumbnail even
                  // when the day has no progress yet — punch up alpha
                  // so the three tracks remain visibly stacked.
                  trackAlpha: 0.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Activity km card — sits under the workout rings in the daily report
// when the user logged walking / running / non-gym cardio for the day.
// Gym sessions live above; this is the "movement outside the gym" row.
// ---------------------------------------------------------------------

class _ActivityKmCard extends StatelessWidget {
  final DailyLog log;
  const _ActivityKmCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[];
    if (log.walkingKmToday > 0) {
      tiles.add(_ActivityKmTile(
        icon: Icons.directions_walk_rounded,
        label: 'Walk',
        value: log.walkingKmToday.toStringAsFixed(1),
        unit: 'km',
        color: AppColors.water,
        motion: _IconMotion.walk,
      ));
    }
    if (log.runningKmToday > 0) {
      tiles.add(_ActivityKmTile(
        icon: Icons.directions_run_rounded,
        label: 'Run',
        value: log.runningKmToday.toStringAsFixed(1),
        unit: 'km',
        color: AppColors.accent,
        motion: _IconMotion.run,
      ));
    }
    if (log.otherCardioMinutes > 0) {
      tiles.add(_ActivityKmTile(
        icon: Icons.local_fire_department_rounded,
        label: 'Cardio',
        value: '${log.otherCardioMinutes}',
        unit: 'min',
        color: AppColors.danger,
        motion: _IconMotion.pulse,
      ));
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
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
              Icon(Icons.timeline_rounded,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text('OUTDOOR / CARDIO',
                  style: AppText.label.copyWith(
                      fontSize: 11, letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 10),
          // Wrap so 1–3 tiles flow nicely on narrow screens.
          Row(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                Expanded(child: tiles[i]),
                if (i < tiles.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Motion style for the activity icon — drives the looping animation
/// that gives the tile a sense of movement (walk gently sways, run
/// sways faster + tilts, cardio pulses like a beating flame).
enum _IconMotion { walk, run, pulse }

class _ActivityKmTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final _IconMotion motion;
  const _ActivityKmTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.motion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.30)),
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
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _MovingIcon(
                  icon: icon,
                  color: color,
                  motion: motion,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppText.meta.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiary,
                    letterSpacing: 0.6,
                  ),
                ),
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
                    style: AppText.bigNumber.copyWith(
                      fontSize: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: AppText.meta.copyWith(
                      fontSize: 11,
                      color: AppColors.textTertiary,
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

/// Tiny looping animation that gives the activity tile icons a sense
/// of motion. Walk = gentle horizontal sway. Run = faster sway + tilt.
/// Pulse = scale in-out like a beating flame. Implemented with a
/// SingleTickerProvider + linear repeating controller so each tile
/// owns one cheap controller.
class _MovingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final _IconMotion motion;
  const _MovingIcon({
    required this.icon,
    required this.color,
    required this.motion,
  });

  @override
  State<_MovingIcon> createState() => _MovingIconState();
}

class _MovingIconState extends State<_MovingIcon>
    with SingleTickerProviderStateMixin {
  late final Duration _period = switch (widget.motion) {
    _IconMotion.walk => const Duration(milliseconds: 1200),
    _IconMotion.run => const Duration(milliseconds: 700),
    _IconMotion.pulse => const Duration(milliseconds: 900),
  };
  late final AnimationController _ctl =
      AnimationController(vsync: this, duration: _period)..repeat();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      builder: (_, _) {
        final t = _ctl.value; // 0..1
        // Smooth sine so the motion eases rather than ticks.
        final phase = math.sin(t * 2 * math.pi);
        double dx = 0;
        double dy = 0;
        double rot = 0;
        double scale = 1.0;
        switch (widget.motion) {
          case _IconMotion.walk:
            // Side-to-side sway, very gentle.
            dx = phase * 1.6;
            dy = (1 - (phase.abs())) * -0.6; // tiny bob on stride
            break;
          case _IconMotion.run:
            // Faster sway + slight forward lean tilt.
            dx = phase * 2.4;
            dy = (1 - (phase.abs())) * -1.0;
            rot = phase * 0.05;
            break;
          case _IconMotion.pulse:
            // Beating-heart style scale: 0.92 → 1.10 → 0.92.
            scale = 1.0 + 0.10 * phase;
            break;
        }
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(
            angle: rot,
            child: Transform.scale(
              scale: scale,
              child: Icon(widget.icon, size: 14, color: widget.color),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------
// Segmented toggle
// ---------------------------------------------------------------------

class _ModeToggle extends StatelessWidget {
  final _ReportMode mode;
  final void Function(_ReportMode) onChange;
  const _ModeToggle({required this.mode, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
              child: _SegmentButton(
                  label: 'Food',
                  icon: Icons.restaurant_rounded,
                  active: mode == _ReportMode.food,
                  onTap: () => onChange(_ReportMode.food))),
          Expanded(
              child: _SegmentButton(
                  label: 'Workout',
                  icon: Icons.fitness_center_rounded,
                  active: mode == _ReportMode.workout,
                  onTap: () => onChange(_ReportMode.workout))),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: active ? AppColors.onAccent : AppColors.textTertiary),
            const SizedBox(width: 6),
            Text(label,
                style: AppText.body.copyWith(
                  color:
                      active ? AppColors.onAccent : AppColors.textTertiary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                )),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Food rings — 3 concentric arcs: Cal, Protein, Carbs
// ---------------------------------------------------------------------

class _FoodRings extends StatelessWidget {
  final Profile profile;
  final DailyTotals totals;
  /// Day's DailyLog when one exists. Provides the running/walking
  /// activity that the calorie target bumps for, so the ring agrees
  /// with the home dashboard instead of showing "over target" after
  /// a run.
  final DailyLog? dayLog;
  const _FoodRings({
    required this.profile,
    required this.totals,
    this.dayLog,
  });

  @override
  Widget build(BuildContext context) {
    final calT = TodaysActivityMath.effectiveTodayCalorieTarget(
      profile: profile,
      log: dayLog,
    );
    final macros = TodaysActivityMath.effectiveTodayMacros(
      profile: profile,
      log: dayLog,
    );
    final pT = macros.proteinG;
    final cT = macros.carbG;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          SizedBox(
            width: 170,
            height: 170,
            child: CustomPaint(
              painter: _TripleRingPainter(
                outerProgress: calT == 0 ? 0 : totals.calories / calT,
                middleProgress: pT == 0 ? 0 : totals.proteinG / pT,
                innerProgress: cT == 0 ? 0 : totals.carbsG / cT,
                outerColor: AppColors.calorieFrom,
                middleColor: AppColors.protein,
                innerColor: AppColors.carbs,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RingStat(
                    color: AppColors.calorieFrom,
                    label: 'Calories',
                    value: '${totals.calories}',
                    target: '/$calT kcal'),
                const SizedBox(height: 14),
                _RingStat(
                    color: AppColors.protein,
                    label: 'Protein',
                    value: '${totals.proteinG}',
                    target: '/${pT}g'),
                const SizedBox(height: 14),
                _RingStat(
                    color: AppColors.carbs,
                    label: 'Carbs',
                    value: '${totals.carbsG}',
                    target: '/${cT}g'),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Water / Fiber / Sodium bar cards — sit under the food rings on the
// selected day. Mirrors the home screen's _WaterFiberChips so users
// can see the same three stats per-day in the report.
// ---------------------------------------------------------------------

class _ExtrasBarsCard extends StatelessWidget {
  final Profile profile;
  final DailyTotals totals;
  const _ExtrasBarsCard({required this.profile, required this.totals});

  @override
  Widget build(BuildContext context) {
    final waterTargetMl = profile.effectiveWaterTarget;
    final fiberTarget = profile.effectiveFiberTarget;
    final sodiumLimit = HealthConstants.sodiumDailyLimitMg;

    final waterProgress =
        waterTargetMl == 0 ? 0.0 : totals.waterMl / waterTargetMl;
    final fiberProgress =
        fiberTarget == 0 ? 0.0 : totals.fiberG / fiberTarget;
    final sodiumProgress =
        sodiumLimit == 0 ? 0.0 : totals.sodiumMg / sodiumLimit;

    return Row(
      children: [
        Expanded(
          child: _StatBarCard(
            icon: Icons.water_drop_rounded,
            label: 'Water',
            value: (totals.waterMl / 1000).toStringAsFixed(1),
            unit: 'L',
            target: '${(waterTargetMl / 1000).toStringAsFixed(1)}L',
            // Pass raw progress — the card handles overflow + up-arrow.
            progress: waterProgress,
            color: AppColors.water,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatBarCard(
            icon: Icons.grass_rounded,
            label: 'Fiber',
            value: '${totals.fiberG}',
            unit: 'g',
            target: '${fiberTarget}g',
            progress: fiberProgress,
            color: AppColors.fiber,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatBarCard(
            icon: Icons.scatter_plot_rounded,
            label: 'Sodium',
            value: (totals.sodiumMg / 1000).toStringAsFixed(1),
            unit: 'g',
            target: '${(sodiumLimit / 1000).toStringAsFixed(1)}g',
            progress: sodiumProgress,
            color: AppColors.calorieFrom,
          ),
        ),
      ],
    );
  }
}

class _StatBarCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final String target;
  /// Raw progress 0..N — values > 1 trigger the up-arrow over indicator
  /// and a stacked darker overflow segment beneath the primary bar.
  final double progress;
  final Color color;
  const _StatBarCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.target,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isOver = progress > 1.0;
    final primary = progress.clamp(0.0, 1.0);
    final overFraction = isOver ? (progress - 1.0).clamp(0.0, 1.0) : 0.0;
    return Container(
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
                  label.toUpperCase(),
                  style: AppText.meta.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiary,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              if (isOver)
                Icon(Icons.arrow_upward_rounded,
                    size: 14, color: color),
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
                    style: AppText.bigNumber.copyWith(
                      fontSize: 18,
                      color: isOver ? color : AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: unit,
                    style: AppText.bigNumber.copyWith(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  TextSpan(
                    text: ' /$target',
                    style: AppText.meta.copyWith(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Single-row bar with the overflow layered on top — same
          // "stacking" feel as the ring overflow on the home screen.
          // No second row beneath; the darker overlay sits inside the
          // primary fill so the strip stays compact.
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 6,
              child: LayoutBuilder(
                builder: (ctx, c) {
                  final w = c.maxWidth;
                  final overlayColor =
                      Color.lerp(color, Colors.black, 0.35)!;
                  return Stack(
                    children: [
                      // Track
                      Container(color: color.withValues(alpha: 0.14)),
                      // Primary lap — clamped to 100%
                      SizedBox(
                        width: w * primary,
                        child: Container(color: color),
                      ),
                      // Overflow lap — sits on top of primary, growing
                      // from the left up to the overshoot proportion.
                      if (isOver)
                        SizedBox(
                          width: w * overFraction,
                          child: Container(color: overlayColor),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Workout rings — duration / sets / exercises (vs default baselines)
// ---------------------------------------------------------------------

class _WorkoutRings extends StatelessWidget {
  final List<WorkoutSession> sessions;
  const _WorkoutRings({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final totalMin = sessions.fold<int>(
        0, (s, w) => s + w.duration.inMinutes);
    final totalSets = sessions.fold<int>(0, (s, w) => s + w.sets.length);
    final exercises = sessions
        .expand((s) => s.sets.map((x) => x.exerciseName))
        .toSet()
        .length;
    const minTarget = 30;
    const setTarget = 12;
    const exerciseTarget = 4;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          SizedBox(
            width: 170,
            height: 170,
            child: CustomPaint(
              painter: _TripleRingPainter(
                outerProgress: totalMin / minTarget,
                middleProgress: totalSets / setTarget,
                innerProgress: exercises / exerciseTarget,
                outerColor: AppColors.danger,
                middleColor: AppColors.warning,
                innerColor: AppColors.water,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RingStat(
                    color: AppColors.danger,
                    label: 'Duration',
                    value: '$totalMin',
                    target: '/$minTarget min'),
                const SizedBox(height: 14),
                _RingStat(
                    color: AppColors.warning,
                    label: 'Sets',
                    value: '$totalSets',
                    target: '/$setTarget'),
                const SizedBox(height: 14),
                _RingStat(
                    color: AppColors.water,
                    label: 'Exercises',
                    value: '$exercises',
                    target: '/$exerciseTarget'),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _RingStat extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final String target;
  const _RingStat({
    required this.color,
    required this.label,
    required this.value,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: AppText.meta.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value,
                style: AppText.giantNumber.copyWith(
                    fontSize: 22, color: AppColors.textPrimary)),
            Text(target,
                style: AppText.meta.copyWith(
                    fontSize: 12, color: AppColors.textTertiary)),
          ],
        ),
      ],
    );
  }
}

/// Apple-Watch-style 3 concentric rings. Each ring has a faded track
/// behind the progress arc so the ring is visible even at 0%.
class _TripleRingPainter extends CustomPainter {
  final double outerProgress;
  final double middleProgress;
  final double innerProgress;
  final Color outerColor;
  final Color middleColor;
  final Color innerColor;

  _TripleRingPainter({
    required this.outerProgress,
    required this.middleProgress,
    required this.innerProgress,
    required this.outerColor,
    required this.middleColor,
    required this.innerColor,
    this.strokeWidth = 18,
    this.gap = 4,
    this.trackAlpha = 0.18,
  });

  final double strokeWidth;
  final double gap;
  /// Background-track opacity. Bumped by the week strip's tiny rings so
  /// future / no-data days still show visible track outlines instead of
  /// a barely-there smudge.
  final double trackAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - strokeWidth / 2 - 2;
    _drawRing(canvas, center, outerRadius, strokeWidth, outerColor,
        outerProgress);
    _drawRing(canvas, center, outerRadius - strokeWidth - gap, strokeWidth,
        middleColor, middleProgress);
    _drawRing(
        canvas,
        center,
        outerRadius - 2 * (strokeWidth + gap),
        strokeWidth,
        innerColor,
        innerProgress);
  }

  void _drawRing(Canvas canvas, Offset center, double radius,
      double strokeWidth, Color color, double progress) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..color = color.withValues(alpha: trackAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);
    if (progress <= 0) return;

    final primaryFraction = math.min(progress, 1.0);
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
        rect, -math.pi / 2, 2 * math.pi * primaryFraction, false, fg);

    // Overflow pass — when consumed > target, lay a second arc on top
    // (Apple-Watch-style) so the user can see how far past the goal
    // they went. Matches the home calorie ring's stacking behavior.
    if (progress > 1.0) {
      final overflowFraction = (progress - 1.0).clamp(0.0, 1.0);
      final overflowSweep = 2 * math.pi * overflowFraction;

      final shadow = Paint()
        ..color = Colors.black.withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 1
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      canvas.drawArc(rect, -math.pi / 2, overflowSweep, false, shadow);

      // Darken toward black for the overflow tip so the second lap
      // is visually distinct from the first without introducing a
      // new color (rings keep their per-macro color identity).
      final overflowColor = Color.lerp(color, Colors.black, 0.35)!;
      final over = Paint()
        ..color = overflowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -math.pi / 2, overflowSweep, false, over);
    }
  }

  @override
  bool shouldRepaint(covariant _TripleRingPainter old) =>
      old.outerProgress != outerProgress ||
      old.middleProgress != middleProgress ||
      old.innerProgress != innerProgress ||
      old.outerColor != outerColor ||
      old.middleColor != middleColor ||
      old.innerColor != innerColor;
}

// ---------------------------------------------------------------------
// AI Summary card
// ---------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  final bool loading;
  final String? text;
  final VoidCallback onGenerate;
  const _SummaryCard({
    required this.loading,
    required this.text,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
              Icon(Icons.auto_awesome_rounded,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('AI REPORT',
                  style: AppText.label.copyWith(
                    color: AppColors.accent,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  )),
              const Spacer(),
              if (text != null && !loading)
                GestureDetector(
                  onTap: onGenerate,
                  behavior: HitTestBehavior.opaque,
                  child: Icon(Icons.refresh_rounded,
                      size: 16, color: AppColors.textTertiary),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (loading)
            const SizedBox(
              height: 24,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ),
            )
          else if (text == null)
            GestureDetector(
              onTap: onGenerate,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 14, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text('Generate report for this day',
                        style: AppText.body.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        )),
                  ],
                ),
              ),
            )
          else
            Text(text!,
                style: AppText.body.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.4,
                  fontSize: 14,
                )),
        ],
      ),
    ).animate().fadeIn(duration: 220.ms);
  }
}

// ---------------------------------------------------------------------
// Lists — food entries / workout sessions for the day
// ---------------------------------------------------------------------

class _FoodList extends StatelessWidget {
  final List<FoodEntry> entries;
  const _FoodList({required this.entries});

  /// Cluster consecutive entries that share the same `rawInput` and
  /// were logged within 2 minutes — i.e. the AI split a single meal
  /// into multiple items. Mirrors the grouping used on Today's Food.
  List<List<FoodEntry>> _group(List<FoodEntry> entries) {
    if (entries.isEmpty) return const [];
    final groups = <List<FoodEntry>>[];
    for (final e in entries) {
      if (groups.isNotEmpty) {
        final last = groups.last.last;
        final sameInput =
            last.rawInput.isNotEmpty && last.rawInput == e.rawInput;
        final closeInTime = last.timestamp
                .difference(e.timestamp)
                .abs() <
            const Duration(minutes: 2);
        if (sameInput && closeInTime) {
          groups.last.add(e);
          continue;
        }
      }
      groups.add([e]);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return _EmptyPanel(
          icon: Icons.restaurant_rounded,
          message: 'No food logged on this day.');
    }
    final groups = _group(entries);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FOOD LOGGED · ${entries.length}',
            style: AppText.label.copyWith(
                fontSize: 10,
                letterSpacing: 0.8,
                color: AppColors.textTertiary)),
        const SizedBox(height: 10),
        for (final g in groups) ...[
          g.length == 1
              ? _FoodRow(entry: g.first)
              : _FoodGroupCard(entries: g),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Compact card for an AI-split meal: header with time + total kcal,
/// the user's raw input quoted, then itemised lines.
class _FoodGroupCard extends StatelessWidget {
  final List<FoodEntry> entries;
  const _FoodGroupCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('h:mm a').format(entries.first.timestamp);
    final totalKcal = entries.fold<int>(0, (s, e) => s + e.calories);
    final totalP = entries.fold<int>(0, (s, e) => s + e.proteinG);
    final totalC = entries.fold<int>(0, (s, e) => s + e.carbsG);
    final totalF = entries.fold<int>(0, (s, e) => s + e.fatG);
    final raw = entries.first.rawInput;
    final snippet = raw.length > 90 ? '${raw.substring(0, 90)}…' : raw;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restaurant_rounded,
                          size: 10, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text('MEAL · ${entries.length} ITEMS',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          )),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.schedule_rounded,
                    size: 11, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(time,
                    style: AppText.meta.copyWith(
                        fontSize: 11,
                        color: AppColors.textTertiary)),
                const Spacer(),
                Text('$totalKcal',
                    style: AppText.bigNumber.copyWith(
                        fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(width: 3),
                Text('kcal',
                    style: AppText.meta.copyWith(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          if (raw.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Text('"$snippet"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                  )),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _MacroPill(
                    label: 'P',
                    value: '${totalP}g',
                    color: AppColors.protein),
                _MacroPill(
                    label: 'C',
                    value: '${totalC}g',
                    color: AppColors.carbs),
                _MacroPill(
                    label: 'F',
                    value: '${totalF}g',
                    color: AppColors.fat),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: AppColors.accent.withValues(alpha: 0.18),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  _MealItemRow(entry: entries[i], index: i + 1),
                  if (i < entries.length - 1) const SizedBox(height: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MealItemRow extends StatelessWidget {
  final FoodEntry entry;
  final int index;
  const _MealItemRow({required this.entry, required this.index});

  @override
  Widget build(BuildContext context) {
    final name =
        entry.description.isEmpty ? entry.rawInput : entry.description;
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('$index',
              style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
              if (entry.quantity.isNotEmpty)
                Text(entry.quantity,
                    style: AppText.meta.copyWith(
                        fontSize: 10,
                        color: AppColors.textTertiary)),
            ],
          ),
        ),
        Text('${entry.calories}',
            style: AppText.bigNumber
                .copyWith(fontSize: 12, color: AppColors.textPrimary)),
        const SizedBox(width: 2),
        Text('kcal',
            style: AppText.meta.copyWith(
                fontSize: 9,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MacroPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text('$value $label',
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          )),
    );
  }
}

class _FoodRow extends StatelessWidget {
  final FoodEntry entry;
  const _FoodRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final name =
        entry.description.isEmpty ? entry.rawInput : entry.description;
    final time = DateFormat('h:mm a').format(entry.timestamp);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.schedule_rounded,
                      size: 11, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(time,
                      style: AppText.meta.copyWith(
                          fontSize: 11, color: AppColors.textTertiary)),
                  if (entry.quantity.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(entry.quantity,
                        style: AppText.meta.copyWith(
                            fontSize: 11, color: AppColors.textTertiary)),
                  ],
                ]),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.calories}',
                  style: AppText.bigNumber
                      .copyWith(fontSize: 16, color: AppColors.textPrimary)),
              Text('kcal',
                  style: AppText.meta.copyWith(
                      fontSize: 10, color: AppColors.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkoutList extends StatelessWidget {
  final List<WorkoutSession> sessions;
  const _WorkoutList({required this.sessions});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return _EmptyPanel(
          icon: Icons.fitness_center_rounded,
          message: 'No workout logged on this day.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SESSIONS · ${sessions.length}',
            style: AppText.label.copyWith(
                fontSize: 10,
                letterSpacing: 0.8,
                color: AppColors.textTertiary)),
        const SizedBox(height: 10),
        for (final s in sessions) ...[
          _WorkoutRow(session: s),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _WorkoutRow extends StatelessWidget {
  final WorkoutSession session;
  const _WorkoutRow({required this.session});

  @override
  Widget build(BuildContext context) {
    final dur = session.duration.inMinutes;
    final volume = session.sets
        .fold<double>(0, (a, b) => a + b.weightKg * b.reps)
        .toStringAsFixed(0);
    final start = DateFormat('h:mm a').format(session.startedAt);
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
              Expanded(
                child: Text(
                    session.routineDayName.isEmpty
                        ? (session.routineName.isEmpty
                            ? 'Workout'
                            : session.routineName)
                        : '${session.routineName} · ${session.routineDayName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
              Text('$dur min',
                  style: AppText.bigNumber.copyWith(
                      fontSize: 14, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.schedule_rounded,
                size: 11, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Text(start,
                style: AppText.meta.copyWith(
                    fontSize: 11, color: AppColors.textTertiary)),
            const SizedBox(width: 10),
            Icon(Icons.repeat_rounded,
                size: 11, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Text('${session.sets.length} sets',
                style: AppText.meta.copyWith(
                    fontSize: 11, color: AppColors.textTertiary)),
            const SizedBox(width: 10),
            Icon(Icons.scale_rounded,
                size: 11, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Text('$volume kg',
                style: AppText.meta.copyWith(
                    fontSize: 11, color: AppColors.textTertiary)),
          ]),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyPanel({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppColors.textTertiary),
          const SizedBox(height: 8),
          Text(message,
              style:
                  AppText.body.copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}
