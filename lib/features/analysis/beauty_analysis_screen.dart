import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/extractors/product_details_extractor.dart';
import '../../core/models/decision_models.dart';
import '../../core/services/decision_engine.dart';
import '../../core/storage/comparison_repository.dart';
import '../products/comparison_result_screen.dart';

class _BeautyAnalysisSection {
  const _BeautyAnalysisSection({
    required this.key,
    required this.marker,
    required this.label,
    required this.prompt,
    required this.keywords,
  });

  final String key;
  final String marker;
  final String label;
  final String prompt;
  final List<String> keywords;
}

class _BeautyAnalysisConfig {
  const _BeautyAnalysisConfig({
    required this.type,
    required this.title,
    required this.headline,
    required this.description,
    required this.emptySummary,
    required this.summaryTitle,
    required this.summaryMetrics,
    required this.productATitle,
    required this.productBTitle,
    required this.productDescriptionA,
    required this.productDescriptionB,
    required this.analyzeLabel,
    required this.missingImagesMessage,
    required this.captureErrorPrefix,
    required this.pickErrorPrefix,
    required this.failurePrefix,
    required this.overallPrompt,
    required this.sections,
    required this.resultFlag,
    required this.icon,
  });

  final BeautyComparisonType type;
  final String title;
  final String headline;
  final String description;
  final String emptySummary;
  final String summaryTitle;
  final List<MapEntry<String, String>> summaryMetrics;
  final String productATitle;
  final String productBTitle;
  final String productDescriptionA;
  final String productDescriptionB;
  final String analyzeLabel;
  final String missingImagesMessage;
  final String captureErrorPrefix;
  final String pickErrorPrefix;
  final String failurePrefix;
  final String overallPrompt;
  final List<_BeautyAnalysisSection> sections;
  final _ResultFlag resultFlag;
  final IconData icon;
}

enum BeautyComparisonType { skincare, perfume }

enum _ResultFlag { skincare, perfume }

class SkincareAnalysisScreen extends StatelessWidget {
  const SkincareAnalysisScreen({
    required this.decisionEngine,
    required this.comparisonRepository,
    super.key,
  });

  final DecisionEngine decisionEngine;
  final ComparisonRepository comparisonRepository;

  @override
  Widget build(BuildContext context) {
    return _BeautyComparisonAnalysisScreen(
      config: _skincareConfig,
      decisionEngine: decisionEngine,
      comparisonRepository: comparisonRepository,
    );
  }
}

class PerfumeAnalysisScreen extends StatelessWidget {
  const PerfumeAnalysisScreen({
    required this.decisionEngine,
    required this.comparisonRepository,
    super.key,
  });

  final DecisionEngine decisionEngine;
  final ComparisonRepository comparisonRepository;

  @override
  Widget build(BuildContext context) {
    return _BeautyComparisonAnalysisScreen(
      config: _perfumeConfig,
      decisionEngine: decisionEngine,
      comparisonRepository: comparisonRepository,
    );
  }
}

class _BeautyComparisonAnalysisScreen extends StatefulWidget {
  const _BeautyComparisonAnalysisScreen({
    required this.config,
    required this.decisionEngine,
    required this.comparisonRepository,
  });

  final _BeautyAnalysisConfig config;
  final DecisionEngine decisionEngine;
  final ComparisonRepository comparisonRepository;

  @override
  State<_BeautyComparisonAnalysisScreen> createState() =>
      _BeautyComparisonAnalysisScreenState();
}

