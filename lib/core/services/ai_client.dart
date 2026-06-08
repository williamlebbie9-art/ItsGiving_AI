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

    final response = await http.post(
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

    final response = await http.post(
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

    final response = await http.post(
      Uri.parse(functionUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'category': category.value,
        'prompt': prompt,
        'request': request.toJson(),
        'images': images,
      }),
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
    if (category == DecisionCategory.food) {
      final best = request.compareOptions.isNotEmpty
          ? request.compareOptions.first
          : _foodBestChoice(request);
      return DecisionResult(
        bestChoice: best,
        alternatives: _foodAlternatives(request),
        reasoning: _foodReasoning(request, best),
        pros: _foodPros(request),
        cons: _foodCons(request),
        confidenceScore: request.compareOptions.isNotEmpty ? '0.79' : '0.75',
        category: category,
      );
    }

    if (category == DecisionCategory.travel) {
      final best = request.compareOptions.isNotEmpty
          ? request.compareOptions.first
          : _travelBestChoice(request);
      return DecisionResult(
        bestChoice: best,
        alternatives: _travelAlternatives(request),
        reasoning: _travelReasoning(request, best),
        pros: _travelPros(request),
        cons: _travelCons(request),
        confidenceScore: request.compareOptions.isNotEmpty ? '0.78' : '0.74',
        category: category,
      );
    }

    if (category == DecisionCategory.fashion) {
      final best = request.compareOptions.isNotEmpty
          ? request.compareOptions.first
          : 'Smart-casual layered outfit';
      return DecisionResult(
        bestChoice: best,
        alternatives: const [
          'Monochrome minimal outfit',
          'Relaxed streetwear look',
        ],
        reasoning:
            'This option balances style and practicality for your context while keeping the silhouette clean and modern.',
        pros: const [
          'Versatile',
          'Photographs well',
          'Comfortable for long wear',
        ],
        cons: const [
          'Needs matching shoes',
          'May require layering if weather shifts',
        ],
        confidenceScore: '0.83',
        category: category,
      );
    }

    if (category == DecisionCategory.products) {
      final best = request.compareOptions.isNotEmpty
          ? request.compareOptions.first
          : _productBestChoice(request);
      return DecisionResult(
        bestChoice: best,
        alternatives: _productAlternatives(request),
        reasoning: _productReasoning(request, best),
        pros: _productPros(request, best),
        cons: _productCons(request),
        confidenceScore: request.compareOptions.isNotEmpty ? '0.84' : '0.81',
        category: category,
      );
    }

    return DecisionResult(
      bestChoice: 'Balanced recommendation for ${category.title}',
      alternatives: const ['Safer option', 'Higher-reward option'],
      reasoning: 'Based on your context, this is the strongest practical fit.',
      pros: const ['Context-aware', 'Low-risk'],
      cons: const ['Generalized without deeper data'],
      confidenceScore: '0.72',
      category: category,
    );
  }

  String _foodBestChoice(DecisionRequest request) {
    final budget = (request.budget ?? '').toLowerCase();
    final occasion = (request.occasion ?? '').toLowerCase();

    if (occasion.contains('date')) {
      return 'Cozy bistro with romantic ambiance and reservation support';
    }
    if (budget.contains('low') ||
        budget.contains('cheap') ||
        budget.contains('under')) {
      return 'Highly rated local casual spot with strong value meals';
    }
    return 'Balanced mid-range restaurant with quality consistency';
  }

  List<String> _foodAlternatives(DecisionRequest request) {
    if (request.compareOptions.isNotEmpty) {
      return request.compareOptions.skip(1).toList(growable: false);
    }
    return const [
      'Quick-serve option with best speed',
      'Premium dining option for special occasions',
    ];
  }

  String _foodReasoning(DecisionRequest request, String best) {
    return 'Picked "$best" because it balances budget fit, location convenience, and the occasion context. '
        'It also provides the best quality-to-price confidence among likely nearby options.';
  }

  List<String> _foodPros(DecisionRequest request) {
    final withLocation = (request.location ?? '').trim().isNotEmpty;
    return [
      'Strong budget-to-quality balance',
      if (withLocation) 'Aligned with your stated area',
      'Suitable vibe for the occasion',
    ];
  }

  List<String> _foodCons(DecisionRequest request) {
    return const [
      'Menu quality may vary by time/day',
      'Wait times can change at peak hours',
    ];
  }

  String _travelBestChoice(DecisionRequest request) {
    final budget = (request.budget ?? '').toLowerCase();
    final query = request.query.toLowerCase();
    if (budget.contains('500') ||
        budget.contains('low') ||
        budget.contains('budget')) {
      return 'Short-haul city break with strong value flights and transit';
    }
    if (query.contains('adventure')) {
      return 'Nature-forward destination with compact multi-activity itinerary';
    }
    return 'Balanced destination with good weather window and manageable logistics';
  }

  List<String> _travelAlternatives(DecisionRequest request) {
    if (request.compareOptions.isNotEmpty) {
      return request.compareOptions.skip(1).toList(growable: false);
    }
    return const [
      'Budget-first destination with fewer premium experiences',
      'Premium destination with higher comfort and cost',
    ];
  }

  String _travelReasoning(DecisionRequest request, String best) {
    return 'Picked "$best" for the best mix of budget realism, trip-time efficiency, and experience fit. '
        'Estimated spend allocation should prioritize transport and lodging first, then activities.';
  }

  List<String> _travelPros(DecisionRequest request) {
    return const [
      'Practical for common budget ranges',
      'High experience value per day',
      'Lower planning friction',
    ];
  }

  List<String> _travelCons(DecisionRequest request) {
    return const [
      'Exact pricing depends on booking window',
      'Weather seasonality can shift itinerary quality',
    ];
  }

  String _productBestChoice(DecisionRequest request) {
    final query = request.query.toLowerCase();
    final budget = (request.budget ?? '').toLowerCase();

    if (query.contains('phone') || query.contains('smartphone')) {
      if (budget.contains('300') || budget.contains('under')) {
        return 'Samsung Galaxy A15 5G';
      }
      return 'Google Pixel 8a';
    }

    if (query.contains('laptop')) {
      return 'Acer Aspire 5';
    }

    if (query.contains('headphone') || query.contains('earbud')) {
      return 'Soundcore Liberty 4 NC';
    }

    return 'Best value option in your budget';
  }

  List<String> _productAlternatives(DecisionRequest request) {
    if (request.compareOptions.isNotEmpty) {
      final priceHint = _productPriceHint(request);
      final storeHint = _productStoreHint(request);
      return request.compareOptions
          .skip(1)
          .map((option) {
            return '$option • $priceHint • $storeHint';
          })
          .toList(growable: false);
    }

    final query = request.query.toLowerCase();
    if (query.contains('phone') || query.contains('smartphone')) {
      return const ['Moto G Power (2024)', 'Nokia G42 5G'];
    }
    if (query.contains('laptop')) {
      return const ['Lenovo IdeaPad Slim 3', 'HP 15 Ryzen Edition'];
    }
    if (query.contains('headphone') || query.contains('earbud')) {
      return const ['JBL Tune Beam', 'Sony WH-CH720N'];
    }
    return const ['Budget-first alternative', 'Premium long-term alternative'];
  }

  String _productPriceHint(DecisionRequest request) {
    final query = request.query.toLowerCase();
    return query.contains('phone') || query.contains('smartphone')
        ? 'Estimated price: about \$180-\$220 for budget picks, or around \$450-\$520 for premium value picks'
        : query.contains('laptop')
        ? 'Estimated price: about \$450-\$700 depending on RAM and storage'
        : query.contains('headphone') || query.contains('earbud')
        ? 'Estimated price: about \$70-\$150 depending on model and discounts'
        : 'Estimated price: check current offers in your budget range for the best deal';
  }

  String _productStoreHint(DecisionRequest request) {
    final location = (request.location ?? '').toLowerCase();
    return location.contains('lagos') ||
            location.contains('nigeria') ||
            location.contains('abuja')
        ? 'Where to buy: Jumia, Konga, Slot, or trusted local phone/computer stores'
        : location.contains('uk') ||
              location.contains('london') ||
              location.contains('manchester')
        ? 'Where to buy: Amazon UK, Argos, Currys, or the brand store'
        : 'Where to buy: Amazon, Best Buy, Walmart Marketplace, or the brand store';
  }

  String _productReasoning(DecisionRequest request, String best) {
    final location = (request.location ?? '').trim();
    final compareText = request.compareOptions.length >= 2
        ? ' It edges out the other compare options on value, availability, and long-term ownership cost.'
        : '';
    final market = location.isEmpty ? 'your market' : location;

    return 'Picked "$best" because it offers a strong balance of price, reliability, and everyday performance in $market.$compareText '
        'I also prioritized products that are usually easy to find from reputable suppliers.';
  }

  List<String> _productPros(DecisionRequest request, String best) {
    final location = (request.location ?? '').toLowerCase();
    final query = request.query.toLowerCase();
    final storeHint =
        location.contains('lagos') ||
            location.contains('nigeria') ||
            location.contains('abuja')
        ? 'Where to buy: Jumia, Konga, Slot, or trusted local phone/computer stores'
        : location.contains('uk') ||
              location.contains('london') ||
              location.contains('manchester')
        ? 'Where to buy: Amazon UK, Argos, Currys, or the brand store'
        : 'Where to buy: Amazon, Best Buy, Walmart Marketplace, or the brand store';

    final priceHint = query.contains('phone') || query.contains('smartphone')
        ? 'Estimated price: about \$180-\$220 for budget picks, or around \$450-\$520 for premium value picks'
        : query.contains('laptop')
        ? 'Estimated price: about \$450-\$700 depending on RAM and storage'
        : query.contains('headphone') || query.contains('earbud')
        ? 'Estimated price: about \$70-\$150 depending on model and discounts'
        : 'Estimated price: check current offers in your budget range for the best deal';

    return [
      priceHint,
      storeHint,
      'Best for: buyers who want dependable value without overspending on extras',
    ];
  }

  List<String> _productCons(DecisionRequest request) {
    return const [
      'Prices can shift quickly across stores and regions',
      'Local warranty and return policies may differ by supplier',
    ];
  }
}
