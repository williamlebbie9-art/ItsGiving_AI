import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/decision_models.dart';
import '../../core/services/decision_engine.dart';
import '../../core/storage/comparison_repository.dart';
import 'comparison_chat_screen.dart';

class ComparisonResultScreen extends StatefulWidget {
  const ComparisonResultScreen({
    required this.comparison,
    required this.decisionEngine,
    required this.comparisonRepository,
    this.startChatExpanded = false,
    super.key,
  });

  final ProductComparison comparison;
  final DecisionEngine decisionEngine;
  final ComparisonRepository comparisonRepository;
  final bool startChatExpanded;

  @override
  State<ComparisonResultScreen> createState() => _ComparisonResultScreenState();
}

class _ComparisonResultScreenState extends State<ComparisonResultScreen> {
  late bool _isSaved;
  late bool _chatExpanded;

  @override
  void initState() {
    super.initState();
    _chatExpanded = widget.startChatExpanded;
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final saved = await widget.comparisonRepository.getById(
      widget.comparison.id,
    );
    if (mounted) {
      setState(() {
        _isSaved = saved != null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final formattedDate = dateFormat.format(widget.comparison.createdAt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparison Result'),
        actions: [
          IconButton(
            icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_outline),
            onPressed: _toggleSave,
            tooltip: _isSaved ? 'Remove from saved' : 'Save comparison',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: _shareComparison,
                child: const Text('Share'),
              ),
              PopupMenuItem(
                onTap: _openChat,
                child: const Text('Ask Questions'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header with images
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(
                                    widget
                                        .comparison
                                        .productAImage
                                        .originalPath,
                                  ),
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.comparison.productAName,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(
                                    widget
                                        .comparison
                                        .productBImage
                                        .originalPath,
                                  ),
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.comparison.productBName,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      formattedDate,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),

            // Recommendation badges
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildRecommendationBadges(),
              ),
            ),

            // Verdict card (prominent)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: _buildVerdictCard(),
              ),
            ),

            // Overview section
            if (widget.comparison.overview.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8,
                  ),
                  child: _buildSection('Overview', widget.comparison.overview),
                ),
              ),

