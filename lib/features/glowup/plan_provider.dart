import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  PlanNotifier(this._service) : super(const PlanState());

  final PlanService _service;

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
  Future<bool> generatePlan({
    required GlowUserProfile profile,
    String? faceScanSummary,
  }) async {
    state = state.copyWith(isGenerating: true, clearError: true);
    try {
      final plan = await _service.generatePlan(
        profile: profile,
        faceScanSummary: faceScanSummary,
      );
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

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final planServiceProvider = Provider<PlanService>((ref) => PlanService());

final planProvider = StateNotifierProvider<PlanNotifier, PlanState>(
  (ref) => PlanNotifier(ref.watch(planServiceProvider)),
);
