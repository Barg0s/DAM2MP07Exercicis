import 'package:flutter/material.dart';
import 'screens/categories_screen.dart';

void main() {
  runApp(const MarvelApp());
}

class MarvelApp extends StatelessWidget {
  const MarvelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Marvel DB',

      theme: ThemeData(
        primarySwatch: Colors.red,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),

      home: const CategoriesScreen(),
    );
  }
}
