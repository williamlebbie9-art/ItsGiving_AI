import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Free-tier usage limits per user.
class FreeLimits {
  static const int maxFaceScans = 1;
  static const int maxCoachInsights = 3;
  static const int maxPlans = 1;
}

/// Tracks per-user AI usage under `users/{uid}/usage`.
///
/// Usage is only incremented AFTER a successful AI operation. Failed
/// requests must NOT consume usage.
class UsageService {
  UsageService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// Returns the current usage counts for the given UID.
  Future<UsageCounts> getUsage(String uid) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('usage')
          .doc('counts')
          .get();
      if (!doc.exists) {
        return const UsageCounts();
      }
      final data = doc.data() ?? const {};
      return UsageCounts(
        faceScanCount: (data['faceScanCount'] as num?)?.toInt() ?? 0,
        coachInsightCount: (data['coachInsightCount'] as num?)?.toInt() ?? 0,
        planCount: (data['planCount'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      debugPrint('[Usage] Could not load usage: $e');
      return const UsageCounts();
    }
  }

  /// Increments the face scan count. Call ONLY after a successful AI scan.
  Future<void> incrementFaceScan(String uid) async {
    await _increment(uid, 'faceScanCount');
  }

  /// Increments the coach insight count. Call ONLY after a successful AI response.
  Future<void> incrementCoachInsight(String uid) async {
    await _increment(uid, 'coachInsightCount');
  }

  /// Increments the plan count. Call ONLY after a successful plan generation.
  Future<void> incrementPlan(String uid) async {
    await _increment(uid, 'planCount');
  }

  Future<void> _increment(String uid, String field) async {
    try {
      final ref = _db
          .collection('users')
          .doc(uid)
          .collection('usage')
          .doc('counts');
      await ref.set({field: FieldValue.increment(1)}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Usage] Could not increment $field: $e');
    }
  }

  /// Whether the user can perform another face scan.
  bool canFaceScan({required UsageCounts usage, required bool isPremium}) {
    if (isPremium) return true;
    return usage.faceScanCount < FreeLimits.maxFaceScans;
  }

  /// Whether the user can get another AI Coach insight.
  bool canCoachInsight({required UsageCounts usage, required bool isPremium}) {
    if (isPremium) return true;
    return usage.coachInsightCount < FreeLimits.maxCoachInsights;
  }

  /// Whether the user can create another plan.
  bool canCreatePlan({required UsageCounts usage, required bool isPremium}) {
    if (isPremium) return true;
    return usage.planCount < FreeLimits.maxPlans;
  }
}

/// Per-user usage counts.
class UsageCounts {
  const UsageCounts({
    this.faceScanCount = 0,
    this.coachInsightCount = 0,
    this.planCount = 0,
  });

  final int faceScanCount;
  final int coachInsightCount;
  final int planCount;

  UsageCounts copyWith({
    int? faceScanCount,
    int? coachInsightCount,
    int? planCount,
  }) {
    return UsageCounts(
      faceScanCount: faceScanCount ?? this.faceScanCount,
      coachInsightCount: coachInsightCount ?? this.coachInsightCount,
      planCount: planCount ?? this.planCount,
    );
  }
}
