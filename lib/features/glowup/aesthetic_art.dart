import 'package:flutter/material.dart';

import 'glow_models.dart';

class AestheticArtPalette {
  const AestheticArtPalette({
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.accent,
  });

  final Color primary;
  final Color secondary;
  final Color surface;
  final Color accent;
}

class AestheticArt {
  const AestheticArt({
    required this.name,
    required this.palette,
    required this.label,
    required this.subtitle,
    required this.badge,
    required this.icon,
  });

  final String name;
  final AestheticArtPalette palette;
  final String label;
  final String subtitle;
  final String badge;
  final IconData icon;
}

AestheticArt aestheticArtFor(String? aestheticName) {
  final normalized = (aestheticName ?? 'Clean Girl').trim();
  final match = vibes.firstWhere(
    (vibe) => vibe.name.toLowerCase() == normalized.toLowerCase(),
    orElse: () => vibes.first,
  );

  switch (match.name) {
    case 'Goth':
      return const AestheticArt(
        name: 'Goth',
        label: 'Dark romance',
        subtitle: 'Intentional, moody, and expressive.',
        badge: 'Noir energy',
        icon: Icons.nightlight_round,
        palette: AestheticArtPalette(
          primary: Color(0xFF2F1E36),
          secondary: Color(0xFFB56C8E),
          surface: Color(0xFFF5EDF4),
          accent: Color(0xFF4E2B49),
        ),
      );
    case 'Goth — Soft & Cute':
      return const AestheticArt(
        name: 'Goth — Soft & Cute',
        label: 'Dark darling',
        subtitle: 'Soft edges with a dreamy romantic twist.',
        badge: 'Sweetly moody',
        icon: Icons.favorite_rounded,
        palette: AestheticArtPalette(
          primary: Color(0xFF6F3C73),
          secondary: Color(0xFFDEA5B9),
          surface: Color(0xFFF9F0F6),
          accent: Color(0xFF8A497F),
        ),
      );
    case 'Goth — Romantic, Sexy & Elegant':
      return const AestheticArt(
        name: 'Goth — Romantic, Sexy & Elegant',
        label: 'Velvet drama',
        subtitle: 'Elegant confidence with rich dark tones.',
        badge: 'Statement luxe',
        icon: Icons.auto_awesome_rounded,
        palette: AestheticArtPalette(
          primary: Color(0xFF311B2D),
          secondary: Color(0xFFB97C83),
          surface: Color(0xFFF7EEF5),
          accent: Color(0xFF6C2F40),
        ),
      );
    case 'Goth Baddie — Bold & Confident':
      return const AestheticArt(
        name: 'Goth Baddie — Bold & Confident',
        label: 'Dark edge',
        subtitle: 'Confident, sharp, and polished.',
        badge: 'Power move',
        icon: Icons.local_fire_department_rounded,
        palette: AestheticArtPalette(
          primary: Color(0xFF3E1F32),
          secondary: Color(0xFFD95B7B),
          surface: Color(0xFFFBEAF1),
          accent: Color(0xFF7B2448),
        ),
      );
    case 'Dark Feminine':
      return const AestheticArt(
        name: 'Dark Feminine',
        label: 'Quiet power',
        subtitle: 'Polished, deep, and grounded.',
        badge: 'Refined drama',
        icon: Icons.dark_mode_rounded,
        palette: AestheticArtPalette(
          primary: Color(0xFF40213E),
          secondary: Color(0xFFD7A4B8),
          surface: Color(0xFFF7F0F2),
          accent: Color(0xFF5F2F51),
        ),
      );
    case 'Coquette':
      return const AestheticArt(
        name: 'Coquette',
        label: 'Romantic polish',
        subtitle: 'Delicate details with feminine charm.',
        badge: 'Sweet luxe',
        icon: Icons.favorite_border_rounded,
        palette: AestheticArtPalette(
          primary: Color(0xFFF39BB6),
          secondary: Color(0xFFE7C5F1),
          surface: Color(0xFFFFF4F8),
          accent: Color(0xFFD8779E),
        ),
      );
    case 'Baddie':
      return const AestheticArt(
        name: 'Baddie',
        label: 'Bold glamour',
        subtitle: 'Confident, sharp, and elevated.',
        badge: 'Main character',
        icon: Icons.local_fire_department_rounded,
        palette: AestheticArtPalette(
          primary: Color(0xFFB9365E),
          secondary: Color(0xFF3D1F2C),
          surface: Color(0xFFFCEAF0),
          accent: Color(0xFF7E2B42),
        ),
      );
    case 'Clean Girl':
      return const AestheticArt(
        name: 'Clean Girl',
        label: 'Fresh polish',
        subtitle: 'Minimal, glowing, and effortless.',
        badge: 'Quiet luxury',
        icon: Icons.spa_rounded,
        palette: AestheticArtPalette(
          primary: Color(0xFF7D8CFF),
          secondary: Color(0xFFFF95C4),
          surface: Color(0xFFF8F5FF),
          accent: Color(0xFF6B5FE7),
        ),
      );
    case 'Soft Girl':
      return const AestheticArt(
        name: 'Soft Girl',
        label: 'Dreamy feminine',
        subtitle: 'Pastels, softness, and gentle glow.',
        badge: 'Soft energy',
        icon: Icons.favorite_rounded,
        palette: AestheticArtPalette(
          primary: Color(0xFFFF8FB1),
          secondary: Color(0xFFBFD9FF),
          surface: Color(0xFFFFF2F8),
          accent: Color(0xFFDC7BAF),
        ),
      );
    case 'Old Money':
      return const AestheticArt(
        name: 'Old Money',
        label: 'Timeless polish',
        subtitle: 'Quiet luxury with classic refinement.',
        badge: 'Estate elegance',
        icon: Icons.workspace_premium_rounded,
        palette: AestheticArtPalette(
          primary: Color(0xFF7D6140),
          secondary: Color(0xFFE2C596),
          surface: Color(0xFFF9F2EA),
          accent: Color(0xFF9C7B51),
        ),
      );
    case 'Model Off Duty':
      return const AestheticArt(
        name: 'Model Off Duty',
        label: 'Effortless cool',
        subtitle: 'Neutral, laid-back, and polished.',
        badge: 'Cool neutral',
        icon: Icons.auto_awesome_rounded,
        palette: AestheticArtPalette(
          primary: Color(0xFF495C73),
          secondary: Color(0xFFB8C2CE),
          surface: Color(0xFFF4F6FA),
          accent: Color(0xFF627C93),
        ),
      );
    case 'Feminine':
      return const AestheticArt(
        name: 'Feminine',
        label: 'Graceful charm',
        subtitle: 'Soft silhouettes and flattering details.',
        badge: 'Soft bloom',
        icon: Icons.local_florist_rounded,
        palette: AestheticArtPalette(
          primary: Color(0xFFFF8BAA),
          secondary: Color(0xFFF3D29B),
          surface: Color(0xFFFFF5F7),
          accent: Color(0xFFCF7292),
        ),
      );
    case 'Sporty':
      return const AestheticArt(
        name: 'Sporty',
        label: 'Fresh energy',
        subtitle: 'Active, clear, and easy confidence.',
        badge: 'Movement ready',
        icon: Icons.fitness_center_rounded,
        palette: AestheticArtPalette(
          primary: Color(0xFF2B7C75),
          secondary: Color(0xFF97DCCB),
          surface: Color(0xFFF1FBF9),
          accent: Color(0xFF3D9489),
        ),
      );
    case 'Natural Beauty':
      return const AestheticArt(
        name: 'Natural Beauty',
        label: 'Radiant ease',
        subtitle: 'Healthy glow and effortless style.',
        badge: 'Fresh skin',
        icon: Icons.wb_sunny_rounded,
        palette: AestheticArtPalette(
          primary: Color(0xFF638E65),
          secondary: Color(0xFFCFDDBC),
          surface: Color(0xFFF5FAF1),
          accent: Color(0xFF4F7D52),
        ),
      );
    case 'Edgy':
      return const AestheticArt(
        name: 'Edgy',
        label: 'Bold statement',
        subtitle: 'Statement pieces with confident edge.',
        badge: 'Sharp mood',
        icon: Icons.dark_mode_rounded,
        palette: AestheticArtPalette(
          primary: Color(0xFF17171B),
          secondary: Color(0xFF725EF8),
          surface: Color(0xFFF2F0FF),
          accent: Color(0xFF4337A8),
        ),
      );
    default:
      return const AestheticArt(
        name: 'Clean Girl',
        label: 'Fresh polish',
        subtitle: 'Minimal, glowing, and effortless.',
        badge: 'Glow up',
        icon: Icons.spa_rounded,
        palette: AestheticArtPalette(
          primary: Color(0xFFFF5FA2),
          secondary: Color(0xFFB69CFF),
          surface: Color(0xFFFFF4FA),
          accent: Color(0xFFB14F88),
        ),
      );
  }
}
