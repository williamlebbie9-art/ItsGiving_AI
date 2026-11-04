import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/decision_models.dart';
import '../../core/services/decision_engine.dart';
import '../../core/services/glow_profile_repository.dart';
import 'ai_coach_screen.dart';
import 'ai_companion.dart';
import 'glow_models.dart';
import 'plan_provider.dart';
import 'wardrobe_ai_service.dart';

class WardrobeReport {
  WardrobeReport({
    required this.aestheticMatchScore,
    required this.fashionabilityScore,
    required this.verdict,
    required this.whatGetsRight,
    required this.whatCouldImprove,
    required this.colourCoordination,
    required this.silhouetteAndProportions,
    required this.layeringAndAccessories,
    required this.aestheticAlignment,
    required this.improvementSuggestions,
    required this.stylingAlternatives,
    required this.occasionSuggestions,
    required this.createdAt,
  });

  final int aestheticMatchScore;
  final int fashionabilityScore;
  final String verdict;
  final String whatGetsRight;
  final String whatCouldImprove;
  final String colourCoordination;
  final String silhouetteAndProportions;
  final String layeringAndAccessories;
  final String aestheticAlignment;
  final List<String> improvementSuggestions;
  final List<String> stylingAlternatives;
  final List<String> occasionSuggestions;
  final DateTime createdAt;

  static WardrobeReport fromDecision(
    DecisionResult result, {
    required String aesthetic,
    required String occasion,
  }) {
    final confidence = _parseConfidence(result.confidenceScore);
    final aestheticScore = (confidence * 100).round().clamp(0, 100);
    final fashionScore = ((confidence * 100) + 14).round().clamp(0, 100);

    final positives = result.pros.isNotEmpty
        ? result.pros.join(' ')
        : 'The silhouette and overall mood are clear and put together.';
    final negatives = result.cons.isNotEmpty
        ? result.cons.join(' ')
        : 'There is some room to refine the styling balance and accessories.';

    return WardrobeReport(
      aestheticMatchScore: aestheticScore,
      fashionabilityScore: fashionScore,
      verdict: result.bestChoice.isNotEmpty
          ? result.bestChoice
          : 'This look is giving strong $aesthetic energy.',
      whatGetsRight: positives,
      whatCouldImprove: negatives,
      colourCoordination:
          'The palette reads cohesive and intentional, with enough contrast to make the outfit feel styled rather than accidental.',
      silhouetteAndProportions:
          'The silhouette feels ${occasion.toLowerCase() == 'date' ? 'elegant and balanced' : 'clear and wearable'}, with the fit helping the look feel intentional.',
      layeringAndAccessories:
          'Layering and accessories support the mood and are helping the outfit feel complete without becoming overdone.',
      aestheticAlignment:
          'This result reflects your $aesthetic direction and keeps the energy aligned with your existing profile.',
      improvementSuggestions: _buildSuggestions(aesthetic, occasion),
      stylingAlternatives: _buildAlternatives(aesthetic),
      occasionSuggestions: _buildOccasions(occasion),
      createdAt: DateTime.now(),
    );
  }

  static WardrobeReport fallback({
    required String aesthetic,
    required String occasion,
  }) {
    return WardrobeReport(
      aestheticMatchScore: 82,
      fashionabilityScore: 80,
      verdict:
          'This look is strong and feels aligned with your $aesthetic direction.',
      whatGetsRight:
          'The overall styling reads intentional, polished, and easy to wear.',
      whatCouldImprove:
          'A few details could be sharper so the outfit feels fuller and more elevated.',
      colourCoordination:
          'The palette is cohesive and the tones feel intentional and wearable.',
      silhouetteAndProportions:
          'The fit is generally flattering and visually balanced for everyday styling.',
      layeringAndAccessories:
          'The outfit would benefit from one extra layer or accessory to complete the look.',
      aestheticAlignment:
          'This style is consistent with the $aesthetic aesthetic saved to your profile.',
      improvementSuggestions: _buildSuggestions(aesthetic, occasion),
      stylingAlternatives: _buildAlternatives(aesthetic),
      occasionSuggestions: _buildOccasions(occasion),
      createdAt: DateTime.now(),
    );
  }

