import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/driver_service.dart';
import '../models/driver.dart';

enum AuthState { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider() { _init(); }

  final _authService = AuthService.instance;
  final _driverService = DriverService.instance;

  AuthState _state = AuthState.unknown;
  Driver? _driver;

  AuthState get state => _state;
  Driver? get driver => _driver;
  bool get isAuthenticated => _state == AuthState.authenticated;

  Future<void> _init() async {
    final token = await _authService.getSavedToken();
    if (token != null) {
      try {
        _driver = await _driverService.getProfile();
        _state = AuthState.authenticated;
      } catch (_) {
        _state = AuthState.unauthenticated;
        await _authService.logout();
      }
    } else {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<int?> requestOtp(String phone) => _authService.requestOtp(phone);

  Future<void> verifyOtp(String phone, String code) async {
    await _authService.verifyOtp(phone, code);
    _driver = await _driverService.getProfile();
    _state = AuthState.authenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _driver = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    _driver = await _driverService.getProfile();
    notifyListeners();
  }
}
