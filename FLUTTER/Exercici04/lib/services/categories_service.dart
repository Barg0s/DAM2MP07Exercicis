import 'dart:convert';
import 'package:http/http.dart' as http;

class CategoriesService {
  static const String baseUrl = "http://localhost:3000";

  static Future<List> getCategories() async {
    final url = Uri.parse("$baseUrl/categories");

    final response = await http.post(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error loading categories");
    }
  }
}
