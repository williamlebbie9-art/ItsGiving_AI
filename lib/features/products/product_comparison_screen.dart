import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/decision_models.dart';
import '../../core/services/decision_engine.dart';
import '../../core/extractors/product_details_extractor.dart';
import '../../core/storage/comparison_repository.dart';
import '../../core/storage/history_repository.dart';
import '../../core/storage/profile_repository.dart';
import 'comparison_result_screen.dart';

class ProductComparisonScreen extends StatefulWidget {
  const ProductComparisonScreen({
    required this.decisionEngine,
    required this.comparisonRepository,
    required this.historyRepository,
    required this.profileRepository,
    super.key,
  });

  final DecisionEngine decisionEngine;
  final ComparisonRepository comparisonRepository;
  final HistoryRepository historyRepository;
  final ProfileRepository profileRepository;

  @override
  State<ProductComparisonScreen> createState() =>
      _ProductComparisonScreenState();
}

class _ProductComparisonScreenState extends State<ProductComparisonScreen> {
  final _imagePicker = ImagePicker();

  // Product A
  XFile? _productAImage;
  String? _productAName;

  // Product B
  XFile? _productBImage;
  String? _productBName;

  bool _isAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    final hasProductA = _productAImage != null;
    final hasProductB = _productBImage != null;
    final canCompare = hasProductA && hasProductB && !_isAnalyzing;

