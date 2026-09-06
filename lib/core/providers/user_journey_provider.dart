import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_providers.dart';
import 'onboarding_provider.dart';
import '../services/notification_service.dart';
import '../../features/glowup/plan_provider.dart';

/// Persistent user-journey state — completely separate from Firebase auth.
///
/// Firebase auth answers only "does this user have an identity?".
/// These states answer:
/// - has the user completed onboarding?
/// - has the user completed the full first-run flow
///   (intro scan → plan → paywall)?
class UserJourneyState {
  const UserJourneyState({
    this.isLoading = true,
    this.onboardingCompleted = false,
    this.introFlowCompleted = false,
  });

  final bool isLoading;
  final bool onboardingCompleted;

  /// True once the user has completed the mandatory first-run flow:
  /// intro scan → plan → paywall.
  final bool introFlowCompleted;

  UserJourneyState copyWith({
    bool? isLoading,
    bool? onboardingCompleted,
    bool? introFlowCompleted,
  }) {
    return UserJourneyState(
      isLoading: isLoading ?? this.isLoading,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      introFlowCompleted: introFlowCompleted ?? this.introFlowCompleted,
    );
  }
}

/// Loads app progress (not auth progress):
/// 1. restore/create the anonymous Firebase identity
/// 2. load onboarding completion
/// 3. load intro-flow completion
/// 4. restore subscription status
class UserJourneyNotifier extends StateNotifier<UserJourneyState> {
  UserJourneyNotifier(this._ref) : super(const UserJourneyState());

  final Ref _ref;
  bool _initialized = false;

  /// Bootstraps the app's journey state.
  ///
  /// This is the ONLY place that decides whether the user has an identity —
  /// it does NOT decide whether the user has completed onboarding, scanned,
  /// or paid. Those decisions stay in [UserJourneyState].
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // 1. Restore or create a persistent anonymous Firebase identity.
      final auth = _ref.read(authServiceProvider);
      try {
        if (auth.currentUser == null) {
          await auth.signInAnonymously();
        }
      } catch (e) {
        debugPrint('[Journey] Anonymous auth restore failed: $e');
      }
      final uid = auth.currentUser?.uid;

      // 2. Load onboarding completion from local storage.
      await _ref.read(onboardingProvider.notifier).load();
      final onboardingCompleted = _ref.read(onboardingProvider);

      // 3. Load the full intro-flow completion flag from local storage.
      final prefs = await SharedPreferences.getInstance();
      final introFlowCompleted =
          prefs.getBool('glowup_intro_flow_completed') ?? false;

      if (uid != null) {
        // Load usage for free-limit enforcement. This does NOT mark the
        // full intro flow complete — the full flow also requires plan + paywall.
        await _ref.read(usageProvider.notifier).load(uid);

        // Initialize notifications and schedule daily reminder if needed.
        try {
          await NotificationService.instance.init();
          // Request permissions (iOS/macOS) when the app initializes.
          unawaited(NotificationService.instance.requestPermissions());

          // Load the current plan and check streak to determine urgency.
          await _ref.read(planProvider.notifier).loadPlan();
          final currentPlan = _ref.read(planProvider).plan;
          if (currentPlan != null) {
            final lastStreak = currentPlan.streak;
            // If streak is 0 or <=2, send a stronger reminder.
            final title = lastStreak <= 1
                ? 'Your streak is at risk ✨'
                : 'Keep your glow streak going';
            final body = lastStreak <= 1
                ? 'Complete today\'s plan to keep your streak alive.'
                : 'You\'re on a $lastStreak-day streak — complete today\'s tasks!';

            // Schedule a daily reminder at 8pm local time.
            await NotificationService.instance.scheduleDailyReminder(
              id: 2001,
              title: title,
              body: body,
              hour: 20,
              minute: 0,
            );
          } else {
            // No plan: schedule a gentle daily nudge at 8pm to create one.
            await NotificationService.instance.scheduleDailyReminder(
              id: 2002,
              title: 'Create your Glow-Up plan',
              body: 'Finish onboarding to get your personalized 30-day plan.',
              hour: 20,
              minute: 0,
            );
          }
        } catch (e) {
          debugPrint('[Notifications] Could not schedule reminders: $e');
        }
        // 4. Restore subscription status (non-blocking).
        unawaited(_ref.read(subscriptionProvider.notifier).initialize(uid));
      }

      state = UserJourneyState(
        isLoading: false,
        onboardingCompleted: onboardingCompleted,
        introFlowCompleted: introFlowCompleted,
      );
    } catch (e) {
      debugPrint('[Journey] Could not load user state: $e');
      state = const UserJourneyState(isLoading: false);
    }
  }

  /// Marks the full first-run intro flow complete (after scan → plan → paywall).
  /// Persists locally so restarting the app does not reset it.
  Future<void> markIntroFlowCompleted() async {
    if (state.introFlowCompleted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('glowup_intro_flow_completed', true);
    state = state.copyWith(introFlowCompleted: true);
  }
}

final userJourneyProvider =
    StateNotifierProvider<UserJourneyNotifier, UserJourneyState>(
      (ref) => UserJourneyNotifier(ref),
    );
