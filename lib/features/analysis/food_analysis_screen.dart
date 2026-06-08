import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/decision_models.dart';
import '../../core/services/decision_engine.dart';
import '../../core/storage/comparison_repository.dart';
import '../products/comparison_result_screen.dart';

class FoodAnalysisScreen extends StatefulWidget {
  const FoodAnalysisScreen({
    required this.decisionEngine,
    required this.comparisonRepository,
    super.key,
  });

  final DecisionEngine decisionEngine;
  final ComparisonRepository comparisonRepository;

  @override
  State<FoodAnalysisScreen> createState() => _FoodAnalysisScreenState();
}

class _FoodAnalysisScreenState extends State<FoodAnalysisScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _productAImage;
  XFile? _productBImage;
  bool _isAnalyzing = false;
  String _analysisSummary = '';
  DecisionCategory _selectedCategory = DecisionCategory.food;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food Analysis'), centerTitle: true),
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
            // Show nutrition summary only after analysis completes
            _analysisSummary.isNotEmpty
                ? _buildNutritionSummary(context)
                : Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Upload both food products and tap Analyze to view ingredients, nutrition, additives, allergens, and the health score.',
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
                    : const Text('Analyze Food Pair'),
                onPressed: _isAnalyzing ? null : _analyzeFood,
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
          'Food product intelligence',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Upload or scan two food items and compare ingredients, nutrients, additives, allergens, and health score.',
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
              'Auto-detects food category from images and text, but you can adjust manually if needed.',
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
          title: 'Food Product A',
          image: _productAImage,
          description: 'Scan ingredients, nutrition label, or package.',
          onCameraTap: () => _pickImageFromCamera((image) {
            setState(() => _productAImage = image);
          }),
          onGalleryTap: () => _pickImageFromGallery((image) {
            setState(() => _productAImage = image);
          }),
        ),
        const SizedBox(height: 16),
        _buildProductCard(
          title: 'Food Product B',
          image: _productBImage,
          description: 'Scan second item to compare side-by-side.',
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

  Widget _buildNutritionSummary(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparison at a glance',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _metricChip(context, 'Sugar', 'A: 12g / B: 8g'),
                _metricChip(context, 'Protein', 'A: 3g / B: 5g'),
                _metricChip(context, 'Fiber', 'A: 2g / B: 4g'),
                _metricChip(context, 'Calories', 'A: 220 / B: 190'),
                _metricChip(context, 'Colors', 'A: Yes / B: No'),
                _metricChip(
                  context,
                  'Sweeteners',
                  'A: Artificial / B: Natural',
                ),
                _metricChip(context, 'Preservatives', 'A: Moderate / B: Low'),
                _metricChip(context, 'Allergens', 'A: Soy / B: Wheat'),
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
                'Upload both food products and tap Analyze to receive a detailed verdict, including health score, additives overview, and nutrition insights.',
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
      _showError('Failed to capture food image: $e');
    }
  }

  Future<void> _pickImageFromGallery(Function(XFile) onPick) async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        onPick(image);
      }
    } catch (e) {
      _showError('Failed to pick food image: $e');
    }
  }

  Future<void> _analyzeFood() async {
    if (_productAImage == null || _productBImage == null) {
      _showError('Please select both food products to compare.');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisSummary = '';
    });

    try {
      final overallRequest = DecisionRequest(
        query:
            'Compare these two food products in detail. For each product provide: Price and where to purchase, Effects or benefits, Major differences, Nutrients, Pros and cons, whether it is processed and the amount of chemicals. Then give a final verdict summarizing everything and choosing a best product.',
        manualCategory: _selectedCategory,
        imagePaths: [_productAImage!.path, _productBImage!.path],
      );
      final overall = await widget.decisionEngine.decide(overallRequest);

      final requestA = DecisionRequest(
        query:
            'Provide a detailed food analysis for Product A. Include: Price and where to purchase, Effects or benefits, Nutrients, Pros and cons, whether it is processed, and amount of chemicals. End with a short recommendation.',
        manualCategory: _selectedCategory,
        imagePaths: [_productAImage!.path],
      );
      final resultA = await widget.decisionEngine.decide(requestA);

      final requestB = DecisionRequest(
        query:
            'Provide a detailed food analysis for Product B. Include: Price and where to purchase, Effects or benefits, Nutrients, Pros and cons, whether it is processed, and amount of chemicals. End with a short recommendation.',
        manualCategory: _selectedCategory,
        imagePaths: [_productBImage!.path],
      );
      final resultB = await widget.decisionEngine.decide(requestB);

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
        valueForMoney: 'See per-product comparison rows.',
        qualityAssessment:
            'A: ${resultA.confidenceScore}, B: ${resultB.confidenceScore}',
        summary: overall.reasoning,
        recommendation: overall.bestChoice.isNotEmpty
            ? overall.bestChoice
            : 'Product A or Product B',
        alternativeRecommendations: {'Verdict': overall.reasoning},
        productADetails: (() {
          String extractCalories(String text) {
            final regex = RegExp(
              r"(?:(\d+(?:[\.,]\d+)?))\s*(kcal|calories|cal|kJ|kj)\b",
              caseSensitive: false,
            );
            final match = regex.firstMatch(text);
            if (match == null) return '';
            final valueRaw = match.group(1) ?? '';
            final unitRaw = match.group(2) ?? '';
            final value = double.tryParse(valueRaw.replaceAll(',', '.')) ?? 0.0;
            final unit = unitRaw.toLowerCase();
            if (unit == 'kj') {
              final kcal = value / 4.184;
              final kcalStr = kcal.truncateToDouble() == kcal
                  ? kcal.toStringAsFixed(0)
                  : kcal.toStringAsFixed(1);
              return '$kcalStr kcal ($valueRaw kJ)';
            }
            final labelUnit = (unit == 'calories' || unit == 'cal')
                ? 'kcal'
                : unit;
            return '$valueRaw $labelUnit';
          }

          final calories = extractCalories(resultA.reasoning);
          return {
            'priceAndPurchase': resultA.reasoning,
            'effectsBenefits': resultA.reasoning,
            'nutrients': resultA.reasoning,
            'ingredients': resultA.reasoning,
            'calories': calories,
            'prosCons': [
              if (resultA.pros.isNotEmpty) resultA.pros.join('\n'),
              if (resultA.cons.isNotEmpty) resultA.cons.join('\n'),
            ].where((item) => item.isNotEmpty).join('\n\n'),
            'processedChemicals': resultA.reasoning,
          };
        })(),
        productBDetails: (() {
          String extractCalories(String text) {
            final regex = RegExp(
              r"(?:(\d+(?:[\.,]\d+)?))\s*(kcal|calories|cal|kJ|kj)\b",
              caseSensitive: false,
            );
            final match = regex.firstMatch(text);
            if (match == null) return '';
            final valueRaw = match.group(1) ?? '';
            final unitRaw = match.group(2) ?? '';
            final value = double.tryParse(valueRaw.replaceAll(',', '.')) ?? 0.0;
            final unit = unitRaw.toLowerCase();
            if (unit == 'kj') {
              final kcal = value / 4.184;
              final kcalStr = kcal.truncateToDouble() == kcal
                  ? kcal.toStringAsFixed(0)
                  : kcal.toStringAsFixed(1);
              return '$kcalStr kcal ($valueRaw kJ)';
            }
            final labelUnit = (unit == 'calories' || unit == 'cal')
                ? 'kcal'
                : unit;
            return '$valueRaw $labelUnit';
          }

          final calories = extractCalories(resultB.reasoning);
          return {
            'priceAndPurchase': resultB.reasoning,
            'effectsBenefits': resultB.reasoning,
            'nutrients': resultB.reasoning,
            'ingredients': resultB.reasoning,
            'calories': calories,
            'prosCons': [
              if (resultB.pros.isNotEmpty) resultB.pros.join('\n'),
              if (resultB.cons.isNotEmpty) resultB.cons.join('\n'),
            ].where((item) => item.isNotEmpty).join('\n\n'),
            'processedChemicals': resultB.reasoning,
          };
        })(),
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
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Food analysis failed: $e');
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
