import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:bitecare_app/services/http_service.dart';

class UserService {
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('${HttpService.baseUrl}/user'),
        headers: await HttpService.getHeaders(),
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

  static Future<bool> uploadAvatar(XFile image) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${HttpService.baseUrl}/user/avatar'),
      );

      final headers = await HttpService.getHeaders();
      request.headers.addAll(headers);

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
}
