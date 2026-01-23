import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:http/http.dart' as http;

class AppData extends ChangeNotifier {
  List<Map<String, String>> categories = [];
  List<Map<String, String>> personatges = [];

  bool isLoading = false;
  String error = "";

  http.Client? _client;

  // -------------------------
  // POST /categories
  // -------------------------
  Future<void> llegirCategories() async {
    isLoading = true;
    error = '';
    notifyListeners();

    _client ??= IOClient(HttpClient());

    try {
      final response = await _client!.post(
        Uri.parse('http://localhost:3000/categories'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}), // POST vacío
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        categories = data.map((e) => {
              "id": e['id'].toString(),
              "name": e['name'].toString(),
              "imatge": e['imatge'].toString(),
            }).toList();

        error = '';
      } else {
        error = 'Error ${response.statusCode}';
        categories = [];
      }
    } catch (e) {
      error = 'Error de conexión: $e';
      categories = [];
    }

    isLoading = false;
    notifyListeners();
  }

  // -------------------------
  // POST /characters
  // -------------------------
  Future<void> llegirPersonatges(int categoryId) async {
    isLoading = true;
    error = '';
    notifyListeners();

    _client ??= IOClient(HttpClient());

    try {
      final response = await _client!.post(
        Uri.parse('http://localhost:3000/characters'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'categoryId': categoryId}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        personatges = data.map((e) => {
              "id": e['id'].toString(),
              "nom": e['nom'].toString(),
              "alias": e['alias'].toString(),
              "imatge": e['imatge'].toString(),
            }).toList();

        error = '';
      } else {
        error = 'Error ${response.statusCode}';
        personatges = [];
      }
    } catch (e) {
      error = 'Error de conexión: $e';
      personatges = [];
    }

    isLoading = false;
    notifyListeners();
  }
}
