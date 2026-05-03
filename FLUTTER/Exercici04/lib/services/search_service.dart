import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchService {
  static const String baseUrl = "http://localhost:3000";

  static Future<List> search(String text) async {
    final url = Uri.parse("$baseUrl/search");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"text": text}),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error searching");
    }
  }
}
