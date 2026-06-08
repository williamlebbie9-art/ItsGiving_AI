import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/decision_models.dart';
import '../../core/services/decision_engine.dart';
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
        const SizedBox(height: 16),
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
      );

      final overall = await widget.decisionEngine.decide(overallRequest);

      // Per-product focused prompts
      final requestA = DecisionRequest(
        query:
            'Provide a concise cosmetic analysis for Product A. Include Effects, Ingredients, Pros, Cons, Estimated price range, and Where to buy. End with a short recommendation.',
        manualCategory: _selectedCategory,
        imagePaths: [_productAImage!.path],
      );
      final resultA = await widget.decisionEngine.decide(requestA);

      final requestB = DecisionRequest(
        query:
            'Provide a concise cosmetic analysis for Product B. Include Effects, Ingredients, Pros, Cons, Estimated price range, and Where to buy. End with a short recommendation.',
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
        productADetails: {
          'priceAndPurchase': resultA.reasoning,
          'effectsBenefits': resultA.reasoning,
          'nutrients': resultA.reasoning,
          'prosCons': [
            if (resultA.pros.isNotEmpty) resultA.pros.join('\n'),
            if (resultA.cons.isNotEmpty) resultA.cons.join('\n'),
          ].where((item) => item.isNotEmpty).join('\n\n'),
          'processedChemicals': resultA.reasoning,
        },
        productBDetails: {
          'priceAndPurchase': resultB.reasoning,
          'effectsBenefits': resultB.reasoning,
          'nutrients': resultB.reasoning,
          'prosCons': [
            if (resultB.pros.isNotEmpty) resultB.pros.join('\n'),
            if (resultB.cons.isNotEmpty) resultB.cons.join('\n'),
          ].where((item) => item.isNotEmpty).join('\n\n'),
          'processedChemicals': resultB.reasoning,
        },
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

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
