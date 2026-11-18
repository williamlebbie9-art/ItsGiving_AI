import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompanionAccessory {
  const CompanionAccessory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    this.secondaryColor = const Color(0xFFB97AA7),
    this.requiresLevel = 1,
    this.description = '',
    this.vibe = 'soft girl',
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final Color secondaryColor;
  final int requiresLevel;
  final String description;
  final String vibe;
}

const List<CompanionAccessory> companionAccessories = [
  CompanionAccessory(
    id: 'starter glow',
    label: 'Starter glow',
    icon: Icons.auto_awesome_rounded,
    color: Color(0xFFFFD8EA),
    secondaryColor: Color(0xFFEA7BB7),
    requiresLevel: 1,
    description: 'A soft peach-golden glow for your everyday vibe.',
    vibe: 'soft girl',
  ),
  CompanionAccessory(
    id: 'soft glam accessory',
    label: 'Soft glam',
    icon: Icons.diamond_rounded,
    color: Color(0xFFE9D5FF),
    secondaryColor: Color(0xFF9A74D3),
    requiresLevel: 2,
    description: 'A luxe, glossy finish that makes her look all dressed up.',
    vibe: 'soft girl',
  ),
  CompanionAccessory(
    id: 'celebration sparkle',
    label: 'Sparkle',
    icon: Icons.star_rounded,
    color: Color(0xFFFFF3B0),
    secondaryColor: Color(0xFFE0A41F),
    requiresLevel: 3,
    description: 'A radiant party sparkle that matches her win streak.',
    vibe: 'soft girl',
  ),
  CompanionAccessory(
    id: 'berry blush',
    label: 'Berry blush',
    icon: Icons.favorite_rounded,
    color: Color(0xFFFFC4D9),
    secondaryColor: Color(0xFFB85E8E),
    requiresLevel: 4,
    description: 'A sweet, flirty little blush dress for premium glow days.',
    vibe: 'soft girl',
  ),
  CompanionAccessory(
    id: 'old money pearls',
    label: 'Old money pearls',
    icon: Icons.workspace_premium_rounded,
    color: Color(0xFFEADCC8),
    secondaryColor: Color(0xFFB88A5C),
    requiresLevel: 2,
    description: 'Warm ivory tones and a polished, rich-girl finish.',
    vibe: 'old money',
  ),
  CompanionAccessory(
    id: 'old money blazer',
    label: 'Old money blazer',
    icon: Icons.style_rounded,
    color: Color(0xFFC7B9A5),
    secondaryColor: Color(0xFF7B5B4B),
    requiresLevel: 4,
    description: 'Tailored, elegant, and a little posh when she wants to be.',
    vibe: 'old money',
  ),
  CompanionAccessory(
    id: 'clean girl gloss',
    label: 'Clean girl gloss',
    icon: Icons.auto_fix_high_rounded,
    color: Color(0xFFDDE8FF),
    secondaryColor: Color(0xFF8AA7D3),
    requiresLevel: 3,
    description: 'Fresh, polished, and extra effortless for everyday wins.',
    vibe: 'clean girl',
  ),
];

class CompanionMood {
  const CompanionMood({
    required this.name,
    required this.emoji,
    required this.message,
  });

  final String name;
  final String emoji;
  final String message;
}

class CompanionProgressState {
  const CompanionProgressState({
    required this.xp,
    required this.level,
    required this.mood,
    required this.unlocks,
    required this.recentEvents,
    required this.selectedAccessory,
  });

  final int xp;
  final int level;
  final String mood;
  final List<String> unlocks;
  final List<String> recentEvents;
  final String selectedAccessory;

  static const int xpPerLevel = 100;

  CompanionProgressState copyWith({
    int? xp,
    int? level,
    String? mood,
    List<String>? unlocks,
    List<String>? recentEvents,
    String? selectedAccessory,
  }) {
    return CompanionProgressState(
      xp: xp ?? this.xp,
      level: level ?? this.level,
      mood: mood ?? this.mood,
      unlocks: unlocks ?? this.unlocks,
      recentEvents: recentEvents ?? this.recentEvents,
      selectedAccessory: selectedAccessory ?? this.selectedAccessory,
    );
  }

  static CompanionProgressState empty() => const CompanionProgressState(
    xp: 0,
    level: 1,
    mood: 'neutral',
    unlocks: ['starter glow'],
    recentEvents: [],
    selectedAccessory: 'starter glow',
  );
}

