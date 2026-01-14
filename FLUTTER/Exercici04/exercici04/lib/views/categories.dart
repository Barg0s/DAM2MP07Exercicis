import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;


void categories() {
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
              OutlinedButton(onPressed: () {print('Botón pulsado');},child: const Text('VILLANS'),),
              const SizedBox(width: 50),
              OutlinedButton(onPressed: () {print('Botón pulsado');},child: const Text('VILLANS'),),
              const SizedBox(width: 50),
              OutlinedButton(onPressed: () {print('Botón pulsado');},child: const Text('EQUIPS'),),
              const SizedBox(width: 50),
              Image.asset('assets/negro.png',
              width : 150)

            ],
          ),
        ),
      ),
    );
  }



}
