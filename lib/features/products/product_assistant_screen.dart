import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/models/decision_models.dart';
import '../../core/services/decision_engine.dart';
import '../../core/services/product_message_parser.dart';
import '../../core/storage/history_repository.dart';
import '../../core/storage/profile_repository.dart';

class ProductAssistantScreen extends StatefulWidget {
  const ProductAssistantScreen({
    required this.initialQuery,
    required this.decisionEngine,
    required this.historyRepository,
    required this.profileRepository,
    super.key,
  });

  final String initialQuery;
  final DecisionEngine decisionEngine;
  final HistoryRepository historyRepository;
  final ProfileRepository profileRepository;

  @override
  State<ProductAssistantScreen> createState() => _ProductAssistantScreenState();
}

class _ProductAssistantScreenState extends State<ProductAssistantScreen> {
  final _messageController = TextEditingController();
  final _compareAController = TextEditingController();
  final _compareBController = TextEditingController();
  final _compareCController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatMessage>[];
  final _parser = const ProductMessageParser();

  String _productName = '';
  String _budget = '';
  String _location = '';
  String _preferences = '';
  String _latestIntent = '';
  String? _pendingField = 'product';
  bool _compareMode = false;
  bool _isThinking = false;
  DecisionResult? _latestResult;

  @override
  void initState() {
    super.initState();
    _latestIntent = widget.initialQuery.trim();
    _messages.add(
      const _ChatMessage(
        byUser: false,
        text:
            'Product assistant is ready. Tell me the product name or type you want, and I can also compare up to 3 options.',
      ),
    );

    if (_latestIntent.isNotEmpty) {
      _messages.add(_ChatMessage(byUser: true, text: _latestIntent));
      _extractContextFromText(_latestIntent);
      _askNextQuestionOrRecommend();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _compareAController.dispose();
    _compareBController.dispose();
    _compareCController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Assistant')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Column(
                children: [
                  _ProductControlsCard(
                    compareMode: _compareMode,
                    compareAController: _compareAController,
                    compareBController: _compareBController,
                    compareCController: _compareCController,
                    onCompareModeChanged: _isThinking
                        ? null
                        : (value) {
                            setState(() {
                              _compareMode = value;
                            });
                          },
                  ),
                  if (_latestResult != null || _productName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _ProductSummaryCard(
                        productName: _productName,
                        budget: _budget,
                        location: _location,
                        compareMode: _compareMode,
                        compareOptions: _currentCompareOptions(),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Align(
                    alignment: message.byUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(maxWidth: 340),
                      decoration: BoxDecoration(
                        color: message.byUser
                            ? const Color(0xFFE76F51)
                            : Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: message.byUser
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isThinking)
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                            'Ex: Samsung phone under 300 in Lagos with good battery',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isThinking ? null : _sendMessage,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    _messageController.clear();
    setState(() {
      _messages.add(_ChatMessage(byUser: true, text: text));
      _latestIntent = text;
    });

    _extractContextFromText(text);
    _askNextQuestionOrRecommend();
    _scrollToBottom();
  }

  void _extractContextFromText(String text) {
    final parsed = _parser.parse(
      text,
      expectedField: _pendingField,
      compareMode: _compareMode,
    );

    if (_compareMode && parsed.compareOptions.length >= 2) {
      if (_compareAController.text.trim().isEmpty) {
        _compareAController.text = parsed.compareOptions[0];
      }
      if (_compareBController.text.trim().isEmpty &&
          parsed.compareOptions.length > 1) {
        _compareBController.text = parsed.compareOptions[1];
      }
      if (_compareCController.text.trim().isEmpty &&
          parsed.compareOptions.length > 2) {
        _compareCController.text = parsed.compareOptions[2];
      }
    }

    switch (_pendingField) {
      case 'product':
        _productName = parsed.productName.isNotEmpty
            ? parsed.productName
            : text;
        break;
      case 'budget':
        _budget = parsed.budget.isNotEmpty ? parsed.budget : text;
        break;
      case 'location':
        _location = parsed.location.isNotEmpty ? parsed.location : text;
        break;
      case 'preferences':
        _preferences = parsed.preferences.isNotEmpty
            ? parsed.preferences
            : text;
        break;
      default:
        if (_productName.isEmpty && parsed.productName.isNotEmpty) {
          _productName = parsed.productName;
        }
        if (_budget.isEmpty && parsed.budget.isNotEmpty) {
          _budget = parsed.budget;
        }
        if (_location.isEmpty && parsed.location.isNotEmpty) {
          _location = parsed.location;
        }
        if (_preferences.isEmpty && parsed.preferences.isNotEmpty) {
          _preferences = parsed.preferences;
        }
    }

    if (_productName.isEmpty && parsed.productName.isNotEmpty) {
      _productName = parsed.productName;
    }
    if (_budget.isEmpty && parsed.budget.isNotEmpty) {
      _budget = parsed.budget;
    }
    if (_location.isEmpty && parsed.location.isNotEmpty) {
      _location = parsed.location;
    }
    if (_preferences.isEmpty && parsed.preferences.isNotEmpty) {
      _preferences = parsed.preferences;
    }
  }

  void _askNextQuestionOrRecommend() {
    final compareOptions = _currentCompareOptions();

    if (_productName.isEmpty && compareOptions.length < 2) {
      _pendingField = 'product';
      _addAssistantMessage('What product name or type are you looking for?');
      return;
    }

    if (_budget.isEmpty) {
      _pendingField = 'budget';
      _addAssistantMessage('What is your budget for this product?');
      return;
    }

    if (_location.isEmpty) {
      _pendingField = 'location';
      _addAssistantMessage(
        'What city, country, or market should I use for supplier options?',
      );
      return;
    }

    if (_preferences.isEmpty) {
      _pendingField = 'preferences';
      _addAssistantMessage(
        'Any preferred brand, features, or specs? You can also say "no preference".',
      );
      return;
    }

    if (_compareMode && compareOptions.length < 2) {
      _pendingField = null;
      _addAssistantMessage(
        'Compare mode is on. Add at least two products in the compare boxes above, or send them like "iPhone 13 vs Samsung A54".',
      );
      return;
    }

    _pendingField = null;
    _generateProductRecommendation();
  }

  Future<void> _generateProductRecommendation() async {
    setState(() {
      _isThinking = true;
    });

    final compareOptions = _currentCompareOptions();
    final productLabel = _productName.isEmpty
        ? compareOptions.join(' vs ')
        : _productName;
    final compareInstruction = compareOptions.length >= 2
        ? 'Compare these options: ${compareOptions.join(' | ')}. Mention each option by name, compare the pros and cons, and pick the best one for the user.'
        : '';

    final query =
        'Help me buy a product. Product type/name: $productLabel. '
        'Budget: $_budget. Market/location: $_location. '
        'Preferences/features: $_preferences. Latest user message: $_latestIntent. '
        '$compareInstruction Recommend the best product, include estimated current price range and where to buy or supplier/store options.';

    try {
      // Load user profile and product history for personalization
      final userProfile = await widget.profileRepository.load();
      final allHistory = await widget.historyRepository.list();

      // Extract relevant product decisions from history
      final productHistory = allHistory
          .where((item) => item.result.category == DecisionCategory.products)
          .map((item) => item.result)
          .toList();

      final request = DecisionRequest(
        query: query,
        manualCategory: DecisionCategory.products,
        compareOptions: compareOptions,
        budget: _budget,
        location: _location,
        preferences: 'Product: $productLabel. $_preferences',
        userProfile: userProfile,
        pastDecisions: productHistory
            .take(5)
            .toList(), // Use last 5 product decisions
      );

      final result = await widget.decisionEngine.decide(request);
      setState(() {
        _latestResult = result;
      });

      final response = StringBuffer()
        ..writeln('🛍 Top recommendation: ${result.bestChoice}')
        ..writeln()
        ..writeln(result.reasoning);

      if (result.pros.isNotEmpty) {
        response
          ..writeln()
          ..writeln('Price / supplier details:')
          ..writeln('- ${result.pros.join('\n- ')}');
      }

      final fallbackAlternatives = compareOptions
          .where(
            (option) =>
                !result.bestChoice.toLowerCase().contains(option.toLowerCase()),
          )
          .toList(growable: false);
      final displayAlternatives = result.alternatives.isNotEmpty
          ? result.alternatives
          : fallbackAlternatives;

      if (displayAlternatives.isNotEmpty) {
        response
          ..writeln()
          ..writeln('Other options:')
          ..writeln('- ${displayAlternatives.join('\n- ')}');
      }

      if (result.cons.isNotEmpty) {
        response
          ..writeln()
          ..writeln('Watch-outs:')
          ..writeln('- ${result.cons.join('\n- ')}');
      }

      _addAssistantMessage(response.toString().trim());

      try {
        await widget.profileRepository.save(
          UserProfile(
            budget: _budget,
            location: _location,
            preferences: _preferences,
            userStyle: userProfile.userStyle,
          ),
        );

        final historyItem = DecisionHistoryItem(
          id: '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(9999)}',
          createdAt: DateTime.now(),
          query: query,
          result: result,
        );
        await widget.historyRepository.add(historyItem);
      } catch (error) {
        debugPrint('Could not store product recommendation: $error');
      }
    } catch (error) {
      final text = error.toString().replaceFirst('Exception: ', '').trim();
      _addAssistantMessage(
        text.isEmpty
            ? 'I could not recommend a product right now. Please try again in a moment.'
            : 'I could not recommend a product right now.\n\nDetails: $text',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isThinking = false;
        });
      }
      _scrollToBottom();
    }
  }

  List<String> _currentCompareOptions() {
    return [
      _compareAController.text.trim(),
      _compareBController.text.trim(),
      _compareCController.text.trim(),
    ].where((item) => item.isNotEmpty).toList(growable: false);
  }

  void _addAssistantMessage(String text) {
    setState(() {
      _messages.add(_ChatMessage(byUser: false, text: text));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }
}

class _ProductControlsCard extends StatelessWidget {
  const _ProductControlsCard({
    required this.compareMode,
    required this.compareAController,
    required this.compareBController,
    required this.compareCController,
    required this.onCompareModeChanged,
  });

  final bool compareMode;
  final TextEditingController compareAController;
  final TextEditingController compareBController;
  final TextEditingController compareCController;
  final ValueChanged<bool>? onCompareModeChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Compare mode'),
              subtitle: const Text('Compare up to 3 products or models'),
              value: compareMode,
              onChanged: onCompareModeChanged,
            ),
            if (compareMode) ...[
              TextField(
                controller: compareAController,
                decoration: const InputDecoration(
                  labelText: 'Option A',
                  hintText: 'e.g. iPhone 13',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: compareBController,
                decoration: const InputDecoration(
                  labelText: 'Option B',
                  hintText: 'e.g. Samsung A54',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: compareCController,
                decoration: const InputDecoration(
                  labelText: 'Option C (optional)',
                  hintText: 'e.g. Pixel 8a',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductSummaryCard extends StatelessWidget {
  const _ProductSummaryCard({
    required this.productName,
    required this.budget,
    required this.location,
    required this.compareMode,
    required this.compareOptions,
  });

  final String productName;
  final String budget;
  final String location;
  final bool compareMode;
  final List<String> compareOptions;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product summary',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (productName.isNotEmpty) Text('Product: $productName'),
            if (budget.isNotEmpty) Text('Budget: $budget'),
            if (location.isNotEmpty) Text('Market: $location'),
            if (compareMode && compareOptions.isNotEmpty)
              Text('Comparing: ${compareOptions.join(' • ')}'),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.byUser, required this.text});

  final bool byUser;
  final String text;
}
