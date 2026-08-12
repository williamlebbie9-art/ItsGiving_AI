import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/ai_client.dart';
import 'glow_models.dart';
import 'glow_up_plan_screen.dart';
import 'glowup_app.dart';
import 'plan_provider.dart';

/// A style/look option the user can generate.
class GlowUpStyle {
  const GlowUpStyle({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.description,
  });

  final String id;
  final String name;
  final String emoji;
  final Color color;
  final String description;
}

const glowUpStyles = [
  GlowUpStyle(
    id: 'clean-girl',
    name: 'Clean Girl',
    emoji: '✨',
    color: Color(0xFFFF8FC7),
    description: 'Natural, polished, fresh appearance.',
  ),
  GlowUpStyle(
    id: 'soft-girl',
    name: 'Soft Girl',
    emoji: '🎀',
    color: Color(0xFFFFB6D9),
    description: 'Soft feminine styling, gentle makeup.',
  ),
  GlowUpStyle(
    id: 'old-money',
    name: 'Old Money',
    emoji: '🖤',
    color: Color(0xFF2E2140),
    description: 'Elegant, sophisticated, refined styling.',
  ),
  GlowUpStyle(
    id: 'glam',
    name: 'Glam',
    emoji: '💎',
    color: Color(0xFFFF5FA2),
    description: 'Defined makeup, polished hair, elevated.',
  ),
  GlowUpStyle(
    id: 'sporty',
    name: 'Sporty',
    emoji: '🏃',
    color: Color(0xFFFF8A65),
    description: 'Fresh, athletic, natural styling.',
  ),
  GlowUpStyle(
    id: 'minimalist',
    name: 'Minimalist',
    emoji: '🤍',
    color: Color(0xFFB8A7FF),
    description: 'Simple, clean, understated styling.',
  ),
];

enum GenerationState {
  idle,
  preparing,
  generating,
  almostReady,
  success,
  error,
}

class GlowUpGeneratorScreen extends ConsumerStatefulWidget {
  const GlowUpGeneratorScreen({
    required this.imagePath,
    this.faceScanSummary,
    super.key,
  });

  final String imagePath;
  final String? faceScanSummary;

  @override
  ConsumerState<GlowUpGeneratorScreen> createState() =>
      _GlowUpGeneratorScreenState();
}

class _GlowUpGeneratorScreenState extends ConsumerState<GlowUpGeneratorScreen> {
  final _client = const AiClient();
  GenerationState _state = GenerationState.idle;
  GlowUpStyle? _selectedStyle;
  Uint8List? _generatedImage;
  String? _errorMessage;
  bool _saved = false;
  bool _buildingPlan = false;

  Future<void> _generate(GlowUpStyle style) async {
    setState(() {
      _selectedStyle = style;
      _state = GenerationState.preparing;
      _errorMessage = null;
      _saved = false;
    });

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _state = GenerationState.generating);

    try {
      final bytes = await _client.generateGlowUpImage(
        imagePath: widget.imagePath,
        styleId: style.id,
        faceScanSummary: widget.faceScanSummary,
      );
      if (!mounted) return;
      setState(() {
        _generatedImage = bytes;
        _state = GenerationState.success;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _state = GenerationState.error;
      });
    }
  }

  /// Builds a structured 30-day plan and navigates to the plan screen.
  Future<void> _buildPlan() async {
    if (_selectedStyle == null || _buildingPlan) return;
    setState(() => _buildingPlan = true);

    try {
      // Load the user profile from SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('glowup_profile');
      GlowUserProfile profile = const GlowUserProfile();
      if (raw != null && raw.isNotEmpty) {
        try {
          final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
          profile = GlowUserProfile.fromJson(map);
        } catch (_) {}
      }

      // Generate the structured plan using the provider.
      final success = await ref
          .read(planProvider.notifier)
          .generatePlan(
            profile: profile,
            faceScanSummary: widget.faceScanSummary,
          );

      if (!mounted) return;
      if (success) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const GlowUpPlanScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not generate your plan. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _buildingPlan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlowScaffold(
      child: SafeArea(
        child: _state == GenerationState.success && _generatedImage != null
            ? _buildResult()
            : _buildStylePicker(),
      ),
    );
  }

  Widget _buildStylePicker() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
      children: [
        const ScreenHeading(
          title: 'Explore Your Glow-Up',
          subtitle:
              'Pick a style and AI will generate a realistic version of you with that look.',
        ),
        const SizedBox(height: 16),
        if (_state == GenerationState.preparing ||
            _state == GenerationState.generating ||
            _state == GenerationState.almostReady)
          _buildGeneratingCard()
        else if (_state == GenerationState.error)
          _buildErrorCard()
        else ...[
          Text(
            'Choose a look',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ...glowUpStyles.map(
            (style) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _StyleCard(style: style, onTap: () => _generate(style)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGeneratingCard() {
    final label = switch (_state) {
      GenerationState.preparing => 'Preparing your look...',
      GenerationState.generating => 'AI is creating your glow-up...',
      GenerationState.almostReady => 'Almost ready...',
      _ => 'Working...',
    };
    return GlassCard(
      child: Column(
        children: [
          const SizedBox(height: 12),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'This can take up to a minute. Please stay on this screen.',
            textAlign: TextAlign.center,
            style: TextStyle(color: GlowColors.muted),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return GlassCard(
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFE53935),
            size: 40,
          ),
          const SizedBox(height: 12),
          const Text(
            "We couldn't create this look right now.",
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(color: GlowColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: () {
                  if (_selectedStyle != null) _generate(_selectedStyle!);
                },
                child: const Text('Try Again'),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => setState(() => _state = GenerationState.idle),
                child: const Text('Choose Another Style'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final style = _selectedStyle!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
      children: [
        ScreenHeading(
          title: 'Your Glow-Up Inspiration ✨',
          subtitle: 'A realistic preview of your ${style.name} look.',
        ),
        const SizedBox(height: 16),
        GlassCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Image.memory(
              _generatedImage!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  setState(() => _saved = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Look saved to your plan!')),
                  );
                },
                icon: Icon(
                  _saved
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                ),
                label: Text(_saved ? 'Saved' : 'Save Look'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _buildPlan,
                icon: _buildingPlan
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.route_rounded),
                label: Text(
                  _buildingPlan ? 'Creating plan...' : 'Build My Plan',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _state = GenerationState.idle),
                icon: const Icon(Icons.style_rounded),
                label: const Text('Try Another Style'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _generate(style),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Regenerate'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({required this.style, required this.onTap});

  final GlowUpStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: style.color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    style.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      style.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      style.description,
                      style: TextStyle(color: GlowColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: GlowColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
