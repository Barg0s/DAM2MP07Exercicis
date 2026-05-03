import 'package:flutter/material.dart';

import '../services/categories_service.dart';
import '../widgets/categoriaCard.dart';
import 'items_screen.dart';
import '../models/category.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      final data = await CategoriesService.getCategories();

      setState(() {
        categories = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading categories: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TITULO"),
        backgroundColor: Colors.red,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CategoriaCard(
                    text: category.name,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemsScreen(
                            category: category.name,
                            categoryId: category.id,
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
