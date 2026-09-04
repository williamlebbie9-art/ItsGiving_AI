import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_face_scan_screen.dart';
import 'glow_up_generator_screen.dart';
import 'plan_history_screen.dart';
import 'plan_models.dart';
import 'plan_provider.dart';

/// The dedicated "My Glow-Up Plan" screen showing the structured 30-day
/// program with days, tasks, completion tracking, and weekly check-ins.
class GlowUpPlanScreen extends ConsumerStatefulWidget {
  const GlowUpPlanScreen({super.key});

  @override
  ConsumerState<GlowUpPlanScreen> createState() => _GlowUpPlanScreenState();
}

class _GlowUpPlanScreenState extends ConsumerState<GlowUpPlanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(planProvider.notifier).loadPlan();
    });
  }

  Future<void> _openNewPlanGenerator() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSummary = prefs.getString('glowup_last_scan_summary');
    final savedImagePath = prefs.getString('glowup_last_scan_image_path');

    if ((savedSummary == null || savedSummary.isEmpty) &&
        (savedImagePath == null || savedImagePath.isEmpty)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete a face scan first so your new plan has the right AI context.',
          ),
        ),
      );
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AiFaceScanScreen()));
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GlowUpGeneratorScreen(
          imagePath: savedImagePath ?? '',
          faceScanSummary: savedSummary,
        ),
      ),
    );
  }

  /// Shows a confirmation dialog before creating a new plan.
  /// The current plan is archived, never destroyed.
  Future<void> _confirmNewPlan() async {
    final plan = ref.read(planProvider).plan;

    if (plan == null) {
      await _openNewPlanGenerator();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create a new plan?'),
        content: const Text(
          'Your current plan will be archived and saved to your history. '
          'Your completed progress will not be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create New Plan'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(planProvider.notifier).archiveCurrentPlan();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your current plan was archived. Creating a new one...',
          ),
        ),
      );
      await _openNewPlanGenerator();
    }
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(planProvider);

    if (planState.isLoading && planState.plan == null) {
      return const _PlanLoading();
    }
    if (planState.error != null && planState.plan == null) {
      return _PlanError(
        message: planState.error!,
        onRetry: () => ref.read(planProvider.notifier).loadPlan(),
      );
    }
    final plan = planState.plan;
    if (plan == null) {
      return _PlanError(
        message:
            'You don\'t have a glow-up plan yet. Complete onboarding to create one.',
        onRetry: () => ref.read(planProvider.notifier).loadPlan(),
      );
    }
    return _PlanContent(plan: plan, onNewPlan: _confirmNewPlan);
  }
}

class _PlanContent extends ConsumerWidget {
  const _PlanContent({required this.plan, required this.onNewPlan});

  final GlowUpPlan plan;
  final VoidCallback onNewPlan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentWeek = plan.currentWeekData;
    final currentDay = plan.currentDayData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('✨ My Glow-Up Plan'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Plan History',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PlanHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Create New Plan',
            onPressed: onNewPlan,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF3FA), Color(0xFFFFE4F1), Color(0xFFEADFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
          children: [
            Text(
              '30-Day Glow-Up',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            if (plan.styleName != null && plan.styleName!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '${plan.styleName} style plan',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFF5FA2),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Day ${plan.currentDay} of ${plan.totalDays}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: plan.progress,
                minHeight: 12,
                backgroundColor: Colors.white.withValues(alpha: 0.7),
                color: const Color(0xFFFF5FA2),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(plan.progress * 100).round()}% complete',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            if (currentWeek != null) _WeekCard(week: currentWeek, plan: plan),
            const SizedBox(height: 20),
            if (currentDay != null) ...[
              Text(
                'Today\'s Tasks',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              _DayTasksCard(day: currentDay, plan: plan),
              const SizedBox(height: 20),
            ],
            if (currentWeek != null &&
                currentWeek.checkIn == null &&
                currentWeek.days.isNotEmpty)
              _WeeklyCheckInCard(week: currentWeek),
            if (currentWeek?.checkIn != null) _CheckInDone(week: currentWeek!),
            const SizedBox(height: 20),
            _CreateNewPlanCard(onTap: onNewPlan),
          ],
        ),
      ),
    );
  }
}

/// Card that lets the user create a new plan with confirmation.
class _CreateNewPlanCard extends StatelessWidget {
  const _CreateNewPlanCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Want a fresh start?',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Create a new 30-day plan. Your current plan will be archived — nothing is lost.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Create New Plan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.week, required this.plan});

