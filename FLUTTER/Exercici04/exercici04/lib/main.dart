import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(onPressed: () async {await obtenirDades();},child: const Text('HEROIS'),),
              const SizedBox(width: 50),
              OutlinedButton(onPressed: () {print('Botón pulsado');},child: const Text('VILLANS'),),
              const SizedBox(width: 50),
              OutlinedButton(onPressed: () {print('Botón pulsado');},child: const Text('EQUIPS'),),


            ],
          ),
        ),
      ),
    );
  }

Future<void> obtenirDades() async {
  try {
    // Petición POST al endpoint /getItems
    final response = await http.post(
      Uri.parse('http://localhost:3000/getItems'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      print(jsonDecode(response.body));
    } else {
      print('Error al obtener datos: ${response.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
  }
}

}
