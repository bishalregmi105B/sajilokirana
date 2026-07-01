import 'dart:async';
import 'package:flutter/material.dart';
import '../services/shop_service.dart';
import '../models/analytics.dart';
import '../models/broadcast.dart';
import '../models/shop_order.dart';
import '../models/inventory_item.dart';

class ShopProvider extends ChangeNotifier {
  final _service = ShopService.instance;

  List<IncomingBroadcast> _incoming = [];
  List<ShopOrder> _activeOrders = [];
  List<ShopOrder> _orderHistory = [];
  List<InventoryItem> _inventory = [];
  ShopAnalytics? _analytics;
  bool _isLoading = false;
  String? _error;
  Timer? _pollTimer;

  List<IncomingBroadcast> get incoming => _incoming;
  List<ShopOrder> get activeOrders => _activeOrders;
  List<ShopOrder> get orderHistory => _orderHistory;
  List<InventoryItem> get inventory => _inventory;
  ShopAnalytics? get analytics => _analytics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadIncoming() async {
    try { _incoming = await _service.getIncomingOrders(); notifyListeners(); }
    catch (e) { _error = e.toString(); notifyListeners(); }
  }

  Future<void> loadActiveOrders() async {
    try { _activeOrders = await _service.getActiveOrders(); notifyListeners(); }
    catch (e) { _error = e.toString(); notifyListeners(); }
  }

  Future<void> loadOrderHistory() async {
    _isLoading = true; notifyListeners();
    try { _orderHistory = await _service.getOrderHistory(); }
    catch (e) { _error = e.toString(); }
    _isLoading = false; notifyListeners();
  }

  Future<void> acceptOrder(String orderId) async {
    await _service.acceptOrder(orderId);
    await loadIncoming(); await loadActiveOrders();
  }

  Future<void> rejectOrder(String orderId) async {
    await _service.rejectOrder(orderId); await loadIncoming();
  }

  Future<void> loadInventory() async {
    _isLoading = true; notifyListeners();
    try { _inventory = await _service.getInventory(); }
    catch (e) { _error = e.toString(); }
    _isLoading = false; notifyListeners();
  }

  Future<void> toggleStock(String productId, bool inStock) async {
    await _service.updateInventory(productId, inStock: inStock); await loadInventory();
  }

  Future<void> loadAnalytics() async {
    _isLoading = true; notifyListeners();
    try { _analytics = await _service.getAnalytics(); }
    catch (e) { _error = e.toString(); }
    _isLoading = false; notifyListeners();
  }

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => loadIncoming());
  }
  void stopPolling() { _pollTimer?.cancel(); _pollTimer = null; }

  @override
  void dispose() { stopPolling(); super.dispose(); }
}
