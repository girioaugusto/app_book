import 'dart:convert';
import 'package:http/http.dart' as http;

/// Modelo de Café
class Cafe {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  Cafe({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class CafeService {
  /// Opção A (simples): cole SUA CHAVE aqui (sem "...")
  static const String _apiKeyInline = '26b85eee752043f583b66305d236db92';

  /// Opção B (melhor): via --dart-define=GEOAPIFY_KEY=xxxxx
  static const String _apiKeyFromEnv = String.fromEnvironment('26b85eee752043f583b66305d236db92');

  static String get _apiKey {
    if (_apiKeyFromEnv.isNotEmpty) return _apiKeyFromEnv;
    return _apiKeyInline;
  }

  /// Busca cafés próximos usando Geoapify Places API.
  /// Busca em raio definido (use 5000m para “garantir dados” e filtrar localmente)
  static Future<List<Cafe>> getCafesNearby({
    required double lat,
    required double lon,
    int radiusMeters = 5000,
    int limit = 80,
  }) async {
    if (_apiKey.isEmpty || _apiKey == 'P26b85eee752043f583b66305d236db92') {
      throw Exception(
        'Geoapify API key ausente. Cole sua chave em cafe_service.dart '
        'ou rode com --dart-define=GEOAPIFY_KEY=xxxxx',
      );
    }

    final uri = Uri.https(
      'api.geoapify.com',
      '/v2/places',
      {
        'categories': 'catering.cafe',
        'filter': 'circle:$lon,$lat,$radiusMeters',
        'bias': 'proximity:$lon,$lat',
        'limit': '$limit',
        'apiKey': _apiKey,
      },
    );

    final resp = await http.get(uri, headers: {
      'Accept': 'application/json',
      'User-Agent': 'livros_app/1.0 (cafes nearby)',
    });

    if (resp.statusCode != 200) {
      throw Exception('Geoapify error ${resp.statusCode}: ${resp.body}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final features = (data['features'] as List?) ?? const [];

    return features.map((f) {
      final props = (f['properties'] as Map?) ?? {};
      final name = (props['name'] as String?)?.trim() ?? 'Café';

      // Endereço formatado (quando disponível)
      final formatted = (props['formatted'] as String?)?.trim();

      // Campos para fallback, se formatted vier vazio
      final street = (props['street'] ?? '') as String;
      final housenumber = (props['housenumber'] ?? '') as String;
      final suburb = (props['suburb'] ?? '') as String;
      final city =
          (props['city'] ?? props['town'] ?? props['village'] ?? '') as String;

      final addr = formatted ??
          [
            if (street.isNotEmpty && housenumber.isNotEmpty)
              '$street, $housenumber'
            else if (street.isNotEmpty)
              street,
            if (suburb.isNotEmpty) suburb,
            if (city.isNotEmpty) city,
          ].where((e) => e.isNotEmpty).join(' • ');

      final geom = (f['geometry'] as Map?) ?? {};
      final coords = (geom['coordinates'] as List?) ?? [0.0, 0.0];
      final lonF = (coords[0] as num).toDouble();
      final latF = (coords[1] as num).toDouble();

      return Cafe(
        id: (props['place_id'] ?? '').toString(),
        name: name.isEmpty ? 'Café' : name,
        address: addr.isEmpty ? 'Endereço indisponível' : addr,
        latitude: latF,
        longitude: lonF,
      );
    }).toList();
  }
}