class CompanionProgressionService {
  static const String _storageKey = 'its_giving_companion_progress';
  /// Lets the shell refresh immediately when another feature awards XP or
  /// changes the companion mood.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  Future<CompanionProgressState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return CompanionProgressState.empty();
    }

    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final unlocks = ((map['unlocks'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList();
      return CompanionProgressState(
        xp: (map['xp'] as num?)?.toInt() ?? 0,
        level: (map['level'] as num?)?.toInt() ?? 1,
        mood: (map['mood'] ?? 'neutral').toString(),
        unlocks: unlocks.isEmpty ? ['starter glow'] : unlocks,
        recentEvents: ((map['recentEvents'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        selectedAccessory: (map['selectedAccessory'] ?? 'starter glow')
            .toString(),
      );
    } catch (_) {
      return CompanionProgressState.empty();
    }
  }

  Future<void> _save(CompanionProgressState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode({
        'xp': state.xp,
        'level': state.level,
        'mood': state.mood,
        'unlocks': state.unlocks,
        'selectedAccessory': state.selectedAccessory,
        'recentEvents': state.recentEvents,
      }),
    );
    changes.value++;
  }

  Future<CompanionProgressState> awardXp(String eventId, int amount) async {
    final current = await load();
    final seen = current.recentEvents;
    if (seen.contains(eventId)) {
      return current;
    }

    final nextXp = current.xp + amount;
    final nextLevel = 1 + (nextXp ~/ CompanionProgressState.xpPerLevel);
    final unlocks = [...current.unlocks];
    if (nextLevel >= 2 && !unlocks.contains('soft glam accessory')) {
      unlocks.add('soft glam accessory');
    }
    if (nextLevel >= 3 && !unlocks.contains('celebration sparkle')) {
      unlocks.add('celebration sparkle');
    }
    if (nextLevel >= 2 && !unlocks.contains('old money pearls')) {
      unlocks.add('old money pearls');
    }
    if (nextLevel >= 3 && !unlocks.contains('clean girl gloss')) {
      unlocks.add('clean girl gloss');
    }
    if (nextLevel >= 4 && !unlocks.contains('berry blush')) {
      unlocks.add('berry blush');
    }
    if (nextLevel >= 4 && !unlocks.contains('old money blazer')) {
      unlocks.add('old money blazer');
    }

    final mood = current.mood == 'sad'
        ? 'happy'
        : (nextLevel >= 3 ? 'excited' : 'happy');
    final next = CompanionProgressState(
      xp: nextXp,
      level: nextLevel,
      mood: mood,
      unlocks: unlocks,
      recentEvents: [...seen, eventId].take(25).toList(),
      selectedAccessory: current.selectedAccessory,
    );

    await _save(next);
    return next;
  }

  Future<CompanionProgressState> applyStreakLoss() async {
    final current = await load();
    final next = current.copyWith(
      mood: 'sad',
      recentEvents: [
        ...current.recentEvents,
        'streak_reset_${DateTime.now().millisecondsSinceEpoch}',
      ].take(25).toList(),
    );
    await _save(next);
    return next;
  }

  /// Reflects the user's own weekly feedback without judging their appearance.
  Future<CompanionProgressState> applyWeeklyCheckIn(String rating) async {
    final current = await load();
    final normalized = rating.toLowerCase();
    final mood = normalized.contains('great')
        ? 'excited'
        : normalized.contains('good')
        ? 'happy'
        : normalized.contains('difficult') || normalized.contains('okay')
        ? 'concerned'
        : 'neutral';
    final next = current.copyWith(
      mood: mood,
      recentEvents: [
        ...current.recentEvents,
        'check_in_${DateTime.now().millisecondsSinceEpoch}',
      ].take(25).toList(),
    );
    await _save(next);
    return next;
  }

  Future<CompanionProgressState> setSelectedAccessory(String accessory) async {
    final current = await load();
    final normalized = accessory.trim();
    if (normalized.isEmpty) {
      return current;
    }

    if (!current.unlocks.contains(normalized)) {
      return current;
    }

    final next = current.copyWith(selectedAccessory: normalized);
    await _save(next);
    return next;
  }

  Future<CompanionProgressState> awardPlanGenerated() async {
    return awardXp('app_action_plan_generated', 30);
  }

  Future<CompanionProgressState> awardWardrobeReview() async {
    return awardXp('app_action_wardrobe_review', 25);
  }

  Future<CompanionProgressState> awardCoachInsight() async {
    return awardXp('app_action_coach_insight', 20);
  }
}

class FloatingAvatar extends StatelessWidget {
  const FloatingAvatar({
    required this.mood,
    required this.accessory,
    super.key,
  });

  final String mood;
  final CompanionAccessory accessory;

  Widget _buildEye({
    required double left,
    required double top,
    required bool naughty,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 8,
        height: naughty ? 7 : 8,
        decoration: BoxDecoration(
          color: const Color(0xFF2E1A41),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _buildMouth() {
    final isHappy = mood == 'happy' || mood == 'excited';
    final isSad = mood == 'sad';
    final isConcerned = mood == 'concerned';
    final isThinking = mood == 'thinking';

    return Positioned(
      left: 27,
      top: 54,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: isThinking ? 22 : 28,
        height: isHappy ? 12 : (isSad ? 10 : 7),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSad ? const Color(0xFF7A315A) : const Color(0xFF442350),
              width: isHappy ? 3 : 2.5,
            ),
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: const Radius.circular(18),
            bottomRight: const Radius.circular(18),
            topLeft: Radius.circular(isConcerned ? 8 : 0),
            topRight: Radius.circular(isConcerned ? 8 : 0),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHappy = mood == 'happy' || mood == 'excited';
    final isSad = mood == 'sad';
    final isConcerned = mood == 'concerned';
    final isThinking = mood == 'thinking';
    final blushScale = isHappy ? 1.25 : (isSad ? 0.9 : 1.0);

    return SizedBox(
      width: 94,
      height: 94,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x330E102B),
                    blurRadius: 18,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/its_giving_avatar.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      PremiumAvatarArtwork(mood: mood, accessory: accessory),
                ),
              ),
            ),
          ),
          if (isHappy || isConcerned || isThinking || isSad) ...[
            _buildEye(left: 22, top: 29, naughty: isSad),
            _buildEye(left: 50, top: 29, naughty: isSad),
            Positioned(
              left: 24,
              top: isSad ? 34 : 32,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E1A41),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 27,
              top: isSad ? 19 : 18,
              child: Transform.scale(
                scale: blushScale,
                child: Container(
                  width: isHappy ? 12 : 9,
                  height: isHappy ? 12 : 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD9EC),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            _buildMouth(),
            if (mood == 'excited')
              Positioned(
                right: 12,
                top: 4,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8A8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
          ],
          if (mood == 'sad')
            Positioned(
              left: 20,
              top: 18,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Color(0xFFB97AA7),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(2),
                  ),
                ),
              ),
            ),
          if (mood == 'happy' || mood == 'excited')
            Positioned(
              right: 8,
              top: 4,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE08A),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x44FFD96C),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            right: -4,
            bottom: 1,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accessory.color, accessory.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(accessory.icon, color: Colors.white, size: 17),
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumAvatarArtwork extends StatelessWidget {
  const PremiumAvatarArtwork({
    required this.mood,
    required this.accessory,
    super.key,
  });

  final String mood;
  final CompanionAccessory accessory;

  @override
  Widget build(BuildContext context) {
    final isSad = mood == 'sad';
    final isExcited = mood == 'excited';
    final isThinking = mood == 'thinking';

    return SizedBox(
      width: 94,
      height: 94,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFE4F0).withValues(alpha: 0.9),
                    const Color(0xFFD8E6FF).withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                  radius: 1.2,
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFE7F1), Color(0xFFD8E3FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x332B2B5B),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 18,
            right: 18,
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8C5EB9), Color(0xFFAF7EC7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F4E1A5D),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 25,
            top: 14,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFF8E4D4), Color(0xFFF1D1B2)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: 8,
            child: Container(
              width: 58,
              height: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3E204F), Color(0xFF25173D)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                  bottom: Radius.circular(12),
                ),
              ),
            ),
          ),
          Positioned(
            left: 32,
            top: 28,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF2C1A3B),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 52,
            top: 28,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF2C1A3B),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 30,
            top: 40,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 31,
              height: isSad ? 7 : (isThinking ? 9 : 11),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF7A315A),
                    width: 2.5,
                  ),
                ),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          if (isExcited)
            Positioned(
              left: 58,
              top: 16,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD8EA),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          Positioned(
            right: -4,
            bottom: 1,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accessory.color, accessory.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(accessory.icon, color: Colors.white, size: 17),
            ),
          ),
        ],
      ),
    );
  }
}

