import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'glow_up_generator_screen.dart';

/// A direct entry point for AI look generation outside the face-scan flow.
class ImageGenerationScreen extends StatefulWidget {
  const ImageGenerationScreen({super.key});

  @override
  State<ImageGenerationScreen> createState() => _ImageGenerationScreenState();
}

class _ImageGenerationScreenState extends State<ImageGenerationScreen> {
  final _picker = ImagePicker();
  XFile? _image;
  bool _picking = false;

  Future<void> _pick(ImageSource source) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1536,
        maxHeight: 1536,
      );
      if (mounted && image != null) setState(() => _image = image);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _continueToStyles() {
    final image = _image;
    if (image == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GlowUpGeneratorScreen(imagePath: image.path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Look Generator'), centerTitle: true),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF3FA), Color(0xFFFFE4F1), Color(0xFFEADFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'See your next look',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose a clear selfie, then pick a style to create your personalized glow-up preview.',
              ),
              const SizedBox(height: 24),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white),
                ),
                child: _image == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.face_retouching_natural_rounded, size: 64),
                          SizedBox(height: 12),
                          Text('Your selfie will appear here'),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.file(File(_image!.path), fit: BoxFit.cover),
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _picking ? null : () => _pick(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Take Photo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _picking ? null : () => _pick(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Choose Photo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _image == null ? null : _continueToStyles,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Choose a Style'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
