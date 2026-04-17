import 'package:flutter/material.dart';

class DetailScreen extends StatelessWidget {
  final String name;
  final String image;

  const DetailScreen({
    super.key,
    required this.name,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.red,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // Imagen simulada (luego la cambias por GET desde Node)
          Container(
            height: 250,
            width: double.infinity,
            color: Colors.grey[300],
            child: Center(
              child: Text(
                image.toUpperCase(),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            name,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Aquí irá la descripción del personaje Marvel. Luego lo conectas con NodeJS.",
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