class ItGivingCompanion extends StatefulWidget {
  const ItGivingCompanion({
    super.key,
    this.progress,
    this.onTaskComplete,
    this.onAccessoryChanged,
    this.onDismiss,
  });

  final CompanionProgressState? progress;
  final VoidCallback? onTaskComplete;
  final ValueChanged<String>? onAccessoryChanged;
  final VoidCallback? onDismiss;

  @override
  State<ItGivingCompanion> createState() => _ItGivingCompanionState();
}

class _ItGivingCompanionState extends State<ItGivingCompanion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _headShakeController;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _headShakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _headShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _floatAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _headShakeAnimation = Tween<double>(begin: -0.12, end: 0.12)
        .chain(CurveTween(curve: Curves.easeInOutSine))
        .animate(_headShakeController);
  }

  @override
  void dispose() {
    _controller.dispose();
    _headShakeController.dispose();
    super.dispose();
  }

  CompanionMood _getMood() {
    final mood = (widget.progress?.mood ?? 'neutral');
    switch (mood) {
      case 'excited':
        return const CompanionMood(
          name: 'excited',
          emoji: '✨',
          message: 'Okayyy, we are glowing up! ',
        );
      case 'thinking':
        return const CompanionMood(
          name: 'thinking',
          emoji: '💭',
          message: 'Let’s map the next step together.',
        );
      case 'concerned':
        return const CompanionMood(
          name: 'concerned',
          emoji: '🌷',
          message: 'We’ve got this, one gentle step at a time.',
        );
      case 'sad':
        return const CompanionMood(
          name: 'sad',
          emoji: '😞',
          message:
              'The streak slipped. Let’s give her a fresh little comeback.',
        );
      case 'neutral':
        return const CompanionMood(
          name: 'neutral',
          emoji: '🙂',
          message: 'I’m here for your next little win.',
        );
      case 'happy':
      default:
        return const CompanionMood(
          name: 'happy',
          emoji: '😊',
          message: 'Girl, look at that progress!',
        );
    }
  }

  void _showAccessorySheet(BuildContext context) {
    final owned = (widget.progress?.unlocks ?? const ['starter glow']).toSet();
    final unlockedAccessories = companionAccessories
        .where((item) => owned.contains(item.id))
        .toList();
    final lockedAccessories = companionAccessories
        .where((item) => !owned.contains(item.id))
        .toList();

    final groupedUnlocked = <String, List<CompanionAccessory>>{};
    for (final item in unlockedAccessories) {
      groupedUnlocked.putIfAbsent(item.vibe, () => []).add(item);
    }

    final groupedLocked = <String, List<CompanionAccessory>>{};
    for (final item in lockedAccessories) {
      groupedLocked.putIfAbsent(item.vibe, () => []).add(item);
    }

    final vibeOrder = <String>['soft girl', 'old money', 'clean girl'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF9FC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD5B4D5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Dress her up',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3B1D42),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to equip what she has unlocked with XP and streak wins.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF6D4D6E)),
                  ),
                  const SizedBox(height: 18),
                  for (final vibe in vibeOrder) ...[
                    if ((groupedUnlocked[vibe] ?? []).isNotEmpty ||
                        (groupedLocked[vibe] ?? []).isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8, top: 4),
                          child: Text(
                            vibe[0].toUpperCase() + vibe.substring(1),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF5E3458),
                            ),
                          ),
                        ),
                      ),
                      if ((groupedUnlocked[vibe] ?? []).isNotEmpty) ...[
                        for (final item in groupedUnlocked[vibe]!)
                          _buildAccessoryTile(
                            item: item,
                            isSelected: _getCurrentAccessory().id == item.id,
                            onSelect: () {
                              widget.onAccessoryChanged?.call(item.id);
                              Navigator.of(sheetContext).pop();
                            },
                          ),
                      ],
                      if ((groupedLocked[vibe] ?? []).isNotEmpty) ...[
                        for (final item in groupedLocked[vibe]!)
                          _buildAccessoryTile(
                            item: item,
                            isSelected: false,
                            isLocked: true,
                          ),
                      ],
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccessoryTile({
    required CompanionAccessory item,
    required bool isSelected,
    bool isLocked = false,
    VoidCallback? onSelect,
  }) {
    final tile = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLocked
            ? const Color(0xFFF6EEF7)
            : (isSelected ? const Color(0xFFFFEAF3) : const Color(0xFFFFFFFF)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLocked
              ? const Color(0xFFEADAF3)
              : (isSelected
                    ? const Color(0xFFCE7AA8)
                    : const Color(0xFFF0E1F0)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: isLocked
                  ? null
                  : LinearGradient(colors: [item.color, item.secondaryColor]),
              color: isLocked ? const Color(0xFFE8D8EB) : null,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item.icon,
              color: isLocked ? const Color(0xFF8A628A) : Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3B1D42),
                      ),
                    ),
                    if (isSelected && !isLocked) ...[
                      const SizedBox(width: 8),
                      const Text(
                        'Equipped',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9F4E8C),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isLocked
                      ? 'Unlock at level ${item.requiresLevel}'
                      : item.description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF684F69),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isLocked || onSelect == null) {
      return tile;
    }

    return GestureDetector(onTap: onSelect, child: tile);
  }

  CompanionAccessory _getCurrentAccessory() {
    final unlocks = widget.progress?.unlocks ?? const ['starter glow'];
    final selected = widget.progress?.selectedAccessory ?? 'starter glow';
    final current = unlocks.contains(selected)
        ? selected
        : (unlocks.isNotEmpty ? unlocks.first : 'starter glow');
    return companionAccessories.firstWhere(
      (item) => item.id == current,
      orElse: () => companionAccessories.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mood = _getMood();
    final unlockedAccessories = companionAccessories
        .where(
          (item) => (widget.progress?.unlocks ?? const ['starter glow'])
              .contains(item.id),
        )
        .toList();
    final currentAccessory = _getCurrentAccessory();
    return AnimatedBuilder(
      animation: Listenable.merge([_floatAnimation, _headShakeAnimation]),
      builder: (context, child) {
        final offset =
            10 * (1 - _floatAnimation.value) -
            5 +
            (mood.name == 'excited' ? 3 : 0) +
            (mood.name == 'sad' ? -1 : 0);
        final shakeAngle =
            _headShakeAnimation.value +
            (mood.name == 'sad' ? 0.12 : 0.0) +
            (mood.name == 'excited' ? -0.06 : 0.0);

        return Positioned(
          right: 18,
          bottom: 90,
          child: Transform.translate(
            offset: Offset(0, offset),
            child: Transform.rotate(
              angle: shakeAngle,
              alignment: Alignment.bottomCenter,
              child: Semantics(
                label: 'AI companion, level ${widget.progress?.level ?? 1}',
                hint: 'Tap to customize. Long press to hide for this session.',
                button: true,
                child: GestureDetector(
                onTap: () {
                  widget.onTaskComplete?.call();
                  _showAccessorySheet(context);
                },
                onLongPress: widget.onDismiss,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFFDFE), Color(0xFFF7F2FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFFE9D8F3),
                      width: 1.2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 18,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingAvatar(
                        mood: mood.name,
                        accessory: currentAccessory,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Lv ${widget.progress?.level ?? 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF6B3C6F),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (unlockedAccessories.length > 1) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: unlockedAccessories.map((item) {
                            final isSelected = item.id == currentAccessory.id;
                            return GestureDetector(
                              onTap: () =>
                                  widget.onAccessoryChanged?.call(item.id),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFFFFD8EA),
                                            Color(0xFFE9D5FF),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        )
                                      : const LinearGradient(
                                          colors: [
                                            Color(0xFFFDF5F9),
                                            Color(0xFFF3EEF7),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFB97AA7)
                                        : const Color(0xFFE5D4E3),
                                    width: 1,
                                  ),
                                  boxShadow: isSelected
                                      ? const [
                                          BoxShadow(
                                            color: Color(0x1FDE8BA5),
                                            blurRadius: 8,
                                            offset: Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      item.icon,
                                      size: 12,
                                      color: const Color(0xFF4F2E4C),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.label,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF4F2E4C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        mood.message,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4F2E4C),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ),
            ),
          ),
        );
      },
    );
  }
}
