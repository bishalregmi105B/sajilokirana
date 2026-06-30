/// CatalogProvider — fetches products + categories from the backend.
///
/// Exposes loading, error, and data states to UI. Caches the last successful
/// response so the UI never shows a blank screen on reconnect.
import 'package:flutter/material.dart';
import 'package:ecom/services/catalog_service.dart';

class CatalogProduct {
  final String id;
  final String name;
  final String category;
  final String unit;
  final double? minPrice;
  final bool inStock;

  const CatalogProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    this.minPrice,
    required this.inStock,
  });

  factory CatalogProduct.fromJson(Map<String, dynamic> j) => CatalogProduct(
        id: j['id'] as String,
        name: j['name'] as String,
        category: j['category'] as String,
        unit: j['unit'] as String,
        minPrice: (j['minPrice'] as num?)?.toDouble(),
        inStock: j['inStock'] as bool? ?? false,
      );
}

class CatalogProvider extends ChangeNotifier {
  final _service = CatalogService.instance;

  List<CatalogProduct> _products = [];
  List<String> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<CatalogProduct> get products => _products;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<CatalogProduct> byCategory(String cat) =>
      _products.where((p) => p.category == cat).toList();

  Future<void> load({String? category, String? q}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.fetchProducts(category: category, q: q),
        if (_categories.isEmpty) _service.fetchCategories(),
      ]);
      _products = (results[0] as List<Map<String, dynamic>>)
          .map(CatalogProduct.fromJson)
          .toList();
      if (_categories.isEmpty && results.length > 1) {
        _categories = results[1] as List<String>;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> search(String q) => load(q: q);
  Future<void> filterByCategory(String cat) => load(category: cat);
  Future<void> refresh() => load();
}
