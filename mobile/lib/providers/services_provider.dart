import 'package:flutter/foundation.dart';

import 'package:mobile/models/service.dart';
import 'package:mobile/services/api_client.dart';

// Loads and mutates services; the token comes from AuthProvider.
class ServicesProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<Service> _services = [];
  List<Service> _myServices = [];
  bool _loading = false;
  String? _error;
  bool _myLoaded = false;

  List<Service> get services => _services;
  List<Service> get myServices => _myServices;
  bool get loading => _loading;
  String? get error => _error;

  // Load the public list of active services, optionally filtered by query.
  Future<void> loadServices({String? query}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final path = (query == null || query.isEmpty)
          ? '/services'
          : '/services?q=${Uri.encodeQueryComponent(query)}';
      final data = await _api.get(path) as List<dynamic>;
      _services = data
          .map((e) => Service.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    }
    _loading = false;
    notifyListeners();
  }

  // Load the logged-in user's own services.
  Future<void> loadMyServices(String token) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/services/mine', token: token)
          as List<dynamic>;
      _myServices = data
          .map((e) => Service.fromJson(e as Map<String, dynamic>))
          .toList();
      _myLoaded = true;
    } on ApiException catch (e) {
      _error = e.message;
    }
    _loading = false;
    notifyListeners();
  }

  // Create a service and prepend it to the lists.
  Future<bool> createService({
    required String title,
    required String description,
    required String category,
    required double price,
    required String token,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.post(
        '/services',
        body: {
          'title': title,
          'description': description,
          'category': category,
          'price': price,
        },
        token: token,
      ) as Map<String, dynamic>;
      final service = Service.fromJson(data);
      _services = [service, ..._services];
      if (_myLoaded) {
        _myServices = [service, ..._myServices];
      }
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // Update a service in place in both lists.
  Future<bool> updateService({
    required int id,
    required String title,
    required String description,
    required String category,
    required double price,
    required String token,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.put(
        '/services/$id',
        body: {
          'title': title,
          'description': description,
          'category': category,
          'price': price,
        },
        token: token,
      ) as Map<String, dynamic>;
      final updated = Service.fromJson(data);
      _services = [
        for (final s in _services) s.id == id ? _merge(s, updated) : s,
      ];
      _myServices = [
        for (final s in _myServices) s.id == id ? _merge(s, updated) : s,
      ];
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete a service and remove it from both lists.
  Future<bool> deleteService(int id, String token) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.delete('/services/$id', token: token);
      _services = _services.where((s) => s.id != id).toList();
      _myServices = _myServices.where((s) => s.id != id).toList();
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // The update response has no provider join, so keep the old provider info.
  Service _merge(Service old, Service updated) {
    return updated.copyWith(
      providerName: updated.providerName ?? old.providerName,
      providerPhone: updated.providerPhone ?? old.providerPhone,
    );
  }
}
