import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'glow_models.dart';
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
  String? _selectedAesthetic;

  @override
  void initState() {
    super.initState();
    _loadProfileAesthetic();
  }

  Future<void> _loadProfileAesthetic() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('glowup_profile');
    if (raw == null || raw.isEmpty) {
      if (mounted) setState(() => _selectedAesthetic = null);
      return;
    }

    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final profile = GlowUserProfile.fromJson(map);
      if (mounted) {
        setState(() => _selectedAesthetic = profile.effectiveAesthetic);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _selectedAesthetic = null);
      }
    }
  }

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
    final theme = aestheticThemeFor(_selectedAesthetic);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Look Generator'),
        centerTitle: true,
        backgroundColor: theme.backgroundStart,
        foregroundColor: theme.label,
        surfaceTintColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.backgroundStart, theme.backgroundEnd],
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
              Text(
                'Choose a clear selfie, then pick a style to create your personalized glow-up preview.',
                style: TextStyle(color: theme.label),
              ),
              const SizedBox(height: 24),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.72),
                      theme.backgroundStart.withValues(alpha: 0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: theme.primary.withValues(alpha: 0.2),
                  ),
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
                        child: Image.file(
                          File(_image!.path),
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _picking
                          ? null
                          : () => _pick(ImageSource.camera),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: theme.primary.withValues(alpha: 0.4),
                        ),
                        foregroundColor: theme.label,
                      ),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Take Photo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _picking
                          ? null
                          : () => _pick(ImageSource.gallery),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: theme.primary.withValues(alpha: 0.4),
                        ),
                        foregroundColor: theme.label,
                      ),
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Choose Photo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _image == null ? null : _continueToStyles,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                ),
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
