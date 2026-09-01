import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'glow_models.dart';
import 'plan_models.dart';
import 'plan_service.dart';

/// Holds the current plan state and loading/error status.
class PlanState {
  const PlanState({
    this.plan,
    this.isLoading = false,
    this.isGenerating = false,
    this.error,
  });

  final GlowUpPlan? plan;
  final bool isLoading;
  final bool isGenerating;
  final String? error;

  PlanState copyWith({
    GlowUpPlan? plan,
    bool? isLoading,
    bool? isGenerating,
    String? error,
    bool clearError = false,
  }) {
    return PlanState(
      plan: plan ?? this.plan,
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PlanNotifier extends StateNotifier<PlanState> {
  PlanNotifier(this._service, this._ref) : super(const PlanState());

  final PlanService _service;
  final Ref _ref;

  /// Loads the current plan. Shows local data instantly, then refreshes
  /// from Firebase in the background.
  Future<void> loadPlan() async {
    if (state.plan != null) {
      // Already have a plan — do a background refresh.
      _refreshFromFirebase();
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final plan = await _service.loadCurrentPlan();
      if (plan != null) {
        state = state.copyWith(plan: plan, isLoading: false);
        // Background refresh for the freshest copy.
        _refreshFromFirebase();
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'We couldn\'t load your glow-up plan.',
      );
    }
  }

  Future<void> _refreshFromFirebase() async {
    try {
      final plan = await _service.loadCurrentPlan();
      if (plan != null && mounted) {
        state = state.copyWith(plan: plan);
      }
    } catch (_) {
      // Keep the local plan; background refresh failed silently.
    }
  }

  /// Generates a new personalized plan.
  ///
  /// Works even without authentication — the plan service persists locally
  /// using a local user ID fallback. Usage is only incremented AFTER a
  /// successful plan generation, and only when the user is authenticated.
  Future<bool> generatePlan({
    required GlowUserProfile profile,
    String? faceScanSummary,
    String? styleId,
    String? styleName,
    String? generatedImagePath,
  }) async {
    // Enforce the free plan limit (1 plan) unless the user is premium.
    final isPremium = _ref.read(subscriptionProvider).isPremium;
    final usage = _ref.read(usageProvider);
    if (!isPremium && usage.planCount >= 1) {
      state = state.copyWith(
        isGenerating: false,
        error:
            'You\'ve used your free glow-up plan. Upgrade to Premium for unlimited plans.',
      );
      return false;
    }

    state = state.copyWith(isGenerating: true, clearError: true);
    try {
      final plan = await _service.generatePlan(
        profile: profile,
        faceScanSummary: faceScanSummary,
        styleId: styleId,
        styleName: styleName,
        generatedImagePath: generatedImagePath,
      );
      // The backend owns usage accounting. Refresh its count for the UI.
      final uid = _ref.read(authServiceProvider).currentUid;
      if (uid != null) {
        await _ref.read(usageProvider.notifier).load(uid);
      }
      state = state.copyWith(plan: plan, isGenerating: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: 'We couldn\'t generate your plan. Please try again.',
      );
      return false;
    }
  }

  /// Toggles a task completion and persists.
  Future<void> toggleTask({
    required int weekNumber,
    required int dayNumber,
    required String taskId,
  }) async {
    final plan = state.plan;
    if (plan == null) return;

    try {
      final updated = await _service.toggleTask(
        plan: plan,
        weekNumber: weekNumber,
        dayNumber: dayNumber,
        taskId: taskId,
      );
      state = state.copyWith(plan: updated);
    } catch (_) {
      // Keep the current state; persistence failed silently.
    }
  }

  /// Submits a weekly check-in.
  Future<void> submitWeeklyCheckIn({
    required int weekNumber,
    required String rating,
    String notes = '',
  }) async {
    final plan = state.plan;
    if (plan == null) return;

    try {
      final updated = await _service.submitWeeklyCheckIn(
        plan: plan,
        weekNumber: weekNumber,
        rating: rating,
        notes: notes,
      );
      state = state.copyWith(plan: updated);
    } catch (_) {}
  }

  /// Archives the current plan (for "Create a new plan" flow).
  Future<void> archiveCurrentPlan() async {
    await _service.archiveCurrentPlan();
    state = state.copyWith(plan: null);
  }

  Future<void> activatePlan(GlowUpPlan plan) async {
    final active = await _service.activatePlan(plan);
    state = state.copyWith(plan: active, clearError: true);
  }

  /// Archives an individual plan (from history) via the service.
  Future<void> archivePlan(GlowUpPlan plan) async {
    await _service.archivePlan(plan);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final planServiceProvider = Provider<PlanService>((ref) => PlanService());

final planProvider = StateNotifierProvider<PlanNotifier, PlanState>(
  (ref) => PlanNotifier(ref.watch(planServiceProvider), ref),
);
