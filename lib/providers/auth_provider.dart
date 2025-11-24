import 'package:flutter/foundation.dart';
import 'package:bitecare_app/services/auth_service.dart';
import 'package:bitecare_app/services/http_service.dart'; // <--- Import this

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  String? _authToken;

  bool get isLoggedIn => _isLoggedIn;
  String? get authToken => _authToken;

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    // FIX: Use HttpService to load the token
    await HttpService.loadToken();
    _authToken = HttpService.authToken;
    _isLoggedIn = _authToken != null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final success = await AuthService.login(email, password);
    if (success) {
      // FIX: Get token from HttpService
      _authToken = HttpService.authToken;
      _isLoggedIn = true;
      notifyListeners();
    }
    return success;
  }

  Future<bool> register(String email, String contact, String password) async {
    final success = await AuthService.register(email, contact, password);
    return success;
  }

  Future<void> logout() async {
    await AuthService.logout();
    _authToken = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}