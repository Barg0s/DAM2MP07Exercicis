import 'package:flutter/material.dart';

class PortRedirectWidget extends StatelessWidget {
  final TextEditingController controller;
  final bool isActive;

  final Function(bool) onToggle;

  const PortRedirectWidget({
    super.key,
    required this.controller,
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 2,
      ),

      child: Padding(
        padding: const EdgeInsets.all(8),

        child: Row(
          children: [
            const Icon(Icons.switch_access_shortcut),

            const SizedBox(width: 8),

            Expanded(
              child: TextField(
                controller: controller,

                decoration: const InputDecoration(
                  labelText: "Port destí",
                  border: OutlineInputBorder(),
                ),

                keyboardType: TextInputType.number,
              ),
            ),

            const SizedBox(width: 8),

            Switch(
              value: isActive,
              onChanged: onToggle,
            ),
          ],
        ),
      ),
    );
  }
}