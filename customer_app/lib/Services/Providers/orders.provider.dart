/// OrdersProvider — manages the customer's order list and order detail state.
import 'package:flutter/material.dart';
import 'package:ecom/services/orders_service.dart';

class AppOrder {
  final String id;
  final String status;
  final double totalAmount;
  final List<dynamic> items;
  final String createdAt;
  final int? etaSeconds;

  const AppOrder({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.items,
    required this.createdAt,
    this.etaSeconds,
  });

  factory AppOrder.fromJson(Map<String, dynamic> j) => AppOrder(
        id: j['id'] as String,
        status: j['status'] as String? ?? 'pending',
        totalAmount: (j['totalAmount'] as num?)?.toDouble() ?? 0,
        items: j['items'] as List? ?? [],
        createdAt: j['createdAt'] as String? ?? '',
        etaSeconds: j['etaSeconds'] as int?,
      );

  String get itemSummary {
    if (items.isEmpty) return 'Order';
    final first = (items.first as Map)['product']?['name'] as String? ?? 'Item';
    return items.length > 1 ? '$first + ${items.length - 1} more' : first;
  }
}

class OrdersProvider extends ChangeNotifier {
  final _service = OrdersService.instance;

  List<AppOrder> _orders = [];
  bool _isLoading = false;
  String? _error;

  // For order creation flow
  AppOrder? _lastCreated;

  List<AppOrder> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AppOrder? get lastCreated => _lastCreated;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.fetchOrders();
      _orders = data.map(AppOrder.fromJson).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AppOrder?> fetchOne(String orderId) async {
    try {
      final data = await _service.fetchOrder(orderId);
      return AppOrder.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Place an order. On success clears cart and navigates to confirmation.
  Future<AppOrder?> placeOrder({
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> deliveryAddress,
  }) async {
    try {
      final data = await _service.createOrder(
        items: items,
        deliveryAddress: deliveryAddress,
      );
      _lastCreated = AppOrder.fromJson(data);
      // Prepend to list so it shows up immediately in orders tab.
      _orders = [_lastCreated!, ..._orders];
      notifyListeners();
      return _lastCreated;
    } catch (e) {
      rethrow;
    }
  }
}
