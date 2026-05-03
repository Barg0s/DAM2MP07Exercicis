import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/item.dart';

class ItemsService {
  static const String baseUrl = "http://localhost:3000";

  static Future<List<Item>> getItems(int categoryId) async {
    final url = Uri.parse("$baseUrl/items");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"categoryId": categoryId}),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Item.fromJson(e)).toList();
    } else {
      throw Exception("Error loading items");
    }
  }
}
