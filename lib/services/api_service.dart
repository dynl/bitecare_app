import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bitecare_app/variables.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  // Removes 'const' to allow dynamic switching in variables.dart
  static String baseUrl = apiBaseUrl;
  static String? _authToken;
  static String? get authToken => _authToken;

  // --- TOKEN MANAGEMENT ---
  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  static Future<void> _saveToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> logout() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // --- HEADERS ---
  static Future<Map<String, String>> _getHeaders({
    bool withAuth = true,
    bool isJson = false,
  }) async {
    final Map<String, String> headers = {'Accept': 'application/json'};
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }
    if (withAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // --- AUTH ENDPOINTS ---
  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: await _getHeaders(withAuth: false),
        body: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await _saveToken(data['token']);
          return true;
        }
      }
      return false;
    } catch (e) {
      print("Login error: $e");
      return false;
    }
  }

  static Future<bool> register(
    String email,
    String contact,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: await _getHeaders(withAuth: false),
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

  // --- UPLOAD AVATAR ---
  static Future<bool> uploadAvatar(XFile image) async {
    if (_authToken == null) return false;

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user/avatar'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $_authToken',
        'Accept': 'application/json',
      });

      request.files.add(
        http.MultipartFile.fromBytes(
          'avatar',
          await image.readAsBytes(),
          filename: image.name,
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      return response.statusCode == 200;
    } catch (e) {
      print("Upload error: $e");
      return false;
    }
  }

  // --- GET USER PROFILE ---
  static Future<Map<String, dynamic>?> getUserProfile() async {
    if (_authToken == null) return null;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print("Get User Profile error: $e");
      return null;
    }
  }

  // --- DATA ENDPOINTS ---
  static Future<List<dynamic>> getAppointments() async {
    if (_authToken == null) return [];
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/appointments'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body is List ? body : (body['data'] as List? ?? []);
      }
      return [];
    } catch (e) {
      print("Get appointments error: $e");
      return [];
    }
  }

  static Future<Map<String, int>> getAvailability() async {
    if (_authToken == null) return {};
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/appointments/availability'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['data'];
        Map<String, int> availabilityMap = {};
        for (var item in list) {
          availabilityMap[item['date']] = item['total'];
        }
        return availabilityMap;
      }
      return {};
    } catch (e) {
      print("Availability error: $e");
      return {};
    }
  }

  // --- NEW: GET ALL VACCINE STOCKS AS A MAP (For Calendar) ---
  static Future<Map<String, int>> getVaccineStockMap() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vaccines/stock'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> list = body['data'];

        Map<String, int> stockMap = {};
        for (var item in list) {
          // Map "2025-11-23" to quantity (e.g., 50)
          stockMap[item['date']] = item['quantity'];
        }
        return stockMap;
      }
      return {};
    } catch (e) {
      print("Stock Map error: $e");
      return {};
    }
  }

  static Future<Map<String, dynamic>> bookAppointment(
    Map<String, dynamic> data,
  ) async {
    if (_authToken == null)
      return {'success': false, 'message': 'Not logged in'};
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/appointments'),
        headers: await _getHeaders(isJson: true),
        body: jsonEncode(data),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Booking Successful'};
      } else if (response.statusCode == 409) {
        return {
          'success': false,
          'message': body['message'] ?? 'Slot already booked',
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Booking failed',
        };
      }
    } catch (e) {
      print("Book appointment error: $e");
      return {'success': false, 'message': 'Network error'};
    }
  }

  // --- UPDATE APPOINTMENT ---
  static Future<Map<String, dynamic>> updateAppointment(
    int id,
    Map<String, dynamic> data,
  ) async {
    if (_authToken == null)
      return {'success': false, 'message': 'Not logged in'};
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/appointments/$id'),
        headers: await _getHeaders(isJson: true),
        body: jsonEncode(data),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Appointment Updated'};
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Update failed',
        };
      }
    } catch (e) {
      print("Update appointment error: $e");
      return {'success': false, 'message': 'Network error'};
    }
  }

  // --- DELETE APPOINTMENT ---
  static Future<bool> deleteAppointment(int id) async {
    if (_authToken == null) return false;
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/appointments/$id'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Delete error: $e");
      return false;
    }
  }

  // --- GET TODAY'S VACCINE STOCK ---
  static Future<int> getTodayVaccineStock() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vaccines/stock'),
        headers: await _getHeaders(),
      );

      print("🔍 VACCINE API BODY: ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> stocks = body['data'];

        final now = DateTime.now();
        final String todayStr =
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

        print("🔍 PHONE LOOKING FOR: $todayStr");

        final todayRecord = stocks.firstWhere(
          (item) => item['date'] == todayStr,
          orElse: () => null,
        );

        if (todayRecord != null) {
          print("✅ FOUND STOCK: ${todayRecord['quantity']}");
          return todayRecord['quantity'];
        } else {
          print("❌ NO STOCK FOUND FOR TODAY");
        }
      }
      return 0;
    } catch (e) {
      print("🚨 Vaccine Stock error: $e");
      return 0;
    }
  }

  // --- NEW: GET BEST DAY RECOMMENDATION (PRESCRIPTIVE ANALYSIS) ---
  static Future<Map<String, dynamic>?> getBestDayRecommendation() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/recommendation/best-day'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          return body['data'];
        }
      }
      return null;
    } catch (e) {
      print("Recommendation error: $e");
      return null;
    }
  }
}
