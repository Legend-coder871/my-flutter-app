import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/models/user.dart';
import 'package:mobile/services/api_client.dart';

// Holds the logged-in user, the token and the auth UI state.
class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  static const String _tokenKey = 'auth_token';

  User? _user;
  String? _token;
  bool _loading = false;
  String? _errorMessage;

  bool get isLoggedIn => _user != null && _token != null;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  User? get user => _user;
  String? get token => _token;

  // Register a new account and start a session.
  Future<bool> register(
    String name,
    String email,
    String password,
    String phone,
  ) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final data = await _api.post(
        '/auth/register',
        body: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        },
      ) as Map<String, dynamic>;
      await _startSession(data);
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // Log in with email and password and start a session.
  Future<bool> login(String email, String password) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final data = await _api.post(
        '/auth/login',
        body: {'email': email, 'password': password},
      ) as Map<String, dynamic>;
      await _startSession(data);
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // Forget the current session.
  Future<void> logout() async {
    _user = null;
    _token = null;
    _errorMessage = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    notifyListeners();
  }

  // On startup, restore a saved token and check it against GET /auth/me.
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_tokenKey);
    if (saved == null) return;
    _token = saved;
    try {
      final data = await _api.get('/auth/me', token: saved)
          as Map<String, dynamic>;
      _user = User.fromJson(data['user'] as Map<String, dynamic>);
    } on ApiException {
      // Token is invalid or expired: forget it.
      _token = null;
      await prefs.remove(_tokenKey);
    }
    notifyListeners();
  }

  // Save the token and user from a successful login/register response.
  Future<void> _startSession(Map<String, dynamic> data) async {
    _token = data['token'] as String;
    _user = User.fromJson(data['user'] as Map<String, dynamic>);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _token!);
  }
}
