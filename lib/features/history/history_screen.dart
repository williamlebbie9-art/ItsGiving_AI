import 'package:flutter/material.dart';

import '../../core/models/decision_models.dart';
import '../results/result_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({required this.items, super.key});

  final List<DecisionHistoryItem> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Decision History')),
      body: items.isEmpty
          ? const Center(child: Text('No decisions yet.'))
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(item.result.bestChoice),
                  subtitle: Text(
                    '${item.result.category.title} • ${item.query}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${item.createdAt.month}/${item.createdAt.day}',
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ResultScreen(
                          query: item.query,
                          result: item.result,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
