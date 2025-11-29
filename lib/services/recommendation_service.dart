import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bitecare_app/services/http_service.dart';

class RecommendationService {
  static Future<Map<String, dynamic>?> getBestDayRecommendation() async {
    try {
      final response = await http.get(
        Uri.parse('${HttpService.baseUrl}/recommendation/best-day'),
        headers: await HttpService.getHeaders(),
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
