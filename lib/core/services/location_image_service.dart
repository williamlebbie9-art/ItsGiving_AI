import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class LocationImage {
  const LocationImage({
    required this.url,
    required this.thumbnail,
    required this.attribution,
  });

  final String url;
  final String thumbnail;
  final String attribution;
}

class LocationImageService {
  LocationImageService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Fetches images for a destination using Pixabay API
  /// Falls back to Wikipedia Commons API if Pixabay is unavailable
  /// Falls back to a default if both are unavailable
  Future<List<LocationImage>> fetchDestinationImages(
    String destination, {
    int count = 3,
  }) async {
    try {
      final pixabayKey = dotenv.env['PIXABAY_API_KEY'];
      if (pixabayKey != null && pixabayKey.isNotEmpty) {
        return await _fetchFromPixabay(destination, pixabayKey, count);
      }
    } catch (e) {
      // Fallback to next option
    }

    try {
      return await _fetchFromWikimedia(destination, count);
    } catch (e) {
      // Fallback to generic images
    }

    return _getDefaultImages(destination);
  }

  Future<List<LocationImage>> _fetchFromPixabay(
    String destination,
    String apiKey,
    int count,
  ) async {
    final query = Uri.encodeComponent(destination);
    final url = Uri.parse(
      'https://pixabay.com/api/?key=$apiKey&q=$query&image_type=photo&per_page=$count',
    );

    final response = await _client.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final hits = json['hits'] as List<dynamic>? ?? [];

      return [
        for (final hit in hits)
          LocationImage(
            url: hit['largeImageURL'] as String? ?? '',
            thumbnail: hit['previewURL'] as String? ?? '',
            attribution: 'Photo from Pixabay',
          ),
      ];
    }

    throw Exception('Failed to fetch from Pixabay');
  }

  Future<List<LocationImage>> _fetchFromWikimedia(
    String destination,
    int count,
  ) async {
    final query = Uri.encodeComponent(destination);
    final url = Uri.parse(
      'https://commons.wikimedia.org/w/api.php?'
      'action=query&list=allimages&aisort=timestamp&aidir=descending&'
      'aifrom=$query&AI_prefix=$query&ailimit=$count&format=json',
    );

    final response = await _client.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final query = json['query'] as Map<String, dynamic>? ?? {};
      final allimages = query['allimages'] as List<dynamic>? ?? [];

      final images = <LocationImage>[];
      for (final img in allimages) {
        final title = img['name'] as String? ?? '';
        final url =
            'https://commons.wikimedia.org/wiki/Special:FilePath/$title';
        images.add(
          LocationImage(
            url: url,
            thumbnail: url,
            attribution: 'Wikimedia Commons',
          ),
        );
      }

      return images;
    }

    throw Exception('Failed to fetch from Wikimedia');
  }

  List<LocationImage> _getDefaultImages(String destination) {
    // Fallback to generic travel images with proper attribution
    return [
      LocationImage(
        url:
            'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800&q=80',
        thumbnail:
            'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=200&q=80',
        attribution: 'Photo from Unsplash',
      ),
      LocationImage(
        url:
            'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800&q=80',
        thumbnail:
            'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=200&q=80',
        attribution: 'Photo from Unsplash',
      ),
      LocationImage(
        url:
            'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',
        thumbnail:
            'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=200&q=80',
        attribution: 'Photo from Unsplash',
      ),
    ];
  }
}
