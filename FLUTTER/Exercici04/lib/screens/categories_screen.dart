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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "BARGADOS DB",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 2;

                if (constraints.maxWidth < 600) {
                  crossAxisCount = 1;
                } else if (constraints.maxWidth < 900) {
                  crossAxisCount = 2;
                } else {
                  crossAxisCount = 2;
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: categories.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 3,
                  ),
                  itemBuilder: (context, index) {
                    final category = categories[index];

                    return CategoriaCard(
                      text: category.name,
                      logo: category.logo,
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
                    );
                  },
                );
              },
            ),
    );
  }
}
