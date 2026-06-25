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
import '../../data/repositories/nutrition_repo.dart';
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
  }) async {
    if (_summaryLoading) return;
    setState(() => _summaryLoading = true);
    try {
      final ai = ref.read(aiServiceProvider);
      final dateLabel = DateFormat('EEEE, MMM d, y').format(_selectedDate);
      final ctx = _mode == _ReportMode.food
          ? _foodContext(profile, totals, dayFoods)
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
      Profile profile, DailyTotals totals, List<FoodEntry> foods) {
    final calBalance = profile.effectiveCalorieTarget - totals.calories;
    final mealsList = foods
        .map((f) => '- ${f.description.isEmpty ? f.rawInput : f.description}'
            ' (${f.calories} kcal)')
        .join('\n');
    return [
      'Goal: ${profile.goal.name}',
      'Diet: ${profile.dietPreference.name}',
      'Targets: ${profile.effectiveCalorieTarget} kcal · '
          '${profile.effectiveProteinTarget}g P · '
          '${profile.effectiveCarbTarget}g C · ${profile.effectiveFatTarget}g F',
      'Consumed: ${totals.calories} kcal · ${totals.proteinG}g P · '
          '${totals.carbsG}g C · ${totals.fatG}g F · ${totals.fiberG}g fiber',
      'Calorie balance: '
          '${calBalance >= 0 ? '$calBalance kcal left' : '${-calBalance} kcal over'}',
      'Meals: ${totals.entryCount}',
      if (mealsList.isNotEmpty) 'Items:\n$mealsList',
    ].join('\n');
  }

  Future<void> _sharePdf({
    required Profile profile,
    required DailyTotals totals,
    required List<FoodEntry> dayFoods,
    required List<WorkoutSession> daySessions,
  }) async {
    try {
      final doc = await _buildPdf(
        profile: profile,
        totals: totals,
        dayFoods: dayFoods,
        daySessions: daySessions,
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

          // Stats summary tiles
          if (_mode == _ReportMode.food)
            _pdfFoodStats(profile, totals, accent, muted)
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

  pw.Widget _pdfFoodStats(Profile profile, DailyTotals totals,
      PdfColor accent, PdfColor muted) {
    pw.Widget tile(String label, String value, String target) {
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
                      text: ' $target',
                      style: pw.TextStyle(fontSize: 9, color: muted)),
                ]),
              ),
            ],
          ),
        ),
      );
    }

    return pw.Row(children: [
      tile('CALORIES', '${totals.calories}',
          '/ ${profile.effectiveCalorieTarget} kcal'),
      pw.SizedBox(width: 8),
      tile('PROTEIN', '${totals.proteinG}',
          '/ ${profile.effectiveProteinTarget}g'),
      pw.SizedBox(width: 8),
      tile('CARBS', '${totals.carbsG}',
          '/ ${profile.effectiveCarbTarget}g'),
      pw.SizedBox(width: 8),
      tile('FAT', '${totals.fatG}', '/ ${profile.effectiveFatTarget}g'),
    ]);
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
    final dayKey = DailyLog.keyFor(_selectedDate);
    final dayFoods = allFoods.where((e) => e.dateKey == dayKey).toList();
    final daySessions =
        allSessions.where((s) => s.dateKey == dayKey).toList();
    final totals = NutritionRepo.sumEntries(dayFoods);

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
                      ),
                      const SizedBox(height: 18),
                      _ModeToggle(mode: _mode, onChange: _switchMode),
                      const SizedBox(height: 22),
                      if (_mode == _ReportMode.food)
                        _FoodRings(profile: profile, totals: totals)
                      else
                        _WorkoutRings(sessions: daySessions),
                      const SizedBox(height: 18),
                      _SummaryCard(
                        loading: _summaryLoading,
                        text: _aiSummary,
                        onGenerate: () => _generateSummary(
                          profile: profile,
                          totals: totals,
                          dayFoods: dayFoods,
                          daySessions: daySessions,
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
  const _WeekStrip({
    required this.selected,
    required this.onPick,
    required this.mode,
    required this.profile,
    required this.foods,
    required this.sessions,
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
      final calT = widget.profile.effectiveCalorieTarget;
      final pT = widget.profile.effectiveProteinTarget;
      final cT = widget.profile.effectiveCarbTarget;
      return _DayRingValues(
        outer: calT == 0 ? 0 : t.calories / calT,
        middle: pT == 0 ? 0 : t.proteinG / pT,
        inner: cT == 0 ? 0 : t.carbsG / cT,
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
          Opacity(
            opacity: disabled ? 0.3 : 1,
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
  const _FoodRings({required this.profile, required this.totals});

  @override
  Widget build(BuildContext context) {
    final calT = profile.effectiveCalorieTarget;
    final pT = profile.effectiveProteinTarget;
    final cT = profile.effectiveCarbTarget;
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
  });

  final double strokeWidth;
  final double gap;

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
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);
    final p = progress.clamp(0.0, 1.0);
    if (p <= 0) return;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * p, false, fg);
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
