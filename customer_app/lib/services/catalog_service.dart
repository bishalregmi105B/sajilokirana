import 'package:ecom/services/api_client.dart';

class CatalogService {
  CatalogService._();
  static final CatalogService instance = CatalogService._();

  final _client = ApiClient.instance;

  /// Fetch all products (with optional category or search query filter).
  Future<List<Map<String, dynamic>>> fetchProducts({
    String? category,
    String? q,
    int limit = 100,
  }) async {
    final data = await _client.get('/catalog', query: {
      if (category != null) 'category': category,
      if (q != null && q.isNotEmpty) 'q': q,
      'limit': limit,
    });
    return (data as List).cast<Map<String, dynamic>>();
  }

  /// Fetch distinct category names.
  Future<List<String>> fetchCategories() async {
    final data = await _client.get('/catalog/categories');
    return (data as List).cast<String>();
  }

  /// Fetch nearby shops given lat/lng.
  Future<List<Map<String, dynamic>>> fetchNearbyShops({
    required double lat,
    required double lng,
    double radiusKm = 5,
    String? category,
  }) async {
    final data = await _client.get('/shops/nearby', query: {
      'lat': lat,
      'lng': lng,
      'radius': radiusKm,
      if (category != null) 'category': category,
    });
    return (data as List).cast<Map<String, dynamic>>();
  }
}
