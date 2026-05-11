
import 'package:flutter/material.dart';
import 'package:exercici05a/widgets/CirclePainter.dart';

class StatusCircle extends StatelessWidget {
  final bool isActive;
  const StatusCircle({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CirclePainter(isActive),
      size: const Size(24, 24),
    );
  }
  }