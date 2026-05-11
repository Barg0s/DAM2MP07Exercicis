import 'package:flutter/material.dart';
import '../../models/serverModel.dart';

class ServerControlCard extends StatelessWidget {
  final ServerType serverType;
  final ServerStatus status;
  final int? port;

  final VoidCallback onStart;
  final VoidCallback onStop;

  const ServerControlCard({
    super.key,
    required this.serverType,
    required this.status,
    required this.port,
    required this.onStart,
    required this.onStop,
  });

  Widget _buildStatusWidget() {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case ServerStatus.running:
        color = Colors.green;
        text = "En funcionament";
        icon = Icons.check_circle;
        break;

      case ServerStatus.stopped:
        color = Colors.red;
        text = "Aturat";
        icon = Icons.stop_circle;
        break;

      case ServerStatus.restarting:
        color = Colors.orange;
        text = "Reiniciant...";
        icon = Icons.autorenew;
        break;

      case ServerStatus.error:
        color = Colors.grey;
        text = "Error";
        icon = Icons.error;
        break;
    }

    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(text),
      backgroundColor: color.withOpacity(0.2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.dns, color: Colors.orange),
                      const SizedBox(width: 8),

                      Text(
                        "Projecte ${serverType.name.toUpperCase()}",
                      ),

                      const SizedBox(width: 8),

                      _buildStatusWidget(),
                    ],
                  ),

                  if (port != null)
                    Text(
                      "Port: $port",
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),

            Row(
              children: [
                ElevatedButton.icon(
                  onPressed:
                      status == ServerStatus.running
                          ? null
                          : onStart,

                  icon: const Icon(Icons.play_arrow),
                  label: const Text("START"),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(width: 8),

                ElevatedButton.icon(
                  onPressed:
                      status == ServerStatus.stopped
                          ? null
                          : onStop,

                  icon: const Icon(Icons.stop),
                  label: const Text("STOP"),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}