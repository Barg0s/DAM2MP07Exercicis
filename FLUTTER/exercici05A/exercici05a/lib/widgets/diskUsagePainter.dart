import 'dart:math';
import 'package:flutter/material.dart';

class DiskUsagePainter extends CustomPainter {
  final Map<String, int> folderSizes;

  DiskUsagePainter(this.folderSizes);

  @override
  void paint(Canvas canvas, Size size) {
    if (folderSizes.isEmpty) return;

    final double totalSize = folderSizes.values.fold(0, (sum, item) => sum + item);
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = min(size.width, size.height) / 2;

    double startAngle = 0;
    final List<Color> colors = [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple];

    int i = 0;
    folderSizes.forEach((name, bytes) {
      final sweepAngle = (bytes / totalSize) * 2 * pi;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      // Dibujamos el arco proporcional al tamaño
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
      i++;
    });

    // Dibujar un círculo blanco en el centro para estilo "Donut"
    canvas.drawCircle(center, radius * 0.4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}