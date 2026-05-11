import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'package:exercici05a/widgets/StatusCanvasIndicator.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';

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