import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Free-tier usage limits per user.
class FreeLimits {
  static const int maxFaceScans = 1;
  static const int maxCoachInsights = 3;
  static const int maxPlans = 1;

  /// Glow-up images a free user may generate per calendar month.
  static const int maxGlowUpImagesPerMonth = 1;
}

/// Premium usage limits. Operations not listed here are unlimited for premium.
class PremiumLimits {
  /// Glow-up images a premium user may generate per calendar month.
  static const int maxGlowUpImagesPerMonth = 20;
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
      // Glow-up images are a monthly bucket: counts stored under a previous
      // month are reported as zero so the pre-check agrees with the server.
      final glowUpImageMonth = data['glowUpImageMonth'] as String?;
      final isCurrentGlowUpMonth = glowUpImageMonth == _currentMonthKey();
      return UsageCounts(
        faceScanCount: (data['faceScanCount'] as num?)?.toInt() ?? 0,
        coachInsightCount: (data['coachInsightCount'] as num?)?.toInt() ?? 0,
        planCount: (data['planCount'] as num?)?.toInt() ?? 0,
        glowUpImageCount: isCurrentGlowUpMonth
            ? (data['glowUpImageCount'] as num?)?.toInt() ?? 0
            : 0,
        glowUpImageMonth: isCurrentGlowUpMonth ? glowUpImageMonth : null,
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

  /// Whether the user can generate another glow-up image this calendar month.
  /// Free users get 1 image per month; premium users get 20 per month.
  bool canGenerateGlowUpImage({
    required UsageCounts usage,
    required bool isPremium,
  }) {
    final limit = isPremium
        ? PremiumLimits.maxGlowUpImagesPerMonth
        : FreeLimits.maxGlowUpImagesPerMonth;
    final usedThisMonth = usage.glowUpImageMonth == _currentMonthKey()
        ? usage.glowUpImageCount
        : 0;
    return usedThisMonth < limit;
  }

  /// UTC "YYYY-MM" key for the current monthly quota window. Matches the
  /// server's window so the client pre-check agrees with the backend.
  static String _currentMonthKey() {
    final now = DateTime.now().toUtc();
    final month = now.month.toString().padLeft(2, '0');
    return '${now.year}-$month';
  }
}

/// Per-user usage counts.
class UsageCounts {
  const UsageCounts({
    this.faceScanCount = 0,
    this.coachInsightCount = 0,
    this.planCount = 0,
    this.glowUpImageCount = 0,
    this.glowUpImageMonth,
  });

  final int faceScanCount;
  final int coachInsightCount;
  final int planCount;

  /// Glow-up images generated in the current monthly window.
  final int glowUpImageCount;

  /// "YYYY-MM" window that [glowUpImageCount] belongs to (UTC). A null or
  /// stale month means the allowance has reset.
  final String? glowUpImageMonth;

  UsageCounts copyWith({
    int? faceScanCount,
    int? coachInsightCount,
    int? planCount,
    int? glowUpImageCount,
    String? glowUpImageMonth,
  }) {
    return UsageCounts(
      faceScanCount: faceScanCount ?? this.faceScanCount,
      coachInsightCount: coachInsightCount ?? this.coachInsightCount,
      planCount: planCount ?? this.planCount,
      glowUpImageCount: glowUpImageCount ?? this.glowUpImageCount,
      glowUpImageMonth: glowUpImageMonth ?? this.glowUpImageMonth,
    );
  }
}