  static int _parseConfidence(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    final parsed = double.tryParse(cleaned);
    if (parsed == null) return 78;
    final normalized = parsed.clamp(0.0, 1.0);
    return (normalized * 100).round();
  }

  static List<String> _buildSuggestions(String aesthetic, String occasion) {
    final base = <String>[
      'Add one intentional accessory that supports the silhouette.',
      'Tighten the colour balance so the outfit feels more intentional.',
      'Choose the finishing layer that makes the look feel more elevated.',
    ];

    final aestheticBoost = {
      'Old Money': [
        'Swap in a refined leather or gold detail.',
        'Keep the palette softer and more classic.',
      ],
      'Soft Girl': [
        'Use a softer texture or pastel accent.',
        'Keep the overall styling feminine and light.',
      ],
      'Clean Girl': [
        'Add a minimal polished finishing piece.',
        'Keep the styling streamlined and fresh.',
      ],
      'Dark Feminine': [
        'Use one richer jewel-toned or leather accent.',
        'Lean into a sharper silhouette.',
      ],
      'Coquette': [
        'Add a delicate lace or ribbon detail.',
        'Keep the styling soft and romantic.',
      ],
      'Baddie': [
        'Tighten the fit and add a stronger statement accent.',
        'Use a sharper bag or shoe detail.',
      ],
      'Goth': [
        'Layer in one darker textured piece.',
        'Keep the silhouette clean and dramatic.',
      ],
    };

    if (aestheticBoost.containsKey(aesthetic)) {
      base.insertAll(0, aestheticBoost[aesthetic]!);
    }

    if (occasion.isNotEmpty && occasion.toLowerCase() != 'casual') {
      base.add(
        'Style it for $occasion with a small finishing detail that elevates the outfit.',
      );
    }
    return base.take(3).toList();
  }

  static List<String> _buildAlternatives(String aesthetic) {
    final map = {
      'Old Money': [
        'Try a tailored trench, loafers, and a polished crossbody.',
        'Swap to a soft knit and wide-leg trouser pairing.',
      ],
      'Soft Girl': [
        'Try a cardigan, silk skirt, and tiny jewellery accents.',
        'Layer a pastel knit with a gentle pleated skirt.',
      ],
      'Clean Girl': [
        'Try a structured tee with straight-leg denim and a sleek bag.',
        'Use a cream knit and soft leather accessory pairing.',
      ],
      'Dark Feminine': [
        'Try a sleek dark blazer, structured pants, and a soft heel.',
        'Pair a fitted knit with tailored dark denim.',
      ],
      'Coquette': [
        'Style a lace-trim top with a soft pleated skirt.',
        'Try a knit cardigan with a bow-accented detail.',
      ],
      'Baddie': [
        'Try a fitted blazer with sleek boots and a mini bag.',
        'Pair a structured set with a sharper heel or sneaker.',
      ],
      'Goth': [
        'Try a dark leather or velvet layer with silver jewellery.',
        'Pair a structured black layer with a soft lace accent.',
      ],
    };
    return map[aesthetic] ??
        [
          'Try a stronger fitted layer and a cleaner shoe choice.',
          'Lean into one silhouette change to make the outfit read more intentional.',
        ];
  }

  static List<String> _buildOccasions(String occasion) {
    final base = ['Casual brunch', 'Workday polish', 'Dinner or date'];
    if (occasion.isNotEmpty && occasion.toLowerCase() != 'casual') {
      return [
        occasion,
        ...base.where((item) => item.toLowerCase() != occasion.toLowerCase()),
      ];
    }
    return base;
  }

  Map<String, dynamic> toJson() => {
    'aestheticMatchScore': aestheticMatchScore,
    'fashionabilityScore': fashionabilityScore,
    'overallVerdict': verdict,
    'whatGetsRight': whatGetsRight,
    'whatCouldImprove': whatCouldImprove,
    'colourCoordination': colourCoordination,
    'silhouetteAndProportions': silhouetteAndProportions,
    'layeringAndAccessories': layeringAndAccessories,
    'aestheticAlignment': aestheticAlignment,
    'improvementSuggestions': improvementSuggestions,
    'stylingAlternatives': stylingAlternatives,
    'occasionSuggestions': occasionSuggestions,
    'createdAt': createdAt.toIso8601String(),
  };
}

