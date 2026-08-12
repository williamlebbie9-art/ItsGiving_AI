import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'plan_models.dart';
import 'plan_service.dart';

/// Shows the user's current plan status and their archived plan history.
class PlanHistoryScreen extends ConsumerStatefulWidget {
  const PlanHistoryScreen({super.key});

  @override
  ConsumerState<PlanHistoryScreen> createState() => _PlanHistoryScreenState();
}

class _PlanHistoryScreenState extends ConsumerState<PlanHistoryScreen> {
  final _service = PlanService();
  List<GlowUpPlan> _history = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _service.loadPlanHistory();
    if (!mounted) return;
    setState(() {
      _history = history;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plan History'), centerTitle: true),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF3FA), Color(0xFFFFE4F1), Color(0xFFEADFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _history.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No previous plans yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your completed or archived glow-up plans will appear here.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: _history.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final plan = _history[index];
                  return _HistoryCard(plan: plan);
                },
              ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.plan});

  final GlowUpPlan plan;

  @override
  Widget build(BuildContext context) {
    final month = _monthName(plan.createdAt.month);
    final progress = (plan.progress * 100).round();
    final isComplete = plan.completedDays >= plan.totalDays;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$month Glow-Up',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              if (isComplete)
                const Text('🎉', style: TextStyle(fontSize: 20))
              else
                Text(
                  '${plan.completedDays}/${plan.totalDays} days',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFF5FA2),
                    fontSize: 13,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan.overview.isEmpty
                ? '30-day personalized glow-up program'
                : plan.overview,
            style: TextStyle(color: Colors.grey[600], height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: plan.progress,
              minHeight: 8,
              backgroundColor: Colors.white,
              color: isComplete
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFFF5FA2),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isComplete ? 'Completed $progress%' : '$progress% complete',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[(month - 1).clamp(0, 11)];
  }
}
