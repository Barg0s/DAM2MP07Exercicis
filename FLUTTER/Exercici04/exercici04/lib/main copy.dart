import 'package:flutter/material.dart';

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
              OutlinedButton(onPressed: () {print('Botón pulsado');},child: const Text('HEROIS'),),
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
}
