import 'package:flutter/material.dart';

class CategoriaCard extends StatelessWidget {
  final String text;

  const CategoriaCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          splashColor: Colors.blue.withAlpha(10),
          onTap: () {
            debugPrint("CARD $text");
          },
          child: SizedBox(
            width: 300,
            height: 100,
            child: Center(
              child: Text(
                text,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
