import 'package:flutter/material.dart';
import '../services/details_service.dart';

class DetailScreen extends StatefulWidget {
  final int id;
  final String name;

  const DetailScreen({
    super.key,
    required this.id,
    required this.name,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Map<String, dynamic>? detail;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDetails();
  }

  Future<void> loadDetails() async {
    try {
      final data = await DetailsService.getDetail(widget.id);

      setState(() {
        detail = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading details: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        backgroundColor: Colors.red,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : detail == null
              ? const Center(
                  child: Text("No se encontraron detalles"),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      Image.network(
                        DetailsService.getImageUrl(detail!["image"]),
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 250,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Text("Imagen no disponible"),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      Text(
                        detail!["name"] ?? widget.name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          detail!["description"] ??
                              "Sin descripción disponible",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
