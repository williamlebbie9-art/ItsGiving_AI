import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_coach_screen.dart' as ai_coach;

final selectedLookProvider = StateProvider<GlowLook?>((ref) => null);
final selectedGoalProvider = StateProvider<int?>((ref) => null);
final completedTasksProvider = StateProvider<Set<String>>((ref) => <String>{});
final chatMessagesProvider = StateProvider<List<CoachMessage>>(
  (ref) => const [
    CoachMessage(
      text:
          'Hey bestie ✨ Ask me about skincare, hair, outfits, habits, workouts, or confidence.',
      isUser: false,
    ),
  ],
);

class GlowUpShell extends ConsumerStatefulWidget {
  const GlowUpShell({super.key});

  @override
  ConsumerState<GlowUpShell> createState() => _GlowUpShellState();
}

class _GlowUpShellState extends ConsumerState<GlowUpShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const GlowDashboardScreen(),
      const FaceScanScreen(),
      const RoadmapScreen(),
      const DiaryProgressScreen(),
      const CoachScreen(),
      const CommunityScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 360),
        child: pages[_index],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: NavigationBar(
              selectedIndex: _index,
              height: 72,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.76),
              indicatorColor: const Color(0xFFFFD8EA),
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.auto_awesome_outlined),
                  selectedIcon: Icon(Icons.auto_awesome_rounded),
                  label: 'Glow',
                ),
                NavigationDestination(
                  icon: Icon(Icons.camera_alt_outlined),
                  selectedIcon: Icon(Icons.camera_alt_rounded),
                  label: 'Scan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.checklist_rtl_outlined),
                  selectedIcon: Icon(Icons.checklist_rtl_rounded),
                  label: 'Plan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: 'Diary',
                ),
                NavigationDestination(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  selectedIcon: Icon(Icons.chat_bubble_rounded),
                  label: 'Coach',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_border_rounded),
                  selectedIcon: Icon(Icons.favorite_rounded),
                  label: 'Inspo',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GlowOnboardingScreen extends ConsumerStatefulWidget {
  const GlowOnboardingScreen({super.key});

  @override
  ConsumerState<GlowOnboardingScreen> createState() =>
      _GlowOnboardingScreenState();
}

