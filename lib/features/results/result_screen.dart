import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/decision_models.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({required this.query, required this.result, super.key});

  final String query;
  final DecisionResult result;

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: Text(result.category.title),
        actions: [
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _toShareText()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Result copied to clipboard')),
              );
            },
            icon: const Icon(Icons.share_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(query, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE76F51).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE76F51), width: 1.4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Best Choice',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  result.bestChoice,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text('Confidence: ${result.confidenceScore}'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Reasoning',
            content: Text(result.reasoning),
            color: cardColor,
          ),
          _SectionCard(
            title: 'Alternatives',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: result.alternatives
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('- $item'),
                    ),
                  )
                  .toList(growable: false),
            ),
            color: cardColor,
          ),
          _SectionCard(
            title: 'Pros',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: result.pros
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('+ $item'),
                    ),
                  )
                  .toList(growable: false),
            ),
            color: cardColor,
          ),
          _SectionCard(
            title: 'Cons',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: result.cons
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('- $item'),
                    ),
                  )
                  .toList(growable: false),
            ),
            color: cardColor,
          ),
        ],
      ),
    );
  }

  String _toShareText() {
    return '''
its giving.AI Result
Question: $query
Category: ${result.category.title}
Best Choice: ${result.bestChoice}
Alternatives: ${result.alternatives.join(', ')}
Reasoning: ${result.reasoning}
Pros: ${result.pros.join(', ')}
Cons: ${result.cons.join(', ')}
Confidence: ${result.confidenceScore}
''';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.content,
    required this.color,
  });

  final String title;
  final Widget content;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }
}
