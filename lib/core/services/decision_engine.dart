import '../models/decision_models.dart';
import 'ai_client.dart';
import 'category_router.dart';
import 'decision_prompts.dart';

class DecisionEngine {
  DecisionEngine({
    AiClient? client,
    CategoryRouter? router,
    DecisionPrompts? prompts,
  }) : _client = client ?? const AiClient(),
       _router = router ?? const CategoryRouter(),
       _prompts = prompts ?? const DecisionPrompts();

  final AiClient _client;
  final CategoryRouter _router;
  final DecisionPrompts _prompts;
  final Map<String, DecisionResult> _memoryCache = {};

  Future<DecisionResult> decide(DecisionRequest request) async {
    final category = request.manualCategory ?? _router.route(request.query);
    final normalized = request.toCacheKey();

    if (_memoryCache.containsKey(normalized)) {
      return _memoryCache[normalized]!;
    }

    final prompt = _prompts.build(category: category, request: request);

    final result = await _client.generate(
      category: category,
      prompt: prompt,
      request: request,
    );

    _memoryCache[normalized] = result;
    return result;
  }
}
