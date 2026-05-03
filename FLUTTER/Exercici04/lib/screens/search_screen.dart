import 'package:flutter/material.dart';

import '../services/search_service.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List results = [];
  bool isLoading = false;

  Future<void> searchItems(String text) async {
    if (text.isEmpty) {
      setState(() {
        results = [];
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final data = await SearchService.search(text);

      setState(() {
        results = data;
        isLoading = false;
      });
    } catch (e) {
      print("Search error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search"),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search items...",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: searchItems,
            ),
          ),

          if (isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: results.isEmpty
                  ? const Center(child: Text("No results"))
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final item = results[index];

                        return ListTile(
                          title: Text(item["name"]),
                          trailing: const Icon(Icons.arrow_forward),
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
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}
