import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../widgets/item_tile.dart';
import 'detail_screen.dart';
import '../services/items_service.dart';

class ItemsScreen extends StatefulWidget {
  final String category;
  final int categoryId;

  const ItemsScreen({
    super.key,
    required this.category,
    required this.categoryId,
  });

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  List items = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  Future<void> loadItems() async {
    try {
      final data = await ItemsService.getItems(widget.categoryId);

      setState(() {
        items = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading items: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        backgroundColor: Colors.red,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ItemTile(
                    name: item["name"],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailScreen(
                            id: item["id"],
                            name: item["name"],
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
