import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../services/ai_client.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../services/usage_service.dart';

/// Auth service provider.
final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(auth: FirebaseAuth.instance),
);

/// Subscription service provider.
final subscriptionServiceProvider = Provider<SubscriptionService>(
  (ref) => SubscriptionService(),
);

/// Usage service provider.
final usageServiceProvider = Provider<UsageService>((ref) => UsageService());

/// Current authenticated Firebase UID, or null.
final authUidProvider = Provider<String?>((ref) {
  return ref.watch(authServiceProvider).currentUid;
});

/// Current subscription state.
final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>(
      (ref) => SubscriptionNotifier(ref.watch(subscriptionServiceProvider)),
    );

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier(this._service) : super(const SubscriptionState());

  final SubscriptionService _service;

  /// Initializes RevenueCat with the authenticated Firebase UID.
  Future<void> initialize(String firebaseUid) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _service.initialize(firebaseUid: firebaseUid);
    final loaded = await _service.loadSubscriptionState();
    state = loaded.copyWith(isLoading: false);
    // Best-effort server-side claim sync so Cloud Functions recognize premium
    // users even when their ID token was minted before the claim existed.
    if (loaded.isPremium) {
      unawaited(_syncPremiumClaims());
    }
  }

  /// Purchases a package.
  Future<bool> purchase(Package package) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _service.purchase(package);
      state = result.copyWith(isLoading: false);
      if (result.isPremium) {
        // Wait for the server-verified premium claim and a refreshed ID token
        // so the very next AI request is billed against the premium
        // entitlement instead of the free allowance.
        await _syncPremiumClaims();
      }
      return result.isPremium;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Restores purchases.
  Future<bool> restorePurchases() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _service.restorePurchases();
      state = result.copyWith(isLoading: false);
      if (result.isPremium) {
        await _syncPremiumClaims();
      }
      return result.isPremium;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Logs out of RevenueCat.
  Future<void> logOut() async {
    await _service.logOut();
    state = const SubscriptionState();
  }

  /// Calls `syncPremiumStatus` so the server verifies the RevenueCat
  /// entitlement and mints/clears the `premium` custom claim, then
  /// force-refreshes the ID token so the claim is visible on the next AI
  /// request to Cloud Functions. Best effort; never throws.
  Future<void> _syncPremiumClaims() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final premium = await const AiClient().syncPremiumStatus();
      if (!premium) return;
      // Claims can take a moment to propagate; retry the refresh once.
      try {
        await user.getIdToken(true);
      } catch (_) {
        await user.getIdToken(true);
      }
    } catch (e) {
      debugPrint('[Subscriptions] Premium claim sync failed: $e');
    }
  }
}

/// Current usage counts for the authenticated user.
final usageProvider = StateNotifierProvider<UsageNotifier, UsageCounts>(
  (ref) => UsageNotifier(ref.watch(usageServiceProvider)),
);

class UsageNotifier extends StateNotifier<UsageCounts> {
  UsageNotifier(this._service) : super(const UsageCounts());

  final UsageService _service;

  /// Loads usage for the given UID.
  Future<void> load(String uid) async {
    final usage = await _service.getUsage(uid);
    state = usage;
  }

  /// Increments face scan count. Call ONLY after a successful AI scan.
  Future<void> incrementFaceScan(String uid) async {
    await _service.incrementFaceScan(uid);
    state = state.copyWith(faceScanCount: state.faceScanCount + 1);
  }

  /// Increments coach insight count. Call ONLY after a successful AI response.
  Future<void> incrementCoachInsight(String uid) async {
    await _service.incrementCoachInsight(uid);
    state = state.copyWith(coachInsightCount: state.coachInsightCount + 1);
  }

  /// Increments plan count. Call ONLY after a successful plan generation.
  Future<void> incrementPlan(String uid) async {
    await _service.incrementPlan(uid);
    state = state.copyWith(planCount: state.planCount + 1);
  }

  /// Resets usage (on logout).
  void reset() {
    state = const UsageCounts();
  }
}
