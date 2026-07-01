import 'api_client.dart';
import '../models/driver.dart';
import '../models/batch.dart';
import '../models/earnings.dart';

class DriverService {
  DriverService._();
  static final DriverService instance = DriverService._();
  final _client = ApiClient.instance;

  Future<Driver> getProfile() async {
    final data = await _client.get('/driver/me');
    return Driver.fromJson(data as Map<String, dynamic>);
  }

  Future<Driver> setStatus(String status) async {
    final data = await _client.patch('/driver/status', body: {'status': status});
    return Driver.fromJson(data as Map<String, dynamic>);
  }

  Future<Batch?> getCurrentBatch() async {
    final data = await _client.get('/driver/batches/current');
    if (data == null) return null;
    return Batch.fromJson(data as Map<String, dynamic>);
  }

  Future<void> confirmPickup(String orderId) async {
    await _client.post('/driver/orders/$orderId/pickup');
  }

  Future<void> confirmDelivery(String orderId) async {
    await _client.post('/driver/orders/$orderId/deliver');
  }

  Future<void> sendLocation(double lat, double lng, {String? orderId}) async {
    await _client.post('/driver/location', body: {
      'lat': lat, 'lng': lng,
      if (orderId != null) 'orderId': orderId,
    });
  }

  Future<Earnings> getEarnings() async {
    final data = await _client.get('/driver/earnings');
    return Earnings.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Batch>> getHistory() async {
    final data = await _client.get('/driver/history');
    return (data as List).map((b) => Batch.fromJson(b as Map<String, dynamic>)).toList();
  }
}
