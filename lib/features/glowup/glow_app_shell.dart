import 'dart:ui';

import 'package:flutter/material.dart';

import 'ai_coach_screen.dart';
import 'ai_face_scan_screen.dart';
import 'daily_glow_screen.dart';
import 'feature_cards_screen.dart';
import 'glowup_app.dart';
import 'inspiration_screen.dart';
import 'paywall_screen.dart';
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
      const DailyGlowScreen(),
      const ProgressTrackingScreen(),
      const AiCoachScreen(),
      const InspirationGalleryScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
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

/// Dashboard with quick access to all glow-up features.
class GlowDashboardScreen extends StatelessWidget {
  const GlowDashboardScreen({super.key});

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
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
          children: [
            const GlowBrandHeader(trailing: 'Day 12 🔥'),
            const SizedBox(height: 14),
            Text(
              'Your Glow Journey',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            const GlowScanHeroCard(),
            const SizedBox(height: 18),
            const _DashboardQuickActions(),
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
