import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/user_journey_provider.dart';
import 'ai_face_scan_screen.dart';
import 'glow_app_shell.dart';
import 'glow_up_generator_screen.dart';
import 'glowup_app.dart';
import 'intro_paywall_auth_gate.dart';

/// The mandatory first-run intro flow for new users:
///
///   face scan → real AI results → paywall → auth → personalized plan → Home
///
/// This flow is shown ONLY based on persistent app state
/// (onboarding completed, intro scan not yet completed) — not on Firebase
/// authentication status.
class AiFaceScanIntroFlow extends ConsumerStatefulWidget {
  const AiFaceScanIntroFlow({super.key});

  @override
  ConsumerState<AiFaceScanIntroFlow> createState() =>
      _AiFaceScanIntroFlowState();
}

class _AiFaceScanIntroFlowState extends ConsumerState<AiFaceScanIntroFlow> {
  bool _hasSavedResults = false;
  bool _checkingResults = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSavedResults());
  }

  Future<void> _checkSavedResults() async {
    final prefs = await SharedPreferences.getInstance();
    final summary = prefs.getString('glowup_last_scan_summary');
    final hasSavedSummary = summary != null && summary.isNotEmpty;
    if (!mounted) return;
    setState(() {
      _hasSavedResults = hasSavedSummary;
      _checkingResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingResults) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // The user already used their introductory scan (persisted usage) and we
    // have their real AI analysis saved — continue from the results.
    if (_hasSavedResults) {
      return const _IntroResultsContinuation();
    }

    // First scan — show the real AI face scan screen.
    return const AiFaceScanScreen(isIntroFlow: true);
  }
}

/// Shown when a returning user already completed their introductory face scan
/// but never finished the paywall → auth → plan step. Loads the REAL saved AI
/// analysis and lets them continue building their glow-up plan.
class _IntroResultsContinuation extends ConsumerStatefulWidget {
  const _IntroResultsContinuation();

  @override
  ConsumerState<_IntroResultsContinuation> createState() =>
      _IntroResultsContinuationState();
}

class _IntroResultsContinuationState
    extends ConsumerState<_IntroResultsContinuation> {
  String? _summary;
  String? _imagePath;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final summary = prefs.getString('glowup_last_scan_summary');
    var imagePath = prefs.getString('glowup_last_scan_image_path');
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        if (!File(imagePath).existsSync()) imagePath = null;
      } catch (_) {
        imagePath = null;
      }
    }
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _imagePath = imagePath;
      _loading = false;
    });
  }

  Future<void> _continueToPlan() async {
    final summary = _summary;
    if (summary == null) return;
    final imagePath = _imagePath ?? '';
    if (!mounted) return;

    // Show the paywall then the auth screen before continuing to the
    // glow-up generator / plan builder.
    final completedGate = await showIntroPaywallAuthGate(context, ref);
    if (!completedGate) return;
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GlowUpGeneratorScreen(
          imagePath: imagePath,
          faceScanSummary: summary,
          isIntroFlow: true,
        ),
      ),
    );
  }

  /// Allows the user to skip the intro flow and go straight to the app.
  ///
  /// The paywall and auth screen are ALWAYS shown before entering the app,
  /// even when skipping the plan builder.
  Future<void> _skipFlow() async {
    // Show the paywall then the auth screen before entering the app.
    final completedGate = await showIntroPaywallAuthGate(context, ref);
    if (!completedGate) return;
    if (!mounted) return;

    await ref.read(userJourneyProvider.notifier).markIntroFlowCompleted();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const GlowAppShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlowScaffold(
      child: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
                  const ScreenHeading(
                    title: 'Your Glow-Up Analysis ✨',
                    subtitle:
                        'Your introductory face scan is complete. Review your results and build your personalized plan.',
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle('AI Analysis'),
                        const SizedBox(height: 8),
                        Text(_summary ?? 'Analysis unavailable.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _continueToPlan,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Create My Glow-Up Plan'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your AI analysis, progress, and plan are saved to your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: GlowColors.muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _skipFlow,
                    icon: const Icon(Icons.skip_next_rounded),
                    label: const Text('Skip for now — go to app'),
                    style: TextButton.styleFrom(
                      foregroundColor: GlowColors.muted,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
