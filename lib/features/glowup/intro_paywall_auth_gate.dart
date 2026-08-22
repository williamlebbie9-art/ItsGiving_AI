import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import 'auth_screen.dart';
import 'paywall_screen.dart';

/// Shows the mandatory first-run paywall, followed by the auth screen.
///
/// Called AFTER the introductory face scan completes and BEFORE the user
/// proceeds to the glow-up generator / plan builder.
///
/// Order: paywall → auth screen → return to caller so the user can continue
/// into the personalized glow-up journey.
Future<void> showIntroPaywallAuthGate(
  BuildContext context,
  WidgetRef ref,
) async {
  // Skip the paywall if the user is already a subscriber.
  final isPremium = ref.read(subscriptionProvider).isPremium;
  if (!isPremium) {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PaywallScreen(
          triggerReason:
              'Your introductory face scan is complete ✨ Unlock your full glow-up experience.',
        ),
      ),
    );
  }

  if (!context.mounted) return;

  // Always show the auth screen after the paywall so users can create an
  // account to save their progress (or continue as a guest).
  await Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const AuthScreen()));
}
