import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';

class CategoriesService {
  static const String baseUrl = "http://localhost:3000";

  static Future<List<Category>> getCategories() async {
    final url = Uri.parse("$baseUrl/categories");

    final response = await http.post(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Category.fromJson(e)).toList();
    } else {
      throw Exception("Error loading categories");
    }
  }
}