class _GlowOnboardingScreenState extends ConsumerState<GlowOnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  final _answers = <String, String>{};

  final _steps = const [
    _OnboardingStep(
      title: 'Your AI glow-up era starts here',
      subtitle:
          'Scan your face, preview realistic glow-up directions, and follow a daily plan that actually feels doable.',
      icon: Icons.auto_awesome_rounded,
      field: 'Goal',
      options: ['Clear skin', 'Soft glam', 'Fitness glow', 'Confidence'],
    ),
    _OnboardingStep(
      title: 'Tell us your baseline',
      subtitle:
          'We personalize routines around age, skin type, lifestyle, fitness, budget, and beauty goals.',
      icon: Icons.face_retouching_natural_rounded,
      field: 'Skin type',
      options: ['Combination', 'Dry', 'Oily', 'Sensitive'],
    ),
    _OnboardingStep(
      title: 'Camera access for selfies',
      subtitle:
          'Use your camera or gallery for face scans, progress photos, and side-by-side glow tracking.',
      icon: Icons.camera_alt_rounded,
      field: 'Lifestyle',
      options: ['Busy student', 'Work mode', 'Gym era', 'Soft life'],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlowScaffold(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (value) => setState(() => _page = value),
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const GlowBrandHeader(),
                        const Spacer(),
                        Center(child: GlowOrb(icon: step.icon, size: 210)),
                        const SizedBox(height: 32),
                        Text(
                          step.title,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          step.subtitle,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(height: 1.45, color: GlowColors.muted),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          step.field,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: step.options.map((option) {
                            final selected = _answers[step.field] == option;
                            return ChoiceChip(
                              label: Text(option),
                              selected: selected,
                              onSelected: (_) =>
                                  setState(() => _answers[step.field] = option),
                            );
                          }).toList(),
                        ),
                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _steps.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 9,
                        width: _page == index ? 32 : 9,
                        decoration: BoxDecoration(
                          color: _page == index
                              ? GlowColors.hotPink
                              : Colors.white.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (_page == _steps.length - 1) {
                          SharedPreferences.getInstance().then(
                            (prefs) => prefs.setBool(
                              'glowup_onboarding_completed',
                              true,
                            ),
                          );
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const GlowUpShell(),
                            ),
                          );
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 360),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
                      child: Text(
                        _page == _steps.length - 1
                            ? 'Allow Camera & Start'
                            : 'Continue',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlowHomeScreen extends StatelessWidget {
  const GlowHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlowScaffold(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
          children: [
            const GlowBrandHeader(trailing: 'Day 12 🔥'),
            const SizedBox(height: 18),
            const GlowScoreCard(),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width > 650 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.22,
              children: const [
                QuickActionCard(
                  icon: Icons.camera_alt_rounded,
                  title: 'Scan Face',
                  subtitle: 'AI analysis',
                ),
                QuickActionCard(
                  icon: Icons.route_rounded,
                  title: 'My Plan',
                  subtitle: 'Today’s rituals',
                ),
                QuickActionCard(
                  icon: Icons.timeline_rounded,
                  title: 'Progress',
                  subtitle: 'Weekly glow',
                ),
                QuickActionCard(
                  icon: Icons.chat_rounded,
                  title: 'AI Coach',
                  subtitle: 'Ask anything',
                ),
              ],
            ),
            const SizedBox(height: 18),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Today’s glow tasks'),
                  const SizedBox(height: 12),
                  ...[
                    'AM cleanse + SPF',
                    '2L water',
                    '20 min walk',
                    'No-phone wind down',
                  ].map((task) => GlowChecklistTile(id: task, title: task)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('AI tip of the day'),
                  const SizedBox(height: 8),
                  Text(
                    'Pair barrier-friendly skincare with consistent sleep before adding more actives. Boring is often glowing.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlowDashboardScreen extends StatelessWidget {
  const GlowDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlowScaffold(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
          children: [
            const GlowBrandHeader(trailing: 'Day 12'),
            const SizedBox(height: 14),
            Text(
              'AI Glow Scan',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            const GlowScanHeroCard(),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  'Key Metrics',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                TextButton(onPressed: () {}, child: const Text('View All')),
              ],
            ),
            const SizedBox(height: 8),
            const KeyMetricsGrid(),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('Share My Results'),
            ),
            const SizedBox(height: 18),
            const PersonalPlanPreview(),
            const SizedBox(height: 18),
            const DailyGlowTipCard(),
          ],
        ),
      ),
    );
  }
}

class FaceScanScreen extends ConsumerStatefulWidget {
  const FaceScanScreen({super.key});

  @override
  ConsumerState<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends ConsumerState<FaceScanScreen> {
  final _picker = ImagePicker();
  XFile? _image;
  bool _analyzing = false;

  Future<void> _pick(ImageSource source) async {
    final image = await _picker.pickImage(source: source, imageQuality: 82);
    if (image != null) setState(() => _image = image);
  }

  Future<void> _analyze() async {
    setState(() => _analyzing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _analyzing = false);
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const GlowResultsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return GlowScaffold(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
          children: [
            const ScreenHeading(
              title: 'AI Face Scan',
              subtitle:
                  'Analyze skin, symmetry, brows, hair fit, smile, and glow potential.',
            ),
            const SizedBox(height: 18),
            GlassCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: AspectRatio(
                  aspectRatio: 0.86,
                  child: _image == null
                      ? const GlowCameraPlaceholder()
                      : Image.file(File(_image!.path), fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _image == null || _analyzing ? null : _analyze,
              child: _analyzing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('Analyzing glow potential...'),
                      ],
                    )
                  : const Text('Generate Glow-Up Versions'),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                'Skin quality',
                'Acne',
                'Dark circles',
                'Skin tone',
                'Face shape',
                'Jawline',
                'Symmetry',
                'Hair fit',
                'Eye shape',
                'Brows',
                'Smile',
              ].map((label) => Chip(label: Text(label))).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class GlowResultsScreen extends ConsumerWidget {
  const GlowResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlowScaffold(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            const ScreenHeading(
              title: 'Your Glow-Up Previews',
              subtitle:
                  'Pick a realistic direction and we’ll build your roadmap.',
            ),
            const SizedBox(height: 16),
            ...glowLooks.map(
              (look) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GlowLookCard(
                  look: look,
                  onChoose: () {
                    ref.read(selectedLookProvider.notifier).state = look;
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RoadmapScreen()),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoadmapScreen extends ConsumerWidget {
  const RoadmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final look = ref.watch(selectedLookProvider);
    return GlowScaffold(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
          children: [
            ScreenHeading(
              title: look == null
                  ? 'Personalized Roadmap'
                  : '${look.name} Roadmap',
              subtitle:
                  'Interactive rituals across skincare, fitness, lifestyle, nutrition, sleep, hair, fashion, and confidence.',
            ),
            const SizedBox(height: 16),
            ...roadmapSections.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionTitle(section.title, icon: section.icon),
                      const SizedBox(height: 8),
                      ...section.items.map(
                        (item) => GlowChecklistTile(
                          id: '${section.title}-$item',
                          title: item,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlowScaffold(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
          children: [
            const ScreenHeading(
              title: 'Progress Studio',
              subtitle:
                  'Track selfies, compare changes, and celebrate consistency.',
            ),
            const SizedBox(height: 16),
            const ComparisonCard(),
            const SizedBox(height: 16),
            const GlassCard(child: MiniCharts()),
            const SizedBox(height: 16),
            const SectionTitle('Selfie timeline'),
            const SizedBox(height: 10),
            SizedBox(
              height: 116,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 6,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, index) => Container(
                  width: 92,
                  decoration: BoxDecoration(
                    gradient: GlowColors.cardGradient(index),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      'Week ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiaryProgressScreen extends StatelessWidget {
  const DiaryProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlowScaffold(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
          children: const [
            ScreenHeading(
              title: 'Diary & Progress',
              subtitle:
                  'Your glow calendar, streaks, selfie timeline, and weekly analytics in one soft little command center.',
            ),
            SizedBox(height: 16),
            GlowCalendarCard(),
            SizedBox(height: 16),
            TodayProgressCard(),
            SizedBox(height: 16),
            ComparisonCard(),
            SizedBox(height: 16),
            GlassCard(child: MiniCharts()),
            SizedBox(height: 16),
            SelfieTimelineStrip(),
          ],
        ),
      ),
    );
  }
}

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final messages = ref.read(chatMessagesProvider);
    ref.read(chatMessagesProvider.notifier).state = [
      ...messages,
      CoachMessage(text: text, isUser: true),
      CoachMessage(
        text:
            'Love this question. Start with the gentlest high-impact step: SPF, hydration, protein, sleep consistency, and one confidence rep today. Want a product-safe routine too?',
        isUser: false,
      ),
    ];
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    return GlowScaffold(
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(18),
              child: ScreenHeading(
                title: 'AI Coach',
                subtitle:
                    'Skincare, fashion, confidence, hair, nutrition, fitness, and glow-up advice.',
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                itemCount: messages.length,
                itemBuilder: (_, index) => ChatBubble(message: messages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Ask your glow coach...',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: _send,
                      icon: const Icon(Icons.arrow_upward_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlowScaffold(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
          children: [
            const ScreenHeading(
              title: 'Community Inspiration',
              subtitle:
                  'Daily glow stories, before-and-after energy, and trending beauty tips.',
            ),
            const SizedBox(height: 16),
            ...[
              (
                'Glass skin reset',
                'Barrier repair + SPF consistency for 8 weeks.',
              ),
              (
                'Soft glam confidence',
                'Brows, blush placement, posture, and sleep.',
              ),
              (
                'Fitness glow',
                'Protein breakfasts, walks, strength training, hydration.',
              ),
            ].map(
              (story) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GlassCard(
                  child: Row(
                    children: [
                      const GlowOrb(icon: Icons.favorite_rounded, size: 72),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              story.$1,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 6),
                            Text(story.$2),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const PremiumCard(),
          ],
        ),
      ),
    );
  }
}

class GlowScaffold extends StatelessWidget {
  const GlowScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF3FA), Color(0xFFFFE4F1), Color(0xFFEADFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: GlowColors.hotPink.withValues(alpha: 0.12),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlowBrandHeader extends StatelessWidget {
  const GlowBrandHeader({this.trailing, super.key});

  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: GlowColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'its giving.AI',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        if (trailing != null)
          Chip(
            avatar: const Icon(Icons.local_fire_department_rounded, size: 18),
            label: Text(trailing!),
          ),
      ],
    );
  }
}

class ScreenHeading extends StatelessWidget {
  const ScreenHeading({required this.title, required this.subtitle, super.key});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GlowBrandHeader(),
        const SizedBox(height: 18),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: GlowColors.muted, height: 1.4),
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {this.icon, super.key});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: GlowColors.hotPink),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class GlowOrb extends StatelessWidget {
  const GlowOrb({required this.icon, required this.size, super.key});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.94, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: GlowColors.primaryGradient,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.38),
      ),
    );
  }
}

class GlowScoreCard extends StatelessWidget {
  const GlowScoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: GlowColors.cardGradient(2),
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily glow progress',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Celebrate consistency, not scores. Complete your daily habits and watch your routine compound.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GlowScanHeroCard extends StatelessWidget {
  const GlowScanHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          SizedBox(
            height: 210,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.78, end: 0.9),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeInOut,
                  builder: (_, value, _) => SizedBox(
                    width: 168,
                    height: 168,
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.68),
                      color: GlowColors.hotPink,
                    ),
                  ),
                ),
                Container(
                  width: 144,
                  height: 144,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: GlowColors.cardGradient(1),
                    border: Border.all(color: Colors.white, width: 6),
                    boxShadow: [
                      BoxShadow(
                        color: GlowColors.hotPink.withValues(alpha: 0.18),
                        blurRadius: 26,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.face_retouching_natural_rounded,
                    color: Colors.white,
                    size: 72,
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 56,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: GlowColors.hotPink.withValues(alpha: 0.12),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_rounded, color: GlowColors.hotPink),
                        SizedBox(width: 6),
                        Text(
                          'Amazing!',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.66),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: _HeroScoreMetric(
                    label: 'Current Day',
                    value: 'Day 1',
                    accent: GlowColors.hotPink,
                  ),
                ),
                _softDivider(),
                const Expanded(
                  child: _HeroScoreMetric(
                    label: 'Vibe',
                    value: 'Soft Girl',
                    prefix: '🌸 ',
                  ),
                ),
                _softDivider(),
                const Expanded(
                  child: _HeroScoreMetric(label: 'Habits', value: 'Consistent'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _softDivider() {
    return Container(
      height: 54,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: GlowColors.muted.withValues(alpha: 0.12),
    );
  }
}

class _HeroScoreMetric extends StatelessWidget {
  const _HeroScoreMetric({
    required this.label,
    required this.value,
    this.prefix = '',
    this.accent,
  });

  final String label;
  final String value;
  final String prefix;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: GlowColors.hotPink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: accent ?? GlowColors.text,
              fontWeight: FontWeight.w900,
            ),
            children: [
              TextSpan(text: prefix),
              TextSpan(text: value),
              // no suffix
            ],
          ),
        ),
      ],
    );
  }
}

class KeyMetricsGrid extends StatelessWidget {
  const KeyMetricsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = const [
      MetricData('Skincare', 'Daily', Icons.spa_rounded, 0.82),
      MetricData('Hydration', '2L', Icons.water_drop_rounded, 0.78),
      MetricData('Movement', 'Active', Icons.fitness_center_rounded, 0.84),
      MetricData('Sleep', '7-8h', Icons.bedtime_rounded, 0.9),
    ];

    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width > 650 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: metrics.map((metric) => MetricCard(metric: metric)).toList(),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({required this.metric, super.key});

  final MetricData metric;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: GlowColors.hotPink.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(metric.icon, color: GlowColors.hotPink),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  metric.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            metric.value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: metric.progress),
        ],
      ),
    );
  }
}

