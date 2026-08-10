import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/decision_models.dart';

class AiClient {
  const AiClient();

  Future<DecisionResult> generate({
    required DecisionCategory category,
    required String prompt,
    required DecisionRequest request,
  }) async {
    final provider = (dotenv.env['AI_PROVIDER'] ?? 'mock').toLowerCase();

    try {
      if (provider == 'firebase') {
        return await _callFirebaseFunction(
          category: category,
          prompt: prompt,
          request: request,
        );
      }
      if (provider == 'openai') {
        return await _callOpenAi(
          category: category,
          prompt: prompt,
          request: request,
        );
      }
      if (provider == 'gemini') {
        return await _callGemini(
          category: category,
          prompt: prompt,
          request: request,
        );
      }
    } catch (_) {
      // Fallback below.
    }

    return _mock(category: category, request: request);
  }

  Future<DecisionResult> _callOpenAi({
    required DecisionCategory category,
    required String prompt,
    required DecisionRequest request,
  }) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY is missing');
    }

    final model = dotenv.env['OPENAI_MODEL'] ?? 'gpt-4o-mini';
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

    final userContent = await _buildOpenAiUserContent(
      prompt: prompt,
      imagePaths: request.imagePaths,
    );

    final response = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': model,
            'messages': [
              {'role': 'user', 'content': userContent},
            ],
            'response_format': {'type': 'json_object'},
            'temperature': 0.4,
          }),
        )
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw TimeoutException(
            'OpenAI request timed out',
            const Duration(seconds: 20),
          ),
        );

    if (response.statusCode < 200 || response.statusCode > 299) {
      throw Exception('OpenAI request failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>? ?? const [];
    final content = choices.isNotEmpty
        ? (choices.first as Map<String, dynamic>)['message']['content']
              .toString()
        : '{}';
    final parsed = jsonDecode(content) as Map<String, dynamic>;
    parsed['category'] = parsed['category'] ?? category.value;
    return DecisionResult.fromJson(parsed);
  }

  Future<DecisionResult> _callGemini({
    required DecisionCategory category,
    required String prompt,
    required DecisionRequest request,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is missing');
    }

    final model = dotenv.env['GEMINI_MODEL'] ?? 'gemini-1.5-flash';
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final parts = await _buildGeminiParts(
      prompt: prompt,
      imagePaths: request.imagePaths,
    );

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'generationConfig': {
              'temperature': 0.4,
              'responseMimeType': 'application/json',
            },
            'contents': [
              {'role': 'user', 'parts': parts},
            ],
          }),
        )
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw TimeoutException(
            'Gemini request timed out',
            const Duration(seconds: 20),
          ),
        );

    if (response.statusCode < 200 || response.statusCode > 299) {
      throw Exception('Gemini request failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>? ?? const [];
    final text = candidates.isNotEmpty
        ? ((((candidates.first as Map<String, dynamic>)['content']
                              as Map<String, dynamic>)['parts']
                          as List<dynamic>)
                      .first
                  as Map<String, dynamic>)['text']
              .toString()
        : '{}';
    final parsed = jsonDecode(_stripJsonFence(text)) as Map<String, dynamic>;
    parsed['category'] = parsed['category'] ?? category.value;
    return DecisionResult.fromJson(parsed);
  }

  Future<DecisionResult> _callFirebaseFunction({
    required DecisionCategory category,
    required String prompt,
    required DecisionRequest request,
  }) async {
    final defaultLocalUrl = Platform.isAndroid
        ? 'http://10.0.2.2:5001/decide-ai-89445/us-central1/generateDecision'
        : 'http://127.0.0.1:5001/decide-ai-89445/us-central1/generateDecision';

    final functionUrl =
        dotenv.env['FIREBASE_FUNCTIONS_URL']?.trim().isNotEmpty == true
        ? dotenv.env['FIREBASE_FUNCTIONS_URL']!.trim()
        : defaultLocalUrl;

    final images = await _buildImagePayloads(imagePaths: request.imagePaths);

    final response = await http
        .post(
          Uri.parse(functionUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'category': category.value,
            'prompt': prompt,
            'request': request.toJson(),
            'images': images,
          }),
        )
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw TimeoutException(
            'Firebase function request timed out',
            const Duration(seconds: 20),
          ),
        );

    if (response.statusCode < 200 || response.statusCode > 299) {
      throw Exception(
        'Firebase function request failed: ${response.statusCode}',
      );
    }

    final parsed = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    parsed['category'] = parsed['category'] ?? category.value;
    return DecisionResult.fromJson(parsed);
  }

  Future<List<Map<String, String>>> _buildImagePayloads({
    required List<String> imagePaths,
  }) async {
    final images = <Map<String, String>>[];

    for (final path in imagePaths.take(4)) {
      final bytes = await _readImage(path);
      if (bytes == null) {
        continue;
      }
      images.add({
        'mimeType': _mimeFromPath(path),
        'data': base64Encode(bytes),
      });
    }

    return images;
  }

  Future<dynamic> _buildOpenAiUserContent({
    required String prompt,
    required List<String> imagePaths,
  }) async {
    if (imagePaths.isEmpty) {
      return prompt;
    }

    final content = <Map<String, dynamic>>[
      {'type': 'text', 'text': prompt},
    ];

    for (final path in imagePaths.take(4)) {
      final bytes = await _readImage(path);
      if (bytes == null) {
        continue;
      }
      final base64Image = base64Encode(bytes);
      final mime = _mimeFromPath(path);
      content.add({
        'type': 'image_url',
        'image_url': {'url': 'data:$mime;base64,$base64Image'},
      });
    }
    return content;
  }

  Future<List<Map<String, dynamic>>> _buildGeminiParts({
    required String prompt,
    required List<String> imagePaths,
  }) async {
    final parts = <Map<String, dynamic>>[
      {'text': prompt},
    ];

    for (final path in imagePaths.take(4)) {
      final bytes = await _readImage(path);
      if (bytes == null) {
        continue;
      }
      parts.add({
        'inline_data': {
          'mime_type': _mimeFromPath(path),
          'data': base64Encode(bytes),
        },
      });
    }
    return parts;
  }

  Future<Uint8List?> _readImage(String path) async {
    try {
      return await File(path).readAsBytes();
    } catch (_) {
      return null;
    }
  }

  String _mimeFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  String _stripJsonFence(String raw) {
    final trimmed = raw.trim();
    if (!trimmed.startsWith('```')) {
      return trimmed;
    }

    final lines = trimmed.split('\n').toList();
    if (lines.isNotEmpty && lines.first.startsWith('```')) {
      lines.removeAt(0);
    }
    if (lines.isNotEmpty && lines.last.trim() == '```') {
      lines.removeLast();
    }
    return lines.join('\n').trim();
  }

  DecisionResult _mock({
    required DecisionCategory category,
    required DecisionRequest request,
  }) {
    if (category == DecisionCategory.glowup) {
      return DecisionResult(
        bestChoice: 'Consistent glow-up routine',
        alternatives: const [
          'Morning skincare + SPF',
          'Evening skincare routine',
          'Weekly self-care ritual',
        ],
        reasoning:
            'Your glow-up journey is about consistent, achievable habits. '
            'Focus on building a daily skincare routine with SPF, staying hydrated, '
            'getting quality sleep, and adding gentle movement. '
            'Small daily actions compound into visible results over time.',
        pros: const [
          'Build a consistent AM and PM skincare routine',
          'Drink 2L+ of water daily',
          'Aim for 7-8 hours of quality sleep',
          'Move your body 30 minutes daily',
          'Practice daily gratitude or journaling',
        ],
        cons: const [
          'Consistency takes time to build',
          'Results appear gradually over weeks',
        ],
        confidenceScore: '0.85',
        category: category,
      );
    }

    return DecisionResult(
      bestChoice: 'Balanced style recommendation',
      alternatives: const ['Classic look', 'Trend-forward look'],
      reasoning:
          'Based on your context, this is the strongest practical fit for your style goals.',
      pros: const ['Context-aware', 'Low-risk'],
      cons: const ['Generalized without deeper data'],
      confidenceScore: '0.78',
      category: category,
    );
  }
}
