import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'package:exercici05a/widgets/StatusCanvasIndicator.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:exercici05a/models/models.dart' hide ServerStatus;
import 'package:exercici05a/models/serverStatus.dart';

class ServerStatusWidget extends StatelessWidget {
  final ServerStatus status;

  const ServerStatusWidget({
    super.key,
    required this.status,
  });

  Color _getColor() {
    switch (status) {
      case ServerStatus.running:
        return Colors.green;

      case ServerStatus.stopped:
        return Colors.grey;

      case ServerStatus.restarting:
        return Colors.orange;

      case ServerStatus.error:
        return Colors.red;
    }
  }

  String _getText() {
    switch (status) {
      case ServerStatus.running:
        return "En funcionament";

      case ServerStatus.stopped:
        return "Aturat";

      case ServerStatus.restarting:
        return "Reiniciant";

      case ServerStatus.error:
        return "Error";
    }
  }

  IconData _getIcon() {
    switch (status) {
      case ServerStatus.running:
        return Icons.check_circle;

      case ServerStatus.stopped:
        return Icons.stop_circle;

      case ServerStatus.restarting:
        return Icons.restart_alt;

      case ServerStatus.error:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          _getIcon(),
          color: _getColor(),
        ),
        title: Text(_getText()),
      ),
    );
  }
}