class PersonalPlanPreview extends ConsumerWidget {
  const PersonalPlanPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGoal = ref.watch(selectedGoalProvider);
    final plans = const [
      PlanTileData(
        'Skin Perfection',
        'Custom skincare routines',
        '8-12 Weeks',
        Icons.spa_rounded,
      ),
      PlanTileData(
        'Hair Goals',
        'Hair care & styling',
        '4-8 Weeks',
        Icons.face_3_rounded,
      ),
      PlanTileData(
        'Style & Aesthetic',
        'Outfits that match your vibe',
        '8-12 Weeks',
        Icons.checkroom_rounded,
      ),
      PlanTileData(
        'Confidence Boost',
        'Mindset & self love guides',
        '8 Weeks',
        Icons.favorite_rounded,
      ),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR PERSONAL',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: GlowColors.muted,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          const SectionTitle('Glow Up Goals'),
          const SizedBox(height: 8),
          const Text('Choose one goal to start your personalized AI plan.'),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final columns = maxWidth > 900
                  ? 4
                  : maxWidth > 620
                  ? 2
                  : 1;
              final itemWidth = (maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(plans.length, (index) {
                  final plan = plans[index];
                  return SizedBox(
                    width: itemWidth,
                    child: PlanPreviewTile(
                      plan: plan,
                      selected: selectedGoal == index,
                      onTap: () => _openCoach(context, ref, plan.title, index),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

void _openCoach(BuildContext context, WidgetRef ref, String title, int index) {
  const prompts = {
    'Skin Perfection':
        'I want personalized skincare advice for clearer, glowing skin.',
    'Hair Goals':
        'Help me improve my hair care routine and styling for my hair goals.',
    'Style & Aesthetic':
        'Give me style and aesthetic guidance to match my vibe and wardrobe.',
    'Confidence Boost':
        'How can I build confidence with daily habits, self-love, and mindset?',
  };

  ref.read(selectedGoalProvider.notifier).state = index;
  final question =
      prompts[title] ?? 'Help me get started with a glow-up plan for $title.';
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ai_coach.AiCoachScreen(initialQuestion: question),
    ),
  );
}

class PlanPreviewTile extends StatelessWidget {
  const PlanPreviewTile({
    required this.plan,
    required this.selected,
    this.onTap,
    super.key,
  });

  final PlanTileData plan;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFFFF0F8)
                : Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? const Color(0xFFFF8FC7)
                  : Colors.white.withValues(alpha: 0.7),
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Icon(plan.icon, color: GlowColors.hotPink, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                plan.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                plan.subtitle,
                style: const TextStyle(height: 1.35),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                '• ${plan.duration}',
                style: const TextStyle(
                  color: GlowColors.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DailyGlowTipCard extends StatelessWidget {
  const DailyGlowTipCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle('AI tip of the day'),
          SizedBox(height: 8),
          Text(
            'Scan your face, choose a vibe, then let its giving.AI turn tiny daily habits into visible progress.',
          ),
        ],
      ),
    );
  }
}

class GlowCalendarCard extends StatelessWidget {
  const GlowCalendarCard({super.key});

  @override
  Widget build(BuildContext context) {
    final days = List.generate(30, (index) => index + 1);
    final completed = {1, 2, 3, 5, 6, 9, 10, 11, 12, 15, 16, 20, 23, 24, 25};

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SectionTitle('August Glow Calendar'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: GlowColors.primaryGradient,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '12 day streak',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          color: GlowColors.muted,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: days.map((day) {
              final isDone = completed.contains(day);
              final isToday = day == 12;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                decoration: BoxDecoration(
                  gradient: isToday ? GlowColors.primaryGradient : null,
                  color: isDone
                      ? GlowColors.hotPink.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.58),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isToday
                        ? Colors.white
                        : GlowColors.hotPink.withValues(alpha: 0.12),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: isToday ? Colors.white : GlowColors.text,
                    fontWeight: FontWeight.w900,
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

class TodayProgressCard extends StatelessWidget {
  const TodayProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Today’s Progress'),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                child: _ProgressPill(
                  label: 'Habits',
                  value: '6/8',
                  icon: Icons.check_circle_rounded,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _ProgressPill(
                  label: 'Water',
                  value: '1.8L',
                  icon: Icons.water_drop_rounded,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _ProgressPill(
                  label: 'Sleep',
                  value: '7.5h',
                  icon: Icons.bedtime_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...[
            'AM cleanse + SPF',
            'Workout or walk',
            'Night routine',
          ].map((task) => GlowChecklistTile(id: 'diary-$task', title: task)),
        ],
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: GlowColors.hotPink),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: GlowColors.muted)),
        ],
      ),
    );
  }
}

class SelfieTimelineStrip extends StatelessWidget {
  const SelfieTimelineStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Selfie timeline'),
        const SizedBox(height: 10),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, index) => Container(
              width: 92,
              decoration: BoxDecoration(
                gradient: GlowColors.cardGradient(index),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  'Week ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MetricData {
  const MetricData(this.title, this.value, this.icon, this.progress);

  final String title;
  final String value;
  final IconData icon;
  final double progress;
}

class PlanTileData {
  const PlanTileData(this.title, this.subtitle, this.duration, this.icon);

  final String title;
  final String subtitle;
  final String duration;
  final IconData icon;
}

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: GlowColors.hotPink, size: 30),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              Text(subtitle, style: const TextStyle(color: GlowColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

class GlowChecklistTile extends ConsumerWidget {
  const GlowChecklistTile({required this.id, required this.title, super.key});

  final String id;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = ref.watch(completedTasksProvider).contains(id);
    return CheckboxListTile(
      value: completed,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      activeColor: GlowColors.hotPink,
      onChanged: (_) {
        final current = {...ref.read(completedTasksProvider)};
        completed ? current.remove(id) : current.add(id);
        ref.read(completedTasksProvider.notifier).state = current;
      },
    );
  }
}

class GlowLookCard extends StatelessWidget {
  const GlowLookCard({required this.look, required this.onChoose, super.key});

  final GlowLook look;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 190,
            decoration: BoxDecoration(
              gradient: look.gradient,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: Center(
              child: Icon(look.icon, color: Colors.white, size: 76),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(look.name),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text('${look.percentage}% glow-up')),
                    Chip(label: Text(look.time)),
                    Chip(label: Text('${look.confidence}% confidence')),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onChoose,
                    child: const Text('Choose This Look'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GlowCameraPlaceholder extends StatelessWidget {
  const GlowCameraPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: GlowColors.primaryGradient),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.face_retouching_natural_rounded,
              size: 82,
              color: Colors.white,
            ),
            SizedBox(height: 12),
            Text(
              'Add your selfie',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ComparisonCard extends StatelessWidget {
  const ComparisonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Expanded(child: _comparisonPane('Before', 0)),
          const SizedBox(width: 12),
          Expanded(child: _comparisonPane('After', 1)),
        ],
      ),
    );
  }

  Widget _comparisonPane(String label, int index) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        gradient: GlowColors.cardGradient(index),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}

class MiniCharts extends StatelessWidget {
  const MiniCharts({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = const [
      ('Skin improvement', 0.68),
      ('Consistency', 0.82),
      ('Habit completion', 0.74),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Analytics'),
        const SizedBox(height: 12),
        ...metrics.map(
          (metric) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.$1,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: metric.$2),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({required this.message, super.key});

  final CoachMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: message.isUser ? GlowColors.primaryGradient : null,
          color: message.isUser ? null : Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : GlowColors.text,
          ),
        ),
      ),
    );
  }
}

