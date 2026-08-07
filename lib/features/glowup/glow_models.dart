import 'package:flutter/material.dart';

/// Category scores for the glow-up dashboard.
class GlowCategoryScore {
  const GlowCategoryScore({
    required this.name,
    required this.icon,
    required this.score,
    required this.opportunity,
    required this.color,
  });

  final String name;
  final IconData icon;
  final int score;
  final String opportunity;
  final Color color;
}

/// A single glow-up task.
class GlowTask {
  const GlowTask({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final bool isCompleted;

  GlowTask copyWith({bool? isCompleted}) {
    return GlowTask(
      id: id,
      title: title,
      description: description,
      category: category,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// A daily glow-up plan.
class DailyGlowPlan {
  const DailyGlowPlan({
    required this.day,
    required this.morningTasks,
    required this.eveningTasks,
    required this.selfCareTasks,
  });

  final int day;
  final List<GlowTask> morningTasks;
  final List<GlowTask> eveningTasks;
  final List<GlowTask> selfCareTasks;
}

/// A 30-day transformation plan.
class TransformationPlan {
  const TransformationPlan({
    required this.week,
    required this.title,
    required this.focus,
    required this.tasks,
  });

  final int week;
  final String title;
  final String focus;
  final List<GlowTask> tasks;
}

/// Feature improvement card data.
class FeatureCard {
  const FeatureCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.aiNoticed,
    required this.improvements,
    required this.habits,
    required this.steps,
    required this.products,
    required this.mistakes,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String aiNoticed;
  final List<String> improvements;
  final List<String> habits;
  final List<String> steps;
  final List<String> products;
  final List<String> mistakes;
}

/// Vibe/aesthetic data.
class Vibe {
  const Vibe({
    required this.name,
    required this.icon,
    required this.description,
    required this.outfitIdeas,
    required this.hairIdeas,
    required this.makeupIdeas,
    required this.nailIdeas,
    required this.accessories,
    required this.colors,
    required this.lifestyleHabits,
  });

  final String name;
  final IconData icon;
  final String description;
  final List<String> outfitIdeas;
  final List<String> hairIdeas;
  final List<String> makeupIdeas;
  final List<String> nailIdeas;
  final List<String> accessories;
  final List<String> colors;
  final List<String> lifestyleHabits;
}

/// Inspiration item.
class InspirationItem {
  const InspirationItem({
    required this.id,
    required this.title,
    required this.category,
    required this.icon,
    required this.color,
    required this.recreateSteps,
    required this.tips,
  });

  final String id;
  final String title;
  final String category;
  final IconData icon;
  final Color color;
  final List<String> recreateSteps;
  final List<String> tips;
}

/// User profile for glow-up.
class GlowUserProfile {
  const GlowUserProfile({
    this.goal,
    this.skincareRoutine,
    this.exerciseFrequency,
    this.sleepSchedule,
    this.aesthetic,
    this.skinType,
    this.lifestyle,
  });

  final String? goal;
  final String? skincareRoutine;
  final String? exerciseFrequency;
  final String? sleepSchedule;
  final String? aesthetic;
  final String? skinType;
  final String? lifestyle;

  Map<String, dynamic> toJson() => {
    'goal': goal,
    'skincareRoutine': skincareRoutine,
    'exerciseFrequency': exerciseFrequency,
    'sleepSchedule': sleepSchedule,
    'aesthetic': aesthetic,
    'skinType': skinType,
    'lifestyle': lifestyle,
  };

  factory GlowUserProfile.fromJson(Map<String, dynamic> json) {
    return GlowUserProfile(
      goal: json['goal'] as String?,
      skincareRoutine: json['skincareRoutine'] as String?,
      exerciseFrequency: json['exerciseFrequency'] as String?,
      sleepSchedule: json['sleepSchedule'] as String?,
      aesthetic: json['aesthetic'] as String?,
      skinType: json['skinType'] as String?,
      lifestyle: json['lifestyle'] as String?,
    );
  }
}

/// Available vibes.
const vibes = [
  Vibe(
    name: 'Clean Girl',
    icon: Icons.spa_rounded,
    description:
        'Fresh, minimal, and effortlessly polished. Think dewy skin, slicked-back hair, and neutral tones.',
    outfitIdeas: [
      'White button-down with straight-leg jeans',
      'Neutral knit sets in cream or beige',
      'Simple gold jewelry and clean white sneakers',
    ],
    hairIdeas: [
      'Sleek low bun',
      'Slicked-back ponytail',
      'Glass hair with center part',
    ],
    makeupIdeas: [
      'Glowy skin with minimal foundation',
      'Tinted brow gel and clear gloss',
      'Soft brown mascara and blush',
    ],
    nailIdeas: ['Nude or milky white', 'Short almond shape', 'Glossy top coat'],
    accessories: [
      'Thin gold hoops',
      'Minimal chain necklace',
      'Classic leather handbag',
    ],
    colors: ['White', 'Beige', 'Cream', 'Soft brown', 'Nude'],
    lifestyleHabits: [
      'Morning skincare routine',
      'Hydration first thing',
      'Tidy, minimal spaces',
    ],
  ),
  Vibe(
    name: 'Soft Girl',
    icon: Icons.favorite_rounded,
    description:
        'Romantic, dreamy, and feminine. Pastels, soft textures, and gentle beauty looks.',
    outfitIdeas: [
      'Pastel cardigans with flowy skirts',
      'Lace details and ribbon accents',
      'Chunky knit sweaters in blush tones',
    ],
    hairIdeas: [
      'Soft waves with butterfly clips',
      'Half-up half-down with ribbons',
      'Braided crown or bubble braids',
    ],
    makeupIdeas: [
      'Pink blush on cheeks and nose',
      'Glossy lips in rose shades',
      'Soft shimmer eyeshadow',
    ],
    nailIdeas: [
      'Pastel pink or lavender',
      'Heart accents',
      'Rounded square shape',
    ],
    accessories: [
      'Pearl earrings',
      'Hair bows and ribbons',
      'Pastel phone case',
    ],
    colors: ['Pink', 'Lavender', 'Baby blue', 'Cream', 'Rose'],
    lifestyleHabits: [
      'Journaling and self-care nights',
      'Cozy, soft living spaces',
      'Gentle morning routines',
    ],
  ),
  Vibe(
    name: 'Old Money',
    icon: Icons.workspace_premium_rounded,
    description:
        'Quiet luxury and timeless elegance. Tailored pieces, neutral palettes, and understated polish.',
    outfitIdeas: [
      'Cashmere sweaters with tailored trousers',
      'Classic trench coat and loafers',
      'Silk blouses with gold accents',
    ],
    hairIdeas: ['Sleek blowout', 'Low chignon', 'Polished waves'],
    makeupIdeas: [
      'Skin-focused minimal makeup',
      'Defined brows and neutral lips',
      'Subtle bronzer for warmth',
    ],
    nailIdeas: ['French manicure', 'Nude or soft pink', 'Short, clean shape'],
    accessories: ['Gold watch', 'Silk scarf', 'Structured leather bag'],
    colors: ['Camel', 'Navy', 'Cream', 'Black', 'Champagne'],
    lifestyleHabits: [
      'Quality over quantity',
      'Timeless wardrobe staples',
      'Refined daily routines',
    ],
  ),
  Vibe(
    name: 'Model Off Duty',
    icon: Icons.auto_awesome_rounded,
    description:
        'Effortlessly cool and understated. Oversized fits, neutral tones, and minimal makeup.',
    outfitIdeas: [
      'Oversized blazer with bike shorts',
      'White tee with wide-leg trousers',
      'Leather jacket with slip dress',
    ],
    hairIdeas: [
      'Messy low bun',
      'Sleek middle part',
      'Air-dried natural texture',
    ],
    makeupIdeas: ['Skin tint only', 'Groomed brows', 'Tinted lip balm'],
    nailIdeas: ['Clear or nude', 'Short natural shape', 'Glossy finish'],
    accessories: ['Sunglasses', 'Oversized tote', 'Minimal silver jewelry'],
    colors: ['Black', 'White', 'Grey', 'Olive', 'Denim'],
    lifestyleHabits: [
      'Effortless grooming',
      'Hydration and sleep focus',
      'Simple, functional style',
    ],
  ),
  Vibe(
    name: 'Feminine',
    icon: Icons.local_florist_rounded,
    description:
        'Soft, elegant, and graceful. Flowy fabrics, delicate details, and romantic beauty.',
    outfitIdeas: [
      'Floral midi dresses',
      'Blouses with ruffles',
      'A-line skirts and fitted tops',
    ],
    hairIdeas: ['Soft curls', 'Romantic updos', 'Flowing waves'],
    makeupIdeas: [
      'Rosy cheeks and lips',
      'Soft winged liner',
      'Luminous skin finish',
    ],
    nailIdeas: ['Rose pink or coral', 'Almond shape', 'Subtle shimmer'],
    accessories: [
      'Dainty necklaces',
      'Floral hair clips',
      'Delicate bracelets',
    ],
    colors: ['Rose', 'Coral', 'Ivory', 'Dusty pink', 'Peach'],
    lifestyleHabits: [
      'Graceful daily rituals',
      'Self-care evenings',
      'Soft, feminine spaces',
    ],
  ),
  Vibe(
    name: 'Sporty',
    icon: Icons.fitness_center_rounded,
    description:
        'Active, fresh, and energetic. Athleisure, clean beauty, and healthy habits.',
    outfitIdeas: [
      'Matching athleisure sets',
      'Crop tops with high-waist leggings',
      'Track jackets and sneakers',
    ],
    hairIdeas: [
      'High ponytail',
      'Braids or cornrows',
      'Sleek bun for workouts',
    ],
    makeupIdeas: [
      'Sweat-proof minimal makeup',
      'Tinted sunscreen',
      'Clear brow gel',
    ],
    nailIdeas: ['Short and practical', 'Clear or nude', 'No-fuss finish'],
    accessories: ['Sports watch', 'Headbands', 'Gym bag'],
    colors: ['Black', 'Neon accents', 'Grey', 'White', 'Navy'],
    lifestyleHabits: [
      'Daily movement',
      'Protein-rich meals',
      'Consistent sleep schedule',
    ],
  ),
  Vibe(
    name: 'Natural Beauty',
    icon: Icons.wb_sunny_rounded,
    description:
        'Authentic and radiant. Minimal makeup, healthy skin, and effortless style.',
    outfitIdeas: [
      'Linen pieces in earth tones',
      'Comfortable basics',
      'Natural fabrics and textures',
    ],
    hairIdeas: ['Natural texture embraced', 'Simple braids', 'Air-dried waves'],
    makeupIdeas: [
      'Barely-there makeup',
      'Sunscreen glow',
      'Tinted moisturizer only',
    ],
    nailIdeas: ['Clear polish', 'Short natural nails', 'Buff finish'],
    accessories: ['Wooden or natural jewelry', 'Straw bags', 'Minimal gold'],
    colors: ['Earth tones', 'Olive', 'Terracotta', 'Cream', 'Sage'],
    lifestyleHabits: [
      'Skincare as self-care',
      'Outdoor time',
      'Whole foods focus',
    ],
  ),
  Vibe(
    name: 'Edgy',
    icon: Icons.dark_mode_rounded,
    description:
        'Bold, confident, and expressive. Dark tones, statement pieces, and striking beauty.',
    outfitIdeas: [
      'Leather pants with graphic tees',
      'Oversized black blazers',
      'Chunky boots and chains',
    ],
    hairIdeas: [
      'Sharp bob',
      'Dark colors with bold streaks',
      'Sleek straight styles',
    ],
    makeupIdeas: ['Bold eyeliner', 'Dark or bold lips', 'Sharp brows'],
    nailIdeas: [
      'Black or deep red',
      'Matte finish',
      'Stiletto or coffin shape',
    ],
    accessories: [
      'Chunky silver jewelry',
      'Statement belts',
      'Dark sunglasses',
    ],
    colors: ['Black', 'Deep red', 'Silver', 'Charcoal', 'Burgundy'],
    lifestyleHabits: [
      'Confident self-expression',
      'Bold choices',
      'Creative outlets',
    ],
  ),
];

/// Available inspiration items.
const inspirationItems = [
  InspirationItem(
    id: 'hair-1',
    title: 'Glass Hair',
    category: 'Hairstyles',
    icon: Icons.content_cut_rounded,
    color: Color(0xFFB69CFF),
    recreateSteps: [
      'Start with clean, conditioned hair',
      'Apply heat protectant spray',
      'Blow dry with a round brush for smoothness',
      'Use a flat iron in small sections',
      'Finish with a shine serum on ends only',
    ],
    tips: [
      'Use a boar bristle brush for extra shine',
      'Don\'t overdo the serum — a pea-sized amount is enough',
      'Use a lower heat setting to protect your hair',
    ],
  ),
  InspirationItem(
    id: 'hair-2',
    title: 'Soft Waves',
    category: 'Hairstyles',
    icon: Icons.waves_rounded,
    color: Color(0xFFFF9AC2),
    recreateSteps: [
      'Apply a heat protectant and sea salt spray',
      'Section hair into 2-inch parts',
      'Wrap each section around a 1-inch curling wand',
      'Leave the ends out for a natural finish',
      'Brush through gently and set with hairspray',
    ],
    tips: [
      'Alternate curl direction for a more natural look',
      'Let curls cool completely before brushing',
      'Use a texture spray for extra volume',
    ],
  ),
  InspirationItem(
    id: 'brows-1',
    title: 'Feathered Brows',
    category: 'Brows',
    icon: Icons.face_retouching_natural_rounded,
    color: Color(0xFF96E6FF),
    recreateSteps: [
      'Brush brows upward with a spoolie',
      'Fill sparse areas with fine hair-like strokes',
      'Set with a clear or tinted brow gel',
      'Use concealer to clean up the edges',
    ],
    tips: [
      'Choose a brow pencil one shade lighter than your hair',
      'Less is more — build up gradually',
      'Brush brows up for an instant lift',
    ],
  ),
  InspirationItem(
    id: 'makeup-1',
    title: 'Glowy Skin Look',
    category: 'Makeup',
    icon: Icons.brush_rounded,
    color: Color(0xFFFFB86B),
    recreateSteps: [
      'Start with hydrated, prepped skin',
      'Apply a luminous primer',
      'Use a light-coverage foundation or skin tint',
      'Add liquid highlighter to cheekbones and nose bridge',
      'Set only the T-zone with powder',
    ],
    tips: [
      'Mix a drop of liquid highlighter into your foundation',
      'Use a damp sponge for a skin-like finish',
      'Cream blush melts into skin for a natural glow',
    ],
  ),
  InspirationItem(
    id: 'skincare-1',
    title: 'Glass Skin Routine',
    category: 'Skincare',
    icon: Icons.spa_rounded,
    color: Color(0xFFB8A7FF),
    recreateSteps: [
      'Double cleanse in the evening',
      'Exfoliate gently 2-3 times a week',
      'Layer hydrating toners and essences',
      'Seal with a moisturizer while skin is damp',
      'Always finish with SPF in the morning',
    ],
    tips: [
      'Pat products in rather than rubbing',
      'Hydration is the key to glass skin',
      'Consistency beats intensity',
    ],
  ),
  InspirationItem(
    id: 'outfits-1',
    title: 'Capsule Wardrobe',
    category: 'Outfits',
    icon: Icons.checkroom_rounded,
    color: Color(0xFFFF8FC7),
    recreateSteps: [
      'Choose a neutral color palette',
      'Invest in quality basics: white tee, jeans, blazer',
      'Add 2-3 statement pieces',
      'Mix and match for different looks',
      'Accessorize to elevate any outfit',
    ],
    tips: [
      'Stick to 30 pieces or fewer',
      'Choose versatile items that work together',
      'Quality over quantity',
    ],
  ),
  InspirationItem(
    id: 'nails-1',
    title: 'Classic French Tips',
    category: 'Nails',
    icon: Icons.back_hand_rounded,
    color: Color(0xFFFFD1E8),
    recreateSteps: [
      'Shape nails and push back cuticles',
      'Apply a base coat',
      'Paint the tip with white polish',
      'Seal with a sheer pink or nude polish',
      'Finish with a glossy top coat',
    ],
    tips: [
      'Use nail guides for a clean line',
      'Keep tips thin for an elegant look',
      'Let each layer dry completely',
    ],
  ),
  InspirationItem(
    id: 'fitness-1',
    title: 'Morning Stretch Routine',
    category: 'Fitness',
    icon: Icons.fitness_center_rounded,
    color: Color(0xFFFF8A65),
    recreateSteps: [
      'Start with neck rolls and shoulder shrugs',
      'Do cat-cow stretches for your spine',
      'Hold a downward dog for 30 seconds',
      'Stretch hamstrings and hip flexors',
      'Finish with deep breathing',
    ],
    tips: [
      'Stretch on a mat for comfort',
      'Breathe deeply into each stretch',
      'Consistency matters more than intensity',
    ],
  ),
  InspirationItem(
    id: 'aesthetic-1',
    title: 'Soft Girl Aesthetic',
    category: 'Aesthetic',
    icon: Icons.favorite_rounded,
    color: Color(0xFFFFB6D9),
    recreateSteps: [
      'Choose pastel and soft color palettes',
      'Add feminine details: bows, ribbons, lace',
      'Opt for soft, romantic makeup looks',
      'Create a cozy, dreamy space',
      'Embrace gentle self-care rituals',
    ],
    tips: [
      'Start with one pastel accent piece',
      'Mix textures: knits, silk, and lace',
      'Keep makeup soft and glowy',
    ],
  ),
];

/// Default feature improvement cards.
const featureCards = [
  FeatureCard(
    title: 'Skin',
    icon: Icons.spa_rounded,
    color: Color(0xFFFF8FC7),
    aiNoticed:
        'Your skin has a good natural base. The biggest opportunity is consistency in your daily routine and hydration.',
    improvements: [
      'Build a consistent AM and PM skincare routine',
      'Add SPF 50 every morning without fail',
      'Incorporate a gentle exfoliant 2-3 times a week',
      'Hydrate from within with 2L+ of water daily',
    ],
    habits: [
      'Cleanse morning and night',
      'Moisturize while skin is still damp',
      'Never sleep with makeup on',
      'Change pillowcases weekly',
    ],
    steps: [
      'AM: Cleanse → Tone → Vitamin C → Moisturize → SPF',
      'PM: Double cleanse → Tone → Serum → Moisturize',
      'Weekly: Gentle exfoliation + hydrating mask',
    ],
    products: [
      'Gentle low-pH cleanser',
      'Hydrating toner or essence',
      'Vitamin C serum for brightness',
      'Ceramide moisturizer',
      'SPF 50 sunscreen',
    ],
    mistakes: [
      'Over-exfoliating and damaging the barrier',
      'Skipping SPF on cloudy days',
      'Using too many actives at once',
      'Picking at blemishes',
    ],
  ),
  FeatureCard(
    title: 'Hair',
    icon: Icons.content_cut_rounded,
    color: Color(0xFFB69CFF),
    aiNoticed:
        'Your hair has good potential. Focus on heat protection, regular trims, and a simple wash routine that suits your texture.',
    improvements: [
      'Establish a wash schedule that suits your hair type',
      'Always use heat protectant before styling',
      'Get regular trims every 6-8 weeks',
      'Deep condition weekly',
    ],
    habits: [
      'Use a silk or satin pillowcase',
      'Brush from ends to roots',
      'Air dry when possible',
      'Protect hair from sun exposure',
    ],
    steps: [
      'Wash: Shampoo → Conditioner → Leave-in',
      'Style: Heat protectant → Blow dry → Finish',
      'Weekly: Deep conditioning mask',
    ],
    products: [
      'Sulfate-free shampoo',
      'Hydrating conditioner',
      'Leave-in conditioner',
      'Heat protectant spray',
      'Hair oil for ends',
    ],
    mistakes: [
      'Using heat without protection',
      'Brushing wet hair aggressively',
      'Tight hairstyles that cause breakage',
      'Over-washing stripping natural oils',
    ],
  ),
  FeatureCard(
    title: 'Brows',
    icon: Icons.face_retouching_natural_rounded,
    color: Color(0xFF96E6FF),
    aiNoticed:
        'Your brows frame your face well. A little shaping and filling can enhance your natural arch beautifully.',
    improvements: [
      'Shape brows to complement your face shape',
      'Fill sparse areas with light strokes',
      'Set brows with gel for a polished look',
      'Consider professional shaping every 3-4 weeks',
    ],
    habits: [
      'Brush brows daily with a spoolie',
      'Apply brow serum for growth',
      'Avoid over-plucking',
    ],
    steps: [
      'Brush brows upward',
      'Fill with light strokes in sparse areas',
      'Set with clear or tinted gel',
      'Clean edges with concealer',
    ],
    products: [
      'Brow pencil or powder',
      'Tinted brow gel',
      'Spoolie brush',
      'Brow serum',
    ],
    mistakes: [
      'Over-plucking and thinning brows',
      'Using too-dark brow products',
      'Drawing harsh, unnatural lines',
    ],
  ),
  FeatureCard(
    title: 'Style',
    icon: Icons.checkroom_rounded,
    color: Color(0xFFFFB86B),
    aiNoticed:
        'You have a great canvas for style. Building a cohesive wardrobe with versatile basics will elevate your everyday look.',
    improvements: [
      'Build a capsule wardrobe in your color palette',
      'Invest in well-fitting basics',
      'Add 2-3 statement pieces',
      'Accessorize to elevate outfits',
    ],
    habits: [
      'Plan outfits the night before',
      'Keep your wardrobe organized',
      'Choose quality over quantity',
    ],
    steps: [
      'Define your color palette',
      'Invest in basics: white tee, jeans, blazer',
      'Add statement pieces',
      'Accessorize: jewelry, bags, shoes',
    ],
    products: [
      'Well-fitting jeans',
      'Classic white shirt',
      'Tailored blazer',
      'Versatile handbag',
      'Quality shoes',
    ],
    mistakes: [
      'Buying trendy pieces that don\'t last',
      'Ignoring fit — tailoring makes all the difference',
      'Over-accessorizing',
    ],
  ),
  FeatureCard(
    title: 'Wellness',
    icon: Icons.fitness_center_rounded,
    color: Color(0xFFFF8A65),
    aiNoticed:
        'Your wellness foundation is solid. Adding consistent movement and mindful habits will boost your glow from within.',
    improvements: [
      'Move your body 30 minutes daily',
      'Prioritize protein in your meals',
      'Practice stress management',
      'Build a consistent sleep schedule',
    ],
    habits: [
      'Morning movement or stretch',
      'Hydration throughout the day',
      'Evening wind-down routine',
    ],
    steps: [
      'Start with 10-minute walks',
      'Add strength training 2-3x weekly',
      'Incorporate stretching daily',
      'Track your progress weekly',
    ],
    products: [
      'Comfortable workout clothes',
      'Water bottle',
      'Yoga mat',
      'Fitness tracker',
    ],
    mistakes: [
      'Doing too much too soon',
      'Skipping rest days',
      'Neglecting sleep for workouts',
    ],
  ),
  FeatureCard(
    title: 'Sleep',
    icon: Icons.bedtime_rounded,
    color: Color(0xFF816BFF),
    aiNoticed:
        'Sleep is your beauty superpower. Improving your sleep routine will show up in your skin, energy, and overall glow.',
    improvements: [
      'Aim for 7-9 hours of quality sleep',
      'Keep a consistent sleep schedule',
      'Create a relaxing bedtime routine',
      'Limit screen time before bed',
    ],
    habits: [
      'Same bedtime and wake time daily',
      'Phone down 45 minutes before bed',
      'Cool, dark, quiet sleep environment',
    ],
    steps: [
      'Set a consistent bedtime',
      'Dim lights 1 hour before bed',
      'Do a relaxing wind-down routine',
      'Keep your room cool and dark',
    ],
    products: [
      'Silk pillowcase',
      'Blackout curtains',
      'White noise machine',
      'Sleep mask',
    ],
    mistakes: [
      'Using screens in bed',
      'Caffeine after 2pm',
      'Irregular sleep schedule on weekends',
    ],
  ),
  FeatureCard(
    title: 'Lifestyle',
    icon: Icons.self_improvement_rounded,
    color: Color(0xFFB8A7FF),
    aiNoticed:
        'Your lifestyle habits shape your glow. Small daily rituals and positive routines will compound into visible results.',
    improvements: [
      'Build a morning routine that sets you up for success',
      'Practice daily gratitude or journaling',
      'Create a self-care evening ritual',
      'Surround yourself with positive influences',
    ],
    habits: [
      'Morning pages or journaling',
      'Daily gratitude practice',
      'Weekly self-care date',
    ],
    steps: [
      'Design your ideal morning routine',
      'Add one self-care ritual daily',
      'Create a calming evening wind-down',
      'Review and adjust weekly',
    ],
    products: [
      'Journal and pen',
      'Aromatherapy diffuser',
      'Comfortable loungewear',
      'Skincare for self-care',
    ],
    mistakes: [
      'Overcommitting and burning out',
      'Neglecting rest and recovery',
      'Comparing your journey to others',
    ],
  ),
];

/// Default category scores.
const defaultCategoryScores = [
  GlowCategoryScore(
    name: 'Skin',
    icon: Icons.spa_rounded,
    score: 72,
    opportunity: 'Building a consistent skincare routine',
    color: Color(0xFFFF8FC7),
  ),
  GlowCategoryScore(
    name: 'Hair',
    icon: Icons.content_cut_rounded,
    score: 68,
    opportunity: 'Heat protection and regular trims',
    color: Color(0xFFB69CFF),
  ),
  GlowCategoryScore(
    name: 'Grooming',
    icon: Icons.face_retouching_natural_rounded,
    score: 75,
    opportunity: 'Brow shaping and daily grooming habits',
    color: Color(0xFF96E6FF),
  ),
  GlowCategoryScore(
    name: 'Makeup',
    icon: Icons.brush_rounded,
    score: 65,
    opportunity: 'Learning techniques that enhance your features',
    color: Color(0xFFFFB86B),
  ),
  GlowCategoryScore(
    name: 'Style',
    icon: Icons.checkroom_rounded,
    score: 70,
    opportunity: 'Building a cohesive capsule wardrobe',
    color: Color(0xFFFF8FC7),
  ),
  GlowCategoryScore(
    name: 'Wellness',
    icon: Icons.fitness_center_rounded,
    score: 78,
    opportunity: 'Consistent movement and stress management',
    color: Color(0xFFFF8A65),
  ),
  GlowCategoryScore(
    name: 'Sleep',
    icon: Icons.bedtime_rounded,
    score: 62,
    opportunity: 'Improving sleep quality and consistency',
    color: Color(0xFF816BFF),
  ),
  GlowCategoryScore(
    name: 'Lifestyle',
    icon: Icons.self_improvement_rounded,
    score: 74,
    opportunity: 'Building daily rituals and positive habits',
    color: Color(0xFFB8A7FF),
  ),
];

/// 7-day glow-up challenge.
const sevenDayChallenge = [
  DailyGlowPlan(
    day: 1,
    morningTasks: [
      GlowTask(
        id: 'd1-m1',
        title: 'Drink a glass of water',
        description: 'Start your day hydrated',
        category: 'Wellness',
      ),
      GlowTask(
        id: 'd1-m2',
        title: 'Cleanse and moisturize',
        description: 'Gentle morning skincare',
        category: 'Skin',
      ),
      GlowTask(
        id: 'd1-m3',
        title: 'Apply SPF',
        description: 'Protect your skin all day',
        category: 'Skin',
      ),
    ],
    eveningTasks: [
      GlowTask(
        id: 'd1-e1',
        title: 'Remove makeup',
        description: 'Never sleep with makeup on',
        category: 'Skin',
      ),
      GlowTask(
        id: 'd1-e2',
        title: 'Night skincare routine',
        description: 'Cleanse, tone, moisturize',
        category: 'Skin',
      ),
      GlowTask(
        id: 'd1-e3',
        title: 'Set a sleep goal',
        description: 'Aim for 7-8 hours',
        category: 'Sleep',
      ),
    ],
    selfCareTasks: [
      GlowTask(
        id: 'd1-s1',
        title: '10-minute walk',
        description: 'Get your body moving',
        category: 'Wellness',
      ),
    ],
  ),
  DailyGlowPlan(
    day: 2,
    morningTasks: [
      GlowTask(
        id: 'd2-m1',
        title: 'Hydrate and stretch',
        description: '5-minute morning stretch',
        category: 'Wellness',
      ),
      GlowTask(
        id: 'd2-m2',
        title: 'Skincare + SPF',
        description: 'Consistency is key',
        category: 'Skin',
      ),
      GlowTask(
        id: 'd2-m3',
        title: 'Style your brows',
        description: 'Quick brow grooming',
        category: 'Grooming',
      ),
    ],
    eveningTasks: [
      GlowTask(
        id: 'd2-e1',
        title: 'Double cleanse',
        description: 'Remove all impurities',
        category: 'Skin',
      ),
      GlowTask(
        id: 'd2-e2',
        title: 'Hydrating mask',
        description: 'Weekly hydration boost',
        category: 'Skin',
      ),
      GlowTask(
        id: 'd2-e3',
        title: 'Phone down early',
        description: '45 min before bed',
        category: 'Sleep',
      ),
    ],
    selfCareTasks: [
      GlowTask(
        id: 'd2-s1',
        title: '15-minute workout',
        description: 'Any movement counts',
        category: 'Wellness',
      ),
    ],
  ),
  DailyGlowPlan(
    day: 3,
    morningTasks: [
      GlowTask(
        id: 'd3-m1',
        title: 'Water + vitamins',
        description: 'Fuel your body',
        category: 'Wellness',
      ),
      GlowTask(
        id: 'd3-m2',
        title: 'Skincare + SPF',
        description: 'Keep the routine going',
        category: 'Skin',
      ),
      GlowTask(
        id: 'd3-m3',
        title: 'Plan your outfit',
        description: 'Pick something you love',
        category: 'Style',
      ),
    ],
    eveningTasks: [
      GlowTask(
        id: 'd3-e1',
        title: 'Gentle exfoliation',
        description: '2-3 times weekly max',
        category: 'Skin',
      ),
      GlowTask(
        id: 'd3-e2',
        title: 'Night routine',
        description: 'Cleanse, tone, moisturize',
        category: 'Skin',
      ),
      GlowTask(
        id: 'd3-e3',
        title: 'Journal for 5 minutes',
        description: 'Reflect on your day',
        category: 'Lifestyle',
      ),
    ],
    selfCareTasks: [
      GlowTask(
        id: 'd3-s1',
        title: '20-minute walk',
        description: 'Fresh air and movement',
        category: 'Wellness',
      ),
    ],
  ),
  DailyGlowPlan(
    day: 4,
    morningTasks: [
      GlowTask(
        id: 'd4-m1',
        title: 'Hydrate + healthy breakfast',
        description: 'Protein-rich start',
        category: 'Wellness',
      ),
      GlowTask(
        id: 'd4-m2',
        title: 'Skincare + SPF',
        description: 'Protect and nourish',
        category: 'Skin',
      ),
      GlowTask(
        id: 'd4-m3',
        title: 'Hair care',
        description: 'Brush gently, add leave-in',
        category: 'Hair',
      ),
    ],
    eveningTasks: [
      GlowTask(
        id: 'd4-e1',
        title: 'Remove makeup + cleanse',
        description: 'Clean skin is happy skin',
        category: 'Skin',
      ),
      GlowTask(
        id: 'd4-e2',
        title: 'Night serum',
        description: 'Targeted treatment',
        category: 'Skin',
      ),
      GlowTask(
        id: 'd4-e3',
        title: 'Sleep by 11pm',
        description: 'Beauty sleep matters',
        category: 'Sleep',
      ),
    ],
    selfCareTasks: [
      GlowTask(
        id: 'd4-s1',
        title: '15-minute strength workout',
        description: 'Build that glow',
        category: 'Wellness',
      ),
    ],
  ),
  DailyGlowPlan(
    day: 5,
    morningTasks: [
      GlowTask(
        id: 'd5-m1',
        title: 'Water + movement',
        description: 'Morning stretch or walk',
        category: 'Wellness',
      ),
      GlowTask(
        id: 'd5-m2',
        title: 'Skincare + SPF',
        description: 'Consistency compounds',
        category: 'Skin',
      ),
      GlowTask(
        id: 'd5-m3',
        title: 'Light makeup look',
        description: 'Enhance, don\'t hide',
        category: 'Makeup',
      ),
    ],
    eveningTasks: [
      GlowTask(
        id: 'd5-e1',
        title: 'Full cleanse',
        description: 'Remove everything',
        category: 'Skin',
      ),
      GlowTask(
        id: 'd5-e2',
        title: 'Hydrating mask',
        description: 'Weekly glow boost',
        category: 'Skin',
      ),
      GlowTask(
        id: 'd5-e3',
        title: 'Gratitude journal',
        description: 'Write 3 things you\'re grateful for',
        category: 'Lifestyle',
      ),
    ],
    selfCareTasks: [
      GlowTask(
        id: 'd5-s1',
        title: '20-minute workout',
        description: 'Mix cardio and strength',
        category: 'Wellness',
      ),
    ],
  ),
  DailyGlowPlan(
    day: 6,
    morningTasks: [
      GlowTask(
        id: 'd6-m1',
        title: 'Hydrate + nourish',
        description: 'Healthy breakfast',
        category: 'Wellness',
      ),
      GlowTask(
        id: 'd6-m2',
        title: 'Skincare + SPF',
        description: 'Your skin thanks you',
        category: 'Skin',
      ),
      GlowTask(
        id: 'd6-m3',
        title: 'Style your hair',
        description: 'Try a new look',
        category: 'Hair',
      ),
    ],
    eveningTasks: [
      GlowTask(
        id: 'd6-e1',
        title: 'Deep cleanse',
        description: 'Gentle exfoliation',
        category: 'Skin',
      ),
      GlowTask(
        id: 'd6-e2',
        title: 'Night routine',
        description: 'Cleanse, tone, moisturize',
        category: 'Skin',
      ),
      GlowTask(
        id: 'd6-e3',
        title: 'Plan tomorrow',
        description: 'Set yourself up for success',
        category: 'Lifestyle',
      ),
    ],
    selfCareTasks: [
      GlowTask(
        id: 'd6-s1',
        title: 'Self-care evening',
        description: 'Bath, face mask, relax',
        category: 'Lifestyle',
      ),
    ],
  ),
  DailyGlowPlan(
    day: 7,
    morningTasks: [
      GlowTask(
        id: 'd7-m1',
        title: 'Water + movement',
        description: 'Morning stretch',
        category: 'Wellness',
      ),
      GlowTask(
        id: 'd7-m2',
        title: 'Skincare + SPF',
        description: 'You made it a week!',
        category: 'Skin',
      ),
      GlowTask(
        id: 'd7-m3',
        title: 'Outfit you love',
        description: 'Dress for confidence',
        category: 'Style',
      ),
    ],
    eveningTasks: [
      GlowTask(
        id: 'd7-e1',
        title: 'Full skincare routine',
        description: 'Celebrate your consistency',
        category: 'Skin',
      ),
      GlowTask(
        id: 'd7-e2',
        title: 'Reflect on the week',
        description: 'What worked? What will you keep?',
        category: 'Lifestyle',
      ),
      GlowTask(
        id: 'd7-e3',
        title: 'Early night',
        description: 'Rest and recover',
        category: 'Sleep',
      ),
    ],
    selfCareTasks: [
      GlowTask(
        id: 'd7-s1',
        title: 'Weekly review',
        description: 'Take a progress selfie',
        category: 'Lifestyle',
      ),
    ],
  ),
];

/// 30-day transformation plan.
const transformationPlan = [
  TransformationPlan(
    week: 1,
    title: 'Foundation Week',
    focus: 'Build your daily routine',
    tasks: [
      GlowTask(
        id: 'w1-t1',
        title: 'Establish AM skincare',
        description: 'Cleanse, moisturize, SPF every morning',
        category: 'Skin',
      ),
      GlowTask(
        id: 'w1-t2',
        title: 'Establish PM skincare',
        description: 'Cleanse, treat, moisturize every night',
        category: 'Skin',
      ),
      GlowTask(
        id: 'w1-t3',
        title: 'Drink 2L water daily',
        description: 'Hydration is your glow secret',
        category: 'Wellness',
      ),
      GlowTask(
        id: 'w1-t4',
        title: 'Walk 20 minutes daily',
        description: 'Gentle movement every day',
        category: 'Wellness',
      ),
      GlowTask(
        id: 'w1-t5',
        title: 'Sleep by 11pm',
        description: 'Consistent sleep schedule',
        category: 'Sleep',
      ),
    ],
  ),
  TransformationPlan(
    week: 2,
    title: 'Grooming Week',
    focus: 'Polish your presentation',
    tasks: [
      GlowTask(
        id: 'w2-t1',
        title: 'Shape your brows',
        description: 'Professional shaping or careful DIY',
        category: 'Grooming',
      ),
      GlowTask(
        id: 'w2-t2',
        title: 'Hair care routine',
        description: 'Deep condition + heat protectant',
        category: 'Hair',
      ),
      GlowTask(
        id: 'w2-t3',
        title: 'Nail care',
        description: 'Shape, file, and moisturize cuticles',
        category: 'Grooming',
      ),
      GlowTask(
        id: 'w2-t4',
        title: 'Skincare exfoliation',
        description: 'Gentle exfoliation 2-3 times',
        category: 'Skin',
      ),
      GlowTask(
        id: 'w2-t5',
        title: 'Plan your capsule wardrobe',
        description: 'Define your color palette',
        category: 'Style',
      ),
    ],
  ),
  TransformationPlan(
    week: 3,
    title: 'Style Week',
    focus: 'Elevate your look',
    tasks: [
      GlowTask(
        id: 'w3-t1',
        title: 'Try a new hairstyle',
        description: 'Experiment with a new look',
        category: 'Hair',
      ),
      GlowTask(
        id: 'w3-t2',
        title: 'Learn a makeup technique',
        description: 'Glowy skin, soft glam, or bold lip',
        category: 'Makeup',
      ),
      GlowTask(
        id: 'w3-t3',
        title: 'Build 3 outfits',
        description: 'Mix and match your wardrobe',
        category: 'Style',
      ),
      GlowTask(
        id: 'w3-t4',
        title: 'Strength training 3x',
        description: 'Build strength and confidence',
        category: 'Wellness',
      ),
      GlowTask(
        id: 'w3-t5',
        title: 'Self-care evening',
        description: 'Face mask, bath, journal',
        category: 'Lifestyle',
      ),
    ],
  ),
  TransformationPlan(
    week: 4,
    title: 'Glow Week',
    focus: 'Lock in your transformation',
    tasks: [
      GlowTask(
        id: 'w4-t1',
        title: 'Review your routine',
        description: 'What\'s working? Adjust as needed',
        category: 'Lifestyle',
      ),
      GlowTask(
        id: 'w4-t2',
        title: 'Take progress photos',
        description: 'Document your glow journey',
        category: 'Lifestyle',
      ),
      GlowTask(
        id: 'w4-t3',
        title: 'Try a new vibe',
        description: 'Experiment with your aesthetic',
        category: 'Style',
      ),
      GlowTask(
        id: 'w4-t4',
        title: 'Full body movement',
        description: 'Mix cardio, strength, and flexibility',
        category: 'Wellness',
      ),
      GlowTask(
        id: 'w4-t5',
        title: 'Celebrate your progress',
        description: 'You did 30 days! Treat yourself',
        category: 'Lifestyle',
      ),
    ],
  ),
];
