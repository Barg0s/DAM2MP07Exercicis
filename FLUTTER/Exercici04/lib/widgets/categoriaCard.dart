import 'package:exercici04/services/categories_service.dart';
import 'package:exercici04/services/details_service.dart';
import 'package:flutter/material.dart';

class CategoriaCard extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final Color color;
  final String logo;

  const CategoriaCard({
    super.key,
    required this.text,
    required this.logo,
    this.onTap,
    this.color = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withOpacity(0.15),
        child: SizedBox(
          width: 140,
          height: 190,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Image.network(
                      CategoriesService.getImageUrl(logo),
                      height: 70,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}