import 'dart:convert';

bool _isEssentialDailyTask(String title) {
  final normalized = title.toLowerCase();
  const keywords = [
    'water',
    'hydrate',
    'hydration',
    'spf',
    'sunscreen',
    'skincare',
    'cleanse',
    'cleanser',
    'moisturiz',
    'hygiene',
    'brush',
    'floss',
    'shower',
    'face wash',
    'wash your face',
    'sleep',
    'wind-down',
    'wind down',
    'bedtime',
  ];
  return keywords.any(normalized.contains);
}

/// A single task within a day of the glow-up plan.
class PlanTask {
  const PlanTask({
    required this.id,
    required this.title,
    required this.category,
    this.description = '',
    this.isCompleted = false,
    this.completedAt,
  });

  final String id;
  final String title;
  final String category;
  final String description;
  final bool isCompleted;
  final DateTime? completedAt;

  PlanTask copyWith({bool? isCompleted, DateTime? completedAt}) {
    return PlanTask(
      id: id,
      title: title,
      category: category,
      description: description,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'description': description,
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
  };

  factory PlanTask.fromJson(Map<String, dynamic> json) {
    return PlanTask(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      isCompleted: json['isCompleted'] == true,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
    );
  }
}

/// A single day within a week of the plan.
class PlanDay {
  const PlanDay({required this.dayNumber, required this.tasks});

  final int dayNumber;
  final List<PlanTask> tasks;

  bool get isComplete => tasks.isNotEmpty && tasks.every((t) => t.isCompleted);

  int get completedCount => tasks.where((t) => t.isCompleted).length;

  double get progress => tasks.isEmpty ? 0 : completedCount / tasks.length;

  PlanDay copyWith({List<PlanTask>? tasks}) {
    return PlanDay(dayNumber: dayNumber, tasks: tasks ?? this.tasks);
  }

  Map<String, dynamic> toJson() => {
    'dayNumber': dayNumber,
    'tasks': tasks.map((t) => t.toJson()).toList(),
  };

  factory PlanDay.fromJson(Map<String, dynamic> json) {
    return PlanDay(
      dayNumber: (json['dayNumber'] as num?)?.toInt() ?? 0,
      tasks: (json['tasks'] as List<dynamic>? ?? const [])
          .map((t) => PlanTask.fromJson(Map<String, dynamic>.from(t as Map)))
          .toList(),
    );
  }
}

/// A week within the 30-day plan.
class PlanWeek {
  const PlanWeek({
    required this.weekNumber,
    required this.title,
    required this.goal,
    required this.focusAreas,
    required this.days,
    this.checkIn,
  });

  final int weekNumber;
  final String title;
  final String goal;
  final List<String> focusAreas;
  final List<PlanDay> days;
  final WeeklyCheckIn? checkIn;

  PlanWeek copyWith({WeeklyCheckIn? checkIn}) {
    return PlanWeek(
      weekNumber: weekNumber,
      title: title,
      goal: goal,
      focusAreas: focusAreas,
      days: days,
      checkIn: checkIn ?? this.checkIn,
    );
  }

  Map<String, dynamic> toJson() => {
    'weekNumber': weekNumber,
    'title': title,
    'goal': goal,
    'focusAreas': focusAreas,
    'days': days.map((d) => d.toJson()).toList(),
    'checkIn': checkIn?.toJson(),
  };

