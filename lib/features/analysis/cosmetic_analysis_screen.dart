import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/decision_models.dart';
import '../../core/services/decision_engine.dart';
import '../../core/extractors/product_details_extractor.dart';
import '../../core/storage/comparison_repository.dart';
import '../products/comparison_result_screen.dart';

class CosmeticAnalysisScreen extends StatefulWidget {
  const CosmeticAnalysisScreen({
    required this.decisionEngine,
    required this.comparisonRepository,
    super.key,
  });

  final DecisionEngine decisionEngine;
  final ComparisonRepository comparisonRepository;

  @override
  State<CosmeticAnalysisScreen> createState() => _CosmeticAnalysisScreenState();
}

class _CosmeticAnalysisScreenState extends State<CosmeticAnalysisScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _productAImage;
  XFile? _productBImage;
  bool _isAnalyzing = false;
  String _analysisSummary = '';
  DecisionCategory _selectedCategory = DecisionCategory.fashion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cosmetic Analysis'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildCategorySelector(context),
            const SizedBox(height: 16),
            _buildProductPairSection(context),
            const SizedBox(height: 16),
            // Show ingredient highlights only after analysis completes
            _analysisSummary.isNotEmpty
                ? _buildIngredientSummary(context)
                : Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Upload both cosmetic products and tap Analyze to view ingredient highlights, actives, potential irritants, preservatives, and skin compatibility.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
            const SizedBox(height: 16),
            _buildAnalysisCard(context),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                icon: const Icon(Icons.auto_awesome),
                label: _isAnalyzing
                    ? const Text('Analyzing...')
                    : const Text('Analyze Cosmetic Pair'),
                onPressed: _isAnalyzing ? null : _analyzeCosmetic,
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
          'Cosmetic formulation intelligence',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Compare skincare and beauty products using ingredient analysis, irritant detection, preservatives, fragrances and skin compatibility.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product category',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DecisionCategory.values.map((category) {
                final label = category == DecisionCategory.food
                    ? 'Food'
                    : category == DecisionCategory.fashion
                    ? 'Cosmetics'
                    : 'General';
                return ChoiceChip(
                  label: Text(label),
                  selected: _selectedCategory == category,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              'The AI can detect whether a product is cosmetic, but manual selection gives you more accurate ingredient guidance.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductPairSection(BuildContext context) {
    return Column(
      children: [
        _buildProductCard(
          title: 'Cosmetic Product A',
          image: _productAImage,
          description: 'Scan ingredient list or packaging label.',
          onCameraTap: () => _pickImageFromCamera((image) {
            setState(() => _productAImage = image);
          }),
          onGalleryTap: () => _pickImageFromGallery((image) {
            setState(() => _productAImage = image);
          }),
        ),
        _buildVsDivider(),
        _buildProductCard(
          title: 'Cosmetic Product B',
          image: _productBImage,
          description: 'Scan second formulation to compare.',
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
                FilledButton.icon(
                  onPressed: onCameraTap,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Camera'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: onGalleryTap,
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('Gallery'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientSummary(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingredient highlights',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _metricChip(context, 'Actives', 'Niacinamide, Hyaluronic Acid'),
                _metricChip(context, 'Fragrance', 'Synthetic / Light'),
                _metricChip(
                  context,
                  'Preservatives',
                  'Parabens / Phenoxyethanol',
                ),
                _metricChip(context, 'Irritants', 'Alcohol, Fragrance'),
                _metricChip(context, 'Benefits', 'Hydration, Anti-aging'),
                _metricChip(context, 'Overlap', '58% ingredients in common'),
              ],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verdict',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_analysisSummary.isEmpty)
              Text(
                'Tap Analyze to compare actives, potential irritants, fragrances, skin compatibility, and overall recommendations.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Text(
                _analysisSummary,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
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
      _showError('Failed to capture cosmetic image: $e');
    }
  }

  Future<void> _pickImageFromGallery(Function(XFile) onPick) async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        onPick(image);
      }
    } catch (e) {
      _showError('Failed to pick cosmetic image: $e');
    }
  }

  Future<void> _analyzeCosmetic() async {
    if (_productAImage == null || _productBImage == null) {
      _showError('Please select both cosmetic products to compare.');
      return;
    }
    setState(() {
      _isAnalyzing = true;
      _analysisSummary = '';
    });

    try {
      // Ask for an overall structured comparison focused on cosmetic attributes
      final overallRequest = DecisionRequest(
        query:
            'Compare these two cosmetic products. For each product provide: Effects, Ingredients, Pros, Cons, Estimated price range, Where to buy. Then list Major differences and give a final verdict recommending one product with a short rationale.',
        manualCategory: _selectedCategory,
        imagePaths: [_productAImage!.path, _productBImage!.path],
        compareOptions: ['Product A (Cosmetic)', 'Product B (Cosmetic)'],
      );

      final overall = await widget.decisionEngine.decide(overallRequest);

      // Per-product focused prompts with section markers
      final requestA = DecisionRequest(
        query:
            'Provide a detailed cosmetic analysis for Product A. Organize your response using EXACT section markers like this:\n\n'
            '[PRICE_AND_PURCHASE]\nPrice of this product (e.g., \$50, \$100)\n[/PRICE_AND_PURCHASE]\n\n'
            '[EFFECTS_BENEFITS]\nEffects or benefits of this product\n[/EFFECTS_BENEFITS]\n\n'
            '[INGREDIENTS]\nKey ingredients and materials used to make this product\n[/INGREDIENTS]\n\n'
            '[PROS_CONS]\n+ Pro 1\n+ Pro 2\n- Con 1\n- Con 2\n[/PROS_CONS]\n\n'
            '[RECOMMENDATION]\nShort recommendation\n[/RECOMMENDATION]',
        manualCategory: _selectedCategory,
        imagePaths: [_productAImage!.path],
      );
      final resultA = await widget.decisionEngine.decide(requestA);

      final requestB = DecisionRequest(
        query:
            'Provide a detailed cosmetic analysis for Product B. Organize your response using EXACT section markers like this:\n\n'
            '[PRICE_AND_PURCHASE]\nPrice of this product (e.g., \$50, \$100)\n[/PRICE_AND_PURCHASE]\n\n'
            '[EFFECTS_BENEFITS]\nEffects or benefits of this product\n[/EFFECTS_BENEFITS]\n\n'
            '[INGREDIENTS]\nKey ingredients and materials used to make this product\n[/INGREDIENTS]\n\n'
            '[PROS_CONS]\n+ Pro 1\n+ Pro 2\n- Con 1\n- Con 2\n[/PROS_CONS]\n\n'
            '[RECOMMENDATION]\nShort recommendation\n[/RECOMMENDATION]',
        manualCategory: _selectedCategory,
        imagePaths: [_productBImage!.path],
      );
      final resultB = await widget.decisionEngine.decide(requestB);

      // Build comparison object
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
        valueForMoney: 'See per-product analysis',
        qualityAssessment:
            'A: ${resultA.confidenceScore}, B: ${resultB.confidenceScore}',
        summary: overall.reasoning,
        recommendation: overall.bestChoice.isNotEmpty
            ? overall.bestChoice
            : '${resultA.bestChoice} / ${resultB.bestChoice}',
        alternativeRecommendations: {'Verdict': overall.reasoning},
        productADetails: _extractProductDetails(resultA),
        productBDetails: _extractProductDetails(resultB),
      );

      // Save to repository
      await widget.comparisonRepository.save(comparison);

      if (mounted) {
        // Open result screen and expand chat so users can ask follow-ups
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ComparisonResultScreen(
              comparison: comparison,
              decisionEngine: widget.decisionEngine,
              comparisonRepository: widget.comparisonRepository,
              startChatExpanded: true,
              isCosmetic: true,
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Cosmetic analysis failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Map<String, String> _extractProductDetails(DecisionResult result) {
    final extractor = const ProductDetailsExtractor();
    final text = result.reasoning;

    // If the AI used section markers, extract per-section content
    if (extractor.hasMarkers(text)) {
      final prosConsText = extractor.extract(text, 'PROS_CONS');
      final parsed = extractor.parseProsCons(prosConsText);
      final prosStr = parsed.key.isNotEmpty ? parsed.key.join('\n') : '';
      final consStr = parsed.value.isNotEmpty ? parsed.value.join('\n') : '';
      return {
        'priceAndPurchase': extractor.extract(text, 'PRICE_AND_PURCHASE'),
        'effectsBenefits': extractor.extract(text, 'EFFECTS_BENEFITS'),
        'ingredients': extractor.extract(text, 'INGREDIENTS'),
        'prosCons': [
          if (prosStr.isNotEmpty) 'Pros:\n$prosStr',
          if (consStr.isNotEmpty) 'Cons:\n$consStr',
        ].join('\n\n'),
      };
    }

    // Fallback: intelligently split freeform text into sections to avoid
    // dumping the full reasoning into every field (which causes duplicate
    // text across all cosmetic sections in the comparison view).
    /// Splits freeform text by topic headers and assigns each block
    /// to the best-matching section key.
    String extractSection(
      String haystack,
      String label,
      List<String> keywords,
    ) {
      // Try to match "**Label:** content" or "Label:\ncontent"
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

      // Fallback: search by keyword presence and extract a sensible block
      final lines = haystack.split('\n');
      final buffer = <String>[];
      bool capturing = false;
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) {
          if (capturing) break;
          continue;
        }
        final lower = trimmed.toLowerCase();
        if (!capturing) {
          final hasKeyword = keywords.any((k) => lower.contains(k));
          final isHeader =
              trimmed.startsWith('**') ||
              trimmed.startsWith('#') ||
              trimmed.endsWith(':') ||
              RegExp(r'^[A-Z][A-Z\s]+[:\n]').hasMatch(trimmed);
          if (hasKeyword || isHeader && lower.contains(keywords.first)) {
            capturing = true;
            if (isHeader && lower.contains(keywords.first)) continue;
            buffer.add(trimmed);
          }
        } else {
          if (trimmed.startsWith('**') ||
              trimmed.startsWith('#') ||
              (trimmed.endsWith(':') && trimmed.length < 40)) {
            break;
          }
          buffer.add(trimmed);
        }
      }
      return buffer.isNotEmpty ? buffer.join('\n') : '';
    }

    final price = extractSection(text, 'Price', [
      'price',
      'cost',
      'purchase',
      'buy',
      'budget',
    ]);
    final effects = extractSection(text, 'Effects', [
      'effect',
      'benefit',
      'impact',
    ]);
    final ingredients = extractSection(text, 'Ingredients', [
      'ingredient',
      'composition',
    ]);

    return {
      'priceAndPurchase': price.isNotEmpty
          ? price
          : (result.pros.isNotEmpty
                ? result.pros
                      .where((p) {
                        final lower = p.toLowerCase();
                        return lower.contains('price') ||
                            lower.contains('budget') ||
                            lower.contains('cost') ||
                            lower.contains('buy') ||
                            lower.contains('store') ||
                            lower.contains('value');
                      })
                      .join('\n')
                : ''),
      'effectsBenefits': effects.isNotEmpty
          ? effects
          : (result.pros.isNotEmpty
                ? result.pros.join('\n')
                : 'No effects/benefits extracted.'),
      'ingredients': ingredients.isNotEmpty
          ? ingredients
          : (result.cons.isNotEmpty
                ? result.cons.join('\n')
                : 'No ingredients extracted.'),
      'prosCons': [
        if (result.pros.isNotEmpty) 'Pros:\n${result.pros.join('\n')}',
        if (result.cons.isNotEmpty) 'Cons:\n${result.cons.join('\n')}',
      ].where((item) => item.isNotEmpty).join('\n\n'),
    };
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
