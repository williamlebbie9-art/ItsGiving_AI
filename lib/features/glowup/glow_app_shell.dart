import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'ai_coach_screen.dart';
import 'ai_face_scan_screen.dart';
import 'enhanced_onboarding_screen.dart';
import 'feature_cards_screen.dart';
import 'glow_up_plan_screen.dart';
import 'inspiration_screen.dart';
import 'paywall_screen.dart';
import 'plan_models.dart';
import 'plan_provider.dart';
import 'progress_tracking_screen.dart';
import 'vibe_screen.dart';

/// The pure "its giving.AI" glow-up shell with 6 tabs.
class GlowAppShell extends StatefulWidget {
  const GlowAppShell({super.key});

  @override
  State<GlowAppShell> createState() => _GlowAppShellState();
}

class _GlowAppShellState extends State<GlowAppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const GlowDashboardScreen(),
      const AiFaceScanScreen(),
      const GlowUpPlanScreen(),
      const ProgressTrackingScreen(),
      const AiCoachScreen(),
      const InspirationGalleryScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: NavigationBar(
            selectedIndex: _index,
            height: 72,
            backgroundColor: const Color(0xFFFDF2F8),
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
    );
  }
}

/// Dashboard with quick access to all glow-up features.
/// Uses a proper Loading → Data ready → Home displayed state flow.
class GlowDashboardScreen extends ConsumerStatefulWidget {
  const GlowDashboardScreen({super.key});

  @override
  ConsumerState<GlowDashboardScreen> createState() =>
      _GlowDashboardScreenState();
}

class _GlowDashboardScreenState extends ConsumerState<GlowDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(planProvider.notifier).loadPlan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(planProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF3FA), Color(0xFFFFE4F1), Color(0xFFEADFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(child: _buildBody(planState)),
    );
  }

  Widget _buildBody(PlanState planState) {
    // Loading state — show polished skeleton, never a blurry screen.
    if (planState.isLoading && planState.plan == null) {
      return const _HomeSkeleton();
    }

    // Error state — show a proper error with Try Again.
    if (planState.error != null && planState.plan == null) {
      return _HomeError(
        message: planState.error!,
        onRetry: () => ref.read(planProvider.notifier).loadPlan(),
      );
    }

    // Data ready — show the home screen with the user's plan.
    return _HomeContent(plan: planState.plan);
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.plan});

  final GlowUpPlan? plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDay = plan?.currentDayData;
    final currentWeek = plan?.currentWeekData;
    final dayLabel = plan != null ? 'Day ${plan!.currentDay} 🔥' : 'Ready ✨';

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
      children: [
        _BrandHeader(trailing: dayLabel),
        const SizedBox(height: 14),
        Text(
          'Your Glow Journey',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        const _GlowScanHeroCard(),
        const SizedBox(height: 18),
        const _DashboardQuickActions(),
        const SizedBox(height: 18),
        if (plan != null && currentDay != null && currentWeek != null)
          _TodayPlanCard(plan: plan!, day: currentDay, week: currentWeek)
        else
          const _NoPlanCard(),
        const SizedBox(height: 18),
        const _DailyGlowTipCard(),
      ],
    );
  }
}

/// Today's Glow-Up card — the main reason to return every day.
class _TodayPlanCard extends ConsumerWidget {
  const _TodayPlanCard({
    required this.plan,
    required this.day,
    required this.week,
  });

  final GlowUpPlan plan;
  final PlanDay day;
  final PlanWeek week;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Today\'s Glow-Up',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5FA2).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'Day ${plan.currentDay} — ${week.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFF5FA2),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...day.tasks
              .take(4)
              .map(
                (task) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        task.isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: task.isCompleted
                            ? const Color(0xFF2E7D32)
                            : Colors.grey[400],
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isCompleted ? Colors.grey : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 10),
          Text(
            '${day.completedCount}/${day.tasks.length} completed',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GlowUpPlanScreen()),
                );
              },
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Continue Plan →'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoPlanCard extends StatelessWidget {
  const _NoPlanCard();

  @override
  Widget build(BuildContext context) {
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
          Text(
            'Your 30-Day Glow-Up Awaits ✨',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete onboarding to get your personalized AI program with daily tasks, weekly goals, and progress tracking.',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EnhancedOnboardingScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Create My Plan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardQuickActions extends StatelessWidget {
  const _DashboardQuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width > 650 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.22,
          children: [
            _QuickActionButton(
              icon: Icons.auto_awesome_rounded,
              title: 'Enhance',
              subtitle: 'Feature cards',
              color: const Color(0xFFFF8FC7),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FeatureCardsScreen()),
                );
              },
            ),
            _QuickActionButton(
              icon: Icons.favorite_rounded,
              title: 'My Vibe',
              subtitle: 'Aesthetics',
              color: const Color(0xFFB69CFF),
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const VibeScreen()));
              },
            ),
            _QuickActionButton(
              icon: Icons.workspace_premium_rounded,
              title: 'Premium',
              subtitle: 'Unlock more',
              color: const Color(0xFFFFB86B),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                );
              },
            ),
            _QuickActionButton(
              icon: Icons.camera_alt_rounded,
              title: 'Scan Face',
              subtitle: 'AI analysis',
              color: const Color(0xFFFF5FA2),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AiFaceScanScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowScanHeroCard extends StatelessWidget {
  const _GlowScanHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8FC7), Color(0xFFB69CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5FA2).withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.face_retouching_natural_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Glow Scan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Analyze your features and get personalized glow-up directions.',
                  style: TextStyle(color: Colors.white, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyGlowTipCard extends StatelessWidget {
  const _DailyGlowTipCard();

  @override
  Widget build(BuildContext context) {
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
          Text(
            'AI tip of the day',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Consistency beats intensity. Small daily habits compound into visible glow — stick with your plan and trust the process.',
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends ConsumerWidget {
  const _BrandHeader({this.trailing});

  final String? trailing;

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    // Clear user-specific in-memory state.
    ref.read(usageProvider.notifier).reset();
    ref.read(subscriptionProvider.notifier).logOut();
    // Sign out of Firebase. The auth stream in app.dart will route to auth.
    await ref.read(authServiceProvider).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF70B8), Color(0xFFB69CFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'Log out',
          onPressed: () => _logout(context, ref),
        ),
      ],
    );
  }
}

/// Polished skeleton loading state — never a blurry screen.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
      children: [
        Row(
          children: [
            _SkeletonBox(width: 46, height: 46, radius: 16),
            const SizedBox(width: 12),
            _SkeletonBox(width: 140, height: 20, radius: 8),
          ],
        ),
        const SizedBox(height: 24),
        _SkeletonBox(width: 220, height: 28, radius: 8),
        const SizedBox(height: 18),
        _SkeletonBox(height: 120, radius: 24),
        const SizedBox(height: 18),
        _SkeletonBox(width: 100, height: 20, radius: 8),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _SkeletonBox(height: 110, radius: 20)),
            const SizedBox(width: 12),
            Expanded(child: _SkeletonBox(height: 110, radius: 20)),
          ],
        ),
        const SizedBox(height: 18),
        _SkeletonBox(height: 180, radius: 24),
        const SizedBox(height: 18),
        _SkeletonBox(height: 100, radius: 24),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({this.width, this.height = 16, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Error state with Try Again — the app must not crash.
class _HomeError extends StatelessWidget {
  const _HomeError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
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
            FilledButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}
