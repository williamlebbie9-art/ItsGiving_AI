import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'glow_models.dart';
import '../../core/services/glow_profile_repository.dart';

class VibeScreen extends StatefulWidget {
  const VibeScreen({super.key});

  @override
  State<VibeScreen> createState() => _VibeScreenState();
}

class _VibeScreenState extends State<VibeScreen> {
  Vibe? _selectedVibe;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedVibe();
  }

  Future<void> _loadSavedVibe() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('glowup_profile');
    if (raw == null || raw.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final profile = GlowUserProfile.fromJson(map);
      final saved = profile.effectiveAesthetic;
      final match = vibes.firstWhere(
        (vibe) => vibe.name.toLowerCase() == saved.toLowerCase(),
        orElse: () => vibes.first,
      );
      if (mounted) {
        setState(() {
          _selectedVibe = match;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveVibe(Vibe vibe) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('glowup_profile');
    Map<String, dynamic> map = {};
    if (raw != null && raw.isNotEmpty) {
      try {
        map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {}
    }

    final profile = GlowUserProfile.fromJson(map);
    final updatedProfile = profile.copyWith(
      aesthetic: vibe.name,
      targetAesthetic: vibe.name,
      currentLookSummary: profile.currentLookSummary,
      aestheticCombos: [vibe.name],
    );

    await GlowProfileRepository().save(updatedProfile);
    if (!mounted) return;
    setState(() => _selectedVibe = vibe);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${vibe.name} is now your active aesthetic.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Vibe'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Discover the aesthetic that feels like YOU. Pick a vibe to see outfit, hair, makeup, and lifestyle ideas.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                ...vibes.map(
                  (vibe) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _VibeTile(
                      vibe: vibe,
                      isSelected: _selectedVibe?.name == vibe.name,
                      palette: aestheticThemeFor(vibe.name),
                      onTap: () {
                        setState(() => _selectedVibe = vibe);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => VibeDetailScreen(
                              vibe: vibe,
                              palette: aestheticThemeFor(vibe.name),
                              onApply: (_) async => _saveVibe(vibe),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _VibeTile extends StatelessWidget {
  const _VibeTile({
    required this.vibe,
    required this.isSelected,
    required this.onTap,
    required this.palette,
  });

  final Vibe vibe;
  final bool isSelected;
  final VoidCallback onTap;
  final AestheticTheme palette;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? palette.primary : Colors.grey[200]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [palette.primary, palette.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(vibe.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vibe.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vibe.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class VibeDetailScreen extends StatelessWidget {
  const VibeDetailScreen({
    required this.vibe,
    required this.palette,
    this.onApply,
    super.key,
  });

  final Vibe vibe;
  final AestheticTheme palette;
  final Future<void> Function(Vibe vibe)? onApply;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(vibe.name), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [palette.primary, palette.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(vibe.icon, color: Colors.white, size: 40),
                const SizedBox(height: 12),
                Text(
                  vibe.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  vibe.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.95),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSection(
            context,
            'Outfit Inspiration',
            Icons.checkroom_rounded,
            vibe.outfitIdeas,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Hair Ideas',
            Icons.content_cut_rounded,
            vibe.hairIdeas,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Makeup Ideas',
            Icons.brush_rounded,
            vibe.makeupIdeas,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Nail Ideas',
            Icons.back_hand_rounded,
            vibe.nailIdeas,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Accessories',
            Icons.diamond_rounded,
            vibe.accessories,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Color Suggestions',
            Icons.palette_rounded,
            vibe.colors,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Lifestyle Habits',
            Icons.self_improvement_rounded,
            vibe.lifestyleHabits,
          ),
          const SizedBox(height: 20),
          if (onApply != null)
            FilledButton.icon(
              onPressed: () async {
                await onApply!(vibe);
                if (context.mounted) Navigator.of(context).pop();
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Use this vibe'),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<String> items,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: palette.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 7),
                    decoration: BoxDecoration(
                      color: palette.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
