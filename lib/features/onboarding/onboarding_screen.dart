import 'dart:math';
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
      subtitle:
          'Compare products, foods, skincare, and perfumes instantly with AI.',
      buttonLabel: 'Continue',
      illustration: _OnboardingIllustration.splitProducts,
    ),
    _OnboardingPage(
      title: 'Scan & Compare',
      subtitle:
          'Take a photo or upload images of two products and let its giving.AI analyze the differences.',
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
          'its giving.AI summarizes the important differences and helps you choose the better option for your needs.',
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
                    child: SingleChildScrollView(
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
                          SizedBox(
                            height: min(
                              320,
                              MediaQuery.of(context).size.height * 0.42,
                            ),
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
    // Build illustration using available constraints so child widgets can size
    // themselves relative to the available area and avoid fixed-height overflows.
    return LayoutBuilder(
      builder: (context, constraints) {
        final box = BoxConstraints(
          maxWidth: min(760, constraints.maxWidth),
          maxHeight: constraints.maxHeight,
        );

        Widget content;
        switch (type) {
          case _OnboardingIllustration.splitProducts:
            content = _buildSplitProducts(box);
            break;
          case _OnboardingIllustration.compareItems:
            content = _buildCompareItems(box);
            break;
          case _OnboardingIllustration.foodAnalysis:
            content = _buildFoodAnalysis(box);
            break;
          case _OnboardingIllustration.cosmeticsAnalysis:
            content = _buildCosmeticsAnalysis(box);
            break;
          case _OnboardingIllustration.aiVerdict:
            content = _buildAiVerdict(box);
            break;
          case _OnboardingIllustration.readyToDecide:
            content = _buildReadyToDecide(box);
            break;
        }

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: box.maxWidth,
                maxHeight: min(600, box.maxHeight),
              ),
              child: content,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSplitProducts(BoxConstraints box) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 20,
            child: _productCard(
              box: box,
              color: colorScheme.primaryContainer,
              icon: Icons.shopping_bag_rounded,
              label: 'Product A',
            ),
          ),
          Positioned(
            right: 20,
            child: _productCard(
              box: box,
              color: colorScheme.secondaryContainer,
              icon: Icons.shopping_bag_outlined,
              label: 'Product B',
            ),
          ),
          Container(
            width: min(220, box.maxWidth * 0.45),
            height: min(280, box.maxHeight * 0.85),
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

  Widget _buildCompareItems(BoxConstraints box) {
    final containerHeight = min(200.0, box.maxHeight * 0.6);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _featureBubble(
            color: colorScheme.primaryContainer,
            icon: Icons.camera_alt_rounded,
            label: 'Photo',
          ),
          SizedBox(height: max(12, box.maxHeight * 0.04)),
          Container(
            height: containerHeight,
            width: box.maxWidth,
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
                  top: containerHeight * 0.08,
                  left: box.maxWidth * 0.04,
                  child: _smallCard(
                    box: box,
                    icon: Icons.local_grocery_store_rounded,
                    label: 'A',
                  ),
                ),
                Positioned(
                  bottom: containerHeight * 0.08,
                  right: box.maxWidth * 0.04,
                  child: _smallCard(
                    box: box,
                    icon: Icons.laptop_mac_rounded,
                    label: 'B',
                  ),
                ),
                Positioned(
                  top: containerHeight * 0.12,
                  right: box.maxWidth * 0.08,
                  child: Text(
                    'Compare',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: max(14, box.maxHeight * 0.03),
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

  Widget _buildFoodAnalysis(BoxConstraints box) {
    final mainSize = min(260.0, box.maxHeight * 0.8);
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: max(12, box.maxWidth * 0.06),
            child: _nutritionCard(
              box: box,
              label: 'Nutrition',
              icon: Icons.restaurant_rounded,
              color: colorScheme.primaryContainer,
            ),
          ),
          Positioned(
            right: max(12, box.maxWidth * 0.06),
            child: _nutritionCard(
              box: box,
              label: 'Ingredients',
              icon: Icons.eco_rounded,
              color: colorScheme.secondaryContainer,
            ),
          ),
          Container(
            width: mainSize,
            height: mainSize,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Center(
              child: Icon(
                Icons.fastfood_rounded,
                size: min(88, mainSize * 0.32),
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCosmeticsAnalysis(BoxConstraints box) {
    final outer = min(160.0, box.maxHeight * 0.7);
    final inner = outer * 0.72;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              _circleDot(color: colorScheme.primaryContainer, size: outer),
              _circleDot(color: colorScheme.secondaryContainer, size: inner),
              Container(
                width: inner * 0.9,
                height: inner * 0.9,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(38),
                ),
                child: Icon(
                  Icons.spa_rounded,
                  size: min(60, inner * 0.5),
                  color: const Color(0xFF8843FF),
                ),
              ),
            ],
          ),
          SizedBox(height: max(14, box.maxHeight * 0.06)),
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

  Widget _buildAiVerdict(BoxConstraints box) {
    final cardSize = min(280.0, box.maxHeight * 0.78);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: cardSize,
            height: cardSize,
            padding: EdgeInsets.all(max(12, cardSize * 0.06)),
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
                      size: max(18, cardSize * 0.08),
                    ),
                    SizedBox(width: max(8, cardSize * 0.03)),
                    Text(
                      'Winner',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: max(14, cardSize * 0.06),
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.bar_chart_rounded,
                  size: min(84, cardSize * 0.22),
                  color: const Color(0xFF6C63FF),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Pros',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        fontSize: max(12, cardSize * 0.045),
                      ),
                    ),
                    SizedBox(height: max(6, cardSize * 0.02)),
                    Text(
                      'Clear recommendation',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.75),
                        fontSize: max(12, cardSize * 0.04),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: max(12, box.maxHeight * 0.04)),
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

  Widget _buildReadyToDecide(BoxConstraints box) {
    final size = min(260.0, box.maxHeight * 0.72);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Center(
              child: Icon(
                Icons.rocket_launch_rounded,
                size: min(84, size * 0.28),
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: max(12, box.maxHeight * 0.04)),
          Text(
            'Ready to decide faster and smarter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.75),
              fontSize: max(12, box.maxHeight * 0.035),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard({
    required BoxConstraints box,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      width: min(160, box.maxWidth * 0.18),
      height: min(220, box.maxHeight * 0.7),
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

  Widget _smallCard({
    required BoxConstraints box,
    required IconData icon,
    required String label,
  }) {
    final double w = min(110.0, box.maxWidth * 0.14);
    final double h = min(120.0, box.maxHeight * 0.32);
    return Container(
      width: w,
      height: h,
      padding: EdgeInsets.all(max(8, w * 0.09)),
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
          Icon(icon, color: colorScheme.primary, size: min(28, w * 0.28)),
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
    required BoxConstraints box,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: min(180, box.maxWidth * 0.22),
      height: min(180, box.maxHeight * 0.5),
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
