import 'dart:convert';
import 'package:http/http.dart' as http;

class ItemsService {
  static const String baseUrl = "http://localhost:3000";

  static Future<List> getItems(int categoryId) async {
    final url = Uri.parse("$baseUrl/items");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "categoryId": categoryId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error loading items");
    }
  }
}
