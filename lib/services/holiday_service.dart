import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bitecare_app/services/http_service.dart';
import 'package:intl/intl.dart';

class HolidayService {
  // Returns a Map: { "2025-12-25": "Christmas Day", "2025-12-30": "Rizal Day" }
  static Future<Map<String, String>> getHolidaysMap() async {
    try {
      final response = await http.get(
        Uri.parse('${HttpService.baseUrl}/holidays'),
        headers: await HttpService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> data = body['data'];

        Map<String, String> holidayMap = {};
        for (var item in data) {
          // Ensure we capture date as Key and Name as Value
          String date = item['date'].toString();
          String name = item['name'] ?? "Holiday"; // Default if name missing
          holidayMap[date] = name;
        }
        return holidayMap;
      }
    } catch (e) {
      print("Holiday Fetch Error: $e");
    }
    return {};
  }

  // Check if today is a holiday and return its NAME (or null if not)
  static Future<String?> getTodayHolidayName() async {
    try {
      final now = DateTime.now();
      final String todayStr = DateFormat('yyyy-MM-dd').format(now);

      final holidayMap = await getHolidaysMap();
      return holidayMap[todayStr]; // Returns "Christmas Day" or null
    } catch (e) {
      return null;
    }
  }
}
