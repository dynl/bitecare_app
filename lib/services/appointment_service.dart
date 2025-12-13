import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bitecare_app/services/http_service.dart';

class AppointmentService {
  static Future<List<dynamic>> getAppointments() async {
    try {
      final response = await http.get(
        Uri.parse('${HttpService.baseUrl}/appointments'),
        headers: await HttpService.getHeaders(),
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

  // Get Calendar Availability
  static Future<Map<String, int>> getAvailability() async {
    try {
      final response = await http.get(
        Uri.parse('${HttpService.baseUrl}/appointments/availability'),
        headers: await HttpService.getHeaders(),
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

  // Book Appointment
  static Future<Map<String, dynamic>> bookAppointment(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${HttpService.baseUrl}/appointments'),
        headers: await HttpService.getHeaders(isJson: true),
        body: jsonEncode(data),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Booking Successful'};
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

  // Update Appointment
  static Future<Map<String, dynamic>> updateAppointment(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${HttpService.baseUrl}/appointments/$id'),
        headers: await HttpService.getHeaders(isJson: true),
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
      print("Update error: $e");
      return {'success': false, 'message': 'Network error'};
    }
  }

  // Delete Appointment
  static Future<bool> deleteAppointment(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${HttpService.baseUrl}/appointments/$id'),
        headers: await HttpService.getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Delete error: $e");
      return false;
    }
  }
}