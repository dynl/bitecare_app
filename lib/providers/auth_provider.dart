import 'package:flutter/foundation.dart';
import 'package:bitecare_app/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  String? _authToken;

  bool get isLoggedIn => _isLoggedIn;
  String? get authToken => _authToken;

  AuthProvider() {
    // Load token when provider is initialized
    _loadToken();
  }

  Future<void> _loadToken() async {
    await ApiService.loadToken();
    _authToken = ApiService.authToken;
    _isLoggedIn = _authToken != null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final success = await ApiService.login(email, password);
    if (success) {
      _authToken = ApiService.authToken;
      _isLoggedIn = true;
      notifyListeners();
    }
    return success;
  }

  Future<bool> register(String email, String contact, String password) async {
    final success = await ApiService.register(email, contact, password);
    // Note: Registration doesn't automatically log in the user
    // They need to log in separately after registration
    return success;
  }

  Future<void> logout() async {
    await ApiService.logout();
    _authToken = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
