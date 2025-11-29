import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bitecare_app/services/http_service.dart';

class AuthService {
  // CHANGED: Return Future<Map<String, dynamic>> instead of Future<bool>
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${HttpService.baseUrl}/login'),
        headers: await HttpService.getHeaders(withAuth: false),
        body: {'email': email, 'password': password},
      );

      final body = jsonDecode(response.body);

      // If login is successful (Status 200 AND token exists)
      if (response.statusCode == 200) {
        if (body['token'] != null) {
          await HttpService.saveToken(body['token']);
          return {'success': true, 'message': 'Login Successful'};
        }
      }
      
      // If failed (Status 401, 403, etc.), return the specific message
      return {
        'success': false,
        'message': body['message'] ?? 'Login Failed'
      };

    } catch (e) {
      print("Login error: $e");
      return {'success': false, 'message': 'Network Error'};
    }
  }

  static Future<bool> register(String email, String contact, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${HttpService.baseUrl}/register'),
        headers: await HttpService.getHeaders(withAuth: false),
        body: {
          'email': email,
          'contact_number': contact,
          'password': password,
          'password_confirmation': password,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Register error: $e");
      return false;
    }
  }

  static Future<void> logout() async {
    await HttpService.clearToken();
  }
}