import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  
  AuthStatus _status = AuthStatus.initial;
  User? _currentUser;
  String? _errorMessage;

  AuthProvider(this._apiService) {
    checkLoggedInStatus();
  }

  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> checkLoggedInStatus() async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null) {
        // In real backend, you'd fetch the current user profile or validate the token
        // For mock/local mode, we retrieve cached info
        final username = prefs.getString('mock_current_username') ?? 'demo_user';
        final email = prefs.getString('mock_current_email') ?? 'demo@example.com';
        final userId = prefs.getInt('mock_current_user_id') ?? 1;

        _currentUser = User(
          id: userId,
          username: username,
          email: email,
          token: token,
        );
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String emailOrUsername, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _apiService.login(emailOrUsername, password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.register(username, email, password);
      // Automatically log in the user after successful registration
      return await login(username, password);
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      await _apiService.clearToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('mock_current_username');
      await prefs.remove('mock_current_email');
      await prefs.remove('mock_current_user_id');
      
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
