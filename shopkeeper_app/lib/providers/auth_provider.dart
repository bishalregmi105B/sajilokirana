import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/shop_service.dart';
import '../models/shop.dart';

enum AuthState { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider() { _init(); }
  final _authService = AuthService.instance;
  final _shopService = ShopService.instance;

  AuthState _state = AuthState.unknown;
  Shop? _shop;

  AuthState get state => _state;
  Shop? get shop => _shop;
  bool get isAuthenticated => _state == AuthState.authenticated;

  Future<void> _init() async {
    final token = await _authService.getSavedToken();
    if (token != null) {
      try { _shop = await _shopService.getProfile(); _state = AuthState.authenticated; }
      catch (_) { _state = AuthState.unauthenticated; await _authService.logout(); }
    } else { _state = AuthState.unauthenticated; }
    notifyListeners();
  }

  Future<int?> requestOtp(String phone) => _authService.requestOtp(phone);

  Future<void> verifyOtp(String phone, String code) async {
    await _authService.verifyOtp(phone, code);
    _shop = await _shopService.getProfile();
    _state = AuthState.authenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _shop = null; _state = AuthState.unauthenticated;
    notifyListeners();
  }
}
