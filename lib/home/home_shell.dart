import 'package:flutter/material.dart';
import '../features/coach/coach_page.dart';
import '../features/progress/progress_page.dart';
import '../features/workout/workout_page.dart';
import '../theme.dart';
import 'dashboard_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  // Increments every time the user taps Home from a different tab.
  // DashboardPage uses this as a ValueKey on its calorie ring so the
  // fill animation re-fires on tab return — the dashboard itself is
  // still kept-alive by IndexedStack, only the ring remounts.
  int _homeReentryGen = 0;

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
