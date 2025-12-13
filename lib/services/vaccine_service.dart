import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bitecare_app/services/http_service.dart';

class VaccineService {
  static Future<int> getTodayVaccineStock() async {
    try {
      final response = await http.get(
        Uri.parse('${HttpService.baseUrl}/vaccines/stock'),
        headers: await HttpService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> stocks = body['data'];
        final now = DateTime.now();
        final String todayStr =
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

        final todayRecord = stocks.firstWhere(
          (item) => item['date'] == todayStr,
          orElse: () => null,
        );

        return todayRecord != null ? todayRecord['quantity'] : 0;
      }
      return 0;
    } catch (e) {
      print("Vaccine Stock error: $e");
      return 0;
    }
  }

  static Future<Map<String, int>> getVaccineStockMap() async {
    try {
      final response = await http.get(
        Uri.parse('${HttpService.baseUrl}/vaccines/stock'),
        headers: await HttpService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> list = body['data'];
        Map<String, int> stockMap = {};
        for (var item in list) {
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
}
