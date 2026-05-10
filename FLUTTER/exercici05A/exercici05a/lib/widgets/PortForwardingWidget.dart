import 'package:flutter/material.dart';

class PortForwardingWidget extends StatelessWidget {
  final int targetPort;
  final bool isActive;
  final Function(bool) onToggle;

  const PortForwardingWidget({
    super.key,
    required this.targetPort,
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.alt_route,
          color: isActive ? Colors.blue : Colors.grey,
        ),
        title: Text("Redirecció Port 80 → $targetPort"),
        subtitle: Text("Cap al port intern: $targetPort"),
        trailing: Switch(
          value: isActive,
          onChanged: onToggle,
        ),
      ),
    );
  }
}