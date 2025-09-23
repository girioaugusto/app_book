// lib/services/cafes_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cafe.dart';

class CafesService {
  static Future<List<Cafe>> fetchNearby({
    required double lat,
    required double lng,
    int radiusMeters = 1500,
    int maxResults = 30,
  }) async {
    final query = '''
      [out:json][timeout:25];
      (
        node["amenity"="cafe"](around:$radiusMeters,$lat,$lng);
        node["shop"="coffee"](around:$radiusMeters,$lat,$lng);
      );
      out center $maxResults;
    ''';

    final url = Uri.parse('https://overpass-api.de/api/interpreter');
    final res = await http.post(url, body: {'data': query});
    if (res.statusCode != 200) {
      throw Exception('Erro Overpass: ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final elements = (data['elements'] as List?) ?? [];

    final cafes = <Cafe>[];
    for (final e in elements) {
      final tags = (e['tags'] as Map?) ?? {};
      final name = (tags['name'] ?? '').toString();
      if (name.isEmpty) continue;

      final latNode = (e['lat'] as num?)?.toDouble();
      final lonNode = (e['lon'] as num?)?.toDouble();
      if (latNode == null || lonNode == null) continue;

      cafes.add(Cafe(
        name: name,
        lat: latNode,
        lng: lonNode,
        address: (tags['addr:street'] != null)
            ? '${tags['addr:street']}${tags['addr:housenumber'] != null ? ', ${tags['addr:housenumber']}' : ''}'
            : null,
      ));
    }
    return cafes;
  }
}
