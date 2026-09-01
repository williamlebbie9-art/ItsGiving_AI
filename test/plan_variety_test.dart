import 'package:flutter_test/flutter_test.dart';

import 'package:its_giving_ai/features/glowup/glow_models.dart';
import 'package:its_giving_ai/features/glowup/plan_models.dart';
import 'package:its_giving_ai/features/glowup/plan_variety.dart';

/// Collects every task across all weeks/days in plan order.
List<PlanTask> allTasks(List<PlanWeek> weeks) =>
    [for (final w in weeks) for (final d in w.days) ...d.tasks];

/// The non-essential task titles for a single day (essentials excluded).
List<String> nonEssentialTitles(PlanDay day) => day.tasks
    .where((t) => !isEssentialDailyTask(t))
    .map((t) => t.title.trim().toLowerCase())
    .toList();

/// The essential task titles for a single day.
List<String> essentialTitles(PlanDay day) => day.tasks
    .where(isEssentialDailyTask)
    .map((t) => t.title.trim().toLowerCase())
    .toList();

void main() {
  const beginnerProfile = GlowUserProfile(
    goal: 'Clearer-looking skin',
    skincareRoutine: 'None — I don\'t have one',
    exerciseFrequency: 'Rarely or never',
    sleepSchedule: 'Less than 6 hours',
    aesthetic: 'Clean girl',
    skinType: 'Dry',
    lifestyle: 'Busy student',
  );

  const advancedProfile = GlowUserProfile(
    goal: 'Fitness/body goals',
    skincareRoutine: 'Advanced multi-step routine',
    exerciseFrequency: '5+ times a week',
    sleepSchedule: '8+ hours',
    aesthetic: 'Sporty',
    skinType: 'Oily',
    lifestyle: 'Athletic',
  );

  group('buildFallbackWeeks', () {
    test('produces 30 days across 4 weeks with daily anchors recurring', () {
      final weeks = buildFallbackWeeks(beginnerProfile);

      expect(weeks, hasLength(4));
      expect([for (final w in weeks) w.days.length], [7, 7, 7, 9]);
      final tasks = allTasks(weeks);
      expect(tasks, hasLength(30 * 6));

      // Hydration (a genuinely daily habit) appears every single day.
      final hydrationDays = weeks
          .where(
            (w) => w.days.every(
              (d) => d.tasks.any(
                (t) => t.title.toLowerCase().contains('hydration'),
              ),
            ),
          )
          .length;
      expect(hydrationDays, 4, reason: 'hydration must recur every day');

      // Morning skincare also recurs daily.
      for (final w in weeks) {
        for (final d in w.days) {
          expect(
            essentialTitles(d).any((t) => t.contains('skincare')),
            isTrue,
            reason: 'every day must keep a skincare anchor',
          );
        }
      }
    });

    test('no two consecutive days are exact copies', () {
      final weeks = buildFallbackWeeks(beginnerProfile);
      final days = [for (final w in weeks) ...w.days];

      for (var i = 1; i < days.length; i++) {
        expect(
          nonEssentialTitles(days[i]),
          isNot(equals(nonEssentialTitles(days[i - 1]))),
          reason: 'Day ${days[i].dayNumber} copied '
              'Day ${days[i - 1].dayNumber}\'s routine',
        );
      }
    });

    test('non-essential fitness/routines vary on consecutive days', () {
      final weeks = buildFallbackWeeks(beginnerProfile);
      final days = [for (final w in weeks) ...w.days];

      for (var i = 1; i < days.length; i++) {
        final prev = nonEssentialTitles(days[i - 1]);
        final curr = nonEssentialTitles(days[i]);
        for (final title in curr) {
          expect(
            prev,
            isNot(contains(title)),
            reason: 'non-essential task "$title" repeated on consecutive days '
                '(${days[i - 1].dayNumber} -> ${days[i].dayNumber})',
          );
        }
      }
    });

    test('recovery/rest days are included after workout days', () {
      final weeks = buildFallbackWeeks(beginnerProfile);
      final allTitles = [
        for (final w in weeks)
          for (final d in w.days)
            for (final t in d.tasks) t.title.toLowerCase(),
      ];
      expect(
        allTitles.any(
          (t) => t.contains('recovery') || t.contains('stretch'),
        ),
        isTrue,
        reason: 'plan should include recovery/stretching days',
      );
    });

    test('personalizes to the user profile, not a fixed routine', () {
      final beginner = buildFallbackWeeks(beginnerProfile);
      final advanced = buildFallbackWeeks(advancedProfile);

      final beginnerFitness = beginner.first.days.first.tasks
          .where((t) => t.category.toLowerCase().contains('fit'))
          .map((t) => t.title)
          .toList();
      final advancedFitness = advanced.first.days.first.tasks
          .where((t) => t.category.toLowerCase().contains('fit'))
          .map((t) => t.title)
          .toList();

      expect(beginnerFitness, isNotEmpty);
      expect(advancedFitness, isNotEmpty);
      expect(
        beginnerFitness.join(' | '),
        isNot(contains(advancedFitness.first)),
        reason:
            'a beginner and an advanced user should not get the same first '
            'workout',
      );
    });
  });
group('ensurePlanVariety', () {
    PlanDay duplicateDay(int dayNumber) => PlanDay(
          dayNumber: dayNumber,
          tasks: const [
            PlanTask(
              id: 't1',
              title: 'Morning skincare routine',
              category: 'Morning',
              description: 'Cleanse, tone, moisturize, SPF',
            ),
            PlanTask(
              id: 't2',
              title: 'Hydration goal',
              category: 'Lifestyle',
              description: 'Aim for 2L of water',
            ),
            PlanTask(
              id: 't3',
              title: '20-minute workout',
              category: 'Fitness',
              description: 'Full body session',
            ),
            PlanTask(
              id: 't4',
              title: 'Hair care',
              category: 'Appearance',
              description: 'Nourish hair and scalp',
            ),
            PlanTask(
              id: 't5',
              title: 'Confidence journaling',
              category: 'Mindset',
              description: 'Write three wins',
            ),
          ],
        );

    List<PlanWeek> duplicatedPlan() => List.generate(
          3,
          (w) => PlanWeek(
            weekNumber: w + 1,
            title: 'Week ${w + 1}',
            goal: 'Goal',
            focusAreas: const ['Skin'],
            days: List.generate(7, (d) => duplicateDay(w * 7 + d + 1)),
          ),
        );

    test('flags and corrects a fully duplicated plan', () {
      final corrected = ensurePlanVariety(duplicatedPlan(), beginnerProfile);
      final days = [for (final w in corrected) ...w.days];

      expect(days, hasLength(21), reason: 'all days must be preserved');

      for (var i = 1; i < days.length; i++) {
        expect(
          nonEssentialTitles(days[i]),
          isNot(equals(nonEssentialTitles(days[i - 1]))),
          reason: 'consecutive days must not be exact copies after correction',
        );
      }
    });

    test('essential daily habits remain on every day', () {
      final corrected = ensurePlanVariety(duplicatedPlan(), beginnerProfile);

      for (final week in corrected) {
        for (final day in week.days) {
          expect(
            essentialTitles(day).any((t) => t.contains('skincare')),
            isTrue,
            reason: 'skincare anchor must survive validation',
          );
          expect(
            essentialTitles(day).any((t) => t.contains('hydration')),
            isTrue,
            reason: 'hydration anchor must survive validation',
          );
        }
      }
    });

    test('repeated non-essential tasks are rotated, not dropped', () {
      final corrected = ensurePlanVariety(duplicatedPlan(), beginnerProfile);
      final days = [for (final w in corrected) ...w.days];
      final first = nonEssentialTitles(days.first);
      final second = nonEssentialTitles(days[1]);

      expect(first, isNotEmpty);
      expect(second, isNotEmpty);
      expect(
        second,
        isNot(equals(first)),
        reason: 'day 2 should be swapped, not blank, after validation',
      );
    });

    test('left empty weeks unchanged', () {
      expect(ensurePlanVariety(const [], beginnerProfile), isEmpty);
    });
  });

  group('plan JSON round-trip (fallback plan)', () {
    test('serializes and deserializes without data loss', () {
      final weeks = buildFallbackWeeks(beginnerProfile);
      final plan = GlowUpPlan(
        planId: 'plan-1',
        userId: 'user-1',
        createdAt: DateTime(2026),
        weeks: weeks,
      );

      final restored = GlowUpPlan.fromJson(plan.toJson());

      expect(restored.totalDays, 30);
      expect(restored.weeks, hasLength(4));
      expect(restored.weeks.first.days.first.tasks, hasLength(6));
      expect(
        restored.weeks.first.days.first.tasks.first.title,
        plan.weeks.first.days.first.tasks.first.title,
      );
    });
  });
}
