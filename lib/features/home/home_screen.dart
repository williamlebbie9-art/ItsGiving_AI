import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/decision_models.dart';
import '../../core/services/decision_engine.dart';
import '../../core/storage/comparison_repository.dart';
import '../../core/storage/history_repository.dart';
import '../../core/storage/profile_repository.dart';
import '../analysis/cosmetic_analysis_screen.dart';
import '../analysis/food_analysis_screen.dart';
import '../products/comparison_result_screen.dart';
import '../products/product_comparison_screen.dart';
import '../products/saved_comparisons_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.decisionEngine,
    required this.historyRepository,
    required this.profileRepository,
    super.key,
  });

  final DecisionEngine decisionEngine;
  final HistoryRepository historyRepository;
  final ProfileRepository profileRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ComparisonRepository _comparisonRepository;

  @override
  void initState() {
    super.initState();
    _comparisonRepository = ComparisonRepository();
  }

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomePage(context),
            _buildCompareTab(context),
            _buildFoodTab(context),
            _buildCosmeticTab(context),
            _buildSavedTab(context),
            _buildProfileTab(context),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.compare_arrows_outlined),
            selectedIcon: Icon(Icons.compare_arrows_rounded),
            label: 'Compare',
          ),
          NavigationDestination(
            icon: Icon(Icons.fastfood_outlined),
            selectedIcon: Icon(Icons.fastfood_rounded),
            label: 'Food',
          ),
          NavigationDestination(
            icon: Icon(Icons.brush_outlined),
            selectedIcon: Icon(Icons.brush_rounded),
            label: 'Cosmetics',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark_rounded),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(child: _buildHeader(context)),

        // Primary comparison cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildPrimaryActionSection(context),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Recent Comparisons Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildRecentSection(context),
          ),
        ),

        SliverToBoxAdapter(
          child: FutureBuilder<List<ProductComparison>>(
            future: _comparisonRepository.list(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final comparisons = snapshot.data ?? [];
              if (comparisons.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
                  child: Text(
                    'No comparisons yet. Start by comparing two products!',
                  ),
                );
              }

              return Column(
                children: comparisons
                    .take(3)
                    .map(
                      (comparison) => _buildComparisonItem(context, comparison),
                    )
                    .toList(),
              );
            },
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Saved Comparisons Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildSavedSection(context),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB56AF5), Color(0xFF6B8CFF)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x221D245C),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.compare_arrows_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Product Compare',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Compare two products side-by-side with AI analysis',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.96),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Start a comparison',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildPrimaryCard(
          context,
          title: 'General Product Comparison',
          subtitle:
              'Compare electronics, phones, appliances, and everyday consumer goods.',
          icon: Icons.compare_arrows_rounded,
          onTap: () => _openComparison(context),
        ),
        const SizedBox(height: 12),
        _buildPrimaryCard(
          context,
          title: 'Food Analysis',
          subtitle:
              'Compare ingredients, nutrition, additives, allergens and health scores.',
          icon: Icons.fastfood_rounded,
          onTap: () => _openFoodAnalysis(context),
        ),
        const SizedBox(height: 12),
        _buildPrimaryCard(
          context,
          title: 'Cosmetic Analysis',
          subtitle:
              'Compare skincare and beauty products using ingredient intelligence.',
          icon: Icons.brush_rounded,
          onTap: () => _openCosmeticAnalysis(context),
        ),
      ],
    );
  }

  Widget _buildPrimaryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompareTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compare Products',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'A clean interface for comparing general products, electronics, and consumer goods.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _buildPrimaryCard(
            context,
            title: 'General Product Comparison',
            subtitle:
                'Upload or scan two items to compare specs and recommendations.',
            icon: Icons.devices_rounded,
            onTap: () => _openComparison(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Food Analysis',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Compare ingredients, nutrition, additives, allergens and health scores for food and beverage products.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _buildPrimaryCard(
            context,
            title: 'Scan food products',
            subtitle:
                'Upload or scan labels for nutrition and ingredient insights.',
            icon: Icons.fastfood_rounded,
            onTap: () => _openFoodAnalysis(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCosmeticTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cosmetic Analysis',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Compare skincare and beauty products using ingredient intelligence and skin compatibility analysis.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _buildPrimaryCard(
            context,
            title: 'Scan cosmetic products',
            subtitle:
                'Upload or scan ingredient lists for active ingredient insights.',
            icon: Icons.brush_rounded,
            onTap: () => _openCosmeticAnalysis(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saved Comparisons',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Review saved product comparisons, analysis history, and detailed recommendations.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _buildSavedSection(context),
        ],
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context) {
    return ProfileScreen(
      profileRepository: widget.profileRepository,
      decisionEngine: widget.decisionEngine,
      historyRepository: widget.historyRepository,
    );
  }

  Widget _buildRecentSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Comparisons',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: () => _openSavedComparisons(context),
          child: const Text('View All'),
        ),
      ],
    );
  }

  Widget _buildSavedSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Comparisons',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: Card(
            child: InkWell(
              onTap: () => _openSavedComparisons(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.bookmark_rounded,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'View all saved comparisons',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Search and manage your history',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonItem(
    BuildContext context,
    ProductComparison comparison,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final formattedDate = dateFormat.format(comparison.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openComparisonDetail(context, comparison),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.compare_arrows_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${comparison.productAName} vs ${comparison.productBName}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  void _openComparison(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductComparisonScreen(
          decisionEngine: widget.decisionEngine,
          comparisonRepository: _comparisonRepository,
          historyRepository: widget.historyRepository,
          profileRepository: widget.profileRepository,
        ),
      ),
    );
  }

  void _openComparisonDetail(
    BuildContext context,
    ProductComparison comparison,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ComparisonResultScreen(
          comparison: comparison,
          decisionEngine: widget.decisionEngine,
          comparisonRepository: _comparisonRepository,
          startChatExpanded: true,
        ),
      ),
    );
  }

  void _openSavedComparisons(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SavedComparisonsScreen(
          comparisonRepository: _comparisonRepository,
          decisionEngine: widget.decisionEngine,
        ),
      ),
    );
  }

  void _openFoodAnalysis(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FoodAnalysisScreen(
          decisionEngine: widget.decisionEngine,
          comparisonRepository: _comparisonRepository,
        ),
      ),
    );
  }

  void _openCosmeticAnalysis(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CosmeticAnalysisScreen(
          decisionEngine: widget.decisionEngine,
          comparisonRepository: _comparisonRepository,
        ),
      ),
    );
  }
}
