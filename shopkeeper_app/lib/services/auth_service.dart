import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();
  final _storage = const FlutterSecureStorage();
  final _client = ApiClient.instance;

  Future<int?> requestOtp(String phone) async {
    final data = await _client.post('/auth/otp/request', body: {'phone': phone, 'role': 'shop'});
    return (data as Map<String, dynamic>)['resentAfter'] as int?;
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    final data = await _client.post('/auth/otp/verify', body: {'phone': phone, 'code': code, 'role': 'shop'});
    final map = data as Map<String, dynamic>;
    await _storage.write(key: 'authToken', value: map['token'] as String);
    return map;
  }

  Future<String?> getSavedToken() => _storage.read(key: 'authToken');
  Future<void> logout() => _storage.deleteAll();
}
