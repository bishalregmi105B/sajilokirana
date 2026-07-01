import 'api_client.dart';
import '../models/shop.dart';
import '../models/inventory_item.dart';
import '../models/shop_order.dart';
import '../models/analytics.dart';
import '../models/broadcast.dart';

class ShopService {
  ShopService._();
  static final ShopService instance = ShopService._();
  final _client = ApiClient.instance;

  Future<Shop> getProfile() async {
    final data = await _client.get('/shop/me');
    return Shop.fromJson(data as Map<String, dynamic>);
  }

  Future<List<IncomingBroadcast>> getIncomingOrders() async {
    final data = await _client.get('/shop/orders/incoming');
    return (data as List).map((b) => IncomingBroadcast.fromJson(b as Map<String, dynamic>)).toList();
  }

  Future<List<ShopOrder>> getActiveOrders() async {
    final data = await _client.get('/shop/orders/active');
    return (data as List).map((o) => ShopOrder.fromJson(o as Map<String, dynamic>)).toList();
  }

  Future<List<ShopOrder>> getOrderHistory() async {
    final data = await _client.get('/shop/orders/history');
    return (data as List).map((o) => ShopOrder.fromJson(o as Map<String, dynamic>)).toList();
  }

  Future<void> acceptOrder(String orderId) => _client.post('/shop/orders/\$orderId/accept');
  Future<void> rejectOrder(String orderId) => _client.post('/shop/orders/\$orderId/reject');

  Future<List<InventoryItem>> getInventory() async {
    final data = await _client.get('/shop/inventory');
    return (data as List).map((i) => InventoryItem.fromJson(i as Map<String, dynamic>)).toList();
  }

  Future<void> updateInventory(String productId, {required bool inStock, double? price}) =>
    _client.patch('/shop/inventory/\$productId', body: {'inStock': inStock, if (price != null) 'price': price});

  Future<ShopAnalytics> getAnalytics() async {
    final data = await _client.get('/shop/analytics');
    return ShopAnalytics.fromJson(data as Map<String, dynamic>);
  }
}
