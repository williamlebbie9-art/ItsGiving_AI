import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/decision_models.dart';
import '../../core/services/decision_engine.dart';
import 'glow_models.dart';

class CoachMessage {
  const CoachMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({this.initialQuestion, super.key});

  final String? initialQuestion;

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _engine = DecisionEngine();
  late final List<CoachMessage> _messages;
  bool _isTyping = false;

  GlowUserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _messages = [
      CoachMessage(
        text:
            'Hey bestie ✨ I\'m your AI glow-up coach. Ask me about skincare, hair, outfits, habits, workouts, sleep, or confidence — I\'ll personalize it to your goals.',
        isUser: false,
      ),
    ];
    _loadProfile();
    if (widget.initialQuestion != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.text = widget.initialQuestion!;
        _send();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('glowup_profile');
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = <String, String>{};
        final entries = raw.replaceAll('{', '').replaceAll('}', '').split(', ');
        for (final entry in entries) {
          final parts = entry.split(': ');
          if (parts.length == 2) {
            map[parts[0]] = parts[1];
          }
        }
        _profile = GlowUserProfile.fromJson(map);
      } catch (_) {
        _profile = null;
      }
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isTyping) return;

    setState(() {
      _messages.add(CoachMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final profileContext = _profile != null
          ? 'User context: Goal=${_profile!.goal ?? 'Not set'}, '
                'Skin type=${_profile!.skinType ?? 'Not set'}, '
                'Exercise=${_profile!.exerciseFrequency ?? 'Not set'}, '
                'Sleep=${_profile!.sleepSchedule ?? 'Not set'}, '
                'Vibe=${_profile!.aesthetic ?? 'Not set'}, '
                'Lifestyle=${_profile!.lifestyle ?? 'Not set'}. '
          : '';

      final result = await _engine.decide(
        DecisionRequest(
          query:
              'You are a warm, encouraging beauty and wellness coach. '
              '$profileContext '
              'Answer this question from the user in a supportive tone: "$text" '
              'Keep it practical, kind, and focused on achievable glow-up improvements. '
              'Never mention prices, products to buy, or Product A vs Product B comparisons. '
              '2-4 short paragraphs max.',
          manualCategory: DecisionCategory.glowup,
        ),
      );

      if (!mounted) return;
      final reply = result.reasoning.isNotEmpty
          ? result.reasoning
          : 'Here\'s what I\'d suggest: ${result.bestChoice}. '
                '${result.pros.join(' ')}';
      setState(() {
        _messages.add(CoachMessage(text: reply, isUser: false));
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          CoachMessage(
            text:
                'Here\'s a quick glow-up tip: Start with the gentlest high-impact step — SPF every morning, '
                'hydration, protein, consistent sleep, and one confidence rep today. Want a more personalized routine? '
                'Share a bit more about your goals and I\'ll tailor it! ✨',
            isUser: false,
          ),
        );
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Glow-Up Coach'), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (_, index) {
                if (index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Coach is typing...'),
                      ],
                    ),
                  );
                }
                return ChatBubble(message: _messages[index]);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ask your glow coach...',
                        filled: true,
                        fillColor: const Color(0xFFFFF3FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({required this.message, super.key});

  final CoachMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: message.isUser
              ? const LinearGradient(
                  colors: [Color(0xFFFF70B8), Color(0xFFB69CFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: message.isUser ? null : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: message.isUser ? null : Border.all(color: Colors.grey[200]!),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : const Color(0xFF251B2F),
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
