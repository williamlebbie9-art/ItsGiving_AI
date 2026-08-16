import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/app_providers.dart';
import 'core/providers/onboarding_provider.dart';
import 'features/glowup/auth_screen.dart';
import 'features/glowup/enhanced_onboarding_screen.dart';
import 'features/glowup/glow_app_shell.dart';

/// Root app widget. Routes between onboarding, auth, and the main app.
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
    // Load onboarding status from local storage.
    ref.read(onboardingProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingCompleted = ref.watch(onboardingProvider);

    // Watch auth state. When a user signs in, initialize RevenueCat + usage.
    return StreamBuilder<User?>(
      stream: ref.watch(authServiceProvider).authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          // Schedule initialization after the build phase completes.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeForUser(user);
          });
          return const GlowAppShell();
        }

        // Not authenticated.
        if (!onboardingCompleted) {
          return const EnhancedOnboardingScreen();
        }
        return const AuthScreen();
      },
    );
  }

  void _initializeForUser(User user) {
    // Initialize RevenueCat with the Firebase UID.
    ref.read(subscriptionProvider.notifier).initialize(user.uid);
    // Load usage counts for this UID.
    ref.read(usageProvider.notifier).load(user.uid);
  }
}
