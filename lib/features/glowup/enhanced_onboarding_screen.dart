import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'glow_app_shell.dart';
import 'glow_models.dart';
import 'plan_provider.dart';

class EnhancedOnboardingScreen extends ConsumerStatefulWidget {
  const EnhancedOnboardingScreen({super.key});

  @override
  ConsumerState<EnhancedOnboardingScreen> createState() =>
      _EnhancedOnboardingScreenState();
}

class _OnboardingQuestion {
  const _OnboardingQuestion({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.storageKey,
  });

  final String title;
  final String subtitle;
  final List<String> options;
  final String storageKey;
}

class _EnhancedOnboardingScreenState
    extends ConsumerState<EnhancedOnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  final _answers = <String, String>{};
  bool _isFinishing = false;

  static const _questions = [
    _OnboardingQuestion(
      title: 'What is your main glow-up goal?',
      subtitle: 'This helps us personalize your journey',
      storageKey: 'glowup_goal',
      options: [
        'Clearer-looking skin',
        'Better hair',
        'Facial harmony',
        'Fitness/body goals',
        'Better style',
        'Confidence',
        'Complete transformation',
      ],
    ),
    _OnboardingQuestion(
      title: 'What is your current skincare routine?',
      subtitle: 'Be honest — this is your starting point',
      storageKey: 'glowup_skincare',
      options: [
        'None — I don\'t have one',
        'Basic cleanse + moisturize',
        'Regular routine with actives',
        'Advanced multi-step routine',
      ],
    ),
    _OnboardingQuestion(
      title: 'How often do you exercise?',
      subtitle: 'Your current baseline',
      storageKey: 'glowup_exercise',
      options: [
        'Rarely or never',
        '1-2 times a week',
        '3-4 times a week',
        '5+ times a week',
      ],
    ),
    _OnboardingQuestion(
      title: 'What is your typical sleep schedule?',
      subtitle: 'Sleep is your beauty superpower',
      storageKey: 'glowup_sleep',
      options: ['Less than 6 hours', '6-7 hours', '7-8 hours', '8+ hours'],
    ),
    _OnboardingQuestion(
      title: 'What aesthetic or vibe do you want?',
      subtitle: 'Pick what feels like YOU',
      storageKey: 'glowup_vibe',
      options: [
        'Clean girl',
        'Soft girl',
        'Old money',
        'Model-off-duty',
        'Feminine',
        'Sporty',
        'Natural beauty',
        'Edgy',
      ],
    ),
    _OnboardingQuestion(
      title: 'What is your skin type?',
      subtitle: 'For personalized recommendations',
      storageKey: 'glowup_skin_type',
      options: [
        'Combination',
        'Dry',
        'Oily',
        'Sensitive',
        'Normal',
        'Not sure',
      ],
    ),
    _OnboardingQuestion(
      title: 'What describes your lifestyle?',
      subtitle: 'Last question, promise!',
      storageKey: 'glowup_lifestyle',
      options: [
        'Busy student',
        'Work mode',
        'Gym era',
        'Soft life',
        'Balanced',
      ],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('glowup_onboarding_completed', true);

    final profile = GlowUserProfile(
      goal: _answers['glowup_goal'],
      skincareRoutine: _answers['glowup_skincare'],
      exerciseFrequency: _answers['glowup_exercise'],
      sleepSchedule: _answers['glowup_sleep'],
      aesthetic: _answers['glowup_vibe'],
      skinType: _answers['glowup_skin_type'],
      lifestyle: _answers['glowup_lifestyle'],
    );
    await prefs.setString('glowup_profile', jsonEncode(profile.toJson()));

    if (!mounted) return;

    // Generate the personalized 30-day plan in the background.
    // The Home screen will show a skeleton while this completes.
    ref.read(planProvider.notifier).generatePlan(profile: profile);

    // If onboarding was opened from within the app (e.g. "Create My Plan"
    // after skipping), pop back to the existing shell. Otherwise this is
    // the first-run flow, so replace this screen with the main shell.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GlowAppShell()),
      );
    }
  }

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
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (value) => setState(() => _page = value),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final q = _questions[index];
                  return Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF70B8),
                                    Color(0xFFFFB6D9),
                                    Color(0xFFB69CFF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'its giving.AI',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ),
                            TextButton(
                              onPressed: _isFinishing ? null : _finish,
                              child: const Text('Skip'),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          '${index + 1} of ${_questions.length}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          q.title,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          q.subtitle,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey[600], height: 1.4),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: ListView(
                            children: q.options.map((option) {
                              final isSelected =
                                  _answers[q.storageKey] == option;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildOption(
                                  option,
                                  isSelected,
                                  q.storageKey,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
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
                      _questions.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 8,
                        width: _page == index ? 28 : 8,
                        decoration: BoxDecoration(
                          color: _page == index
                              ? const Color(0xFFFF5FA2)
                              : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isFinishing
                          ? null
                          : _page == _questions.length - 1
                          ? _finish
                          : () {
                              _controller.nextPage(
                                duration: const Duration(milliseconds: 360),
                                curve: Curves.easeOutCubic,
                              );
                            },
                      child: _isFinishing
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text('Creating your plan...'),
                              ],
                            )
                          : Text(
                              _page == _questions.length - 1
                                  ? 'Start My Glow Journey ✨'
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

  Widget _buildOption(String option, bool isSelected, String storageKey) {
    return Material(
      color: Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          setState(() => _answers[storageKey] = option);
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? const Color(0xFFFF5FA2) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isSelected ? const Color(0xFFFF5FA2) : Colors.grey[400],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
