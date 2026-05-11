import 'package:exercici05a/widgets/StatusCanvasIndicator.dart';
import 'package:flutter/material.dart';

class ServerIndicator extends StatelessWidget {
  final bool online;

  const ServerIndicator({
    super.key,
    required this.online,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(
        painter: StatusIndicatorPainter(online),
      ),
    );
  }
}