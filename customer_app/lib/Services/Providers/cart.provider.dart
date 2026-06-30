/// CartProvider — local in-memory cart state.
///
/// Cart is kept purely local (no backend calls) until checkout.
/// On "Place Order" the caller serializes items and calls [OrdersService.createOrder].
import 'package:flutter/material.dart';

class CartItem {
  final String productId;
  final String name;
  final String unit;
  final double price;
  int qty;

  CartItem({
    required this.productId,
    required this.name,
    required this.unit,
    required this.price,
    required this.qty,
  });

  double get lineTotal => price * qty;

  Map<String, dynamic> toOrderItem() => {
        'productId': productId,
        'qty': qty,
      };
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.values.fold(0, (s, i) => s + i.qty);

  double get subtotal =>
      _items.values.fold(0.0, (s, i) => s + i.lineTotal);
  double get deliveryFee => subtotal > 1500 ? 0 : 50;
  double get total => subtotal + deliveryFee;

  void addItem({
    required String productId,
    required String name,
    required String unit,
    required double price,
  }) {
    if (_items.containsKey(productId)) {
      _items[productId]!.qty++;
    } else {
      _items[productId] = CartItem(
        productId: productId,
        name: name,
        unit: unit,
        price: price,
        qty: 1,
      );
    }
    notifyListeners();
  }

  void setQty(String productId, int qty) {
    if (qty <= 0) {
      _items.remove(productId);
    } else if (_items.containsKey(productId)) {
      _items[productId]!.qty = qty;
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  int qtyFor(String productId) => _items[productId]?.qty ?? 0;

  List<Map<String, dynamic>> toOrderItems() =>
      _items.values.map((i) => i.toOrderItem()).toList();
}
