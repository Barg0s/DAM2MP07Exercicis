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

      debugShowCheckedModeBanner: false,

      home: DefaultTabController(

        length: 2,

        child: Scaffold(

          appBar: AppBar(

            title: const Text("EXERCICI09"),

            bottom: const TabBar(
              tabs: [

                Tab(text: "ENCRIPTAR"),

                Tab(text: "DESENCRIPTAR"),
              ],
            ),
          ),

          body: const TabBarView(

            children: [

              VistaEncriptar(),

              VistaDesencriptar(),
            ],
          ),
        ),
      ),
    );
  }
}