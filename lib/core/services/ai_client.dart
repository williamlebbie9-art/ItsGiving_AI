import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/decision_models.dart';

class AiClient {
  const AiClient();

  static const _provider = String.fromEnvironment(
    'AI_PROVIDER',
    defaultValue: 'firebase',
  );
  static const _decisionFunctionUrl = String.fromEnvironment(
    'FIREBASE_FUNCTIONS_URL',
    defaultValue:
        'https://us-central1-decide-ai-89445.cloudfunctions.net/generateDecision',
  );
  static const _imageFunctionUrl = String.fromEnvironment(
    'FIREBASE_IMAGE_FUNCTIONS_URL',
    defaultValue:
        'https://us-central1-decide-ai-89445.cloudfunctions.net/generateGlowUpImage',
  );

  Future<DecisionResult> generate({
    required DecisionCategory category,
    required String prompt,
    required DecisionRequest request,
  }) async {
    final provider = _provider.toLowerCase();

    // AI request started
    // ignore: avoid_print
    print(
      '[AI] AI request started. provider=$provider category=${category.value}',
    );

    if (provider == 'firebase') {
      return await _callFirebaseFunction(
        category: category,
        prompt: prompt,
        request: request,
      );
    }

    // Provider API keys must never be distributed inside a mobile app.
    throw StateError(
      'AI_PROVIDER must be firebase. Current value: '
      '"${provider.isEmpty ? '(empty)' : provider}".',
    );
  }

  /// Requests the dedicated plan schema. Unlike coach/scan responses this
  /// preserves the full plan object instead of forcing it into DecisionResult.
  Future<Map<String, dynamic>> generatePlan({required String prompt}) async {
    final provider = _provider.toLowerCase();
    if (provider != 'firebase') {
      throw StateError('AI_PROVIDER must be firebase for plan generation.');
    }

    final functionUrl = _decisionFunctionUrl;

    final idToken = await _getIdToken();

    final response = await http
        .post(
          Uri.parse(functionUrl),
          headers: {
            'Content-Type': 'application/json',
            if (idToken != null) 'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({'prompt': prompt, 'operation': 'plan'}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode > 299) {
      throw Exception('Plan request failed: ${response.statusCode}');
    }
    final payload = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    final plan = payload['plan'];
    if (plan is! Map) {
      throw const FormatException('Plan response is missing a plan object.');
    }
    return Map<String, dynamic>.from(plan);
  }

  Future<DecisionResult> _callFirebaseFunction({
    required DecisionCategory category,
    required String prompt,
    required DecisionRequest request,
  }) async {
    final functionUrl = _decisionFunctionUrl;

    final images = await _buildImagePayloads(imagePaths: request.imagePaths);

    // Attach the Firebase ID token for backend auth validation.
    final idToken = await _getIdToken();

    // Function received request
    // ignore: avoid_print
    print(
      '[AI] Function received request. url=$functionUrl images=${images.length}',
    );

    final response = await http
        .post(
          Uri.parse(functionUrl),
          headers: {
            'Content-Type': 'application/json',
            if (idToken != null) 'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'category': category.value,
            'prompt': prompt,
            'request': request.toJson(),
            'images': images,
            'operation': request.operation,
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
      // ignore: avoid_print
      print('[AI] OpenAI/Firebase request failed: ${response.statusCode}');
      throw Exception(
        'Firebase function request failed: ${response.statusCode}',
      );
    }

    // ignore: avoid_print
    print('[AI] OpenAI response received. status=${response.statusCode}');

    final parsed = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    parsed['category'] = parsed['category'] ?? category.value;
    return DecisionResult.fromJson(parsed);
  }

  /// Calls the deployed `generateGlowUpImage` Firebase function which uses
  /// OpenAI's gpt-image-1 image-editing model with the user's photo as the
  /// identity reference. Returns the generated image as base64 PNG bytes.
  Future<Uint8List> generateGlowUpImage({
    required String imagePath,
    required String styleId,
    String? faceScanSummary,
  }) async {
    final functionUrl = _imageFunctionUrl;

    final bytes = await _readImage(imagePath);
    if (bytes == null) {
      throw Exception('Could not read image at $imagePath');
    }

    // Attach the Firebase ID token for backend auth validation.
    final idToken = await _getIdToken();

    // ignore: avoid_print
    print('[AI] Image generation request started. style=$styleId');

    final response = await http
        .post(
          Uri.parse(functionUrl),
          headers: {
            'Content-Type': 'application/json',
            if (idToken != null) 'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'image': {
              'mimeType': _mimeFromPath(imagePath),
              'data': base64Encode(bytes),
            },
            'styleId': styleId,
            'faceScanSummary': faceScanSummary,
          }),
        )
        .timeout(
          const Duration(seconds: 120),
          onTimeout: () => throw TimeoutException(
            'Image generation timed out',
            const Duration(seconds: 120),
          ),
        );

    if (response.statusCode < 200 || response.statusCode > 299) {
      // ignore: avoid_print
      print('[AI] Image generation failed: ${response.statusCode}');
      throw Exception('Image generation failed: ${response.statusCode}');
    }

    final parsed = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    final b64 = parsed['image'] as String?;
    if (b64 == null || b64.isEmpty) {
      throw Exception('Image generation response missing image data.');
    }

    // ignore: avoid_print
    print('[AI] Image generation response received. bytes=${b64.length}');

    return base64Decode(b64);
  }

  /// Gets the current Firebase ID token for backend auth validation.
  Future<String?> _getIdToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return await user.getIdToken();
    } catch (_) {
      return null;
    }
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

}
