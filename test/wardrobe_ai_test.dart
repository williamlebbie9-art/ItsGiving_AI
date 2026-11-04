import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:its_giving_ai/features/glowup/wardrobe_ai_service.dart';

void main() {
  group('Wardrobe AI validation', () {
    test('accepts a valid outfit analysis result', () {
      final valid = {
        'aestheticMatchScore': 88,
        'fashionabilityScore': 84,
        'overallVerdict': 'This outfit fits your Old Money direction well.',
        'whatGetsRight': [
          'The silhouette is polished.',
          'The palette feels luxe.',
        ],
        'whatCouldImprove': ['Round out the outfit with a sharper accessory.'],
        'colourCoordination':
            'The neutral palette feels cohesive and intentional.',
        'silhouetteAndProportions':
            'The layering reads elegant and proportionate.',
        'layeringAndAccessories': 'The accessories support the refined mood.',
        'aestheticAlignment':
            'This strongly reflects your Old Money aesthetic.',
        'improvementSuggestions': [
          'Add a tailored layer.',
          'Switch to a sleeker bag.',
        ],
        'stylingAlternatives': ['Try a trench coat with loafers.'],
        'occasionSuggestions': ['Brunch', 'Dinner'],
      };

      expect(validateWardrobeReport(valid), isTrue);
    });

    test('rejects incomplete wardrobe analysis data', () {
      final invalid = {
        'aestheticMatchScore': 80,
        'overallVerdict': 'Looks strong.',
      };

      expect(validateWardrobeReport(invalid), isFalse);
    });
  });

  group('Aesthetic plan generation', () {
    test('builds an Old Money-specific personality plan context', () {
      final context = buildAestheticPlanContext(
        'Old Money',
        goal: 'Confidence',
        lifestyle: 'Busy student',
      );

      expect(context, contains('Old Money'));
      expect(context, contains('timeless elegance'));
      expect(context, contains('Busy student'));
    });
  });

  group('Wardrobe history parsing', () {
    test('reads valid saved reports from persisted wardrobe history', () {
      final archive = [
        jsonEncode({
          'overallVerdict': 'This look is polished.',
          'aestheticMatchScore': 90,
          'fashionabilityScore': 88,
          'whatGetsRight': 'The silhouette is strong.',
          'whatCouldImprove': 'Add one sharper accessory.',
          'colourCoordination': 'The palette is cohesive.',
          'silhouetteAndProportions': 'The proportions feel balanced.',
          'layeringAndAccessories': 'The layering is polished.',
          'aestheticAlignment': 'This fits your Clean Girl vibe.',
          'improvementSuggestions': ['Add a tailored layer.'],
          'stylingAlternatives': ['Swap to loafers.'],
          'occasionSuggestions': ['Dinner'],
          'createdAt': DateTime(2026, 11, 3).toIso8601String(),
        }),
      ];

      final parsed = parseWardrobeHistory(archive);

      expect(parsed, isNotEmpty);
      expect(parsed.first['overallVerdict'], 'This look is polished.');
      expect(parsed.first['aestheticMatchScore'], 90);
    });
  });
}
