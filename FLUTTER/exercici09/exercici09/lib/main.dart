import 'package:flutter/material.dart';
import 'vistaEncriptar.dart';
import 'vistaDesencriptar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(text: "ENCRIPTAR"),
                Tab(text: "DESENCRIPTAR"),
              ],
            ),
            title: const Text("EXERCICI09"),
          ),
          body: TabBarView(
            children: [
              VistaEncriptar(),
              vistaDesencriptar(),
            ],
          ),
        ),
      ),
    );
  }
}
