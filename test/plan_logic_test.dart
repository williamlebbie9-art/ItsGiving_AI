import 'package:flutter_test/flutter_test.dart';
import 'package:its_giving_ai/features/glowup/plan_models.dart';

void main() {
  group('GlowUpPlan logic', () {
    test('streak resets after 24 hours of missed completion', () {
      final now = DateTime.now();
      final plan = GlowUpPlan(
        planId: 'streak-check',
        userId: 'user-1',
        createdAt: now.subtract(const Duration(days: 2)),
        weeks: [
          PlanWeek(
            weekNumber: 1,
            title: 'Foundation',
            goal: 'Build consistency',
            focusAreas: const ['Skin'],
            days: [
              PlanDay(
                dayNumber: 1,
                tasks: [
                  const PlanTask(
                    id: 'd1t1',
                    title: 'Hydration goal',
                    category: 'Lifestyle',
                    description: 'Drink more water',
                    isCompleted: true,
                  ).copyWith(
                    completedAt: DateTime.now().subtract(
                      const Duration(hours: 30),
                    ),
                  ),
                ],
              ),
              PlanDay(
                dayNumber: 2,
                tasks: [
                  const PlanTask(
                    id: 'd2t1',
                    title: 'Hydration goal',
                    category: 'Lifestyle',
                    description: 'Drink more water',
                    isCompleted: true,
                  ).copyWith(
                    completedAt: DateTime.now().subtract(
                      const Duration(hours: 25),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      expect(plan.streak, 0);
    });

    test(
      'duplicate routine across consecutive days is flagged as low variation',
      () {
        final plan = GlowUpPlan(
          planId: 'variation-check',
          userId: 'user-1',
          createdAt: DateTime.now(),
          weeks: [
            PlanWeek(
              weekNumber: 1,
              title: 'Foundation',
              goal: 'Build consistency',
              focusAreas: const ['Skin'],
              days: [
                PlanDay(
                  dayNumber: 1,
                  tasks: const [
                    PlanTask(
                      id: 'd1t1',
                      title: 'Morning skincare routine',
                      category: 'Morning',
                      description: 'Cleanse, tone, moisturize, SPF',
                    ),
                    PlanTask(
                      id: 'd1t2',
                      title: 'Hydration goal',
                      category: 'Lifestyle',
                      description: 'Drink more water',
                    ),
                    PlanTask(
                      id: 'd1t3',
                      title: 'Gentle walk',
                      category: 'Fitness',
                      description: 'A simple walk for energy',
                    ),
                  ],
                ),
                PlanDay(
                  dayNumber: 2,
                  tasks: const [
                    PlanTask(
                      id: 'd2t1',
                      title: 'Morning skincare routine',
                      category: 'Morning',
                      description: 'Cleanse, tone, moisturize, SPF',
                    ),
                    PlanTask(
                      id: 'd2t2',
                      title: 'Hydration goal',
                      category: 'Lifestyle',
                      description: 'Drink more water',
                    ),
                    PlanTask(
                      id: 'd2t3',
                      title: 'Gentle walk',
                      category: 'Fitness',
                      description: 'A simple walk for energy',
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

        expect(plan.hasMeaningfulDayVariation, isFalse);
      },
    );

    test(
      'a genuinely varied plan preserves a meaningful day-to-day change',
      () {
        final plan = GlowUpPlan(
          planId: 'variation-good',
          userId: 'user-1',
          createdAt: DateTime.now(),
          weeks: [
            PlanWeek(
              weekNumber: 1,
              title: 'Foundation',
              goal: 'Build consistency',
              focusAreas: const ['Skin'],
              days: [
                PlanDay(
                  dayNumber: 1,
                  tasks: const [
                    PlanTask(
                      id: 'd1t1',
                      title: 'Hydration goal',
                      category: 'Lifestyle',
                      description: 'Drink more water',
                    ),
                    PlanTask(
                      id: 'd1t2',
                      title: 'Gentle walk',
                      category: 'Fitness',
                      description: 'A simple walk for energy',
                    ),
                  ],
                ),
                PlanDay(
                  dayNumber: 2,
                  tasks: const [
                    PlanTask(
                      id: 'd2t1',
                      title: 'Hydration goal',
                      category: 'Lifestyle',
                      description: 'Drink more water',
                    ),
                    PlanTask(
                      id: 'd2t2',
                      title: 'HIIT cardio session',
                      category: 'Fitness',
                      description: 'Short intervals to improve endurance',
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

        expect(plan.hasMeaningfulDayVariation, isTrue);
      },
    );
  });
}
