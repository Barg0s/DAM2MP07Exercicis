import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:exercici05a/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

class StatusCanvasIndicator extends StatelessWidget {
  final bool isOnline;
  final double size;

  const StatusCanvasIndicator({
    super.key, 
    required this.isOnline, 
    this.size = 20.0
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _StatusPainter(isOnline: isOnline),
    );
  }
}

class _StatusPainter extends CustomPainter {
  final bool isOnline;
  _StatusPainter({required this.isOnline});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isOnline ? Colors.green : Colors.red
      ..style = PaintingStyle.fill;

    // Dibuja el círculo en el centro del canvas
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2), 
      size.width / 2, 
      paint
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}