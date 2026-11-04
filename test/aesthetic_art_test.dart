import 'package:flutter_test/flutter_test.dart';

import 'package:its_giving_ai/features/glowup/aesthetic_art.dart';
import 'package:its_giving_ai/features/glowup/glow_models.dart';

void main() {
  group('Aesthetic art system', () {
    test('returns art data for every supported vibe', () {
      final names = vibes.map((vibe) => vibe.name).toList();

      for (final name in names) {
        final art = aestheticArtFor(name);
        expect(art.name, name);
        expect(art.palette.primary, isNotNull);
        expect(art.palette.secondary, isNotNull);
      }
    });
  });
}
