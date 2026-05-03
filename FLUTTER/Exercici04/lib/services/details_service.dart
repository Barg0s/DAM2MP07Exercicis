import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/detail.dart';

class DetailsService {
  static const String baseUrl = "http://localhost:3000";

  static Future<Detail> getDetail(int id) async {
    final url = Uri.parse("$baseUrl/detalls");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id": id}),
    );

    if (response.statusCode == 200) {
      return Detail.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Error loading detail");
    }
  }

  static String getImageUrl(String image) {
    return "$baseUrl/images/$image";
  }
}
