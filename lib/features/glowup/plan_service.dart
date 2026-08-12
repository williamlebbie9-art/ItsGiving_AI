import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/decision_models.dart';
import '../../core/services/decision_engine.dart';
import 'glow_models.dart';
import 'plan_models.dart';

/// Manages the user's 30-day glow-up plan: generation, persistence,
/// progress tracking, and retrieval.
class PlanService {
  PlanService({DecisionEngine? engine}) : _engine = engine ?? DecisionEngine();

  final DecisionEngine _engine;
  static const _localPlanKey = 'glowup_current_plan';
  static const _localPlanHistoryKey = 'glowup_plan_history';
  static const _localUserIdKey = 'glowup_user_id';

  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString(_localUserIdKey);
    if (userId == null || userId.isEmpty) {
      userId = const Uuid().v4();
      await prefs.setString(_localUserIdKey, userId);
    }
    return userId;
  }

  /// Loads the current plan from local storage first (instant),
  /// then attempts a Firebase refresh in the background.
  Future<GlowUpPlan?> loadCurrentPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localPlanKey);
    GlowUpPlan? localPlan;
    if (raw != null && raw.isNotEmpty) {
      try {
        localPlan = GlowUpPlan.fromJsonString(raw);
      } catch (_) {
        localPlan = null;
      }
    }

    // Try Firebase for the freshest copy (background refresh).
    try {
      final userId = await _getUserId();
      final db = FirebaseDatabase.instance;
      final ref = db.ref('glowup_plans/$userId/current');
      final snapshot = await ref.get().timeout(const Duration(seconds: 8));
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final remotePlan = GlowUpPlan.fromJson(data);
        await prefs.setString(_localPlanKey, remotePlan.toJsonString());
        return remotePlan;
      }
    } catch (_) {
      // Firebase unavailable — fall back to local plan.
    }

    return localPlan;
  }

  /// Saves the plan to Firebase and local storage.
  Future<void> savePlan(GlowUpPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localPlanKey, plan.toJsonString());

    try {
      final userId = await _getUserId();
      final db = FirebaseDatabase.instance;
      await db
          .ref('glowup_plans/$userId/current')
          .set(plan.toJson())
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Local save succeeded; Firebase may be offline. Will sync later.
    }
  }

  /// Archives the current plan and stores it in history.
  Future<void> archiveCurrentPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localPlanKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final plan = GlowUpPlan.fromJsonString(raw);
      final archived = plan.copyWith(status: 'archived');
      final historyRaw = prefs.getString(_localPlanHistoryKey) ?? '[]';
      final history = (jsonDecode(historyRaw) as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      history.insert(0, archived.toJson());
      await prefs.setString(
        _localPlanHistoryKey,
        jsonEncode(history.take(10).toList()),
      );

      try {
        final userId = await _getUserId();
        final db = FirebaseDatabase.instance;
        await db
            .ref('glowup_plans/$userId/history/${plan.planId}')
            .set(archived.toJson())
            .timeout(const Duration(seconds: 8));
        await db.ref('glowup_plans/$userId/current').remove();
      } catch (_) {}
    } catch (_) {}
  }

  /// Returns the list of archived plans.
  Future<List<GlowUpPlan>> loadPlanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localPlanHistoryKey) ?? '[]';
    try {
      return (jsonDecode(raw) as List<dynamic>? ?? const [])
          .map((e) => GlowUpPlan.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Generates a personalized 30-day plan using the user's onboarding
  /// profile and optional face-scan summary. Returns structured data.
  Future<GlowUpPlan> generatePlan({
    required GlowUserProfile profile,
    String? faceScanSummary,
  }) async {
    final userId = await _getUserId();
    final planId = const Uuid().v4();

    final profileContext = _buildProfileContext(profile);
    final faceContext = faceScanSummary != null && faceScanSummary.isNotEmpty
        ? 'Face scan analysis: $faceScanSummary\n'
        : '';

    final prompt =
        'Create a personalized 30-day glow-up program for this user.\n'
        '$profileContext'
        '$faceContext'
        '\n'
        'Return STRICT JSON with this exact structure:\n'
        '{\n'
        '  "overview": "2-3 sentence summary of the program",\n'
        '  "goals": ["goal 1", "goal 2", "goal 3"],\n'
        '  "weeks": [\n'
        '    {\n'
        '      "weekNumber": 1,\n'
        '      "title": "Foundation",\n'
        '      "goal": "Clear weekly objective",\n'
        '      "focusAreas": ["Skin", "Hair", "Fitness", "Style", "Lifestyle"],\n'
        '      "days": [\n'
        '        {\n'
        '          "dayNumber": 1,\n'
        '          "tasks": [\n'
        '            {"id": "w1d1t1", "title": "Morning skincare routine", "category": "Morning", "description": "Cleanse, tone, moisturize, SPF"},\n'
        '            {"id": "w1d1t2", "title": "Drink your hydration target", "category": "Lifestyle", "description": "2L of water"},\n'
        '            {"id": "w1d1t3", "title": "20-minute movement", "category": "Fitness", "description": "Walk, stretch, or workout"},\n'
        '            {"id": "w1d1t4", "title": "Grooming task", "category": "Appearance", "description": "Brows, hair, or grooming"},\n'
        '            {"id": "w1d1t5", "title": "5-minute confidence exercise", "category": "Mindset", "description": "Affirmation or journaling"}\n'
        '          ]\n'
        '        }\n'
        '      ]\n'
        '    }\n'
        '  ]\n'
        '}\n'
        '\n'
        'RULES:\n'
        '- 4 weeks: Week 1 "Foundation" (days 1-7), Week 2 "Build" (days 8-14), '
        'Week 3 "Elevate" (days 15-21), Week 4 "Refine" (days 22-30).\n'
        '- Each week has exactly 7 days (last week has 9 days: 22-30).\n'
        '- Each day has 4-6 realistic tasks across Morning, Lifestyle, Fitness, Appearance, Mindset.\n'
        '- Tasks must be personalized to the user\'s goal, skin type, exercise level, sleep, vibe, and lifestyle.\n'
        '- Tasks must be realistic and not overwhelming.\n'
        '- Use unique task IDs like w1d1t1, w1d2t1, w2d1t1, etc.\n'
        '- Do NOT return markdown, code fences, or extra text. Return ONLY valid JSON.';

    final result = await _engine.decide(
      DecisionRequest(query: prompt, manualCategory: DecisionCategory.glowup),
    );

    final plan = _parsePlanFromResult(
      result: result,
      planId: planId,
      userId: userId,
      profile: profile,
    );

    await savePlan(plan);
    return plan;
  }

  GlowUpPlan _parsePlanFromResult({
    required DecisionResult result,
    required String planId,
    required String userId,
    required GlowUserProfile profile,
  }) {
    final json = _extractJson(result.reasoning);
    if (json != null) {
      try {
        final weeks = _parseWeeks(json['weeks']);
        if (weeks.isNotEmpty) {
          return GlowUpPlan(
            planId: planId,
            userId: userId,
            createdAt: DateTime.now(),
            weeks: weeks,
            overview: (json['overview'] ?? '').toString(),
            goals: (json['goals'] as List<dynamic>? ?? const [])
                .map((g) => g.toString())
                .toList(),
          );
        }
      } catch (_) {}
    }
    return _buildFallbackPlan(planId: planId, userId: userId, profile: profile);
  }

  Map<String, dynamic>? _extractJson(String raw) {
    if (raw.isEmpty) return null;
    final trimmed = raw.trim();
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}

    final fenceMatch = RegExp(
      r'```(?:json)?\s*([\s\S]*?)```',
    ).firstMatch(trimmed);
    if (fenceMatch != null) {
      try {
        final decoded = jsonDecode(fenceMatch.group(1)!.trim());
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }

    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start >= 0 && end > start) {
      try {
        final decoded = jsonDecode(trimmed.substring(start, end + 1));
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  List<PlanWeek> _parseWeeks(dynamic weeksRaw) {
    if (weeksRaw is! List) return const [];
    final weeks = <PlanWeek>[];

    for (final weekRaw in weeksRaw) {
      if (weekRaw is! Map) continue;
      final weekMap = Map<String, dynamic>.from(weekRaw);
      final weekNumber = (weekMap['weekNumber'] as num?)?.toInt() ?? 0;
      final daysRaw = weekMap['days'];
      if (daysRaw is! List) continue;

      final days = <PlanDay>[];
      for (final dayRaw in daysRaw) {
        if (dayRaw is! Map) continue;
        final dayMap = Map<String, dynamic>.from(dayRaw);
        final dayNumber = (dayMap['dayNumber'] as num?)?.toInt() ?? 0;
        final tasksRaw = dayMap['tasks'];
        if (tasksRaw is! List) continue;

        final tasks = <PlanTask>[];
        for (final taskRaw in tasksRaw) {
          if (taskRaw is! Map) continue;
          final taskMap = Map<String, dynamic>.from(taskRaw);
          tasks.add(
            PlanTask(
              id: (taskMap['id'] ?? '').toString(),
              title: (taskMap['title'] ?? '').toString(),
              category: (taskMap['category'] ?? '').toString(),
              description: (taskMap['description'] ?? '').toString(),
            ),
          );
        }
        if (tasks.isNotEmpty) {
          days.add(PlanDay(dayNumber: dayNumber, tasks: tasks));
        }
      }

      if (days.isNotEmpty) {
        weeks.add(
          PlanWeek(
            weekNumber: weekNumber,
            title: (weekMap['title'] ?? 'Week $weekNumber').toString(),
            goal: (weekMap['goal'] ?? '').toString(),
            focusAreas: (weekMap['focusAreas'] as List<dynamic>? ?? const [])
                .map((f) => f.toString())
                .toList(),
            days: days,
          ),
        );
      }
    }
    return weeks;
  }

  String _buildProfileContext(GlowUserProfile profile) {
    return [
      if (profile.goal != null) 'Goal: ${profile.goal}',
      if (profile.skincareRoutine != null)
        'Current skincare: ${profile.skincareRoutine}',
      if (profile.exerciseFrequency != null)
        'Exercise: ${profile.exerciseFrequency}',
      if (profile.sleepSchedule != null) 'Sleep: ${profile.sleepSchedule}',
      if (profile.aesthetic != null) 'Desired vibe: ${profile.aesthetic}',
      if (profile.skinType != null) 'Skin type: ${profile.skinType}',
      if (profile.lifestyle != null) 'Lifestyle: ${profile.lifestyle}',
    ].join('\n');
  }

  GlowUpPlan _buildFallbackPlan({
    required String planId,
    required String userId,
    required GlowUserProfile profile,
  }) {
    final goal = profile.goal ?? 'Complete transformation';
    final skinType = profile.skinType ?? 'Combination';
    final exercise = profile.exerciseFrequency ?? '1-2 times a week';
    final vibe = profile.aesthetic ?? 'Clean girl';
    final lifestyle = profile.lifestyle ?? 'Balanced';

    final weekTitles = ['Foundation', 'Build', 'Elevate', 'Refine'];
    final weekGoals = [
      'Build a consistent skincare and lifestyle foundation.',
      'Strengthen your daily habits and increase the challenge.',
      'Elevate your grooming, style, and confidence.',
      'Refine your routine and lock in lasting results.',
    ];

    final weeks = <PlanWeek>[];
    var globalDay = 1;

    for (var w = 0; w < 4; w++) {
      final daysInWeek = w == 3 ? 9 : 7;
      final days = <PlanDay>[];

      for (var d = 0; d < daysInWeek; d++) {
        final dayNum = globalDay++;
        final tasks = <PlanTask>[
          PlanTask(
            id: 'w${w + 1}d${d + 1}t1',
            title: 'Morning skincare routine',
            category: 'Morning',
            description:
                'Cleanse, tone, moisturize, and apply SPF. Focus on $skinType skin needs.',
          ),
          PlanTask(
            id: 'w${w + 1}d${d + 1}t2',
            title: 'Drink your hydration target',
            category: 'Lifestyle',
            description: 'Aim for 2L of water throughout the day.',
          ),
          PlanTask(
            id: 'w${w + 1}d${d + 1}t3',
            title: d % 2 == 0 ? '20-minute movement' : '15-minute walk',
            category: 'Fitness',
            description:
                'Based on your $exercise baseline. Keep it enjoyable and consistent.',
          ),
          PlanTask(
            id: 'w${w + 1}d${d + 1}t4',
            title: 'Grooming task',
            category: 'Appearance',
            description:
                'Brows, hair, or grooming detail to elevate your $vibe look.',
          ),
          PlanTask(
            id: 'w${w + 1}d${d + 1}t5',
            title: '5-minute confidence exercise',
            category: 'Mindset',
            description:
                'Affirmation, journaling, or posture practice. Your glow starts within.',
          ),
        ];
        days.add(PlanDay(dayNumber: dayNum, tasks: tasks));
      }

      weeks.add(
        PlanWeek(
          weekNumber: w + 1,
          title: weekTitles[w],
          goal: weekGoals[w],
          focusAreas: const ['Skin', 'Hair', 'Fitness', 'Style', 'Lifestyle'],
          days: days,
        ),
      );
    }

    return GlowUpPlan(
      planId: planId,
      userId: userId,
      createdAt: DateTime.now(),
      weeks: weeks,
      overview:
          'A personalized 30-day glow-up program built around your $goal goal, '
          '$vibe aesthetic, and $lifestyle lifestyle.',
      goals: [goal, 'Build lasting confidence', 'Create consistent habits'],
    );
  }

  /// Marks a task as completed/uncompleted and persists the change.
  Future<GlowUpPlan> toggleTask({
    required GlowUpPlan plan,
    required int weekNumber,
    required int dayNumber,
    required String taskId,
  }) async {
    final weeks = plan.weeks.map((week) {
      if (week.weekNumber != weekNumber) return week;
      final days = week.days.map((day) {
        if (day.dayNumber != dayNumber) return day;
        final tasks = day.tasks.map((task) {
          if (task.id != taskId) return task;
          final now = DateTime.now();
          return task.copyWith(
            isCompleted: !task.isCompleted,
            completedAt: task.isCompleted ? null : now,
          );
        }).toList();
        return day.copyWith(tasks: tasks);
      }).toList();
      return PlanWeek(
        weekNumber: week.weekNumber,
        title: week.title,
        goal: week.goal,
        focusAreas: week.focusAreas,
        days: days,
        checkIn: week.checkIn,
      );
    }).toList();

    var nextWeek = plan.currentWeek;
    var nextDay = plan.currentDay;
    final currentWeekData = weeks
        .where((w) => w.weekNumber == plan.currentWeek)
        .firstOrNull;
    final currentDayData = currentWeekData?.days
        .where((d) => d.dayNumber == plan.currentDay)
        .firstOrNull;
    if (currentDayData != null && currentDayData.isComplete) {
      final allDays = <(int, int)>[];
      for (final week in weeks) {
        for (final day in week.days) {
          allDays.add((week.weekNumber, day.dayNumber));
        }
      }
      final currentIndex = allDays.indexWhere(
        (e) => e.$1 == plan.currentWeek && e.$2 == plan.currentDay,
      );
      if (currentIndex >= 0 && currentIndex < allDays.length - 1) {
        final next = allDays[currentIndex + 1];
        nextWeek = next.$1;
        nextDay = next.$2;
      }
    }

    final updated = plan.copyWith(
      weeks: weeks,
      currentWeek: nextWeek,
      currentDay: nextDay,
    );
    await savePlan(updated);
    return updated;
  }

  /// Records a weekly check-in.
  Future<GlowUpPlan> submitWeeklyCheckIn({
    required GlowUpPlan plan,
    required int weekNumber,
    required String rating,
    String notes = '',
  }) async {
    final weeks = plan.weeks.map((week) {
      if (week.weekNumber != weekNumber) return week;
      return week.copyWith(
        checkIn: WeeklyCheckIn(
          weekNumber: weekNumber,
          rating: rating,
          notes: notes,
          createdAt: DateTime.now(),
        ),
      );
    }).toList();

    final updated = plan.copyWith(weeks: weeks);
    await savePlan(updated);
    return updated;
  }
}
