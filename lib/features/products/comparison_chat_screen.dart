import 'package:flutter/material.dart';

import '../../core/models/decision_models.dart';
import '../../core/services/decision_engine.dart';

class ComparisonChatScreen extends StatefulWidget {
  const ComparisonChatScreen({
    required this.comparison,
    required this.decisionEngine,
    super.key,
  });

  final ProductComparison comparison;
  final DecisionEngine decisionEngine;

  @override
  State<ComparisonChatScreen> createState() => _ComparisonChatScreenState();
}

class _ComparisonChatScreenState extends State<ComparisonChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatMessage>[];
  bool _isThinking = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      const _ChatMessage(
        byUser: false,
        text:
            'I can help answer your questions about this comparison. Ask me anything about these products!',
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.comparison.productAName} vs ${widget.comparison.productBName}',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _ChatBubble(
                    byUser: message.byUser,
                    text: message.text,
                  );
                },
              ),
            ),
            if (_isThinking)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 32,
                    width: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !_isThinking,
                      decoration: InputDecoration(
                        hintText: 'Ask about this comparison...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _isThinking ? null : (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    child: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _isThinking ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    setState(() {
      _messages.add(_ChatMessage(byUser: true, text: message));
      _isThinking = true;
    });

    _scrollToBottom();

    try {
      // Create a context-aware query combining the original question with comparison info
      final query =
          'User asked about these two products (${widget.comparison.productAName} vs ${widget.comparison.productBName}): $message\n\n'
          'Product A advantages: ${widget.comparison.advantagesA}\n'
          'Product B advantages: ${widget.comparison.advantagesB}\n\n'
          'Please answer the user question based on this comparison.';

      final request = DecisionRequest(
        query: query,
        manualCategory: DecisionCategory.products,
        plainResponse: true,
      );

      final result = await widget.decisionEngine.decide(request);

      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(byUser: false, text: result.reasoning));
          _isThinking = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            _ChatMessage(
              byUser: false,
              text: 'Sorry, I encountered an error. Please try again.',
            ),
          );
          _isThinking = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
}

class _ChatMessage {
  final bool byUser;
  final String text;

  const _ChatMessage({required this.byUser, required this.text});
}

class _ChatBubble extends StatelessWidget {
  final bool byUser;
  final String text;

  const _ChatBubble({required this.byUser, required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: byUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: byUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: byUser
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Embeddable chat widget version of the comparison chat screen.
class ComparisonChatWidget extends StatefulWidget {
  const ComparisonChatWidget({
    required this.comparison,
    required this.decisionEngine,
    this.onMessageSent,
    super.key,
  });

  final ProductComparison comparison;
  final DecisionEngine decisionEngine;
  final VoidCallback? onMessageSent;

  @override
  State<ComparisonChatWidget> createState() => _ComparisonChatWidgetState();
}

class _ComparisonChatWidgetState extends State<ComparisonChatWidget> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatMessage>[];
  bool _isThinking = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      const _ChatMessage(
        byUser: false,
        text:
            'I can help answer your questions about this comparison. Ask me anything about these products!',
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _ChatBubble(
                    byUser: message.byUser,
                    text: message.text,
                  );
                },
              ),
            ),
            if (_isThinking)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !_isThinking,
                      decoration: InputDecoration(
                        hintText: 'Ask about this comparison...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _isThinking ? null : (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    child: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _isThinking ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    setState(() {
      _messages.add(_ChatMessage(byUser: true, text: message));
      _isThinking = true;
    });

    _scrollToBottom();

    try {
      final query =
          'User asked about these two products (${widget.comparison.productAName} vs ${widget.comparison.productBName}): $message\n\n'
          'Product A advantages: ${widget.comparison.advantagesA}\n'
          'Product B advantages: ${widget.comparison.advantagesB}\n\n'
          'Please answer the user question based on this comparison.';

      final request = DecisionRequest(
        query: query,
        manualCategory: DecisionCategory.products,
        plainResponse: true,
      );

      final result = await widget.decisionEngine.decide(request);

      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(byUser: false, text: result.reasoning));
          _isThinking = false;
        });
        _scrollToBottom();

        // Notify parent that a message was handled so it can collapse the chat.
        widget.onMessageSent?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            _ChatMessage(
              byUser: false,
              text: 'Sorry, I encountered an error. Please try again.',
            ),
          );
          _isThinking = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
}
