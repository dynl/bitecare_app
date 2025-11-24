import 'package:shared_preferences/shared_preferences.dart';
import 'package:bitecare_app/variables.dart';

class HttpService {
  // Base URL from variables.dart
  static String baseUrl = apiBaseUrl; 
  static String? _authToken;
  static String? get authToken => _authToken;

  // Load Token on App Start
  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  // Save Token after Login
  static Future<void> saveToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Remove Token on Logout
  static Future<void> clearToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Generate Headers
  static Future<Map<String, String>> getHeaders({
    bool withAuth = true,
    bool isJson = false,
  }) async {
    final Map<String, String> headers = {'Accept': 'application/json'};
    
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }
    
    // Ensure token is loaded if null
    if (_authToken == null) await loadToken();

    if (withAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }
}