import 'package:flutter/material.dart';
import '../widgets/item_tile.dart';
import 'detail_screen.dart';

class ItemsScreen extends StatelessWidget {
  final String category;

  const ItemsScreen({super.key, required this.category});

  final Map<String, List<Map<String, String>>> data = const {
    "Heroes": [
      {"name": "Spider-Man", "image": "spiderman"},
      {"name": "Iron Man", "image": "ironman"},
      {"name": "Thor", "image": "thor"},
    ],
    "Villanos": [
      {"name": "Thanos", "image": "thanos"},
      {"name": "Loki", "image": "loki"},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final items = data[category] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(category),
        backgroundColor: Colors.red,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ItemTile(
              name: item["name"]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailScreen(
                      name: item["name"]!,
                      image: item["image"]!,
                    ),
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