class PremiumCard extends StatelessWidget {
  const PremiumCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            'its giving.AI Premium',
            icon: Icons.workspace_premium_rounded,
          ),
          const SizedBox(height: 8),
          const Text(
            'Unlimited AI scans, glow-up images, AI Coach, advanced skin analysis, weekly reports, and progress analytics.',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.lock_open_rounded),
            label: const Text('Unlock Premium'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Free plan: 3 scans/month, basic roadmap, limited AI chat.',
          ),
        ],
      ),
    );
  }
}

class GlowLook {
  const GlowLook({
    required this.name,
    required this.percentage,
    required this.time,
    required this.confidence,
    required this.icon,
    required this.gradient,
  });

  final String name;
  final int percentage;
  final String time;
  final int confidence;
  final IconData icon;
  final Gradient gradient;
}

class CoachMessage {
  const CoachMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class RoadmapSection {
  const RoadmapSection({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<String> items;
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.field,
    required this.options,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String field;
  final List<String> options;
}

class GlowColors {
  static const hotPink = Color(0xFFFF5FA2);
  static const text = Color(0xFF251B2F);
  static const muted = Color(0xFF755D75);

  static const primaryGradient = LinearGradient(
    colors: [Color(0xFFFF70B8), Color(0xFFFFB6D9), Color(0xFFB69CFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Gradient cardGradient(int seed) {
    final palettes = [
      const [Color(0xFFFF8FC7), Color(0xFFFFC1DE)],
      const [Color(0xFFB69CFF), Color(0xFFFFA8C7)],
      const [Color(0xFFFFB86B), Color(0xFFFF75AF)],
      const [Color(0xFF816BFF), Color(0xFFFF8FC7)],
      const [Color(0xFFFFD1E8), Color(0xFFB8A7FF)],
    ];
    final colors = palettes[seed % palettes.length];
    return LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      transform: GradientRotation(pi / 9),
    );
  }
}

const glowLooks = [
  GlowLook(
    name: 'Natural Glow',
    percentage: 72,
    time: '2-4 months',
    confidence: 91,
    icon: Icons.wb_sunny_rounded,
    gradient: LinearGradient(colors: [Color(0xFFFFB86B), Color(0xFFFF7BAC)]),
  ),
  GlowLook(
    name: 'Glass Skin',
    percentage: 84,
    time: '3-6 months',
    confidence: 88,
    icon: Icons.water_drop_rounded,
    gradient: LinearGradient(colors: [Color(0xFF96E6FF), Color(0xFFFFB6D9)]),
  ),
  GlowLook(
    name: 'Fitness Glow',
    percentage: 79,
    time: '4-8 months',
    confidence: 86,
    icon: Icons.fitness_center_rounded,
    gradient: LinearGradient(colors: [Color(0xFFFF8A65), Color(0xFFFFD180)]),
  ),
  GlowLook(
    name: 'Luxury Look',
    percentage: 90,
    time: '3-6 months',
    confidence: 93,
    icon: Icons.diamond_rounded,
    gradient: LinearGradient(colors: [Color(0xFF2E2140), Color(0xFFFF8FC7)]),
  ),
  GlowLook(
    name: 'Soft Glam',
    percentage: 87,
    time: '2-5 months',
    confidence: 94,
    icon: Icons.brush_rounded,
    gradient: LinearGradient(colors: [Color(0xFFFF9AC2), Color(0xFFB69CFF)]),
  ),
];

const roadmapSections = [
  RoadmapSection(
    title: 'Morning Routine',
    icon: Icons.light_mode_rounded,
    items: [
      'Gentle cleanse',
      'Vitamin C or hydrating serum',
      'Moisturizer',
      'SPF 50',
    ],
  ),
  RoadmapSection(
    title: 'Night Routine',
    icon: Icons.nightlight_round,
    items: [
      'Double cleanse',
      'Barrier serum',
      'Treatment nights 2x/week',
      'Lip mask',
    ],
  ),
  RoadmapSection(
    title: 'Workout Plan',
    icon: Icons.fitness_center_rounded,
    items: [
      '3 strength sessions',
      '2 low-impact walks',
      'Daily stretching',
      'Posture reset',
    ],
  ),
  RoadmapSection(
    title: 'Nutrition Plan',
    icon: Icons.restaurant_rounded,
    items: [
      'Protein breakfast',
      'Colorful lunch plate',
      'Omega-3 source',
      'Limit late sugar',
    ],
  ),
  RoadmapSection(
    title: 'Hydration & Sleep',
    icon: Icons.bedtime_rounded,
    items: [
      '2.2L water goal',
      'Electrolytes after workouts',
      '8 hour sleep window',
      'Phone down 45 min before bed',
    ],
  ),
  RoadmapSection(
    title: 'Haircare & Skincare',
    icon: Icons.spa_rounded,
    items: [
      'Weekly scalp care',
      'Heat protectant',
      'Patch test new actives',
      'Monthly routine review',
    ],
  ),
  RoadmapSection(
    title: 'Fashion Tips',
    icon: Icons.checkroom_rounded,
    items: [
      'Build color palette',
      'Tailored basics',
      'Signature scent',
      'Jewelry layering',
    ],
  ),
  RoadmapSection(
    title: 'Confidence Challenges',
    icon: Icons.psychology_alt_rounded,
    items: [
      'One compliment journal entry',
      'Posture walk',
      'Speak up once today',
      'Weekly solo date',
    ],
  ),
  RoadmapSection(
    title: 'Weekly Missions',
    icon: Icons.flag_rounded,
    items: [
      'Progress selfie',
      'Habit audit',
      'Refresh outfits',
      'Plan next week rituals',
    ],
  ),
];
