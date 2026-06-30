import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/coach/coach_page.dart';
import '../features/progress/progress_page.dart';
import '../features/workout/workout_page.dart';
import '../state/providers.dart';
import '../theme.dart';
import 'dashboard_page.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  int _index = 0;
  // Increments every time the user taps Home from a different tab.
  // DashboardPage uses this as a ValueKey on its calorie ring so the
  // fill animation re-fires on tab return — the dashboard itself is
  // still kept-alive by IndexedStack, only the ring remounts.
  int _homeReentryGen = 0;

  // Tracks the date we last refreshed `todayProvider` for. Resume + the
  // midnight timer both compare against this to decide whether to invalidate.
  DateTime _lastSeenDate = DateTime.now();
  Timer? _midnightTimer;

  static const _items = [
    (Icons.dashboard_rounded, 'Home'),
    (Icons.fitness_center_rounded, 'Workout'),
    (Icons.show_chart_rounded, 'Progress'),
    (Icons.auto_awesome_rounded, 'Coach'),
  ];

  void _onTab(int i) {
    if (i == 0 && _index != 0) _homeReentryGen++;
    setState(() => _index = i);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnightTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshIfDateChanged();
      // Resume may land on a new day; reschedule the midnight tick so the
      // next rollover invalidation lands at the right moment.
      _scheduleMidnightTimer();
    }
  }

  void _refreshIfDateChanged() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = DateTime(
        _lastSeenDate.year, _lastSeenDate.month, _lastSeenDate.day);
    if (today != last) {
      _lastSeenDate = today;
      // Invalidating todayProvider re-runs every dependent stream
      // (today entries, water, totals, etc.) against the new date.
      ref.invalidate(todayProvider);
    }
  }

  void _scheduleMidnightTimer() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    // +1s buffer so we land firmly on the new day, not on the boundary.
    final delay = nextMidnight.difference(now) + const Duration(seconds: 1);
    _midnightTimer = Timer(delay, () {
      _refreshIfDateChanged();
      _scheduleMidnightTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: IndexedStack(
          index: _index,
          children: [
            DashboardPage(homeReentryGen: _homeReentryGen),
            const WorkoutPage(),
            const ProgressPage(),
            const CoachPage(),
          ],
        ),
        bottomNavigationBar: _BottomNav(
          index: _index,
          items: _items,
          onTap: _onTab,
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int index;
  final List<(IconData, String)> items;
  final ValueChanged<int> onTap;
  const _BottomNav({
    required this.index,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.stroke, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / items.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    left: tabWidth * index + 6,
                    top: 0,
                    bottom: 0,
                    width: tabWidth - 12,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.accent.withValues(alpha: 0.18),
                            AppColors.accent.withValues(alpha: 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.30),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(
                          child: _NavItem(
                            icon: items[i].$1,
                            label: items[i].$2,
                            active: index == i,
                            onTap: () => onTap(i),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: active ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: Icon(
                icon,
                color:
                    active ? AppColors.accent : AppColors.textTertiary,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                color:
                    active ? AppColors.accent : AppColors.textTertiary,
                fontSize: 11,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.2,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
