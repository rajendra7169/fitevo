import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/db.dart';
import 'data/repositories/exercise_repo.dart';
import 'features/auth/login_page.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'firebase_options.dart';
import 'home/home_shell.dart';
import 'services/notifications/notification_service.dart';
import 'services/settings/app_settings.dart';
import 'state/providers.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final db = await Db.init();
  final settings = await AppSettings.init();
  await NotificationService.instance.init();
  await ExerciseRepo(db).seedIfEmpty();
  await ExerciseRepo(db).seedIfEmpty();

  // Set palette before first widget builds so AppColors.x is correct.
  AppColors.palette =
      settings.themeMode == ThemeMode.light ? lightPalette : darkPalette;

  runApp(ProviderScope(
    overrides: [
      dbProvider.overrideWithValue(db),
      appSettingsProvider.overrideWithValue(settings),
    ],
    child: const FitevoApp(),
  ));
}

class FitevoApp extends ConsumerWidget {
  const FitevoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final palette = mode == ThemeMode.light ? lightPalette : darkPalette;
    AppColors.palette = palette;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: palette.brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarColor: palette.bg,
      systemNavigationBarIconBrightness: palette.brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
    ));

    return MaterialApp(
      title: 'Fitevo',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(lightPalette),
      darkTheme: buildAppTheme(darkPalette),
      themeMode: mode,
      builder: (context, child) {
        // Force the entire navigator (and all pushed routes) to rebuild
        // when the palette changes, since widgets read AppColors directly
        // instead of via Theme.of(context).
        return KeyedSubtree(
          key: ValueKey(palette.brightness),
          child: child!,
        );
      },
      home: const _Root(),
    );
  }
}

class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    return auth.when(
      loading: () => const _Splash(),
      error: (_, _) => const _Splash(),
      data: (user) {
        if (user == null) return const LoginPage();
        return _ProfileGate(uid: user.uid);
      },
    );
  }
}

class _ProfileGate extends ConsumerWidget {
  final String uid;
  const _ProfileGate({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restore = ref.watch(initialSyncProvider(uid));
    return restore.when(
      loading: () => const _Splash(),
      error: (_, _) => const _ProfileResolver(),
      data: (_) => const _ProfileResolver(),
    );
  }
}

class _ProfileResolver extends ConsumerWidget {
  const _ProfileResolver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileStreamProvider);
    return profile.when(
      loading: () => const _Splash(),
      error: (_, _) => const _Splash(),
      data: (p) {
        if (p == null) return const OnboardingFlow();
        return const HomeShell();
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo/logo.png', width: 96, height: 96),
            const SizedBox(height: 24),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.2, color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}
