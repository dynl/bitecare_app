import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bitecare_app/services/http_service.dart';

class AuthService {
  // Login
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${HttpService.baseUrl}/login'),
        headers: await HttpService.getHeaders(withAuth: false, isJson: true),
        body: jsonEncode({'email': email, 'password': password}),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (body['token'] != null) {
          await HttpService.saveToken(body['token']);
          return {'success': true, 'message': 'Login Successful'};
        }
      }

      return {'success': false, 'message': body['message'] ?? 'Login Failed'};
    } catch (e) {
      print("Login error: $e");
      return {'success': false, 'message': 'Network Error'};
    }
  }

  // Register
  static Future<bool> register(
    String name,
    String email,
    String contact,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${HttpService.baseUrl}/register'),
        headers: await HttpService.getHeaders(withAuth: false, isJson: true),
        body: jsonEncode({
          'name': name,
          'email': email,
          'contact_number': contact,
          'password': password,
          'password_confirmation': password,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print("Register Failed: ${response.body}");
      }

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
