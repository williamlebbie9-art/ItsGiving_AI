import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/services/auth_service.dart';

/// Polished account creation / sign-in screen shown after onboarding.
///
/// The user must authenticate BEFORE their AI face scan and personalized
/// plan are permanently created. This screen matches the "its giving.AI"
/// visual identity.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;
  bool _showEmailForm = false;
  String? _error;

  // Email form controllers.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogle() async {
    await _linkOrSignIn(
      linkAction: () => ref.read(authServiceProvider).linkWithGoogle(),
      signInAction: () => ref.read(authServiceProvider).signInWithGoogle(),
    );
  }

  Future<void> _handleApple() async {
    await _linkOrSignIn(
      linkAction: () => ref.read(authServiceProvider).linkWithApple(),
      signInAction: () => ref.read(authServiceProvider).signInWithApple(),
    );
  }

  Future<void> _handleEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }
    final auth = ref.read(authServiceProvider);
    await _linkOrSignIn(
      linkAction: () => auth.linkWithEmail(email: email, password: password),
      signInAction: () => _isSignUp
          ? auth.signUpWithEmail(email: email, password: password)
          : auth.signInWithEmail(email: email, password: password),
    );
  }

  /// If the current user is anonymous (guest mode), LINKS the credential to
  /// that same anonymous UID so all existing data is preserved. If there is no
  /// current user, falls back to a normal sign-in / sign-up.
  Future<void> _linkOrSignIn({
    required Future<dynamic> Function() linkAction,
    required Future<dynamic> Function() signInAction,
  }) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final current = ref.read(authServiceProvider).currentUser;
      if (current != null && current.isAnonymous) {
        await linkAction().timeout(const Duration(seconds: 20));
      } else {
        await signInAction().timeout(const Duration(seconds: 20));
      }
      if (!mounted) return;
      // The intro gate awaits this route; close it immediately on success so
      // the user can continue instead of remaining on a loading auth screen.
      Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  /// Continue as a guest without creating an account. Signs in anonymously
  /// so the user still gets a persistent UID for their data.
  Future<void> _continueAsGuest() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref
          .read(authServiceProvider)
          .signInAnonymously()
          .timeout(const Duration(seconds: 12));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not continue as guest. Please try again.';
      });
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
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF70B8), Color(0xFFB69CFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Your glow-up is almost ready ✨',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your free account to unlock your personalized analysis and save your glow-up journey.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            if (_showEmailForm) ...[
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp
                          ? 'Already have an account? Sign in'
                          : 'New here? Create account',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleEmail,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isSignUp ? 'Create Account' : 'Sign In'),
                ),
              ),
            ] else ...[
              _SocialButton(
                icon: Icons.g_mobiledata_rounded,
                label: 'Continue with Google',
                color: const Color(0xFF4285F4),
                onTap: _isLoading ? null : _handleGoogle,
              ),
              const SizedBox(height: 12),
              _SocialButton(
                icon: Icons.apple_rounded,
                label: 'Continue with Apple',
                color: const Color(0xFF251B2F),
                onTap: _isLoading ? null : _handleApple,
              ),
              const SizedBox(height: 12),
              _SocialButton(
                icon: Icons.mail_outline_rounded,
                label: 'Continue with Email',
                color: const Color(0xFFFF5FA2),
                onTap: _isLoading
                    ? null
                    : () => setState(() => _showEmailForm = true),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFB00020)),
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _isLoading ? null : _continueAsGuest,
              icon: const Icon(Icons.person_outline_rounded, size: 20),
              label: const Text('Continue as Guest'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'You can explore the app now and create an account anytime to save your progress.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.8),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(icon, color: color),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
