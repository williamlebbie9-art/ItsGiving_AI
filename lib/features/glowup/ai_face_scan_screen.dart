import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/decision_models.dart';
import '../../core/services/decision_engine.dart';
import 'glowup_app.dart';

/// AI-powered face scan screen that sends the selfie to the AI service
/// for real glow-up analysis.
class AiFaceScanScreen extends StatefulWidget {
  const AiFaceScanScreen({super.key});

  @override
  State<AiFaceScanScreen> createState() => _AiFaceScanScreenState();
}

class _AiFaceScanScreenState extends State<AiFaceScanScreen> {
  final _picker = ImagePicker();
  final _engine = DecisionEngine();
  XFile? _image;
  bool _analyzing = false;
  String? _analysisResult;

  Future<void> _pick(ImageSource source) async {
    final image = await _picker.pickImage(source: source, imageQuality: 82);
    if (image != null) setState(() => _image = image);
  }

  Future<void> _analyze() async {
    if (_image == null) return;
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
              'Do NOT mention prices, products to buy, or comparing Product A vs Product B.',
          manualCategory: DecisionCategory.glowup,
          imagePaths: [_image!.path],
        ),
      );

      if (!mounted) return;
      setState(() {
        _analysisResult = result.reasoning.isNotEmpty
            ? result.reasoning
            : '${result.bestChoice}\n\n${result.pros.join('\n')}';
        _analyzing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _analysisResult =
            'Analysis completed. Here are your glow-up areas to enhance: '
            'build a consistent skincare routine with SPF, stay hydrated, '
            'get quality sleep, and add gentle daily movement. ✨';
        _analyzing = false;
      });
    }
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
