import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ecom/services/api_client.dart';

class AuthApiService {
  AuthApiService._();
  static final AuthApiService instance = AuthApiService._();

  final _storage = const FlutterSecureStorage();
  final _client = ApiClient.instance;

  /// Step 1 — request OTP. Returns `resentAfter` (cooldown seconds) or null.
  Future<int?> requestOtp(String phone) async {
    final data = await _client.post('/auth/otp/request', body: {
      'phone': phone,
      'role': 'customer',
    });
    return (data as Map<String, dynamic>)['resentAfter'] as int?;
  }

  /// Step 2 — verify OTP, store token, return user map.
  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    final data = await _client.post('/auth/otp/verify', body: {
      'phone': phone,
      'code': code,
      'role': 'customer',
    });
    final map = data as Map<String, dynamic>;
    await _storage.write(key: 'authToken', value: map['token'] as String);
    await _storage.write(key: 'userId', value: (map['user'] as Map)['id'] as String);
    await _storage.write(key: 'userPhone', value: phone);
    return map;
  }

  Future<String?> getSavedToken() => _storage.read(key: 'authToken');

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final data = await _client.get('/me');
      return data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) async {
    final data = await _client.patch('/me', body: body);
    return data as Map<String, dynamic>;
  }
}