  factory PlanWeek.fromJson(Map<String, dynamic> json) {
    return PlanWeek(
      weekNumber: (json['weekNumber'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      goal: (json['goal'] ?? '').toString(),
      focusAreas: (json['focusAreas'] as List<dynamic>? ?? const [])
          .map((f) => f.toString())
          .toList(),
      days: (json['days'] as List<dynamic>? ?? const [])
          .map((d) => PlanDay.fromJson(Map<String, dynamic>.from(d as Map)))
          .toList(),
      checkIn: json['checkIn'] != null
          ? WeeklyCheckIn.fromJson(
              Map<String, dynamic>.from(json['checkIn'] as Map),
            )
          : null,
    );
  }
}

/// Weekly check-in feedback.
class WeeklyCheckIn {
  const WeeklyCheckIn({
    required this.weekNumber,
    required this.rating,
    this.notes = '',
    this.createdAt,
  });

  final int weekNumber;
  final String rating; // 😊 Great, 🙂 Good, 😐 Okay, 😓 Difficult
  final String notes;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
    'weekNumber': weekNumber,
    'rating': rating,
    'notes': notes,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory WeeklyCheckIn.fromJson(Map<String, dynamic> json) {
    return WeeklyCheckIn(
      weekNumber: (json['weekNumber'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

/// The full 30-day glow-up plan.
class GlowUpPlan {
  const GlowUpPlan({
    required this.planId,
    required this.userId,
    required this.createdAt,
    required this.weeks,
    this.currentWeek = 1,
    this.currentDay = 1,
    this.status = 'active',
    this.overview = '',
    this.goals = const [],
    this.styleId,
    this.styleName,
    this.faceScanSummary,
    this.generatedImagePath,
  });

  final String planId;
  final String userId;
  final DateTime createdAt;
  final List<PlanWeek> weeks;
  final int currentWeek;
  final int currentDay;
  final String status;
  final String overview;
  final List<String> goals;

  /// The look selected in the image-generation step, stored with this plan.
  final String? styleId;
  final String? styleName;

  /// Context used to personalize the plan; never displayed unless requested.
  final String? faceScanSummary;

  /// Path to the locally saved AI-generated glow-up preview image.
  final String? generatedImagePath;

  int get totalDays => weeks.fold(0, (sum, w) => sum + w.days.length);

  int get completedDays =>
      weeks.fold(0, (sum, w) => sum + w.days.where((d) => d.isComplete).length);

  double get progress => totalDays == 0 ? 0 : completedDays / totalDays;

  bool get hasMeaningfulDayVariation {
    final orderedDays = weeks.expand((week) => week.days).toList();
    if (orderedDays.length < 2) return true;

    for (var index = 1; index < orderedDays.length; index++) {
      final previous = orderedDays[index - 1].tasks
          .where((task) => !_isEssentialDailyTask(task.title))
          .map((task) => task.title.trim().toLowerCase())
          .toSet();
      final current = orderedDays[index].tasks
          .where((task) => !_isEssentialDailyTask(task.title))
          .map((task) => task.title.trim().toLowerCase())
          .toSet();

      if (previous.isEmpty || current.isEmpty) continue;
      final anyVariation = previous
          .union(current)
          .any(
            (value) => !previous.contains(value) || !current.contains(value),
          );
      if (!anyVariation) {
        return false;
      }
    }

    return true;
  }

  int get streak {
    final orderedDays = weeks.expand((week) => week.days).toList();
    if (orderedDays.isEmpty) return 0;

    var latestCompleteIndex = -1;
    for (var index = orderedDays.length - 1; index >= 0; index--) {
      if (orderedDays[index].isComplete) {
        latestCompleteIndex = index;
        break;
      }
    }

    if (latestCompleteIndex < 0) return 0;

    final latestCompletion = orderedDays[latestCompleteIndex].tasks
        .where((task) => task.completedAt != null)
        .map((task) => task.completedAt!)
        .fold<DateTime?>(null, (latest, date) {
          if (latest == null || date.isAfter(latest)) return date;
          return latest;
        });

    final referenceTime = latestCompletion ?? DateTime.now();
    if (DateTime.now().difference(referenceTime) > const Duration(hours: 24)) {
      return 0;
    }

    var streak = 0;
    for (var index = latestCompleteIndex; index >= 0; index--) {
      if (!orderedDays[index].isComplete) break;
      streak++;
    }
    return streak;
  }

  PlanWeek? get currentWeekData {
    if (weeks.isEmpty) return null;
    final index = (currentWeek - 1).clamp(0, weeks.length - 1);
    return weeks[index];
  }

  PlanDay? get currentDayData {
    final week = currentWeekData;
    if (week == null || week.days.isEmpty) return null;
    final index = (currentDay - 1).clamp(0, week.days.length - 1);
    return week.days[index];
  }

  GlowUpPlan copyWith({
    int? currentWeek,
    int? currentDay,
    String? status,
    List<PlanWeek>? weeks,
    String? styleId,
    String? styleName,
    String? faceScanSummary,
    String? generatedImagePath,
  }) {
    return GlowUpPlan(
      planId: planId,
      userId: userId,
      createdAt: createdAt,
      weeks: weeks ?? this.weeks,
      currentWeek: currentWeek ?? this.currentWeek,
      currentDay: currentDay ?? this.currentDay,
      status: status ?? this.status,
      overview: overview,
      goals: goals,
      styleId: styleId ?? this.styleId,
      styleName: styleName ?? this.styleName,
      faceScanSummary: faceScanSummary ?? this.faceScanSummary,
      generatedImagePath: generatedImagePath ?? this.generatedImagePath,
    );
  }

  Map<String, dynamic> toJson() => {
    'planId': planId,
    'userId': userId,
    'createdAt': createdAt.toIso8601String(),
    'weeks': weeks.map((w) => w.toJson()).toList(),
    'currentWeek': currentWeek,
    'currentDay': currentDay,
    'status': status,
    'overview': overview,
    'goals': goals,
    'styleId': styleId,
    'styleName': styleName,
    'faceScanSummary': faceScanSummary,
    'generatedImagePath': generatedImagePath,
  };

  factory GlowUpPlan.fromJson(Map<String, dynamic> json) {
    return GlowUpPlan(
      planId: (json['planId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      weeks: (json['weeks'] as List<dynamic>? ?? const [])
          .map((w) => PlanWeek.fromJson(Map<String, dynamic>.from(w as Map)))
          .toList(),
      currentWeek: (json['currentWeek'] as num?)?.toInt() ?? 1,
      currentDay: (json['currentDay'] as num?)?.toInt() ?? 1,
      status: (json['status'] ?? 'active').toString(),
      overview: (json['overview'] ?? '').toString(),
      goals: (json['goals'] as List<dynamic>? ?? const [])
          .map((g) => g.toString())
          .toList(),
      styleId: json['styleId']?.toString(),
      styleName: json['styleName']?.toString(),
      faceScanSummary: json['faceScanSummary']?.toString(),
      generatedImagePath: json['generatedImagePath']?.toString(),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory GlowUpPlan.fromJsonString(String raw) {
    return GlowUpPlan.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }
}
