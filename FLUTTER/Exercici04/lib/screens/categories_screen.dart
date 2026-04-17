import 'package:flutter/material.dart';
import '../widgets/categoriaCard.dart';
import 'items_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  final List<String> categories = const [
    "Heroes",
    "Villanos",
    "Equipos",
    "Eventos",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Marvel DB"),
        backgroundColor: Colors.red,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CategoriaCard(
              text: category,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemsScreen(category: category),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
