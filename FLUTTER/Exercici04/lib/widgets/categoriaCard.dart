import 'package:flutter/material.dart';

class CategoriaCard extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const CategoriaCard({
    super.key,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      elevation: 3,
      child: InkWell(
        splashColor: Colors.red.withOpacity(0.2),
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          height: 90,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.category, color: Colors.red),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
