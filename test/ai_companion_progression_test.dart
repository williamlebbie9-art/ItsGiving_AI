import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:its_giving_ai/features/glowup/ai_companion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI companion progression', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('awards XP once for the same event id', () async {
      final service = CompanionProgressionService();
      final before = await service.load();
      final first = await service.awardXp('task_completed_test_1', 25);
      final second = await service.awardXp('task_completed_test_1', 25);

      expect(before.xp, 0);
      expect(first.xp, 25);
      expect(second.xp, 25);
      expect(second.recentEvents.contains('task_completed_test_1'), isTrue);
    });

    test('levels up and exposes unlockable cosmetics', () async {
      final service = CompanionProgressionService();
      final state = await service.awardXp('milestone_1', 180);

      expect(state.level, greaterThanOrEqualTo(2));
      expect(state.unlocks, isNotEmpty);
      expect(state.mood, isNotEmpty);
    });

    test(
      'rewards real app actions like plan generation and wardrobe review',
      () async {
        final service = CompanionProgressionService();
        final planState = await service.awardPlanGenerated();
        final wardrobeState = await service.awardWardrobeReview();
        final coachState = await service.awardCoachInsight();

        expect(planState.xp, greaterThan(0));
        expect(wardrobeState.xp, greaterThan(0));
        expect(coachState.xp, greaterThan(0));
      },
    );

    test(
      'falls into a sad mood when a streak is lost and keeps an unlocked accessory selected',
      () async {
        final service = CompanionProgressionService();
        final base = await service.awardXp('unlock_test', 150);
        final unlocked = await service.setSelectedAccessory(
          'soft glam accessory',
        );
        final sad = await service.applyStreakLoss();

        expect(base.unlocks, contains('soft glam accessory'));
        expect(unlocked.selectedAccessory, 'soft glam accessory');
        expect(sad.mood, 'sad');
        expect(sad.selectedAccessory, 'soft glam accessory');
      },
    );
  });
}
