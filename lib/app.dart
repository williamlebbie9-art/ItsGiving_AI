import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/services/decision_engine.dart';
import 'core/storage/history_repository.dart';
import 'core/storage/profile_repository.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

class DecideAiApp extends StatelessWidget {
  const DecideAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7B6CF6),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Decide AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: baseScheme,
        scaffoldBackgroundColor: const Color(0xFFF4F2FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFFFF),
          foregroundColor: Color(0xFF1C1F3B),
          elevation: 0,
          centerTitle: true,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: const Color(0xFF27304F),
          displayColor: const Color(0xFF27304F),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
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
          seedColor: const Color(0xFF7B6CF6),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF090B14),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF111827),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF111827),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      themeMode: ThemeMode.dark,
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool _checking = true;
  bool _showOnboarding = false;
  bool _showSignIn = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    final signInCompleted = prefs.getBool('signin_completed') ?? false;

    setState(() {
      _showOnboarding = !onboardingCompleted;
      _showSignIn = onboardingCompleted && !signInCompleted;
      _checking = false;
    });
  }

  Future<void> _onAuthComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('signin_completed', true);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final decisionEngine = DecisionEngine();
    final historyRepository = HistoryRepository();
    final profileRepository = ProfileRepository();

    if (_showOnboarding) {
      return OnboardingScreen(
        decisionEngine: decisionEngine,
        historyRepository: historyRepository,
        profileRepository: profileRepository,
      );
    }

    if (_showSignIn) {
      return SignInScreen(
        decisionEngine: decisionEngine,
        historyRepository: historyRepository,
        profileRepository: profileRepository,
        onAuthComplete: _onAuthComplete,
      );
    }

    // Skip sign-in and paywall — go straight to home
    return HomeScreen(
      decisionEngine: decisionEngine,
      historyRepository: historyRepository,
      profileRepository: profileRepository,
    );
  }
}
