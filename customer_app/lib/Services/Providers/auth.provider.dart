import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'package:ecom/services/auth_api_service.dart';

enum AuthState { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _init();
  }

  final _storage = const FlutterSecureStorage();
  final _authService = AuthApiService.instance;

  AuthState _state = AuthState.unknown;
  String? _token;
  Map<String, dynamic>? _user;

  AuthState get state => _state;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _state == AuthState.authenticated;

  Future<void> _init() async {
    _token = await _storage.read(key: 'authToken');
    if (_token != null) {
      // Verify token is still valid by fetching profile.
      _user = await _authService.getProfile();
      _state = _user != null ? AuthState.authenticated : AuthState.unauthenticated;
      if (_user == null) await _storage.deleteAll();
    } else {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<int?> requestOtp(String phone) =>
      _authService.requestOtp(phone);

  Future<void> verifyOtp(String phone, String code) async {
    final data = await _authService.verifyOtp(phone, code);
    _token = data['token'] as String;
    _user = data['user'] as Map<String, dynamic>;
    _state = AuthState.authenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _token = null;
    _user = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    _user = await _authService.getProfile();
    notifyListeners();
  }

  // Keep old helper for backward compat.
  Future<void> getAuthToken() async => _init();

  String? get authToken => _token;

  static AuthProvider of(BuildContext context) =>
      Provider.of<AuthProvider>(context, listen: false);
}

