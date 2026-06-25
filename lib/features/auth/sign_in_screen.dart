import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/services/decision_engine.dart';
import '../../core/storage/history_repository.dart';
import '../../core/storage/profile_repository.dart';
import '../paywall/paywall_screen.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({
    required this.decisionEngine,
    required this.historyRepository,
    required this.profileRepository,
    this.onAuthComplete,
    super.key,
  });

  final DecisionEngine decisionEngine;
  final HistoryRepository historyRepository;
  final ProfileRepository profileRepository;
  final VoidCallback? onAuthComplete;

  Future<void> _goToPaywall(BuildContext context) async {
    if (onAuthComplete != null) {
      onAuthComplete!();
    }
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PaywallScreen(
            decisionEngine: decisionEngine,
            historyRepository: historyRepository,
            profileRepository: profileRepository,
          ),
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    // Check if Google Sign-In is supported on this platform
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Google Sign-In is not available on this platform. Please use "Continue as guest".',
            ),
          ),
        );
      }
      return;
    }

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final account = await googleSignIn.signIn();
      if (account != null) {
        await _goToPaywall(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not complete Google Sign-In. Please try again or continue as guest.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleAppleSignIn(BuildContext context) async {
    await _goToPaywall(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Sign in to Continue',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use Google or Apple to quickly sign in and save your comparisons.',
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.g_mobiledata_rounded,
                            color: Colors.black87,
                            size: 28,
                          ),
                          label: const Text('Continue with Google'),
                          onPressed: () => _handleGoogleSignIn(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.apple, size: 20),
                          label: const Text('Continue with Apple'),
                          onPressed: () => _handleAppleSignIn(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => _goToPaywall(context),
                        child: const Text('Continue as guest'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
