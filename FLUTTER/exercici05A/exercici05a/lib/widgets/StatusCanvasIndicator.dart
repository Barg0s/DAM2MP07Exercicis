import 'package:flutter/material.dart';

class StatusIndicatorPainter extends CustomPainter {
  final bool isOnline;

  StatusIndicatorPainter(this.isOnline);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isOnline ? Colors.green : Colors.red
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}