import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';


class AppData extends ChangeNotifier{
  List<Map<String, String>> categories = [];
  bool isLoading = false;
  String error = "";
  HttpClient? _httpClient;
  IOClient? _ioClient;
  http.Client? _client;

Future<void> llegirCategories() async {
  isLoading = true;
  error = '';
  notifyListeners();
 _client ??= IOClient(HttpClient()); 
  try {
    // Creamos la request POST
    var request = http.Request(
      'POST',
      Uri.parse('http://localhost:3000/categories'), // endpoint
    );

    request.headers.addAll({'Content-Type': 'application/json'});
    request.body = jsonEncode({}); 
    var streamedResponse = await _client!.send(request);
    var responseString = await streamedResponse.stream.bytesToString();
    if (streamedResponse.statusCode == 200) {
      final List data = jsonDecode(responseString);
      categories = data.map((e) => {
        "name": e['alias'].toString(),
        "imatge": e['imatge'].toString(),
      }).toList();
            

      error = '';
    } else {
      error = 'Error ${streamedResponse.statusCode}';
      categories = [];
    }
  } catch (e) {
    error = 'Error de conexión: $e';
    categories = [];
  }

  isLoading = false;
  notifyListeners();
}

}
