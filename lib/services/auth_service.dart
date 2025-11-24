import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bitecare_app/services/http_service.dart';

class AuthService {
  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${HttpService.baseUrl}/login'),
        headers: await HttpService.getHeaders(withAuth: false),
        body: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await HttpService.saveToken(data['token']);
          return true;
        }
      }
      return false;
    } catch (e) {
      print("Login error: $e");
      return false;
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