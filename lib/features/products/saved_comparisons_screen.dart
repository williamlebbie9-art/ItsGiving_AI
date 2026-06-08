import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/decision_models.dart';
import '../../core/services/decision_engine.dart';
import '../../core/storage/comparison_repository.dart';
import 'comparison_result_screen.dart';

class SavedComparisonsScreen extends StatefulWidget {
  const SavedComparisonsScreen({
    required this.comparisonRepository,
    required this.decisionEngine,
    super.key,
  });

  final ComparisonRepository comparisonRepository;
  final DecisionEngine decisionEngine;

  @override
  State<SavedComparisonsScreen> createState() => _SavedComparisonsScreenState();
}

class _SavedComparisonsScreenState extends State<SavedComparisonsScreen> {
  final _searchController = TextEditingController();
  late Future<List<ProductComparison>> _comparisons;

  @override
  void initState() {
    super.initState();
    _loadComparisons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadComparisons() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _comparisons = widget.comparisonRepository.list();
      } else {
        _comparisons = widget.comparisonRepository.search(
          _searchController.text,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Comparisons'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _loadComparisons(),
                decoration: InputDecoration(
                  hintText: 'Search comparisons...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<ProductComparison>>(
                future: _comparisons,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final comparisons = snapshot.data ?? [];

                  if (comparisons.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bookmark_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No saved comparisons',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Save comparisons to view them later',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: comparisons.length,
                    itemBuilder: (context, index) {
                      final comparison = comparisons[index];
                      return _ComparisonCard(
                        comparison: comparison,
                        onTap: () => _openComparison(comparison),
                        onDelete: () => _deleteComparison(comparison),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openComparison(ProductComparison comparison) {
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

  Future<void> _deleteComparison(ProductComparison comparison) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comparison?'),
        content: Text(
          'Are you sure you want to delete the comparison between ${comparison.productAName} and ${comparison.productBName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.comparisonRepository.delete(comparison.id);
      _loadComparisons();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comparison deleted')));
      }
    }
  }
}

class _ComparisonCard extends StatelessWidget {
  final ProductComparison comparison;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ComparisonCard({
    required this.comparison,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final formattedDate = dateFormat.format(comparison.createdAt);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Recommendation badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getRecommendationIcon(),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),

              // Product names and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${comparison.productAName} vs ${comparison.productBName}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Winner: ${comparison.recommendation}',
                            style: Theme.of(context).textTheme.labelSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formattedDate,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getRecommendationIcon() {
    if (comparison.recommendation.toLowerCase().contains('a')) {
      return Icons.first_page;
    }
    return Icons.last_page;
  }
}
