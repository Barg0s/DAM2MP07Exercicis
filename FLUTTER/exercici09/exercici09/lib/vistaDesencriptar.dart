import 'package:flutter/material.dart';
import 'label.dart';

class vistaDesencriptar extends StatelessWidget {
  const vistaDesencriptar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Label(text: "DESENCRIPTAR ARXIU"),
          const SizedBox(height: 20),
          const Label(text: "Clau privada (RSA):"),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '~/ssh/id_rsa',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () {
                  print("Selecciona privada");
                },
                child: const Text('SELECCIONA'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(thickness: 0.5, color: Colors.grey),
          const SizedBox(height: 100),
          Center(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                print("DESENCRIPTA ARXIU");
              },
              child: const Text('DESENCRIPTA ARXIU'),
            ),
          ),
        ],
      ),
    );
  }
}
