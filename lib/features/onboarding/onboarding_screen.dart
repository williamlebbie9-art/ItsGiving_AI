import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/decision_engine.dart';
import '../../core/storage/history_repository.dart';
import '../../core/storage/profile_repository.dart';
import '../auth/sign_in_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    required this.decisionEngine,
    required this.historyRepository,
    required this.profileRepository,
    super.key,
  });

  final DecisionEngine decisionEngine;
  final HistoryRepository historyRepository;
  final ProfileRepository profileRepository;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _activePage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      title: 'Make Smarter Choices',
      subtitle: 'Compare products, foods, and cosmetics instantly with AI.',
      buttonLabel: 'Continue',
      illustration: _OnboardingIllustration.splitProducts,
    ),
    _OnboardingPage(
      title: 'Scan & Compare',
      subtitle:
          'Take a photo or upload images of two products and let Decide AI analyze the differences.',
      highlights: [
        'Product comparisons',
        'Feature breakdowns',
        'Price insights',
        'Pros & cons',
      ],
      buttonLabel: 'Next',
      illustration: _OnboardingIllustration.compareItems,
    ),
    _OnboardingPage(
      title: 'Know What You Eat',
      subtitle:
          'Compare food products by ingredients, nutrition, additives, and overall quality.',
      highlights: [
        'Ingredient analysis',
        'Nutrition comparison',
        'Health insights',
      ],
      buttonLabel: 'Next',
      illustration: _OnboardingIllustration.foodAnalysis,
    ),
    _OnboardingPage(
      title: 'Understand Your Skincare',
      subtitle:
          'Discover ingredient differences, potential irritants, and key benefits before you buy.',
      highlights: [
        'Ingredient breakdown',
        'Skin-friendly insights',
        'Product recommendations',
      ],
      buttonLabel: 'Next',
      illustration: _OnboardingIllustration.cosmeticsAnalysis,
    ),
    _OnboardingPage(
      title: 'Get Clear Recommendations',
      subtitle:
          'Decide AI summarizes the important differences and helps you choose the better option for your needs.',
      buttonLabel: 'Next',
      illustration: _OnboardingIllustration.aiVerdict,
    ),
    _OnboardingPage(
      title: 'Start Comparing',
      subtitle:
          'Join thousands of users making informed decisions with AI-powered comparisons.',
      buttonLabel: 'Start Free',
      alternativeButtonLabel: 'Sign In',
      illustration: _OnboardingIllustration.readyToDecide,
    ),
  ];

  void _goToNextPage() {
    if (_activePage == _pages.length - 1) {
      _finishOnboarding();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SignInScreen(
          decisionEngine: widget.decisionEngine,
          historyRepository: widget.historyRepository,
          profileRepository: widget.profileRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _activePage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _OnboardingHeader(
                          stepIndex: index,
                          page: page,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 28),
                        Expanded(
                          child: _OnboardingIllustrationWidget(
                            type: page.illustration,
                            colorScheme: colorScheme,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          page.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 32,
                              ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          page.subtitle,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.75,
                                ),
                                height: 1.5,
                              ),
                        ),
                        if (page.highlights != null) ...[
                          const SizedBox(height: 24),
                          _OnboardingHighlights(items: page.highlights!),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                children: [
                  _PageIndicator(
                    count: _pages.length,
                    activeIndex: _activePage,
                    activeColor: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  if (_activePage == _pages.length - 1) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _finishOnboarding,
                            child: Text(_pages[_activePage].buttonLabel),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        _pages[_activePage].alternativeButtonLabel ?? 'Sign In',
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _goToNextPage,
                        child: Text(_pages[_activePage].buttonLabel),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.illustration,
    this.highlights,
    this.alternativeButtonLabel,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final String? alternativeButtonLabel;
  final List<String>? highlights;
  final _OnboardingIllustration illustration;
}

enum _OnboardingIllustration {
  splitProducts,
  compareItems,
  foodAnalysis,
  cosmeticsAnalysis,
  aiVerdict,
  readyToDecide,
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.count,
    required this.activeIndex,
    required this.activeColor,
  });

  final int count;
  final int activeIndex;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == activeIndex ? 28 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: index == activeIndex
                ? activeColor
                : activeColor.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _OnboardingHighlights extends StatelessWidget {
  const _OnboardingHighlights({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.78),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.stepIndex,
    required this.page,
    required this.colorScheme,
  });

  final int stepIndex;
  final _OnboardingPage page;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Step ${stepIndex + 1} of 6',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        Text(
          page.buttonLabel,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}

class _OnboardingIllustrationWidget extends StatelessWidget {
  const _OnboardingIllustrationWidget({
    required this.type,
    required this.colorScheme,
  });

  final _OnboardingIllustration type;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case _OnboardingIllustration.splitProducts:
        return _buildSplitProducts();
      case _OnboardingIllustration.compareItems:
        return _buildCompareItems();
      case _OnboardingIllustration.foodAnalysis:
        return _buildFoodAnalysis();
      case _OnboardingIllustration.cosmeticsAnalysis:
        return _buildCosmeticsAnalysis();
      case _OnboardingIllustration.aiVerdict:
        return _buildAiVerdict();
      case _OnboardingIllustration.readyToDecide:
        return _buildReadyToDecide();
    }
  }

  Widget _buildSplitProducts() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 20,
            child: _productCard(
              color: colorScheme.primaryContainer,
              icon: Icons.shopping_bag_rounded,
              label: 'Product A',
            ),
          ),
          Positioned(
            right: 20,
            child: _productCard(
              color: colorScheme.secondaryContainer,
              icon: Icons.shopping_bag_outlined,
              label: 'Product B',
            ),
          ),
          Container(
            width: 180,
            height: 230,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.memory_rounded,
                  size: 48,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'AI Compare',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fast insights with one tap',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompareItems() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _featureBubble(
            color: colorScheme.primaryContainer,
            icon: Icons.camera_alt_rounded,
            label: 'Photo',
          ),
          const SizedBox(height: 18),
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 18,
                  left: 18,
                  child: _smallCard(
                    icon: Icons.local_grocery_store_rounded,
                    label: 'A',
                  ),
                ),
                Positioned(
                  bottom: 18,
                  right: 18,
                  child: _smallCard(icon: Icons.laptop_mac_rounded, label: 'B'),
                ),
                Positioned(
                  top: 28,
                  right: 28,
                  child: Text(
                    'Compare',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodAnalysis() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 40,
            child: _nutritionCard(
              label: 'Nutrition',
              icon: Icons.restaurant_rounded,
              color: colorScheme.primaryContainer,
            ),
          ),
          Positioned(
            right: 40,
            child: _nutritionCard(
              label: 'Ingredients',
              icon: Icons.eco_rounded,
              color: colorScheme.secondaryContainer,
            ),
          ),
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Center(
              child: Icon(
                Icons.fastfood_rounded,
                size: 72,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCosmeticsAnalysis() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              _circleDot(color: colorScheme.primaryContainer),
              _circleDot(color: colorScheme.secondaryContainer, size: 116),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(38),
                ),
                child: const Icon(
                  Icons.spa_rounded,
                  size: 60,
                  color: Color(0xFF8843FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _featureBubble(
            color: colorScheme.surfaceContainerHighest,
            icon: Icons.health_and_safety_rounded,
            label: 'Skin-friendly insights',
            textColor: colorScheme.onSurface,
          ),
        ],
      ),
    );
  }

  Widget _buildAiVerdict() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 240,
            height: 240,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Winner',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.bar_chart_rounded,
                  size: 64,
                  color: Color(0xFF6C63FF),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Pros',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Clear recommendation',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'AI verdict keeps the choice simple and actionable.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.72),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyToDecide() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Center(
              child: Icon(
                Icons.rocket_launch_rounded,
                size: 72,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Ready to decide faster and smarter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.75),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard({
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      width: 128,
      height: 182,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 36, color: colorScheme.onPrimary),
          const Spacer(),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallCard({required IconData icon, required String label}) {
    return Container(
      width: 82,
      height: 92,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary, size: 24),
          const Spacer(),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutritionCard({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 144,
      height: 132,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: colorScheme.onPrimary),
          const Spacer(),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureBubble({
    required Color color,
    required IconData icon,
    required String label,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor ?? colorScheme.onSurface, size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: textColor ?? colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleDot({required Color color, double size = 88}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