    return Scaffold(
      appBar: AppBar(title: const Text('Compare Products'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    // Product A Section
                    _ProductSelectionCard(
                      title: 'Product A',
                      image: _productAImage,
                      onCameraTap: () => _pickImageFromCamera(_pickProductA),
                      onGalleryTap: () => _pickImageFromGallery(_pickProductA),
                      onRemove: _productAImage != null
                          ? () => setState(() => _productAImage = null)
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // VS Divider
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.compare_arrows,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Product B Section
                    _ProductSelectionCard(
                      title: 'Product B',
                      image: _productBImage,
                      onCameraTap: () => _pickImageFromCamera(_pickProductB),
                      onGalleryTap: () => _pickImageFromGallery(_pickProductB),
                      onRemove: _productBImage != null
                          ? () => setState(() => _productBImage = null)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Compare Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: canCompare ? _analyzeComparison : null,
                  child: _isAnalyzing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Compare Products'),
                ),
              ),
            ],
          ),
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
      _showError('Failed to capture image: $e');
    }
  }

  Future<void> _pickImageFromGallery(Function(XFile) onPick) async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        onPick(image);
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  void _pickProductA(XFile image) {
    setState(() => _productAImage = image);
  }

  void _pickProductB(XFile image) {
    setState(() => _productBImage = image);
  }

  Future<void> _analyzeComparison() async {
    if (_productAImage == null || _productBImage == null) {
      _showError('Please select both products');
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      // Create comparison request
      final request = DecisionRequest(
        query:
            'Compare these two products in detail. Provide Product A details as the pros array and Product B details as the alternatives array, and include an estimated current price range for both products.',
        manualCategory: DecisionCategory.products,
        imagePaths: [_productAImage!.path, _productBImage!.path],
        compareOptions: [
          _productAName ?? 'Product A',
          _productBName ?? 'Product B',
        ],
      );

      // Get overall AI analysis (comparison)
      final result = await widget.decisionEngine.decide(request);

      // Also request focused analysis for each product to ensure both get individual summaries
      final requestA = DecisionRequest(
        query:
            'Provide a concise analysis for Product A (${_productAName ?? 'Product A'}). Organize your response using EXACT section markers like this:\n\n'
            '[PRICE_AND_PURCHASE]\nEstimated price range and where to buy this product\n[/PRICE_AND_PURCHASE]\n\n'
            '[EFFECTS_BENEFITS]\nKey features, specifications, and benefits\n[/EFFECTS_BENEFITS]\n\n'
            '[PROS_CONS]\n+ Main advantages\n+ Pro 2\n- Main drawbacks\n- Con 2\n[/PROS_CONS]\n\n'
            '[RECOMMENDATION]\nShort recommendation\n[/RECOMMENDATION]',
        manualCategory: DecisionCategory.products,
        imagePaths: [_productAImage!.path],
      );
      final resultA = await widget.decisionEngine.decide(requestA);

      final requestB = DecisionRequest(
        query:
            'Provide a concise analysis for Product B (${_productBName ?? 'Product B'}). Organize your response using EXACT section markers like this:\n\n'
            '[PRICE_AND_PURCHASE]\nEstimated price range and where to buy this product\n[/PRICE_AND_PURCHASE]\n\n'
            '[EFFECTS_BENEFITS]\nKey features, specifications, and benefits\n[/EFFECTS_BENEFITS]\n\n'
            '[PROS_CONS]\n+ Main advantages\n+ Pro 2\n- Main drawbacks\n- Con 2\n[/PROS_CONS]\n\n'
            '[RECOMMENDATION]\nShort recommendation\n[/RECOMMENDATION]',
        manualCategory: DecisionCategory.products,
        imagePaths: [_productBImage!.path],
      );
      final resultB = await widget.decisionEngine.decide(requestB);

      // Create product images
      final productAImage = ProductImage(
        originalPath: _productAImage!.path,
        extractedText: '',
      );

      final productBImage = ProductImage(
        originalPath: _productBImage!.path,
        extractedText: '',
      );

      // Build comparison using per-product analyses plus the overall comparison
      final comparison = ProductComparison(
        id: const Uuid().v4(),
        productAName: _productAName ?? 'Product A',
        productBName: _productBName ?? 'Product B',
        productAImage: productAImage,
        productBImage: productBImage,
        createdAt: DateTime.now(),
        overview: result.reasoning.isNotEmpty
            ? result.reasoning
            : '${resultA.reasoning}\n\n${resultB.reasoning}',
        specifications: '${resultA.reasoning}\n\n---\n\n${resultB.reasoning}',
        ingredients:
            '${resultA.cons.isNotEmpty ? resultA.cons.join('\n') : resultA.reasoning}\n\n${resultB.cons.isNotEmpty ? resultB.cons.join('\n') : resultB.reasoning}',
        advantagesA: resultA.pros.isNotEmpty
            ? resultA.pros.join('\n')
            : resultA.reasoning,
        advantagesB: resultB.pros.isNotEmpty
            ? resultB.pros.join('\n')
            : resultB.reasoning,
        majorDifferences: result.reasoning,
        valueForMoney: 'See per-product notes and recommendations',
        qualityAssessment:
            'A: ${resultA.confidenceScore}, B: ${resultB.confidenceScore}',
        summary: result.reasoning.isNotEmpty
            ? result.reasoning
            : 'A: ${resultA.reasoning}\n\nB: ${resultB.reasoning}',
        recommendation: result.bestChoice,
        alternativeRecommendations: (() {
          final overall = result.bestChoice;
          final pickA = resultA.bestChoice.isNotEmpty
              ? resultA.bestChoice
              : (overall.isNotEmpty ? overall : 'Product A');
          final pickB = resultB.bestChoice.isNotEmpty
              ? resultB.bestChoice
              : (overall.isNotEmpty ? overall : 'Product B');
          return {
            'Best Overall': overall,
            'Product A Pick': pickA,
            'Product B Pick': pickB,
          };
        })(),
        productADetails: _extractProductDetails(resultA),
        productBDetails: _extractProductDetails(resultB),
      );

      // Save to history
      await widget.comparisonRepository.save(comparison);

      if (mounted) {
        // Navigate to result screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ComparisonResultScreen(
              comparison: comparison,
              decisionEngine: widget.decisionEngine,
              comparisonRepository: widget.comparisonRepository,
              isGeneral: true,
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to analyze products: $e');
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
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
        'prosCons': [
          if (prosStr.isNotEmpty) 'Pros:\n$prosStr',
          if (consStr.isNotEmpty) 'Cons:\n$consStr',
        ].join('\n\n'),
      };
    }

    // Fallback: give each section DIFFERENT content instead of duplicating the full text
    return {
      'priceAndPurchase': result.pros.isNotEmpty
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
          : '',
      'effectsBenefits': result.pros.isNotEmpty ? result.pros.join('\n') : text,
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

class _ProductSelectionCard extends StatelessWidget {
  final String title;
  final XFile? image;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;
  final VoidCallback? onRemove;

  const _ProductSelectionCard({
    required this.title,
    required this.image,
    required this.onCameraTap,
    required this.onGalleryTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (image == null)
              Column(
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onCameraTap,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onGalleryTap,
                          icon: const Icon(Icons.image),
                          label: const Text('Gallery'),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(image!.path),
                      fit: BoxFit.cover,
                      height: 200,
                      width: double.infinity,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onCameraTap,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Retake'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onGalleryTap,
                          icon: const Icon(Icons.image),
                          label: const Text('Change'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (onRemove != null)
                        SizedBox(
                          height: 40,
                          width: 40,
                          child: IconButton(
                            onPressed: onRemove,
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red[100],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
