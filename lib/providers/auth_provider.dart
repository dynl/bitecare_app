import 'package:flutter/foundation.dart';
import 'package:bitecare_app/services/auth_service.dart';
import 'package:bitecare_app/services/http_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  String? _authToken;

  bool get isLoggedIn => _isLoggedIn;
  String? get authToken => _authToken;

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    await HttpService.loadToken();
    _authToken = HttpService.authToken;
    _isLoggedIn = _authToken != null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final result = await AuthService.login(email, password);

    if (result['success'] == true) {
      _authToken = HttpService.authToken;
      _isLoggedIn = true;
      notifyListeners();
    }

    return result;
  }

  // UPDATED: Added 'name' parameter
  Future<bool> register(String name, String email, String contact, String password) async {
    final success = await AuthService.register(name, email, contact, password);
    return success;
  }

  Future<void> logout() async {
    await AuthService.logout();
    _authToken = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}