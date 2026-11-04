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
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final Color secondaryColor;
}

const List<CompanionAccessory> companionAccessories = [
  CompanionAccessory(
    id: 'starter glow',
    label: 'Starter glow',
    icon: Icons.auto_awesome_rounded,
    color: Color(0xFFFFD8EA),
    secondaryColor: Color(0xFFEA7BB7),
  ),
  CompanionAccessory(
    id: 'soft glam accessory',
    label: 'Soft glam',
    icon: Icons.diamond_rounded,
    color: Color(0xFFE9D5FF),
    secondaryColor: Color(0xFF9A74D3),
  ),
  CompanionAccessory(
    id: 'celebration sparkle',
    label: 'Sparkle',
    icon: Icons.star_rounded,
    color: Color(0xFFFFF3B0),
    secondaryColor: Color(0xFFE0A41F),
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
    mood: 'happy',
    unlocks: ['starter glow'],
    recentEvents: [],
    selectedAccessory: 'starter glow',
  );
}

class CompanionProgressionService {
  static const String _storageKey = 'its_giving_companion_progress';

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
        mood: (map['mood'] ?? 'happy').toString(),
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
    final isConcerned = mood == 'concerned';
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
  });

  final CompanionProgressState? progress;
  final VoidCallback? onTaskComplete;
  final ValueChanged<String>? onAccessoryChanged;

  @override
  State<ItGivingCompanion> createState() => _ItGivingCompanionState();
}

class _ItGivingCompanionState extends State<ItGivingCompanion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _floatAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  CompanionMood _getMood() {
    final mood = (widget.progress?.mood ?? 'happy');
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
          message: 'We can bounce back. One step at a time.',
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
      animation: _floatAnimation,
      builder: (context, child) {
        final offset = 8 * (1 - _floatAnimation.value) - 4;
        return Positioned(
          right: 18,
          bottom: 90,
          child: Transform.translate(
            offset: Offset(0, offset),
            child: GestureDetector(
              onTap: widget.onTaskComplete,
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
                    PremiumAvatarArtwork(
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
                            child: Container(
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
        );
      },
    );
  }
}
