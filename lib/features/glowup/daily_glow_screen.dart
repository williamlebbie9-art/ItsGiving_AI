import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'glow_models.dart';

class DailyGlowScreen extends StatefulWidget {
  const DailyGlowScreen({super.key});

  @override
  State<DailyGlowScreen> createState() => _DailyGlowScreenState();
}

class _DailyGlowScreenState extends State<DailyGlowScreen> {
  int _day = 1;
  final Set<String> _completedTasks = <String>{};

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _day = prefs.getInt('glowup_current_day') ?? 1;
      _completedTasks.addAll(
        prefs.getStringList('glowup_completed_tasks') ?? const [],
      );
    });
  }

  Future<void> _toggleTask(String id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_completedTasks.contains(id)) {
        _completedTasks.remove(id);
      } else {
        _completedTasks.add(id);
      }
    });
    await prefs.setStringList(
      'glowup_completed_tasks',
      _completedTasks.toList(),
    );

    // Auto-increment streak when all tasks for the day are done.
    final plan = sevenDayChallenge[_day - 1];
    final allTasks = [
      ...plan.morningTasks,
      ...plan.eveningTasks,
      ...plan.selfCareTasks,
    ];
    final allDone = allTasks.every((t) => _completedTasks.contains(t.id));
    if (allDone && _day < 7) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Day Complete! 🎉'),
          content: const Text(
            'You finished all your glow-up tasks for today. Ready for day 2?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _advanceDay();
              },
              child: const Text('Stay on Day 1'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _advanceDay();
              },
              child: const Text('Go to Day 2 ✨'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _advanceDay() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_day < 7) _day += 1;
    });
    await prefs.setInt('glowup_current_day', _day);

    // Update streak
    final streak = prefs.getInt('glowup_streak') ?? 0;
    await prefs.setInt('glowup_streak', streak + 1);
  }

  @override
  Widget build(BuildContext context) {
    final plan = sevenDayChallenge[_day - 1];
    final allTasks = [
      ...plan.morningTasks,
      ...plan.eveningTasks,
      ...plan.selfCareTasks,
    ];
    final completedCount = allTasks
        .where((t) => _completedTasks.contains(t.id))
        .length;
    final totalCount = allTasks.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Glow-Up'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF70B8), Color(0xFFB69CFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'DAY $_day OF 7',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'TODAY\'S GLOW-UP',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$completedCount of $totalCount tasks completed',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: totalCount > 0 ? completedCount / totalCount : 0,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  color: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildTaskSection(context, '☀️ MORNING', plan.morningTasks),
          const SizedBox(height: 16),
          _buildTaskSection(context, '🌙 EVENING', plan.eveningTasks),
          const SizedBox(height: 16),
          _buildTaskSection(context, '💖 SELF-CARE', plan.selfCareTasks),
        ],
      ),
    );
  }

  Widget _buildTaskSection(
    BuildContext context,
    String title,
    List<GlowTask> tasks,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ...tasks.map((task) {
            final isDone = _completedTasks.contains(task.id);
            return CheckboxListTile(
              value: isDone,
              title: Text(
                task.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  color: isDone ? Colors.grey : null,
                ),
              ),
              subtitle: Text(task.description),
              activeColor: const Color(0xFFFF5FA2),
              contentPadding: EdgeInsets.zero,
              onChanged: (_) => _toggleTask(task.id),
            );
          }),
        ],
      ),
    );
  }
}
