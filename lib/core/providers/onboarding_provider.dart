import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the user has completed onboarding.
class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier() : super(false);

  /// Loads the onboarding completion status from local storage.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('glowup_onboarding_completed') ?? false;
  }

  /// Marks onboarding as complete.
  Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('glowup_onboarding_completed', true);
    state = true;
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, bool>(
  (ref) => OnboardingNotifier(),
);
