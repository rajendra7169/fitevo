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

  // Replace the default red "Exception thrown" widget with a readable
  // card that shows the actual error + stack tail, plus a Copy button.
  // Default behavior on release builds also gets the friendlier card so
  // users can paste us the failure instead of just describing "red
  // screen" — that turned out to be load-bearing for debugging.
  ErrorWidget.builder = (FlutterErrorDetails details) => _FriendlyError(
        details: details,
      );

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
      settings.themeMode == ThemeMode.light ? lightPalette : warmDarkPalette;

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
    final palette = mode == ThemeMode.light ? lightPalette : warmDarkPalette;
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
      darkTheme: buildAppTheme(warmDarkPalette),
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
    // Start background auto-backup once the user is signed in. Riverpod
    // keeps the provider alive as long as it's watched, so backgrounding
    // a build that observes this is the right place to anchor it.
    ref.watch(autoBackupLifecycleProvider);
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

/// Replacement for Flutter's default red "Exception" widget. Shows the
/// real error + stack tail so the user can read or copy what actually
/// went wrong instead of just seeing a wall of red.
class _FriendlyError extends StatelessWidget {
  final FlutterErrorDetails details;
  const _FriendlyError({required this.details});

  String _stackTail() {
    final st = details.stack?.toString() ?? '';
    final lines = st.split('\n').take(8).join('\n');
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final msg = details.exceptionAsString();
    return Material(
      color: AppColors.bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: AppColors.danger, size: 20),
                  const SizedBox(width: 8),
                  Text('Something broke on this screen',
                      style: AppText.sectionTitle.copyWith(fontSize: 15)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.stroke),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(msg,
                            style: AppText.body.copyWith(
                                fontSize: 12.5,
                                color: AppColors.textPrimary,
                                fontFamily: 'monospace')),
                        const SizedBox(height: 10),
                        Text(_stackTail(),
                            style: AppText.meta.copyWith(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                                fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(
                      text: '$msg\n\n${details.stack ?? ''}'));
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    SnackBar(
                      content: Text('Error copied to clipboard',
                          style: AppText.body
                              .copyWith(color: AppColors.textPrimary)),
                      backgroundColor: AppColors.surfaceHigh,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text('Copy error',
                      style: TextStyle(
                        color: AppColors.onAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
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
