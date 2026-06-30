import 'package:ecom/services/api_client.dart';

class OrdersService {
  OrdersService._();
  static final OrdersService instance = OrdersService._();

  final _client = ApiClient.instance;

  /// Create a new order. Returns the order map from the backend.
  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> deliveryAddress,
  }) async {
    final data = await _client.post('/orders', body: {
      'items': items,
      'deliveryAddress': deliveryAddress,
    });
    return data as Map<String, dynamic>;
  }

  /// Fetch all orders for the current user.
  Future<List<Map<String, dynamic>>> fetchOrders() async {
    final data = await _client.get('/orders');
    return (data as List).cast<Map<String, dynamic>>();
  }

  /// Fetch a single order by ID.
  Future<Map<String, dynamic>> fetchOrder(String orderId) async {
    final data = await _client.get('/orders/$orderId');
    return data as Map<String, dynamic>;
  }
}
