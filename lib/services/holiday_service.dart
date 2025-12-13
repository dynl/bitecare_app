import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bitecare_app/services/http_service.dart';
import 'package:intl/intl.dart';

class HolidayService {
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
          String date = item['date'].toString();
          String name = item['name'] ?? "Holiday";
          holidayMap[date] = name;
        }
        return holidayMap;
      }
    } catch (e) {
      print("Holiday Fetch Error: $e");
    }
    return {};
  }

  static Future<String?> getTodayHolidayName() async {
    try {
      final now = DateTime.now();
      final String todayStr = DateFormat('yyyy-MM-dd').format(now);

      final holidayMap = await getHolidaysMap();
      return holidayMap[todayStr];
    } catch (e) {
      return null;
    }
  }
}