class _BeautyComparisonAnalysisScreenState
    extends State<_BeautyComparisonAnalysisScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _productAImage;
  XFile? _productBImage;
  bool _isAnalyzing = false;

  _BeautyAnalysisConfig get _config => widget.config;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_config.title), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildProductPairSection(context),
            const SizedBox(height: 16),
            _buildSummaryCard(context),
            const SizedBox(height: 16),
            _buildAnalysisCard(context),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                icon: Icon(_config.icon),
                label: _isAnalyzing
                    ? const Text('Analyzing...')
                    : Text(_config.analyzeLabel),
                onPressed: _isAnalyzing ? null : _analyze,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _config.headline,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _config.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildProductPairSection(BuildContext context) {
    return Column(
      children: [
        _buildProductCard(
          title: _config.productATitle,
          image: _productAImage,
          description: _config.productDescriptionA,
          onCameraTap: () => _pickImageFromCamera((image) {
            setState(() => _productAImage = image);
          }),
          onGalleryTap: () => _pickImageFromGallery((image) {
            setState(() => _productAImage = image);
          }),
        ),
        _buildVsDivider(),
        _buildProductCard(
          title: _config.productBTitle,
          image: _productBImage,
          description: _config.productDescriptionB,
          onCameraTap: () => _pickImageFromCamera((image) {
            setState(() => _productBImage = image);
          }),
          onGalleryTap: () => _pickImageFromGallery((image) {
            setState(() => _productBImage = image);
          }),
        ),
      ],
    );
  }

  Widget _buildVsDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'VS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onPrimary,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard({
    required String title,
    required XFile? image,
    required String description,
    required VoidCallback onCameraTap,
    required VoidCallback onGalleryTap,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(image.path),
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onCameraTap,
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onGalleryTap,
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _config.summaryTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _config.summaryMetrics
                  .map(
                    (metric) => _metricChip(context, metric.key, metric.value),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricChip(BuildContext context, String label, String value) {
    return Chip(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      label: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Widget _buildAnalysisCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _config.emptySummary,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera(Function(XFile) onPick) async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image != null) {
        onPick(image);
      }
    } catch (e) {
      _showError('${_config.captureErrorPrefix}: $e');
    }
  }

  Future<void> _pickImageFromGallery(Function(XFile) onPick) async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        onPick(image);
      }
    } catch (e) {
      _showError('${_config.pickErrorPrefix}: $e');
    }
  }

  Future<void> _analyze() async {
    if (_productAImage == null || _productBImage == null) {
      _showError(_config.missingImagesMessage);
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      // Run all 3 AI calls in parallel for maximum speed
      final results = await Future.wait([
        widget.decisionEngine.decide(
          DecisionRequest(
            query: _config.overallPrompt,
            manualCategory: DecisionCategory.fashion,
            imagePaths: [_productAImage!.path, _productBImage!.path],
            compareOptions: [
              'Product A (${_config.type.name})',
              'Product B (${_config.type.name})',
            ],
          ),
        ),
        _analyzeProduct('Product A', _productAImage!.path),
        _analyzeProduct('Product B', _productBImage!.path),
      ]);

      final overall = results[0];
      final resultA = results[1];
      final resultB = results[2];

      final comparison = ProductComparison(
        id: const Uuid().v4(),
        productAName: 'Product A',
        productBName: 'Product B',
        productAImage: ProductImage(originalPath: _productAImage!.path),
        productBImage: ProductImage(originalPath: _productBImage!.path),
        createdAt: DateTime.now(),
        overview: overall.reasoning,
        specifications: '${resultA.reasoning}\n\n---\n\n${resultB.reasoning}',
        ingredients: '${resultA.reasoning}\n\n${resultB.reasoning}',
        advantagesA: resultA.pros.isNotEmpty
            ? resultA.pros.join('\n')
            : resultA.reasoning,
        advantagesB: resultB.pros.isNotEmpty
            ? resultB.pros.join('\n')
            : resultB.reasoning,
        majorDifferences: overall.reasoning,
        valueForMoney: _extractValueForMoney(resultA, resultB),
        qualityAssessment:
            'A: ${resultA.confidenceScore}, B: ${resultB.confidenceScore}',
        summary: overall.reasoning,
        recommendation: overall.bestChoice.isNotEmpty
            ? overall.bestChoice
            : 'Product A or Product B',
        alternativeRecommendations: {'Verdict': overall.reasoning},
        productADetails: _extractProductDetails(resultA),
        productBDetails: _extractProductDetails(resultB),
      );

      await widget.comparisonRepository.save(comparison);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ComparisonResultScreen(
              comparison: comparison,
              decisionEngine: widget.decisionEngine,
              comparisonRepository: widget.comparisonRepository,
              startChatExpanded: true,
              isSkincare: _config.resultFlag == _ResultFlag.skincare,
              isPerfume: _config.resultFlag == _ResultFlag.perfume,
            ),
          ),
        );
      }
    } catch (e) {
      _showError('${_config.failurePrefix}: $e');
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<DecisionResult> _analyzeProduct(String productName, String imagePath) {
    return widget.decisionEngine.decide(
      DecisionRequest(
        query: _productPrompt(productName),
        manualCategory: DecisionCategory.fashion,
        imagePaths: [imagePath],
      ),
    );
  }

  String _productPrompt(String productName) {
    final buffer = StringBuffer()
      ..writeln(
        'Provide a detailed ${_config.type.name} analysis for $productName.',
      )
      ..writeln(
        'IMPORTANT: The JSON response must include ALL section markers below inside the "reasoning" field.',
      )
      ..writeln(
        'Include each section exactly as shown with opening and closing markers like [SECTION]...[/SECTION].',
      )
      ..writeln()
      ..writeln('Organize your analysis using these EXACT section markers:')
      ..writeln();
    for (final section in _config.sections) {
      buffer
        ..writeln('[${section.marker}]')
        ..writeln(section.prompt)
        ..writeln('[/${section.marker}]')
        ..writeln();
    }
    buffer
      ..writeln('[PROS_CONS]')
      ..writeln('+ Pro 1')
      ..writeln('- Con 1')
      ..writeln('[/PROS_CONS]')
      ..writeln()
      ..writeln('[RECOMMENDATION]')
      ..writeln('Short recommendation')
      ..writeln('[/RECOMMENDATION]')
      ..writeln()
      ..writeln(
        'REMEMBER: Place ALL sections with their exact markers inside the "reasoning" field of the JSON output.',
      );
    return buffer.toString();
  }

  Map<String, String> _extractProductDetails(DecisionResult result) {
    final extractor = const ProductDetailsExtractor();
    final text = result.reasoning;
    final details = <String, String>{};

    for (final section in _config.sections) {
      // Prefer explicit section markers when available.
      String value = extractor.extract(text, section.marker);
      if (value.isEmpty) {
        value = _extractSection(text, section.label, section.keywords);
      }
      if (value.isEmpty) {
        value = _extractKeywordContext(text, section.keywords);
      }
      if (value.isEmpty) {
        value = 'No details extracted.';
      }
      details[section.key] = value;
    }

    final prosConsText = extractor.extract(text, 'PROS_CONS');
    final parsed = extractor.parseProsCons(prosConsText);
    final pros = parsed.key.isNotEmpty
        ? parsed.key.join('\n')
        : result.pros.isNotEmpty
        ? result.pros.join('\n')
        : '';
    final cons = parsed.value.isNotEmpty
        ? parsed.value.join('\n')
        : result.cons.isNotEmpty
        ? result.cons.join('\n')
        : '';

    details['prosCons'] = [
      if (pros.isNotEmpty) 'Pros:\n$pros',
      if (cons.isNotEmpty) 'Cons:\n$cons',
    ].where((item) => item.isNotEmpty).join('\n\n');

    details['comparisonType'] = _config.type.name;
    return details;
  }

  /// Extracts a sentence or two from reasoning that mention the keywords.
  String _extractKeywordContext(String haystack, List<String> keywords) {
    if (keywords.isEmpty) return 'No details extracted.';
    final lines = haystack.split('\n');
    final relevantLines = <String>[];
    for (final line in lines) {
      final lower = line.trim().toLowerCase();
      if (lower.isEmpty) continue;
      final hasKeyword = keywords.any((k) => lower.contains(k));
      if (hasKeyword) {
        relevantLines.add(line.trim());
      }
      if (relevantLines.length >= 4) break; // Limit to 4 lines
    }
    return relevantLines.isNotEmpty
        ? relevantLines.join('\n')
        : 'No details extracted.';
  }

  String _extractSection(String haystack, String label, List<String> keywords) {
    final headerRegex = RegExp(
      r'\*{0,2}' +
          RegExp.escape(label) +
          r'\*{0,2}\s*:\s*(.+?)(?=\n\s*\n|\n\s*\*{0,2}\w+\*{0,2}\s*:|$)',
      caseSensitive: false,
      dotAll: true,
    );
    final match = headerRegex.firstMatch(haystack);
    if (match != null) {
      return match.group(1)!.trim();
    }

    final lines = haystack.split('\n');
    final buffer = <String>[];
    var capturing = false;
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        if (capturing) break;
        continue;
      }

      final lower = trimmed.toLowerCase();
      if (!capturing) {
        final hasKeyword = keywords.any((keyword) => lower.contains(keyword));
        final isHeader =
            trimmed.startsWith('**') ||
            trimmed.startsWith('#') ||
            trimmed.endsWith(':') ||
            RegExp(r'^[A-Z][A-Z\s]+[:\n]').hasMatch(trimmed);
        if (hasKeyword ||
            (isHeader && keywords.any((keyword) => lower.contains(keyword)))) {
          capturing = true;
          if (isHeader && keywords.any((keyword) => lower.contains(keyword))) {
            continue;
          }
          buffer.add(trimmed);
        }
      } else {
        if (trimmed.startsWith('**') ||
            trimmed.startsWith('#') ||
            (trimmed.endsWith(':') && trimmed.length < 40) ||
            RegExp(r'^[A-Z][A-Z\s]+[:\n]').hasMatch(trimmed)) {
          break;
        }
        buffer.add(trimmed);
      }
    }
    return buffer.isNotEmpty ? buffer.join('\n') : '';
  }

  String _extractValueForMoney(DecisionResult resultA, DecisionResult resultB) {
    if (_config.type != BeautyComparisonType.perfume) {
      return '';
    }

    final detailsA = _extractProductDetails(resultA);
    final detailsB = _extractProductDetails(resultB);
    return [
      'Product A: ${detailsA['valueForMoney'] ?? 'No value assessment extracted.'}',
      'Product B: ${detailsB['valueForMoney'] ?? 'No value assessment extracted.'}',
    ].join('\n\n');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

const _skincareConfig = _BeautyAnalysisConfig(
  type: BeautyComparisonType.skincare,
  title: 'Skincare Analysis',
  headline: 'Skincare product intelligence',
  description:
      'Compare two skincare products for ingredients, benefits, active ingredients, acne friendliness, fragrance content, and skin safety.',
  emptySummary:
      'Upload both skincare products and tap Analyze to compare ingredients, actives, comedogenic risk, sensitivity fit, fragrance, and overall skin safety.',
  summaryTitle: 'Skin safety at a glance',
  summaryMetrics: [
    MapEntry('Actives', 'Retinoids, acids, niacinamide'),
    MapEntry('Acne', 'Non-comedogenic focus'),
    MapEntry('Sensitive skin', 'Irritant screening'),
    MapEntry('Fragrance', 'Fragrance content check'),
    MapEntry('Safety', 'Barrier and allergy review'),
  ],
  productATitle: 'Skincare Product A',
  productBTitle: 'Skincare Product B',
  productDescriptionA: 'Scan ingredients, box, or product label.',
  productDescriptionB: 'Scan the second skincare label to compare.',
  analyzeLabel: 'Analyze Skincare Pair',
  missingImagesMessage: 'Please select both skincare products to compare.',
  captureErrorPrefix: 'Failed to capture skincare image',
  pickErrorPrefix: 'Failed to pick skincare image',
  failurePrefix: 'Skincare analysis failed',
  overallPrompt:
      'Compare Product A and Product B (two skincare products). Give a final verdict that mentions BOTH products by name. Then compare them on: Ingredients, Benefits, Acne friendliness, Sensitive skin suitability, Comedogenic risk, Active ingredients, Fragrance content, and Overall skin safety. You MUST discuss each product individually for every criteria.',
  resultFlag: _ResultFlag.skincare,
  icon: Icons.spa_rounded,
  sections: [
    _BeautyAnalysisSection(
      key: 'ingredients',
      marker: 'INGREDIENTS',
      label: 'Ingredients',
      prompt: 'Ingredient list and notable formulation details',
      keywords: ['ingredient', 'formula', 'composition'],
    ),
    _BeautyAnalysisSection(
      key: 'benefits',
      marker: 'BENEFITS',
      label: 'Benefits',
      prompt: 'Main skin benefits and expected effects',
      keywords: ['benefit', 'effect', 'skin'],
    ),
    _BeautyAnalysisSection(
      key: 'acneFriendliness',
      marker: 'ACNE_FRIENDLINESS',
      label: 'Acne friendliness',
      prompt: 'How suitable this is for acne-prone skin',
      keywords: ['acne', 'breakout', 'blemish'],
    ),
    _BeautyAnalysisSection(
      key: 'sensitiveSkinSuitability',
      marker: 'SENSITIVE_SKIN_SUITABILITY',
      label: 'Sensitive skin suitability',
      prompt: 'How suitable this is for sensitive skin',
      keywords: ['sensitive', 'irritation', 'redness'],
    ),
    _BeautyAnalysisSection(
      key: 'comedogenicRisk',
      marker: 'COMEDOGENIC_RISK',
      label: 'Comedogenic risk',
      prompt: 'Risk that ingredients may clog pores',
      keywords: ['comedogenic', 'clog', 'pore'],
    ),
    _BeautyAnalysisSection(
      key: 'activeIngredients',
      marker: 'ACTIVE_INGREDIENTS',
      label: 'Active ingredients',
      prompt: 'Active ingredients and what they do',
      keywords: ['active', 'retinol', 'acid', 'niacinamide'],
    ),
    _BeautyAnalysisSection(
      key: 'fragranceContent',
      marker: 'FRAGRANCE_CONTENT',
      label: 'Fragrance content',
      prompt: 'Fragrance, essential oils, and scent-related irritants',
      keywords: ['fragrance', 'perfume', 'essential oil'],
    ),
    _BeautyAnalysisSection(
      key: 'overallSkinSafety',
      marker: 'OVERALL_SKIN_SAFETY',
      label: 'Overall skin safety',
      prompt: 'Overall skin safety verdict',
      keywords: ['safety', 'safe', 'risk'],
    ),
  ],
);

const _perfumeConfig = _BeautyAnalysisConfig(
  type: BeautyComparisonType.perfume,
  title: 'Perfume Analysis',
  headline: 'Perfume comparison intelligence',
  description:
      'Compare two fragrances for longevity, projection, notes, occasion fit, season fit, gender neutrality, and value.',
  emptySummary:
      'Upload both perfumes and tap Analyze to compare longevity, sillage, fragrance notes, occasion, season, gender neutrality, and value for money.',
  summaryTitle: 'Fragrance at a glance',
  summaryMetrics: [
    MapEntry('Longevity', 'Short / moderate / long lasting'),
    MapEntry('Sillage', 'Close / moderate / strong'),
    MapEntry('Notes', 'Top, heart, base'),
    MapEntry('Occasion', 'Daily, office, evening'),
    MapEntry('Season', 'Warm, cool, all-season'),
  ],
  productATitle: 'Perfume Product A',
  productBTitle: 'Perfume Product B',
  productDescriptionA: 'Scan perfume bottle, box, or label.',
  productDescriptionB: 'Scan the second fragrance to compare.',
  analyzeLabel: 'Analyze Perfume Pair',
  missingImagesMessage: 'Please select both perfumes to compare.',
  captureErrorPrefix: 'Failed to capture perfume image',
  pickErrorPrefix: 'Failed to pick perfume image',
  failurePrefix: 'Perfume analysis failed',
  overallPrompt:
      'Compare Product A and Product B (two perfumes). Give a final verdict that mentions BOTH products by name. Then compare them on: Longevity, Sillage or projection, Fragrance notes, Occasion suitability, Season suitability, Gender neutrality, and Value for money. You MUST discuss each product individually for every criteria.',
  resultFlag: _ResultFlag.perfume,
  icon: Icons.local_florist_rounded,
  sections: [
    _BeautyAnalysisSection(
      key: 'longevity',
      marker: 'LONGEVITY',
      label: 'Longevity',
      prompt: 'How long the scent is likely to last',
      keywords: ['longevity', 'lasting', 'hours'],
    ),
    _BeautyAnalysisSection(
      key: 'sillage',
      marker: 'SILLAGE',
      label: 'Sillage',
      prompt: 'How far the scent projects from the wearer',
      keywords: ['sillage', 'projection', 'projects'],
    ),
    _BeautyAnalysisSection(
      key: 'fragranceNotes',
      marker: 'FRAGRANCE_NOTES',
      label: 'Fragrance notes',
      prompt: 'Top, heart, and base notes',
      keywords: ['note', 'top', 'heart', 'base'],
    ),
    _BeautyAnalysisSection(
      key: 'occasionSuitability',
      marker: 'OCCASION_SUITABILITY',
      label: 'Occasion suitability',
      prompt: 'Best occasions and settings for this perfume',
      keywords: ['occasion', 'office', 'date', 'evening'],
    ),
    _BeautyAnalysisSection(
      key: 'seasonSuitability',
      marker: 'SEASON_SUITABILITY',
      label: 'Season suitability',
      prompt: 'Best seasons and weather for this perfume',
      keywords: ['season', 'summer', 'winter', 'weather'],
    ),
    _BeautyAnalysisSection(
      key: 'genderNeutrality',
      marker: 'GENDER_NEUTRALITY',
      label: 'Gender neutrality',
      prompt: 'How masculine, feminine, or gender-neutral it reads',
      keywords: ['gender', 'masculine', 'feminine', 'unisex'],
    ),
    _BeautyAnalysisSection(
      key: 'valueForMoney',
      marker: 'VALUE_FOR_MONEY',
      label: 'Value for money',
      prompt: 'Value based on price, performance, and versatility',
      keywords: ['value', 'money', 'price', 'performance'],
    ),
  ],
);
