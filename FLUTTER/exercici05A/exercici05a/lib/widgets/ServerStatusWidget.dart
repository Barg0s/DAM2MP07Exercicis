import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'package:exercici05a/widgets/StatusCanvasIndicator.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:exercici05a/models/models.dart';

class ServerStatusWidget extends StatelessWidget {
  final String status; // 'funcionant', 'aturat', 'reiniciant', 'error'

  const ServerStatusWidget({super.key, required this.status});

  Color _getStatusColor() {
    switch (status) {
      case 'funcionant': return Colors.green;
      case 'aturat': return Colors.orange;
      case 'reiniciant': return Colors.blue;
      case 'error': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor()),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusCanvasIndicator(isOnline: status == 'funcionant', size: 10),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: TextStyle(color: _getStatusColor(), fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}