  final PlanWeek week;
  final GlowUpPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5FA2).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Week ${week.weekNumber} — ${week.title}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFFFF5FA2),
            ),
          ),
          const SizedBox(height: 8),
          Text(week.goal, style: const TextStyle(fontSize: 15, height: 1.4)),
          if (week.focusAreas.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: week.focusAreas
                  .map(
                    (area) => Chip(
                      label: Text(area),
                      backgroundColor: Colors.white.withValues(alpha: 0.7),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: week.days.map((day) {
              final isToday =
                  day.dayNumber == plan.currentDay &&
                  week.weekNumber == plan.currentWeek;
              final isDone = day.isComplete;
              final isFuture =
                  day.dayNumber > plan.currentDay ||
                  week.weekNumber > plan.currentWeek;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isToday
                          ? const Color(0xFFFF5FA2)
                          : isDone
                          ? const Color(0xFFB8E6C8)
                          : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: isToday
                          ? null
                          : Border.all(
                              color: Colors.grey.withValues(alpha: 0.2),
                            ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isDone
                          ? '✓'
                          : isFuture
                          ? '🔒'
                          : '${day.dayNumber}',
                      style: TextStyle(
                        color: isToday
                            ? Colors.white
                            : isDone
                            ? const Color(0xFF2E7D32)
                            : Colors.grey[600],
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DayTasksCard extends ConsumerWidget {
  const _DayTasksCard({required this.day, required this.plan});

  final PlanDay day;
  final GlowUpPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Day ${day.dayNumber}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              Text(
                '${day.completedCount}/${day.tasks.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFF5FA2),
                ),
              ),
            ],
          ),
          if (day.isComplete) ...[
            const SizedBox(height: 8),
            const Text(
              'Day complete! 🔥',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...day.tasks.map(
            (task) => _TaskTile(
              task: task,
              weekNumber: plan.currentWeek,
              dayNumber: day.dayNumber,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({
    required this.task,
    required this.weekNumber,
    required this.dayNumber,
  });

  final PlanTask task;
  final int weekNumber;
  final int dayNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CheckboxListTile(
      value: task.isCompleted,
      contentPadding: EdgeInsets.zero,
      title: Text(
        task.title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          color: task.isCompleted ? Colors.grey : null,
        ),
      ),
      subtitle: task.description.isNotEmpty
          ? Text(task.description, style: const TextStyle(fontSize: 12))
          : null,
      activeColor: const Color(0xFFFF5FA2),
      onChanged: (_) {
        ref
            .read(planProvider.notifier)
            .toggleTask(
              weekNumber: weekNumber,
              dayNumber: dayNumber,
              taskId: task.id,
            );
      },
    );
  }
}

class _WeeklyCheckInCard extends ConsumerStatefulWidget {
  const _WeeklyCheckInCard({required this.week});

  final PlanWeek week;

  @override
  ConsumerState<_WeeklyCheckInCard> createState() => _WeeklyCheckInCardState();
}

class _WeeklyCheckInCardState extends ConsumerState<_WeeklyCheckInCard> {
  String? _selectedRating;
  final _notesController = TextEditingController();

  static const _ratings = ['😊 Great', '🙂 Good', '😐 Okay', '😓 Difficult'];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Check-In',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text('How did this week go?'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ratings.map((rating) {
              final selected = _selectedRating == rating;
              return ChoiceChip(
                label: Text(rating),
                selected: selected,
                onSelected: (_) => setState(() => _selectedRating = rating),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              hintText: 'Optional note...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedRating == null
                  ? null
                  : () {
                      ref
                          .read(planProvider.notifier)
                          .submitWeeklyCheckIn(
                            weekNumber: widget.week.weekNumber,
                            rating: _selectedRating!,
                            notes: _notesController.text.trim(),
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Check-in saved! AI will adapt next week.',
                          ),
                        ),
                      );
                    },
              child: const Text('Submit Check-In'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckInDone extends StatelessWidget {
  const _CheckInDone({required this.week});

  final PlanWeek week;

  @override
  Widget build(BuildContext context) {
    final checkIn = week.checkIn!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Check-In Complete ✅',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('Your rating: ${checkIn.rating}'),
          if (checkIn.notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('"${checkIn.notes}"'),
          ],
        ],
      ),
    );
  }
}

class _PlanLoading extends StatelessWidget {
  const _PlanLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('✨ My Glow-Up Plan'), centerTitle: true),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF3FA), Color(0xFFFFE4F1), Color(0xFFEADFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFFFF5FA2)),
              SizedBox(height: 16),
              Text('Loading your glow-up plan...'),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanError extends StatelessWidget {
  const _PlanError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('✨ My Glow-Up Plan'), centerTitle: true),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF3FA), Color(0xFFFFE4F1), Color(0xFFEADFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFE53935),
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
