import 'dart:math';

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
        body: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                color: Colors.blue, 
                child : const Text(
                'DB',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24),
              ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  categoriaCard("CAT 1"),
                  const SizedBox(width: 20),
                  categoriaCard("CAT 2"),
                  const SizedBox(width: 20),
                  categoriaCard("CAT 3"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget categoriaCard(String value) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        splashColor: Colors.blue.withAlpha(30),
        onTap: () {
          debugPrint("A");
        },
        child: SizedBox(
          width: 250,
          height: 400,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image(
                image: AssetImage('assets/negro.png'),
                width: 250,
                height: 100,
              ),
              SizedBox(height: 10),
              Text(value),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> llegirCategories() async {
    //TODO
}
}