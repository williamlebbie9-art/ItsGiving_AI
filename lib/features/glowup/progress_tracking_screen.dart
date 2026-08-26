import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'plan_models.dart';
import 'plan_provider.dart';

class ProgressTrackingScreen extends ConsumerStatefulWidget {
  const ProgressTrackingScreen({super.key});

  @override
  ConsumerState<ProgressTrackingScreen> createState() => _ProgressTrackingScreenState();
}

class _ProgressTrackingScreenState extends ConsumerState<ProgressTrackingScreen> {
  final _picker = ImagePicker();
  String? _beforeImagePath;
  String? _afterImagePath;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _beforeImagePath = prefs.getString('glowup_before_photo');
      _afterImagePath = prefs.getString('glowup_after_photo');
    });
  }

  Future<void> _pickPhoto(bool isBefore) async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = isBefore ? 'glowup_before_photo' : 'glowup_after_photo';
    await prefs.setString(key, image.path);

    if (!mounted) return;
    setState(() {
      if (isBefore) {
        _beforeImagePath = image.path;
      } else {
        _afterImagePath = image.path;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(planProvider).plan;
    return Scaffold(
      appBar: AppBar(title: const Text('Progress'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStreakCard(context, plan),
          const SizedBox(height: 16),
          _buildPlanProgressCard(context, plan),
          const SizedBox(height: 16),
          _buildBeforeAfterSection(context),
        ],
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, GlowUpPlan? plan) {
    final streak = plan?.streak ?? 0;
    final completedDays = plan?.completedDays ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF70B8), Color(0xFFB69CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak-day streak',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completedDays plan days completed',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanProgressCard(BuildContext context, GlowUpPlan? plan) {
    final completedTasks = plan == null
        ? 0
        : plan.weeks.fold<int>(
            0,
            (sum, week) => sum + week.days.fold<int>(
              0,
              (daySum, day) => daySum + day.completedCount,
            ),
          );
    final totalTasks = plan == null
        ? 0
        : plan.weeks.fold<int>(
            0,
            (sum, week) => sum + week.days.fold<int>(
              0,
              (daySum, day) => daySum + day.tasks.length,
            ),
          );
    final progress = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;
    final percent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: const Color(0xFFFFE4F1),
                  color: const Color(0xFFFF5FA2),
                ),
                Center(
                  child: Text(
                    '$percent%',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan Progress',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  totalTasks == 0
                      ? 'Start a plan to track completed habits here.'
                      : '$completedTasks of $totalTasks planned habits completed. This is progress, not a beauty rating.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeforeAfterSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Before & After',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          'Take a monthly photo to see your progress. We never alter your face — just track your natural glow.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildPhotoPane(
              context,
              'Before',
              _beforeImagePath,
              () => _pickPhoto(true),
            ),
            const SizedBox(width: 12),
            _buildPhotoPane(
              context,
              'After',
              _afterImagePath,
              () => _pickPhoto(false),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoPane(
    BuildContext context,
    String label,
    String? path,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB69CFF), Color(0xFFFF9AC2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: path != null
              ? Image.file(File(path), fit: BoxFit.cover)
              : InkWell(
                  onTap: onTap,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add $label',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

}
