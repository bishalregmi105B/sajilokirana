import 'dart:async';
import 'package:flutter/material.dart';
import '../services/driver_service.dart';
import '../models/driver.dart';
import '../models/batch.dart';
import '../models/earnings.dart';

class DriverProvider extends ChangeNotifier {
  final _service = DriverService.instance;

  Driver? _driver;
  Batch? _currentBatch;
  Earnings? _earnings;
  List<Batch> _history = [];
  bool _isLoading = false;
  String? _error;
  Timer? _pollTimer;

  Driver? get driver => _driver;
  Batch? get currentBatch => _currentBatch;
  Earnings? get earnings => _earnings;
  List<Batch> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOnline => _driver?.isOnline ?? false;
  bool get hasBatch => _currentBatch != null;

  Future<void> loadProfile() async {
    try {
      _driver = await _service.getProfile();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleOnline(bool online) async {
    try {
      _driver = await _service.setStatus(online ? 'available' : 'offline');
      if (online) {
        _startPolling();
      } else {
        _stopPolling();
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadCurrentBatch() async {
    try {
      _currentBatch = await _service.getCurrentBatch();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> confirmPickup(String orderId) async {
    await _service.confirmPickup(orderId);
    await loadCurrentBatch();
  }

  Future<void> confirmDelivery(String orderId) async {
    await _service.confirmDelivery(orderId);
    await loadCurrentBatch();
    await loadProfile();
  }

  Future<void> sendLocation(double lat, double lng, {String? orderId}) async {
    try {
      await _service.sendLocation(lat, lng, orderId: orderId);
    } catch (_) {}
  }

  Future<void> loadEarnings() async {
    _isLoading = true;
    notifyListeners();
    try {
      _earnings = await _service.getEarnings();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();
    try {
      _history = await _service.getHistory();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startPolling() {
    _stopPolling();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => loadCurrentBatch());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
