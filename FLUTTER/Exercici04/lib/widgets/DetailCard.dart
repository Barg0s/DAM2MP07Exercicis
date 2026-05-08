import 'package:flutter/material.dart';
import '../models/detail.dart';
import '../services/details_service.dart';

class DetailCard extends StatelessWidget {
  final Detail detail;

  const DetailCard({
    super.key,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 👤 NOM
            Center(
              child: Text(
                detail.name ?? "Sense nom",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // IMATGE
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                DetailsService.getImageUrl(detail.image),
                height: 260,
                width: 260,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 260,
                    width: 260,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Text("Imatge no disponible"),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),

            //PRIMERA APARICIO
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today,
                    size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  "Primera aparició:",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                Text(
                  detail.firstAppearance ?? "Desconegut",
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Align(
              alignment: Alignment.center,
              child: Text(
                "Descripció",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              detail.description ?? "Sense descripció disponible",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}