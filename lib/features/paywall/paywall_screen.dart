import 'package:flutter/material.dart';

import '../../core/services/decision_engine.dart';
import '../../core/storage/history_repository.dart';
import '../../core/storage/profile_repository.dart';
import '../home/home_screen.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({
    required this.decisionEngine,
    required this.historyRepository,
    required this.profileRepository,
    this.fromUpgrade = false,
    super.key,
  });

  final DecisionEngine decisionEngine;
  final HistoryRepository historyRepository;
  final ProfileRepository profileRepository;

  /// When true, the paywall is shown as an upgrade option from the profile
  /// screen and pressing back goes to profile instead of home.
  final bool fromUpgrade;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int? _selectedIndex;

  void _continueToHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          decisionEngine: widget.decisionEngine,
          historyRepository: widget.historyRepository,
          profileRepository: widget.profileRepository,
        ),
      ),
    );
  }

  void _dismiss(BuildContext context) {
    if (widget.fromUpgrade) {
      Navigator.of(context).pop();
    } else {
      _continueToHome(context);
    }
  }

  String _buttonLabel() {
    if (_selectedIndex == null) return 'Start Free';
    switch (_selectedIndex) {
      case 1:
        return 'Subscribe to Premium - \$2.99 / mo';
      case 2:
        return 'Subscribe to Pro - \$4.99 / mo';
      default:
        return 'Start Free';
    }
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard({
    required String tier,
    required String label,
    required String price,
    required String sublabel,
    required List<String> items,
    required Color borderColor,
    required Color backgroundColor,
    required bool highlighted,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 260,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected
                ? borderColor
                : borderColor.withValues(alpha: 0.5),
            width: isSelected ? 3.0 : 1.4,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 16),
                  ),
                ]
              : highlighted
              ? [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tier.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  tier,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            if (tier.isNotEmpty) const SizedBox(height: 18),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              price,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w800,
                fontSize: 32,
              ),
            ),
            if (sublabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  sublabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final background = const Color(0xFF0B0D1F);
    final accent = const Color(0xFF8D6CFF);
    final highlight = const Color(0xFF3D8DFF);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text('Decide AI'),
        leading: widget.fromUpgrade
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    const Text(
                      'Compare anything. Decide smarter.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Scan any two products and get AI-powered comparisons to help you make the right choice.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _CategoryChip(
                            label: 'Food',
                            icon: Icons.fastfood_rounded,
                          ),
                          _CategoryChip(
                            label: 'Cosmetics',
                            icon: Icons.brush_rounded,
                          ),
                          _CategoryChip(
                            label: 'Electronics',
                            icon: Icons.devices_other_rounded,
                          ),
                          _CategoryChip(
                            label: 'Gaming PCs',
                            icon: Icons.videogame_asset_rounded,
                          ),
                          _CategoryChip(
                            label: 'Household Goods',
                            icon: Icons.shopping_bag_rounded,
                          ),
                          _CategoryChip(
                            label: '& More',
                            icon: Icons.apps_rounded,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 440,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPricingCard(
                              tier: '',
                              label: 'Free',
                              price: '\$0',
                              sublabel: 'Forever free',
                              items: [
                                '7 comparisons per month',
                                'Basic AI insights',
                                'No save or share',
                                'Limited reports',
                              ],
                              borderColor: Colors.white24,
                              backgroundColor: const Color(0xFF111429),
                              highlighted: false,
                              index: 0,
                            ),
                            _buildPricingCard(
                              tier: 'MOST POPULAR',
                              label: 'PREMIUM',
                              price: '\$2.99',
                              sublabel: 'per month',
                              items: [
                                '50 comparisons per month',
                                'Detailed AI insights',
                                'Comparison chat',
                                'Save comparisons',
                                'Share results',
                              ],
                              borderColor: accent,
                              backgroundColor: const Color(0xFF241E49),
                              highlighted: true,
                              index: 1,
                            ),
                            _buildPricingCard(
                              tier: 'BEST VALUE',
                              label: 'PRO',
                              price: '\$4.99',
                              sublabel: 'per month',
                              items: [
                                'Unlimited comparisons',
                                'Everything in Premium',
                                'Advanced AI reports',
                                'Faster comparison processing',
                                'Priority support',
                              ],
                              borderColor: highlight,
                              backgroundColor: const Color(0xFF132043),
                              highlighted: false,
                              index: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151B34),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildFeatureItem(
                                Icons.smart_toy_rounded,
                                'AI-Powered Comparisons',
                                'Smart analysis of ingredients, specs & more.',
                              ),
                              const SizedBox(width: 20),
                              _buildFeatureItem(
                                Icons.shield_rounded,
                                'Trusted Insights',
                                'Get clear, accurate information to make smarter choices.',
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _buildFeatureItem(
                                Icons.history_rounded,
                                'Save & Access History',
                                'Keep your comparisons organized and access anytime.',
                              ),
                              const SizedBox(width: 20),
                              _buildFeatureItem(
                                Icons.share_rounded,
                                'Share Your Results',
                                'Share comparisons with friends and family.',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Text(
                        'By continuing, you agree to our Terms of Use and Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.52),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _dismiss(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _selectedIndex != null
                            ? accent
                            : Colors.white.withValues(alpha: 0.15),
                        foregroundColor: _selectedIndex != null
                            ? Colors.white
                            : Colors.white70,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _buttonLabel(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (!widget.fromUpgrade)
                    Column(
                      children: [
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => _continueToHome(context),
                          child: const Text('Already have an account? Sign In'),
                        ),
                      ],
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
