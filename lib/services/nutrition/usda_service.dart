import 'dart:convert';

import 'package:http/http.dart' as http;

class UsdaFood {
  final String description;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double? fiberPer100g;
  final double? sodiumPer100mg;

  const UsdaFood({
    required this.description,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.fiberPer100g,
    this.sodiumPer100mg,
  });
}

class UsdaService {
  UsdaService({required String apiKey, http.Client? client})
      : _apiKey = apiKey,
        _client = client ?? http.Client();

  final String _apiKey;
  final http.Client _client;

  bool get isConfigured => _apiKey.isNotEmpty;

  Future<UsdaFood?> searchSingleFood(String query) async {
    if (!isConfigured) return null;
    final uri = Uri.parse(
      'https://api.nal.usda.gov/fdc/v1/foods/search'
      '?api_key=$_apiKey'
      '&pageSize=1'
      '&dataType=Foundation,SR%20Legacy'
      '&query=${Uri.encodeQueryComponent(query)}',
    );
    try {
      final res = await _client
          .get(uri)
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final foods = (body['foods'] as List?) ?? const [];
      if (foods.isEmpty) return null;
      final first = foods.first as Map<String, dynamic>;
      final desc = (first['description'] as String?) ?? query;
      final nutrients =
          (first['foodNutrients'] as List?)?.cast<Map<String, dynamic>>() ??
              const [];
      double? get(String name) {
        for (final n in nutrients) {
          final nm = (n['nutrientName'] as String?) ?? '';
          if (nm.toLowerCase().contains(name.toLowerCase())) {
            final v = n['value'];
            if (v is num) return v.toDouble();
          }
        }
        return null;
      }

      return UsdaFood(
        description: desc,
        caloriesPer100g: get('Energy') ?? 0,
        proteinPer100g: get('Protein') ?? 0,
        carbsPer100g: get('Carbohydrate') ?? 0,
        fatPer100g: get('Total lipid') ?? 0,
        fiberPer100g: get('Fiber'),
        sodiumPer100mg: get('Sodium'),
      );
    } catch (_) {
      return null;
    }
  }
}
