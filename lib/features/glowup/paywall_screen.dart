import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/app_providers.dart';

/// Polished, modern Gen-Z female beauty/glow-up paywall.
///
/// Powered by RevenueCat. The yearly plan is the recommended option.
/// Shows a Free vs Premium comparison and dynamic CTA based on selection.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.triggerReason});

  /// Optional reason the paywall was shown (e.g. "You've used your free scan").
  final String? triggerReason;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _yearlySelected = true;
  bool _purchasing = false;
  String? _error;
  List<Package> _packages = const [];

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    final packages = await ref.read(subscriptionServiceProvider).getPackages();
    if (!mounted) return;
    setState(() => _packages = packages);
  }

  Package? get _selectedPackage {
    if (_packages.isEmpty) return null;
    // Prefer yearly if selected, otherwise monthly.
    if (_yearlySelected) {
      return _packages.firstWhere(
        (p) => p.storeProduct.identifier.toLowerCase().contains('yearly'),
        orElse: () => _packages.first,
      );
    }
    return _packages.firstWhere(
      (p) => p.storeProduct.identifier.toLowerCase().contains('monthly'),
      orElse: () => _packages.first,
    );
  }

  Future<void> _purchase() async {
    final package = _selectedPackage;
    if (package == null || _purchasing) return;

    setState(() {
      _purchasing = true;
      _error = null;
    });

    final success = await ref
        .read(subscriptionProvider.notifier)
        .purchase(package);

    if (!mounted) return;
    setState(() => _purchasing = false);

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      final state = ref.read(subscriptionProvider);
      setState(
        () => _error = state.error ?? 'Purchase failed. Please try again.',
      );
    }
  }

  Future<void> _restore() async {
    if (_purchasing) return;
    setState(() {
      _purchasing = true;
      _error = null;
    });

    final success = await ref
        .read(subscriptionProvider.notifier)
        .restorePurchases();

    if (!mounted) return;
    setState(() => _purchasing = false);

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'No previous purchases found to restore.');
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(subscriptionProvider).isPremium;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _restore,
                  child: const Text('Restore Purchases'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF70B8), Color(0xFFB69CFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isPremium
                  ? 'You\'re Premium ✨'
                  : 'Your glow-up doesn\'t stop here ✨',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              isPremium
                  ? 'Enjoy unlimited AI scans, personalized plans, and advanced recommendations!'
                  : 'Unlock your full personalized glow-up journey.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
            if (widget.triggerReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.triggerReason!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
            const SizedBox(height: 20),
            _buildComparisonCard(),
            const SizedBox(height: 16),
            _buildPlanCard(
              title: 'MONTHLY',
              price: '\$9.99/month',
              trial: '3-day free trial',
              isSelected: !_yearlySelected,
              onTap: () => setState(() => _yearlySelected = false),
            ),
            const SizedBox(height: 12),
            _buildPlanCard(
              title: 'YEARLY',
              price: '\$69.99/year',
              trial: '7-day free trial',
              isSelected: _yearlySelected,
              isBestValue: true,
              onTap: () => setState(() => _yearlySelected = true),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _purchasing ? null : _purchase,
                child: _purchasing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _yearlySelected
                            ? 'Start 7-Day Free Trial'
                            : 'Start 3-Day Free Trial',
                      ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB00020)),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Free trial, then \$9.99/month or \$69.99/year. Cancel anytime. '
              'Payment will be charged to your App Store / Google Play account. '
              'Subscription renews automatically unless cancelled at least 24 hours '
              'before the end of the current period.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => _openUrl('https://itsgiving.ai/terms'),
                  child: const Text('Terms of Use'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _openUrl('https://itsgiving.ai/privacy'),
                  child: const Text('Privacy Policy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD8EA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildComparisonColumn(
              title: 'FREE',
              color: Colors.grey[700]!,
              items: const [
                '1 introductory face scan',
                '3 AI Coach insights',
                '1 glow-up plan',
                'Limited recommendations',
              ],
            ),
          ),
          Container(width: 1, height: 160, color: const Color(0xFFFFD8EA)),
          const SizedBox(width: 12),
          Expanded(
            child: _buildComparisonColumn(
              title: 'PREMIUM',
              color: const Color(0xFFFF5FA2),
              items: const [
                'Unlimited face scans',
                'Unlimited AI Coach',
                'Unlimited glow-up plans',
                'Full personalized recommendations',
                'Full progress tracking',
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonColumn({
    required String title,
    required Color color,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_rounded, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 12, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String trial,
    required bool isSelected,
    required VoidCallback onTap,
    bool isBestValue = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0F7) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF5FA2) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? const Color(0xFFFF5FA2) : Colors.grey[400],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (isBestValue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5FA2),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text(
                            'BEST VALUE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    trial,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
