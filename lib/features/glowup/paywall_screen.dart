import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _checkPremium();
  }

  Future<void> _checkPremium() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _isPremium = prefs.getBool('glowup_premium') ?? false);
    }
  }

  Future<void> _upgrade() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _isPremium = true);
    await prefs.setBool('glowup_premium', true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Welcome to Premium! ✨ Your glow-up experience is unlocked.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unlock Premium'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _isPremium ? 'You\'re Premium ✨' : 'Elevate Your Glow Journey ✨',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Text(
            _isPremium
                ? 'Enjoy unlimited AI scans, personalized plans, and advanced recommendations!'
                : 'Choose what works for you. Start free, upgrade anytime.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          _buildTierCard(
            title: 'FREE',
            price: '\$0',
            features: const [
              'Basic face analysis',
              'Limited recommendations',
              'Basic daily challenges',
              'Limited inspiration',
              '3 scans per month',
            ],
            isPremium: false,
            isCurrent: !_isPremium,
            onTap: _isPremium ? null : () => _downgrade(),
            buttonLabel: _isPremium ? 'Current Plan' : 'Start Free',
          ),
          const SizedBox(height: 16),
          _buildTierCard(
            title: 'PREMIUM',
            price: '\$9.99/mo',
            features: const [
              'Full AI face analysis',
              'Personalized 30-day glow-up plan',
              'Unlimited AI coach',
              'Advanced recommendations',
              'Personalized aesthetics & vibes',
              'Progress analysis',
              'Unlimited inspiration',
              'Detailed routines & reminders',
            ],
            isPremium: true,
            isCurrent: _isPremium,
            onTap: _isPremium ? null : _upgrade,
            buttonLabel: _isPremium ? 'Current Plan' : 'Go Premium',
          ),
          const SizedBox(height: 20),
          Text(
            'You can cancel anytime. Premium enhances your experience — it never replaces your natural beauty. 💕',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Future<void> _downgrade() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isPremium = false);
    await prefs.setBool('glowup_premium', false);
  }

  Widget _buildTierCard({
    required String title,
    required String price,
    required List<String> features,
    required bool isPremium,
    required bool isCurrent,
    required VoidCallback? onTap,
    required String buttonLabel,
  }) {
    final color = isPremium ? const Color(0xFFFF5FA2) : Colors.grey[700]!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPremium ? const Color(0xFFFF5FA2) : Colors.grey[300]!,
          width: isPremium ? 2 : 1,
        ),
        boxShadow: isPremium
            ? [
                BoxShadow(
                  color: const Color(0xFFFF5FA2).withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 1.5,
                ),
              ),
              if (isPremium) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5FA2).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'MOST POPULAR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFF5FA2),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            price,
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, size: 20, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feature,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              style: isPremium
                  ? null
                  : FilledButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.grey[800],
                    ),
              onPressed: isCurrent ? null : onTap,
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
