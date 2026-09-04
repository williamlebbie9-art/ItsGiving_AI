import 'glow_models.dart';
import 'plan_models.dart';

/// Anti-duplication and day-variety logic for the 30-day glow-up plan.
///
/// This file contains three pieces:
///
/// 1. [isEssentialDailyTask] — distinguishes genuinely daily habits (water,
///    basic skincare, SPF, hygiene, sleep/wind-down) from rotating activities.
///    Essential tasks are allowed to repeat on consecutive days.
///
/// 2. [ensurePlanVariety] — a post-generation validation layer. After the AI
///    returns a plan it detects repeated non-essential tasks on consecutive
///    days (or an identical routine copied across days) and swaps the
///    duplicates for profile-derived alternatives from the rotation pools.
///
/// 3. [buildFallbackWeeks] — a deterministic, genuinely varied 30-day plan
///    used when the AI call fails, built from the same pools so it stays
///    personalized to the user's onboarding + face-scan profile.

/// Normalizes a title for duplication checks (lowercase, alphanumeric only).
String _normalize(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

/// Returns true when a task is a genuinely daily habit.
///
/// These habits MAY repeat on consecutive days by design:
/// water/hydration, basic skincare + SPF, basic hygiene, sleep/wind-down.
/// Everything else is considered a rotating activity that must vary.
bool isEssentialDailyTask(PlanTask task) {
  final title = ('${task.title} ${task.category}').toLowerCase();
  const keywords = [
    'water',
    'hydrate',
    'hydration',
    'spf',
    'sunscreen',
    'skincare',
    'cleanse',
    'cleanser',
    'moisturis',
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
  return keywords.any(title.contains);
}

/// Maps an arbitrary task category to one of the rotation-pool keys.
String _categoryKey(String category) {
  final c = category.toLowerCase();
  if (c.contains('fit') ||
      c.contains('workout') ||
      c.contains('movement') ||
      c.contains('stretch') ||
      c.contains('recovery') ||
      c.contains('exercise')) {
    return 'fitness';
  }
  if (c.contains('skin')) return 'skin';
  if (c.contains('hair') ||
      c.contains('appearance') ||
      c.contains('groom') ||
      c.contains('style') ||
      c.contains('body')) {
    return 'hair';
  }
  if (c.contains('mind') ||
      c.contains('confid') ||
      c.contains('self') ||
      c.contains('mental')) {
    return 'mind';
  }
  return 'lifestyle';
}

/// A single option in a rotation pool.
class PoolItem {
  const PoolItem(this.title, this.description);

  final String title;
  final String description;
}

/// All rotation pools for one user profile.
class RotationPools {
  const RotationPools({
    required this.fitness,
    required this.recovery,
    required this.skin,
    required this.hair,
    required this.mind,
    required this.lifestyle,
  });

  final List<PoolItem> fitness;
  final List<PoolItem> recovery;
  final List<PoolItem> skin;
  final List<PoolItem> hair;
  final List<PoolItem> mind;
  final List<PoolItem> lifestyle;

  List<PoolItem> poolFor(String key) {
    switch (key) {
      case 'fitness':
        return fitness;
      case 'recovery':
        return recovery;
      case 'skin':
        return skin;
      case 'hair':
        return hair;
      case 'mind':
        return mind;
      default:
        return lifestyle;
    }
  }
}

/// Builds the rotation pools personalized from the user's profile.
RotationPools buildRotationPools(GlowUserProfile profile) {
  final exercise = (profile.exerciseFrequency ?? '').toLowerCase();
  final skinType = (profile.skinType ?? '').toLowerCase();
  final vibe = (profile.aesthetic ?? '').toLowerCase();
  final goal = (profile.goal ?? '').toLowerCase();
  final lifestyle = (profile.lifestyle ?? '').toLowerCase();
  final sleep = (profile.sleepSchedule ?? '').toLowerCase();

  // --- Fitness pool (keyed by the user's current exercise level) ---
  final List<PoolItem> fitness;
  if (exercise.contains('5+')) {
    fitness = const [
      PoolItem(
        '45-minute strength session',
        'Push your strength with compound lifts and a focused cool-down.',
      ),
      PoolItem(
        'High-intensity interval cardio',
        'Short sprints and body-weight circuits to elevate your heart rate.',
      ),
      PoolItem(
        'Lower-body power day',
        'Squats, lunges, and glute work to sculpt and strengthen the lower body.',
      ),
      PoolItem(
        'Upper-body push day',
        'Push-ups, presses, and rows to build balanced upper-body strength.',
      ),
      PoolItem(
        'Runs or cycling intervals',
        'Alternate effort and recovery intervals for an efficient sweat session.',
      ),
    ];
  } else if (exercise.contains('3-4')) {
    fitness = const [
      PoolItem(
        '30-minute strength training',
        'Full-body strength work that fits your regular training rhythm.',
      ),
      PoolItem(
        'HIIT cardio session',
        '20-30 minutes of interval cardio to build endurance.',
      ),
      PoolItem(
        'Lower-body strength day',
        'Target legs and glutes to balance your routine.',
      ),
      PoolItem(
        'Upper-body & core day',
        'Tone arms, back, and core with controlled reps.',
      ),
      PoolItem(
        'Active recovery walk + gentle stretch',
        'A lighter day to keep blood flowing without overdoing it.',
      ),
      PoolItem(
        'Pilates or barre flow',
        'Low-impact, high-control movements for posture and core.',
      ),
    ];
  } else if (exercise.contains('1-2')) {
    fitness = const [
      PoolItem(
        '20-minute full-body workout',
        'A steady full-body session that builds on your 1-2 day baseline.',
      ),
      PoolItem(
        'Upper-body toning session',
        'Light weights or resistance bands for arms and shoulders.',
      ),
      PoolItem(
        'Lower-body strength session',
        'Grounded squats and lunges to build confidence and strength.',
      ),
      PoolItem(
        'Cardio + core circuit',
        'Mix walking/running with core holds to build stamina.',
      ),
      PoolItem(
        'Yoga or mobility flow',
        'Gentle yoga that improves flexibility and posture.',
      ),
      PoolItem(
        'Posture & stretching routine',
        'Targeted stretches to undo desk slump and open the chest.',
      ),
    ];
  } else {
    fitness = const [
      PoolItem(
        '10-minute beginner workout',
        'A gentle, doable first session that builds the habit without overwhelm.',
      ),
      PoolItem(
        'Gentle full-body mobility',
        'Slow, deliberate movements to wake up your body and joints.',
      ),
      PoolItem(
        'Easy 15-minute walk',
        'A confidence-building daily walk to get moving.',
      ),
      PoolItem(
        'Posture reset exercises',
        'Simple chest-openers and shoulder rolls for better posture.',
      ),
      PoolItem(
        'Light yoga flow',
        'Beginner yoga sequences to relax and increase flexibility.',
      ),
    ];
  }

  // --- Recovery pool (rotated every few days) ---
  const recovery = [
    PoolItem(
      'Recovery & stretching routine',
      'A full-body stretch session to help muscles recover and reset.',
    ),
    PoolItem(
      'Restorative mobility flow',
      'Slow mobility work for hips, shoulders, and spine.',
    ),
    PoolItem(
      'Slow calming yoga',
      'Low-intensity yoga to unwind and support recovery.',
    ),
    PoolItem(
      'Foam rolling + deep stretch',
      'Release tight muscles and improve flexibility.',
    ),
    PoolItem(
      'Easy walk + breathing practice',
      'Gentle movement paired with deep, calming breaths.',
    ),
    PoolItem(
      'Full-body relaxation stretch',
      'End-of-day stretches that promote better sleep.',
    ),
  ];

  // --- Skin-care treatment pool (keyed by skin type) ---
  final List<PoolItem> skin;
  if (skinType.contains('oil')) {
    skin = const [
      PoolItem(
        'Gentle clay mask',
        'Draws out excess oil without stripping your barrier.',
      ),
      PoolItem(
        'Balancing hydration focus',
        'Lightweight hydration that keeps oil in check.',
      ),
      PoolItem(
        'Salicylic-acid pore care evening',
        'Gentle deep-cleaning actives for oily skin.',
      ),
      PoolItem(
        'Steam + gentle cleanse facial',
        'Warm steam followd by a soft cleanse to clear pores.',
      ),
    ];
  } else if (skinType.contains('dry')) {
    skin = const [
      PoolItem(
        'Overnight hydrating mask',
        'Wake up with plumper, calmer skin.',
      ),
      PoolItem(
        'Hyaluronic acid hydration boost',
        'Draws moisture into the skin for a dewy finish.',
      ),
      PoolItem(
        'Facial oil + moisturizer massage',
        'Locks in hydration and supports your moisture barrier.',
      ),
      PoolItem('Oatmeal calming mask', 'Soothes dry, tight-feeling skin.'),
    ];
  } else if (skinType.contains('sens')) {
    skin = const [
      PoolItem(
        'Oatmeal soothing mask',
        'A calming, fragrance-free treatment for sensitive skin.',
      ),
      PoolItem(
        'Cooling aloe vera gel mask',
        'Reduces redness and soothes irritation.',
      ),
      PoolItem(
        'Patch-test a gentle serum',
        'Introduce one new soothing serum the gentle way.',
      ),
      PoolItem(
        'Fragrance-free hydration focus',
        'Simple, minimal-ingredient moisture for calmer skin.',
      ),
    ];
  } else if (skinType.contains('normal')) {
    skin = const [
      PoolItem(
        'Gentle exfoliation session',
        'Polishes away dullness for a brighter glow.',
      ),
      PoolItem('Hydrating sheet mask', 'An instant moisture + radiance boost.'),
      PoolItem(
        'Facial massage + gua sha',
        'Boosts circulation and de-puffs naturally.',
      ),
      PoolItem(
        'Vitamin C glow boost',
        'Brightens skin tone with natural citrus-based serums.',
      ),
    ];
  } else {
    // Combination, "not sure", or unset.
    skin = const [
      PoolItem(
        'Balancing clay mask (T-zone only)',
        'Treats the oilier zones while leaving dry areas calm.',
      ),
      PoolItem(
        'Gentle exfoliating facial',
        'Softly smooths skin texture across the whole face.',
      ),
      PoolItem(
        'Hydration + balance routine',
        'A gentle routine that hydrates without feeling heavy.',
      ),
      PoolItem(
        'Gentle beginner face mask',
        'A safe, simple mask to ease into skin treatments.',
      ),
      PoolItem(
        'Soft facial massage',
        'Wake up face muscles and boost circulation.',
      ),
    ];
  }

  // --- Hair + body/appearance pool (keyed by the user's desired vibe) ---
  final List<PoolItem> hair;
  if (vibe.contains('clean')) {
    hair = const [
      PoolItem(
        'Sleek ponytail or bun styling',
        'An effortless polished look that protects your hair ends.',
      ),
      PoolItem('Brow tidy & shape', 'Neat, natural brows that frame the face.'),
      PoolItem(
        'Scalp massage + hair oil',
        'Boosts circulation and nourishes the hairline.',
      ),
      PoolItem(
        'Full-body moisturizing routine',
        'Body care that keeps skin soft and glowing.',
      ),
    ];
  } else if (vibe.contains('soft')) {
    hair = const [
      PoolItem(
        'Soft waves styling session',
        'Heatless or low-heat waves for a feminine finish.',
      ),
      PoolItem(
        'Hair oiling + scalp massage',
        'A nourishing ritual for softer, healthier hair.',
      ),
      PoolItem(
        'Hair accessories styling',
        'Ribbons, bows, or clips to elevate a simple style.',
      ),
      PoolItem(
        'Body butter application routine',
        'Rich moisture for soft, kempt skin.',
      ),
    ];
  } else if (vibe.contains('old') || vibe.contains('money')) {
    hair = const [
      PoolItem(
        'Classic blowout practice',
        'Smooth, elegant styling that reads polished.',
      ),
      PoolItem(
        'Elegant low bun styling',
        'A refined up-do that looks expensive in seconds.',
      ),
      PoolItem(
        'Brow definition + shaping',
        'Subtle definition for an elegant silhouette.',
      ),
      PoolItem(
        'Silk wrap hair protection',
        'Protects hair overnight for a glossy finish.',
      ),
    ];
  } else if (vibe.contains('glam') || vibe.contains('femin')) {
    hair = const [
      PoolItem(
        'Volume lift styling',
        'Adds body and movement for a glamorous finish.',
      ),
      PoolItem(
        'Heatless curls prep',
        'Set soft curls overnight with zero heat damage.',
      ),
      PoolItem(
        'Brow + lash grooming',
        'Polishes your features for a camera-ready look.',
      ),
      PoolItem(
        'Hair mask or oil treatment',
        'Deep-nourishes hair for extra shine.',
      ),
    ];
  } else if (vibe.contains('sport')) {
    hair = const [
      PoolItem(
        'Low ponytail + headband reset',
        'A sporty, quick style that stays put.',
      ),
      PoolItem(
        'Scalp refresh + dry shampoo reset',
        'Keeps hair fresh between washes.',
      ),
      PoolItem(
        'Post-workout hair care routine',
        'Cleanses sweat and re-hydrates hair after training.',
      ),
      PoolItem(
        'Full-body care after training',
        'Moisturize and stretch to keep skin and muscles happy.',
      ),
    ];
  } else if (vibe.contains('minimal')) {
    hair = const [
      PoolItem(
        'Clean part + sleek strands',
        'Effortless, low-maintenance polish.',
      ),
      PoolItem('Low-effort polished bun', 'Tidy hair in under five minutes.'),
      PoolItem('Scalp care + light massage', 'Simple, grounding hair ritual.'),
      PoolItem(
        'Subtle body glow routine',
        'Light moisturizing for a natural sheen.',
      ),
    ];
  } else {
    hair = const [
      PoolItem(
        'Hair care + scalp massage',
        'Nourish hair and scalp to support healthy growth.',
      ),
      PoolItem('Brow tidy & shape', 'Clean, natural brows frame every look.'),
      PoolItem(
        'Hair mask or oil treatment',
        'Deep nourishment for shine and softness.',
      ),
      PoolItem(
        'Full-body moisturizing routine',
        'Body care for soft, glowing skin.',
      ),
      PoolItem(
        'Dry brushing session',
        'Boosts circulation and smooths skin texture.',
      ),
    ];
  }

  // --- Mindset / self-care pool (keyed by the user's main goal) ---
  final List<PoolItem> mind;
  if (goal.contains('confid')) {
    mind = const [
      PoolItem(
        '5-minute confidence journaling',
        'Write one win and one thing you love about yourself.',
      ),
      PoolItem(
        'Positive affirmation practice',
        'Repeat three affirmations that reframe your self-talk.',
      ),
      PoolItem(
        'Posture & presence exercise',
        'Stand tall, speak slowly, and take up space on purpose.',
      ),
      PoolItem(
        'Mirror-work affirmation',
        'Look yourself in the eye and say something kind.',
      ),
      PoolItem(
        'Visualization of your best self',
        'Picture the confident version of you living your day.',
      ),
    ];
  } else {
    mind = const [
      PoolItem(
        '10-minute mindful breathing',
        'Calms the nervous system and resets your focus.',
      ),
      PoolItem(
        'Evening gratitude reflection',
        'Note three good things from the day.',
      ),
      PoolItem(
        '5-minute journaling session',
        'Clear your mind and track your glow-up progress.',
      ),
      PoolItem(
        'Self-talk reset exercise',
        'Catch one negative thought and gently reframe it.',
      ),
      PoolItem(
        'Relaxing self-care evening',
        'Tea, low lights, and a quiet activity just for you.',
      ),
    ];
  }

  // --- Lifestyle pool (keyed by lifestyle, sleep, and goal) ---
  final lifestyleOptions = <PoolItem>[
    const PoolItem(
      'Herbal tea wind-down',
      'Chamomile or green tea to unwind without the caffeine.',
    ),
    const PoolItem(
      'Prep a glow-boosting snack',
      'Fresh fruit, nuts, or veggies that support skin and hair.',
    ),
    const PoolItem(
      'Screen-free wind-down',
      'Put the phone away 30 minutes before bed.',
    ),
    const PoolItem(
      'Antioxidant-rich meal moment',
      'Add greens or berries to one meal for an inside-out glow.',
    ),
    const PoolItem(
      '10-minute decompression walk',
      'A short walk to clear your head and get some light.',
    ),
  ];
  if (lifestyle.contains('student') || lifestyle.contains('busy')) {
    lifestyleOptions.addAll(const [
      PoolItem(
        'Quick study-break stretch',
        'A 5-minute reset between study or work blocks.',
      ),
      PoolItem(
        'Caffeine cut-off by 3pm',
        'Protects your sleep without giving up your coffee ritual.',
      ),
    ]);
  } else if (lifestyle.contains('professional') ||
      lifestyle.contains('work') ||
      lifestyle.contains('office')) {
    lifestyleOptions.addAll(const [
      PoolItem(
        'Desk posture reset',
        'Re-angle your chair and screen, then roll your shoulders.',
      ),
      PoolItem(
        'Evening digital sunset',
        'Swap one hour of screens for a calming activity.',
      ),
    ]);
  }
  if (sleep.contains('less') || sleep.contains('<') || sleep.contains('6')) {
    lifestyleOptions.addAll(const [
      PoolItem(
        'Sleep optimization: blackout prep',
        'Dim lights and prep a dark, cool bedroom for better sleep.',
      ),
      PoolItem(
        'Wind-down: lights out at 9pm',
        'Start your sleep routine 30 minutes earlier than usual.',
      ),
    ]);
  }
  if (lifestyle.contains('athlete') ||
      lifestyle.contains('gym') ||
      lifestyle.contains('active')) {
    lifestyleOptions.addAll(const [
      PoolItem(
        'Post-workout protein + hydration',
        'Refuel within an hour of training for recovery.',
      ),
      PoolItem(
        'Muscle recovery stretch',
        'A short stretch focusing on the muscles you trained.',
      ),
    ]);
  }
  if (goal.contains('skin')) {
    lifestyleOptions.add(
      const PoolItem(
        'Skin-support food swap',
        'Swap one snack for an antioxidant-rich option (berries, greens).',
      ),
    );
  }
  if (goal.contains('hair')) {
    lifestyleOptions.add(
      const PoolItem(
        'Hair-support nutrition moment',
        'Add a protein or biotin-rich food to one meal.',
      ),
    );
  }

  return RotationPools(
    fitness: fitness,
    recovery: recovery,
    skin: skin,
    hair: hair,
    mind: mind,
    lifestyle: lifestyleOptions,
  );
}

/// Steps through a rotation pool one entry at a time, avoiding recently used
/// titles so a category never repeats on consecutive days.
class _Rotator {
  _Rotator(this.pool);

  final List<PoolItem> pool;
  int _lastIndex = -1;

  PoolItem? next({Set<String>? avoid}) {
    if (pool.isEmpty) return null;
    final avoidTitles = avoid ?? const <String>{};
    if (avoidTitles.isEmpty) {
      _lastIndex = (_lastIndex + 1) % pool.length;
      return pool[_lastIndex];
    }
    for (var step = 1; step <= pool.length; step++) {
      final index = (_lastIndex + step) % pool.length;
      final candidate = pool[index];
      if (!avoidTitles.contains(_normalize(candidate.title))) {
        _lastIndex = index;
        return candidate;
      }
    }
    _lastIndex = (_lastIndex + 1) % pool.length;
    return pool[_lastIndex];
  }
}

/// Post-generation validation.
///
/// Detects non-essential tasks that repeat on consecutive days (including
/// full routines copied verbatim across days) and replaces them with
/// profile-derived alternatives. Essential daily habits are left untouched.
bool hasMeaningfulDayVariation(List<PlanWeek> weeks) {
  final orderedDays = weeks.expand((week) => week.days).toList();
  if (orderedDays.length < 2) return true;

  for (var index = 1; index < orderedDays.length; index++) {
    final previous = orderedDays[index - 1].tasks
        .where((task) => !isEssentialDailyTask(task))
        .map((task) => _normalize(task.title))
        .toSet();
    final current = orderedDays[index].tasks
        .where((task) => !isEssentialDailyTask(task))
        .map((task) => _normalize(task.title))
        .toSet();

    if (previous.isEmpty || current.isEmpty) continue;
    final anyVariation = previous
        .union(current)
        .any((value) => !previous.contains(value) || !current.contains(value));
    if (!anyVariation) {
      return false;
    }
  }

  return true;
}

List<PlanWeek> ensurePlanVariety(
  List<PlanWeek> weeks,
  GlowUserProfile profile,
) {
  if (weeks.isEmpty) return weeks;
  final pools = buildRotationPools(profile);
  final rotators = <String, _Rotator>{};
  // normalized rotating title -> most recent global day position (0-based)
  final lastSeenByTitle = <String, int>{};
  // categoryKey -> normalized title -> most recent day position
  final recentByCategory = <String, Map<String, int>>{};

  final result = <PlanWeek>[];
  var globalPos = 0;

  for (final week in weeks) {
    final newDays = <PlanDay>[];
    for (final day in week.days) {
      final newTasks = <PlanTask>[];
      final seenThisDay = <String>{};

      for (final task in day.tasks) {
        if (isEssentialDailyTask(task)) {
          newTasks.add(task);
          continue;
        }

        final titleNorm = _normalize(task.title);
        final lastGlobal = lastSeenByTitle[titleNorm];
        final repeatedConsecutive =
            lastGlobal != null && (globalPos - lastGlobal) <= 1;
        final repeatedWithinDay = seenThisDay.contains(titleNorm);

        PlanTask effective = task;
        if (repeatedConsecutive || repeatedWithinDay) {
          final categoryKey = _categoryKey(task.category);
          final recent = recentByCategory[categoryKey] ?? const <String, int>{};
          final avoid = <String>{...recent.keys, ...seenThisDay};
          final rotator = rotators[categoryKey] ??= _Rotator(
            pools.poolFor(categoryKey),
          );
          final replacement = rotator.next(avoid: avoid);
          if (replacement != null) {
            effective = PlanTask(
              id: task.id,
              title: replacement.title,
              category: task.category,
              description: replacement.description,
            );
            final replNorm = _normalize(replacement.title);
            lastSeenByTitle[replNorm] = globalPos;
            (recentByCategory[categoryKey] ??= {})[replNorm] = globalPos;
          }
        }

        newTasks.add(effective);
        lastSeenByTitle[_normalize(effective.title)] = globalPos;
        (recentByCategory[_categoryKey(effective.category)] ??= {})[_normalize(
              effective.title,
            )] =
            globalPos;
        seenThisDay.add(_normalize(effective.title));
      }

      newDays.add(PlanDay(dayNumber: day.dayNumber, tasks: newTasks));
      globalPos++;
    }

    result.add(
      PlanWeek(
        weekNumber: week.weekNumber,
        title: week.title,
        goal: week.goal,
        focusAreas: week.focusAreas,
        days: newDays,
        checkIn: week.checkIn,
      ),
    );
  }
  return result;
}

/// Returns the 1-based week number for a global day (1..30) in 7-day blocks.
int _weekNumber(int globalDay) => ((globalDay - 1) ~/ 7) + 1;

/// Chooses the rotating "slot B" category for a day, tuned by the user's goal.
String _slotBCategory(GlowUserProfile profile, int dayNumber) {
  final goal = (profile.goal ?? '').toLowerCase();
  const generic = ['hair', 'mind', 'skin', 'lifestyle'];
  if (goal.contains('skin')) {
    const sequence = ['skin', 'skin', 'hair', 'mind'];
    return sequence[(dayNumber - 1) % sequence.length];
  }
  if (goal.contains('hair')) {
    const sequence = ['hair', 'hair', 'skin', 'mind'];
    return sequence[(dayNumber - 1) % sequence.length];
  }
  if (goal.contains('fit')) {
    const sequence = ['mind', 'lifestyle', 'hair', 'skin'];
    return sequence[(dayNumber - 1) % sequence.length];
  }
  if (goal.contains('confid')) {
    const sequence = ['mind', 'mind', 'hair', 'skin'];
    return sequence[(dayNumber - 1) % sequence.length];
  }
  return generic[(dayNumber - 1) % generic.length];
}

/// Builds a deterministic, varied 30-day fallback plan from the user profile.
///
/// Every day keeps the truly daily anchors (morning skincare, hydration,
/// evening hygiene/sleep) and rotates fitness/recovery + a goal-tuned
/// secondary activity (hair, skin treatment, mindset, or lifestyle), so no
/// two consecutive days share the same non-essential routine.
List<PlanWeek> buildFallbackWeeks(GlowUserProfile profile) {
  final pools = buildRotationPools(profile);
  final fitness = _Rotator(pools.fitness);
  final recovery = _Rotator(pools.recovery);
  final skin = _Rotator(pools.skin);
  final hair = _Rotator(pools.hair);
  final mind = _Rotator(pools.mind);
  final lifestyle = _Rotator(pools.lifestyle);

  const weekTitles = ['Foundation', 'Build', 'Elevate', 'Refine'];
  const weekGoals = [
    'Build a consistent skincare and lifestyle foundation.',
    'Strengthen daily habits and increase the challenge.',
    'Elevate grooming, style, and confidence.',
    'Refine your routine and lock in lasting results.',
  ];

  final weeks = <PlanWeek>[];
  var globalDay = 1;
  for (var w = 0; w < 4; w++) {
    final daysInWeek = w == 3 ? 9 : 7;
    final days = <PlanDay>[];
    for (var d = 0; d < daysInWeek; d++) {
      final dayNumber = globalDay++;
      final isRecovery = dayNumber % 3 == 0;
      final slotB = isRecovery ? 'mind' : _slotBCategory(profile, dayNumber);

      final tasks = <PlanTask>[
        PlanTask(
          id: 'd${dayNumber}t1',
          title: 'Morning skincare routine',
          category: 'Morning',
          description:
              'Cleanse, tone, moisturize, and apply SPF. Focus on '
              '${profile.skinType ?? 'combination'} skin needs.',
        ),
        PlanTask(
          id: 'd${dayNumber}t2',
          title: 'Hydration goal',
          category: 'Lifestyle',
          description: 'Aim for 2L of water today — hydration is glow fuel.',
        ),
      ];

      // Rotating slot A — fitness or recovery.
      final slotARotator = isRecovery ? recovery : fitness;
      final slotAItem = slotARotator.next();
      tasks.add(
        PlanTask(
          id: 'd${dayNumber}t3',
          title: slotAItem?.title ?? 'Fitness focus',
          category: 'Fitness',
          description:
              slotAItem?.description ??
              (isRecovery
                  ? 'Rest and stretch so your body can rebuild stronger.'
                  : 'Move your body in a way that feels good for your level.'),
        ),
      );

      // Rotating slot B — goal-tuned category.
      final slotBRotator = switch (slotB) {
        'skin' => skin,
        'hair' => hair,
        'mind' => mind,
        _ => lifestyle,
      };
      final slotBItem = slotBRotator.next();
      final slotBCategory = switch (slotB) {
        'skin' => 'Skin',
        'hair' => 'Appearance',
        'mind' => 'Mindset',
        _ => 'Lifestyle',
      };
      tasks.add(
        PlanTask(
          id: 'd${dayNumber}t4',
          title: slotBItem?.title ?? 'Mindset focus',
          category: slotBCategory,
          description: slotBItem?.description ?? 'A mindful moment for today.',
        ),
      );

      // Occasional lifestyle extra (naturally varied).
      final lifestyleItem = lifestyle.next();
      tasks.add(
        PlanTask(
          id: 'd${dayNumber}t5',
          title: lifestyleItem?.title ?? 'Screen-free wind-down',
          category: 'Lifestyle',
          description:
              lifestyleItem?.description ?? 'Ease out of the day calmly.',
        ),
      );

      // Evening anchor — lightly rotated phrasing but always a daily habit.
      final windDown = _eveningWindDown(dayNumber, profile);
      tasks.add(
        PlanTask(
          id: 'd${dayNumber}t6',
          title: windDown.title,
          category: 'Evening',
          description: windDown.description,
        ),
      );

      days.add(PlanDay(dayNumber: dayNumber, tasks: tasks));
    }

    weeks.add(
      PlanWeek(
        weekNumber: _weekNumber(globalDay - daysInWeek),
        title: weekTitles[w],
        goal: weekGoals[w],
        focusAreas: const ['Skin', 'Hair', 'Fitness', 'Style', 'Lifestyle'],
        days: days,
      ),
    );
  }
  return weeks;
}

/// A daily evening anchor that rotates phrasing but stays a daily habit.
({String title, String description}) _eveningWindDown(
  int dayNumber,
  GlowUserProfile profile,
) {
  final sleep = profile.sleepSchedule ?? 'a consistent bedtime';
  final values = [
    (
      title: 'Evening cleanse + wind-down',
      description:
          'Wash your face, brush and floss, then dim the lights before bed.',
    ),
    (
      title: 'Nightly hygiene + sleep prep',
      description:
          'Face cleanse, oral hygiene, and a calm bedroom signal it is time to sleep.',
    ),
    (
      title: 'Bedtime routine practice',
      description:
          'Consistent hygiene steps help you fall asleep faster — aim for $sleep.',
    ),
  ];
  return values[(dayNumber - 1) % values.length];
}
