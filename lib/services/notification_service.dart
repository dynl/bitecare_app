import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bitecare_app/services/http_service.dart';
import 'package:bitecare_app/models/app_notification.dart';

class NotificationService {
  static Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('${HttpService.baseUrl}/notifications'),
        headers: await HttpService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['notifications'] != null) {
          final List<dynamic> list = body['notifications'];
          return list.map((json) => AppNotification.fromJson(json)).toList();
        }
      }
    } catch (e) {
      print("Notification Fetch Error: $e");
    }
    return [];
  }

  static Future<bool> markAsRead(String id) async {
    try {
      final response = await http.put(
        Uri.parse('${HttpService.baseUrl}/notifications/$id/read'),
        headers: await HttpService.getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Mark Read Error: $e");
      return false;
    }
  }
}
