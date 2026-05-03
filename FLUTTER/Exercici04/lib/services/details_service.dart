import 'dart:convert';
import 'package:http/http.dart' as http;

class DetailsService {
  static const String baseUrl = "http://localhost:3000";

  static String getImageUrl(String imageName) {
    return "$baseUrl/images/$imageName";
  }

  static Future<Map<String, dynamic>> getDetail(int id) async {
    final url = Uri.parse("$baseUrl/detalls");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "id": id,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error loading detail");
    }
  }
}
