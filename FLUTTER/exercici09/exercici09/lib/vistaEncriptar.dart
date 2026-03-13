import 'package:flutter/material.dart';
import 'label.dart';
import 'arxius.dart';

class VistaEncriptar extends StatefulWidget {
  const VistaEncriptar({super.key});

  @override
  State<VistaEncriptar> createState() => _VistaEncriptarState();
}

class _VistaEncriptarState extends State<VistaEncriptar> {
  final Arxius arxius = Arxius();
  String filename = 'document.txt';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Label(text: "ENCRIPTAR ARXIU"),
          const SizedBox(height: 20),
          const Label(text: "Clau pública (RSA):"),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Clau publica',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () {
                  print("Selecciona pública");
                },
                child: const Text('SELECCIONA'),
              ),
            ],
          ),
          const Label(text: "Arxiu a encriptar"),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: filename, 
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () async {
                  await arxius.loadFileWithPicker();
                  setState(() {
                    filename = arxius.getPath();
                  });
                },
                child: const Text('Navega...'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(thickness: 0.5, color: Colors.grey),
          const SizedBox(height: 100),
          Center(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                print("ENCRIPTA ARXIU");
              },
              child: const Text('ENCRIPTA ARXIU'),
            ),
          ),
        ],
      ),
    );
  }
}
