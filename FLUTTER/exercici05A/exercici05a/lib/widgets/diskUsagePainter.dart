import 'dart:math';
import 'package:flutter/material.dart';

class DiskUsagePainter extends CustomPainter {
  final Map<String, int> folderSizes;

  DiskUsagePainter(this.folderSizes);

  @override
  void paint(Canvas canvas, Size size) {
    if (folderSizes.isEmpty) return;

    double total = folderSizes.values.fold(0, (s, i) => s + i);
    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = min(size.width, size.height) / 2;
    double startAngle = -pi / 2;

    final colors = _getColors();
    int i = 0;

    folderSizes.forEach((name, bytes) {
      double sweep = (bytes / total) * 2 * pi;

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = colors[i % colors.length];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        paint,
      );

      startAngle += sweep;
      i++;
    });

    // círculo interior (efecto donut)
    canvas.drawCircle(
      center,
      radius * 0.4,
      Paint()..color = Colors.white,
    );
  }

  List<Color> _getColors() {
    return [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.pink,
      Colors.indigo,
    ];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}