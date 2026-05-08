import 'package:flutter/material.dart';
import '../models/detail.dart';
import '../services/details_service.dart';

class DetailCard extends StatelessWidget {
  final Detail detail;

  const DetailCard({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              detail.name ?? "Sense nom",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // IMATGE
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Image.network(
                    DetailsService.getImageUrl(detail.image),
                    width: constraints.maxWidth,
                    height: constraints.maxWidth * 0.8,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: constraints.maxWidth,
                        height: constraints.maxWidth * 0.8,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Text("Imatge no disponible"),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),

            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                const Text(
                  "Primera aparició:",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(detail.firstAppearance ?? "Desconegut"),
              ],
            ),

            const SizedBox(height: 15),

            const Text(
              "Descripció",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),

            Text(
              detail.description ?? "Sense descripció disponible",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
