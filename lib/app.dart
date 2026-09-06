// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/onboarding_provider.dart';
import 'core/providers/user_journey_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/notification_service.dart';
// notification settings screen is available in features; not imported here to avoid unused import
import 'features/glowup/enhanced_onboarding_screen.dart';
import 'features/glowup/ai_face_scan_intro_flow.dart';
import 'features/glowup/glow_app_shell.dart';

/// Root app widget. Routes between onboarding, auth, and the main app.
///
/// IMPORTANT: Firebase authentication status is NOT used to decide whether
/// the user has completed onboarding, scanned, or paid. Those are separate
/// persistent states tracked by [UserJourneyState].
class GivingAiApp extends StatelessWidget {
  const GivingAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF5FA2),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'its giving.AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: baseScheme,
        scaffoldBackgroundColor: const Color(0xFFFFF3FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF251B2F),
          elevation: 0,
          centerTitle: true,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: const Color(0xFF251B2F),
          displayColor: const Color(0xFF251B2F),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            side: const BorderSide(color: Color(0xFFFF9AC2)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.white.withValues(alpha: 0.64),
          selectedColor: const Color(0xFFFFD8EA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.76),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5FA2),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF160D1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      themeMode: ThemeMode.light,
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends ConsumerStatefulWidget {
  const _AppEntry();

  @override
  ConsumerState<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends ConsumerState<_AppEntry> {
  @override
  void initState() {
    super.initState();
    // Load the user's persistent app state (onboarding, intro scan, etc.)
    // and restore/create the anonymous Firebase identity.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userJourneyProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final journey = ref.watch(userJourneyProvider);
    // Watch the live onboarding notifier directly. This state updates
    // immediately when onboarding is completed mid-session.
    final onboardingCompleted = ref.watch(onboardingProvider);

    // Show a proper loading screen while state is loading.
    // Never show Home (or any other screen) until we know where the user is.
    if (journey.isLoading) {
      return const _SplashScreen();
    }

    // 1. Onboarding first — regardless of auth state.
    if (!onboardingCompleted) {
      return const EnhancedOnboardingScreen();
    }

    // 2. Show the introductory face scan before opening Home.
    if (!journey.introFlowCompleted) {
      return const AiFaceScanIntroFlow();
    }

    // 3. AI plans are created on demand, never while the user waits to enter.
    // Show the one-time notification opt-in prompt if not shown before.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final prompted =
          prefs.getBool('glowup_notifications_prompt_shown') ?? false;
      final enabledPref = prefs.getBool('glowup_notifications_enabled');
      if (!prompted && enabledPref == null) {
        // Show a dialog asking the user to opt-in to daily reminders.
        if (!mounted) return;
        final result = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Enable reminders?'),
            content: const Text(
              'Would you like daily reminders to keep your glow streak alive?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Later'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Enable'),
              ),
            ],
          ),
        );
        await prefs.setBool('glowup_notifications_prompt_shown', true);
        if (result == true) {
          await prefs.setBool('glowup_notifications_enabled', true);
          await prefs.setInt('glowup_notifications_hour', 20);
          await prefs.setInt('glowup_notifications_minute', 0);
          try {
            await NotificationService.instance.requestPermissions();
            await NotificationService.instance.scheduleDailyReminder(
              id: 2001,
              title: 'Keep your glow streak going',
              body: 'Complete today\'s tasks to keep your streak alive.',
              hour: 20,
              minute: 0,
            );
          } catch (_) {}
        }
      }
    });

    return const GlowAppShell();
  }
}

/// Simple branded splash while app state loads.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