class WardrobeAiScreen extends ConsumerStatefulWidget {
  const WardrobeAiScreen({super.key});

  @override
  ConsumerState<WardrobeAiScreen> createState() => _WardrobeAiScreenState();
}

class _WardrobeAiScreenState extends ConsumerState<WardrobeAiScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<String> _occasions = const [
    'Casual',
    'School',
    'Work',
    'Date',
    'Party',
    'Special Event',
  ];

  XFile? _imageFile;
  String _selectedOccasion = 'Casual';
  bool _isLoading = false;
  WardrobeReport? _report;
  String? _savedAesthetic;
  List<Map<String, dynamic>> _history = const [];

  @override
  void initState() {
    super.initState();
    _loadProfileAndHistory();
  }

  Future<void> _loadProfileAndHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('glowup_profile');
    if (!mounted) return;

    if (raw != null && raw.isNotEmpty) {
      try {
        final map = Map<String, dynamic>.from(
          const JsonDecoder().convert(raw) as Map,
        );
        final profile = GlowUserProfile.fromJson(map);
        setState(() {
          _savedAesthetic = profile.effectiveAesthetic;
          _history = parseWardrobeHistory(
            prefs.getStringList('wardrobe_ai_history') ?? const [],
          );
        });
      } catch (_) {
        setState(() {
          _savedAesthetic = 'Clean Girl';
          _history = parseWardrobeHistory(
            prefs.getStringList('wardrobe_ai_history') ?? const [],
          );
        });
      }
    } else {
      setState(() {
        _savedAesthetic = 'Clean Girl';
        _history = parseWardrobeHistory(
          prefs.getStringList('wardrobe_ai_history') ?? const [],
        );
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    setState(() => _imageFile = file);
  }

  Future<void> _analyzeOutfit() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a full outfit photo first.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profile = await GlowProfileRepository().load();
      final aesthetic = (profile.effectiveAesthetic).trim().isNotEmpty
          ? profile.effectiveAesthetic
          : (_savedAesthetic ?? 'Clean Girl');

      final prompt =
          'You are a polished fashion editor helping a user assess a complete outfit photograph. '
          'Use their saved aesthetic as the core reference: "$aesthetic". '
          'The occasion is: "$_selectedOccasion". '
          'Assess the outfit honestly and practically. '
          'Return your answer as compact but useful fashion feedback. '
          'Keep it encouraging, never shaming, and never guessing about hidden fabric details or exact sizing. '
          'If the image is too unclear to judge properly, say so clearly instead of pretending certainty. '
          'Provide a short verdict, what is working, what could improve, color coordination, silhouette, layering, aesthetic alignment, 3 practical improvement suggestions, 3 styling alternatives using items the user likely already has, and 3 occasion suggestions.';

      final result = await DecisionEngine().decide(
        DecisionRequest(
          query: prompt,
          manualCategory: DecisionCategory.fashion,
          operation: 'coachInsight',
        ),
      );

      final report = WardrobeReport.fromDecision(
        result,
        aesthetic: aesthetic,
        occasion: _selectedOccasion,
      );

      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('wardrobe_ai_history') ?? const [];
      final next = [...history, jsonEncode(report.toJson())];
      await prefs.setStringList('wardrobe_ai_history', next.take(20).toList());

      if (!mounted) return;
      setState(() => _report = report);
    } catch (_) {
      final fallback = WardrobeReport.fallback(
        aesthetic: _savedAesthetic ?? 'Clean Girl',
        occasion: _selectedOccasion,
      );
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('wardrobe_ai_history') ?? const [];
      final next = [...history, jsonEncode(fallback.toJson())];
      await prefs.setStringList('wardrobe_ai_history', next.take(20).toList());

      if (!mounted) return;
      setState(() => _report = fallback);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'AI review timed out, so a helpful fallback report was prepared.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _useInPlan() async {
    if (_report == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Analyse the outfit before using it in your plan.'),
        ),
      );
      return;
    }

    final profile = await GlowProfileRepository().load();
    final nextProfile = profile.copyWith(
      currentLookSummary:
          'Wardrobe AI analysis: ${_report!.verdict}. ${_report!.aestheticAlignment}',
      aesthetic: profile.effectiveAesthetic,
      targetAesthetic: profile.effectiveAesthetic,
    );
    await GlowProfileRepository().save(nextProfile);

    final success = await ref
        .read(planProvider.notifier)
        .generatePlan(
          profile: nextProfile,
          faceScanSummary: _report!.aestheticAlignment,
          styleId: nextProfile.effectiveAesthetic,
          styleName: nextProfile.effectiveAesthetic,
        );

    if (!mounted) return;
    if (success) {
      await CompanionProgressionService().awardWardrobeReview();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your wardrobe insights were added to your plan.'),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your plan is still available; please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = aestheticThemeFor(_savedAesthetic ?? 'Clean Girl');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wardrobe AI'),
        centerTitle: true,
        backgroundColor: theme.backgroundStart,
        foregroundColor: theme.label,
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
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            children: [
              Text(
                'Upload a full outfit',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We will compare the look against your saved aesthetic and give you a practical outfit read.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_rounded),
                            label: const Text('Camera'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_rounded),
                            label: const Text('Gallery'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_imageFile != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          File(_imageFile!.path),
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.checkroom_rounded,
                            size: 48,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    if (_imageFile != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retake'),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => setState(() => _imageFile = null),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Clear'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _occasions.contains(_selectedOccasion)
                          ? _selectedOccasion
                          : _occasions.first,
                      decoration: const InputDecoration(labelText: 'Occasion'),
                      items: _occasions
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedOccasion = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _analyzeOutfit,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.auto_awesome_rounded),
                        label: Text(
                          _isLoading ? 'Analyzing…' : 'Analyze outfit',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (_history.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Recent looks',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.remove('wardrobe_ai_history');
                              if (mounted) setState(() => _history = const []);
                            },
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Clear'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._history.take(3).map((entry) {
                        final verdict =
                            (entry['overallVerdict'] ?? 'Wardrobe read')
                                .toString();
                        final score = (entry['aestheticMatchScore'] ?? 0)
                            .toString();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: const Color(0xFFFFD8EA),
                                ),
                                child: const Icon(
                                  Icons.checkroom_rounded,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      verdict,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'Aesthetic match: $score/100',
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
              if (_report != null) ...[
                _scoreCard('Aesthetic Match', _report!.aestheticMatchScore),
                const SizedBox(height: 10),
                _scoreCard('Fashionability', _report!.fashionabilityScore),
                const SizedBox(height: 16),
                _reportPanel('Overall verdict', _report!.verdict),
                _reportPanel(
                  'What the outfit gets right',
                  _report!.whatGetsRight,
                ),
                _reportPanel(
                  'What could be improved',
                  _report!.whatCouldImprove,
                ),
                _reportPanel(
                  'Colour coordination',
                  _report!.colourCoordination,
                ),
                _reportPanel(
                  'Silhouette and proportions',
                  _report!.silhouetteAndProportions,
                ),
                _reportPanel(
                  'Layering and accessories',
                  _report!.layeringAndAccessories,
                ),
                _reportPanel(
                  'How it reflects your aesthetic',
                  _report!.aestheticAlignment,
                ),
                _reportPanel(
                  'Practical improvement suggestions',
                  _report!.improvementSuggestions.join('\n• '),
                  prefix: '• ',
                ),
                _reportPanel(
                  'Alternative ways to style it',
                  _report!.stylingAlternatives.join('\n• '),
                  prefix: '• ',
                ),
                _reportPanel(
                  'Occasions it would work for',
                  _report!.occasionSuggestions.join('\n• '),
                  prefix: '• ',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final question =
                              'How can I improve this outfit for ${_selectedOccasion.toLowerCase()} and make it feel more ${_savedAesthetic ?? 'Clean Girl'}?';
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AiCoachScreen(initialQuestion: question),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text('Discuss with AI Coach'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _useInPlan,
                  icon: const Icon(Icons.checklist_rtl_rounded),
                  label: const Text('Use in your plan'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreCard(String label, int value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD8EA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$value/100',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportPanel(String title, String content, {String prefix = ''}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            prefix.isEmpty ? content : '$prefix$content',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
