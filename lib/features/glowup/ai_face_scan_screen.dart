import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/decision_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/decision_engine.dart';
import 'glow_up_generator_screen.dart';
import 'glowup_app.dart';
import 'paywall_screen.dart';

/// AI-powered face scan screen that sends the selfie to the AI service
/// for real glow-up analysis.
///
/// Enforces:
/// - User must be authenticated.
/// - Free users get 1 introductory scan; premium users get unlimited.
/// - Usage is only incremented AFTER a successful AI call.
/// - Request locking prevents duplicate taps from triggering multiple AI calls.
class AiFaceScanScreen extends ConsumerStatefulWidget {
  const AiFaceScanScreen({super.key});

  @override
  ConsumerState<AiFaceScanScreen> createState() => _AiFaceScanScreenState();
}

class _AiFaceScanScreenState extends ConsumerState<AiFaceScanScreen> {
  final _picker = ImagePicker();
  final _engine = DecisionEngine();
  XFile? _image;
  bool _analyzing = false;
  String? _analysisResult;
  bool _requestLocked = false;

  Future<void> _pick(ImageSource source) async {
    final image = await _picker.pickImage(source: source, imageQuality: 82);
    if (image != null) setState(() => _image = image);
  }

  /// Checks whether the user can perform a face scan.
  /// Returns null if allowed, or a reason string if blocked.
  String? _checkScanAllowed() {
    final uid = ref.read(authServiceProvider).currentUid;
    if (uid == null) {
      return 'Please sign in to use the AI Face Scan.';
    }

    final isPremium = ref.read(subscriptionProvider).isPremium;
    if (isPremium) return null;

    final usage = ref.read(usageProvider);
    if (usage.faceScanCount >= 1) {
      return 'You\'ve used your free face scan. Upgrade to Premium for unlimited scans.';
    }
    return null;
  }

  Future<void> _analyze() async {
    if (_image == null || _analyzing || _requestLocked) return;

    // Check auth + usage before making any expensive AI call.
    final blockedReason = _checkScanAllowed();
    if (blockedReason != null) {
      _showPaywall(blockedReason);
      return;
    }

    // Lock the request to prevent duplicate taps.
    _requestLocked = true;
    setState(() {
      _analyzing = true;
      _analysisResult = null;
    });

    try {
      final result = await _engine.decide(
        DecisionRequest(
          query:
              'Analyze this face selfie as a warm, encouraging glow-up coach. '
              'Provide a detailed assessment covering: skin appearance and skincare opportunities, '
              'face shape and styling compatibility, hairstyle compatibility, brow styling, '
              'makeup/styling opportunities, overall grooming, facial proportions for styling purposes, '
              'and wellness habits that affect glow. '
              'Give a glow score out of 100 and specific, supportive recommendations. '
              'Use encouraging language like "Here\'s what you can enhance" — never judge or rank. '
              'Do NOT mention prices, products to buy, or comparing Product A vs Product B. '
              'When relevant, also suggest natural remedies to support the user\'s glow — '
              'such as natural skincare ingredients (aloe vera, green tea, honey, oatmeal, rose water, '
              'jojoba oil, coconut oil, shea butter), herbal teas (chamomile, green tea, peppermint, ginger), '
              'dietary suggestions (antioxidant-rich foods, omega-3s, vitamin C, hydration), '
              'lifestyle remedies (sleep, stress reduction, facial massage, dry brushing), '
              'and natural hair care (coconut oil masks, aloe vera gel, rosemary rinse). '
              'Always frame these as gentle, supportive suggestions — never as medical treatment '
              'or a replacement for professional care.',
          manualCategory: DecisionCategory.glowup,
          imagePaths: [_image!.path],
          operation: 'faceScan',
        ),
      );

      // Only increment usage AFTER a successful AI call.
      final uid = ref.read(authServiceProvider).currentUid;
      if (uid != null) {
        await ref.read(usageProvider.notifier).incrementFaceScan(uid);
      }

      if (!mounted) return;
      setState(() {
        _analysisResult = result.reasoning.isNotEmpty
            ? result.reasoning
            : '${result.bestChoice}\n\n${result.pros.join('\n')}';
        _analyzing = false;
        _requestLocked = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Surface the real error. Never mask AI failures with a fake analysis.
      // Do NOT increment usage on failure.
      setState(() {
        _analysisResult = 'AI REQUEST FAILED\n\n$e';
        _analyzing = false;
        _requestLocked = false;
      });
    }
  }

  void _showPaywall(String reason) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PaywallScreen(triggerReason: reason)),
    );
  }

  Future<void> _openGenerator() async {
    final image = _image;
    if (image == null) return;
    final summary = _analysisResult;
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GlowUpGeneratorScreen(
          imagePath: image.path,
          faceScanSummary: summary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlowScaffold(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
          children: [
            const ScreenHeading(
              title: 'AI Face Scan',
              subtitle:
                  'Analyze skin, symmetry, brows, hair fit, smile, and glow potential.',
            ),
            const SizedBox(height: 18),
            GlassCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: AspectRatio(
                  aspectRatio: 0.86,
                  child: _image == null
                      ? const GlowCameraPlaceholder()
                      : Image.file(File(_image!.path), fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _image == null || _analyzing ? null : _analyze,
              child: _analyzing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('Analyzing glow potential...'),
                      ],
                    )
                  : const Text('Generate Glow-Up Assessment'),
            ),
            if (_analysisResult != null) ...[
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('AI Analysis'),
                    const SizedBox(height: 8),
                    Text(_analysisResult!),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _openGenerator,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Explore Your Glow-Up'),
              ),
            ],
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                'Skin quality',
                'Skincare opportunities',
                'Face shape',
                'Hairstyle fit',
                'Brow styling',
                'Makeup opportunities',
                'Grooming',
                'Wellness habits',
              ].map((label) => Chip(label: Text(label))).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