            // Side-by-side comparison cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: _buildComparisonCards(),
              ),
            ),

            // Specifications
            if (widget.comparison.specifications.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8,
                  ),
                  child: _buildSection(
                    'Specifications',
                    widget.comparison.specifications,
                  ),
                ),
              ),

            // Major Differences
            if (widget.comparison.majorDifferences.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8,
                  ),
                  child: _buildSection(
                    'Major Differences',
                    widget.comparison.majorDifferences,
                  ),
                ),
              ),

            // Value for Money
            if (widget.comparison.valueForMoney.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8,
                  ),
                  child: _buildSection(
                    'Value for Money',
                    widget.comparison.valueForMoney,
                  ),
                ),
              ),

            // Quality Assessment
            if (widget.comparison.qualityAssessment.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8,
                  ),
                  child: _buildSection(
                    'Quality Assessment',
                    widget.comparison.qualityAssessment,
                  ),
                ),
              ),

            // Summary
            if (widget.comparison.summary.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8,
                  ),
                  child: _buildSection('Summary', widget.comparison.summary),
                ),
              ),

            // Inline collapsible chat for follow-up questions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () =>
                          setState(() => _chatExpanded = !_chatExpanded),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Ask follow-up questions',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _chatExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                            onPressed: () =>
                                setState(() => _chatExpanded = !_chatExpanded),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: SizedBox(
                        height: 360,
                        child: ComparisonChatWidget(
                          comparison: widget.comparison,
                          decisionEngine: widget.decisionEngine,
                        ),
                      ),
                      crossFadeState: _chatExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.bottom + 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationBadges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommendations',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.comparison.alternativeRecommendations.entries
              .map((entry) => _buildBadge(entry.key, entry.value))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.primary),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerdictCard() {
    final pick = widget.comparison.recommendation.isNotEmpty
        ? widget.comparison.recommendation
        : widget.comparison.productADetails.containsKey('priceAndPurchase')
        ? widget.comparison.productAName
        : widget.comparison.productBName;

    final reason =
        widget.comparison.alternativeRecommendations['Verdict'] ??
        widget.comparison.summary;
    final isA = pick.toLowerCase().contains(
      widget.comparison.productAName.toLowerCase(),
    );
    final isB = pick.toLowerCase().contains(
      widget.comparison.productBName.toLowerCase(),
    );

    final bgColor = isA
        ? Theme.of(context).colorScheme.primaryContainer
        : isB
        ? Theme.of(context).colorScheme.secondaryContainer
        : Theme.of(context).colorScheme.surfaceContainerHighest;

    return Card(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Verdict',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  pick,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(reason, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCards() {
    final priceA =
        widget.comparison.productADetails['priceAndPurchase'] ??
        'No price details available.';
    final priceB =
        widget.comparison.productBDetails['priceAndPurchase'] ??
        'No price details available.';
    final effectsA =
        widget.comparison.productADetails['effectsBenefits'] ??
        widget.comparison.advantagesA;
    final effectsB =
        widget.comparison.productBDetails['effectsBenefits'] ??
        widget.comparison.advantagesB;
    final nutrientsA =
        widget.comparison.productADetails['nutrients'] ??
        widget.comparison.ingredients;
    final nutrientsB =
        widget.comparison.productBDetails['nutrients'] ??
        widget.comparison.ingredients;
    final ingredientsA =
        widget.comparison.productADetails['ingredients'] ??
        widget.comparison.ingredients;
    final ingredientsB =
        widget.comparison.productBDetails['ingredients'] ??
        widget.comparison.ingredients;
    final caloriesA = widget.comparison.productADetails['calories'] ?? '';
    final caloriesB = widget.comparison.productBDetails['calories'] ?? '';
    final ingredientsWithCaloriesA =
        ingredientsA + (caloriesA.isNotEmpty ? '\n\nCalories: $caloriesA' : '');
    final ingredientsWithCaloriesB =
        ingredientsB + (caloriesB.isNotEmpty ? '\n\nCalories: $caloriesB' : '');
    final prosConsA =
        widget.comparison.productADetails['prosCons'] ??
        widget.comparison.advantagesA;
    final prosConsB =
        widget.comparison.productBDetails['prosCons'] ??
        widget.comparison.advantagesB;
    final processedA =
        widget.comparison.productADetails['processedChemicals'] ??
        'No processed/chemicals summary available.';
    final processedB =
        widget.comparison.productBDetails['processedChemicals'] ??
        'No processed/chemicals summary available.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Comparison',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Table(
          border: TableBorder.all(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          defaultVerticalAlignment: TableCellVerticalAlignment.top,
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              children: [
                _buildComparisonHeaderCell(''),
                _buildComparisonHeaderCell(widget.comparison.productAName),
                _buildComparisonHeaderCell(widget.comparison.productBName),
              ],
            ),
            _buildComparisonTableRow('Price & Purchase', priceA, priceB),
            _buildComparisonTableRow('Effects / Benefits', effectsA, effectsB),
            _buildComparisonTableRow(
              'Ingredients',
              ingredientsWithCaloriesA,
              ingredientsWithCaloriesB,
            ),
            _buildComparisonTableRow('Nutrients', nutrientsA, nutrientsB),
            _buildComparisonTableRow('Pros & Cons', prosConsA, prosConsB),
            _buildComparisonTableRow(
              'Processed / Chemicals',
              processedA,
              processedB,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComparisonHeaderCell(String title) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  TableRow _buildComparisonTableRow(
    String label,
    String productA,
    String productB,
  ) {
    return TableRow(
      children: [
        _buildComparisonLabelCell(label),
        _buildComparisonCell(productA),
        _buildComparisonCell(productB),
      ],
    );
  }

  Widget _buildComparisonLabelCell(String label) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(12.0),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildComparisonCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }

  Widget _buildSection(String title, String content) {
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
            Text(content, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSave() async {
    if (_isSaved) {
      await widget.comparisonRepository.delete(widget.comparison.id);
    } else {
      await widget.comparisonRepository.save(widget.comparison);
    }
    setState(() {
      _isSaved = !_isSaved;
    });
    _showMessage(_isSaved ? 'Comparison saved!' : 'Comparison removed!');
  }

  void _shareComparison() {
    // TODO: Implement sharing
    _showMessage('Share feature coming soon');
  }

  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ComparisonChatScreen(
          comparison: widget.comparison,
          decisionEngine: widget.decisionEngine,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
