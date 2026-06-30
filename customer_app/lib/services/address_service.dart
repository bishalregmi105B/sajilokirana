import 'package:ecom/services/api_client.dart';

class AddressService {
  AddressService._();
  static final AddressService instance = AddressService._();

  final _client = ApiClient.instance;

  Future<List<Map<String, dynamic>>> fetchAddresses() async {
    final data = await _client.get('/me/addresses');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> addAddress(Map<String, dynamic> body) async {
    final data = await _client.post('/me/addresses', body: body);
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> setDefault(String addressId) async {
    final data =
        await _client.patch('/me/addresses/$addressId/default');
    return data as Map<String, dynamic>;
  }

  Future<void> deleteAddress(String addressId) =>
      _client.delete('/me/addresses/$addressId');
}
