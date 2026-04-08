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
  String publicKeyPath = '';

  // Controllers per als TextFields
  final TextEditingController fileController = TextEditingController();
  final TextEditingController publicKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fileController.text = filename;
    publicKeyController.text = publicKeyPath;
  }

  @override
  void dispose() {
    fileController.dispose();
    publicKeyController.dispose();
    super.dispose();
  }

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
                  controller: publicKeyController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Clau publica',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () async {
                  await arxius.loadPublicKey();
                  setState(() {
                    publicKeyPath = arxius.getPath();
                    publicKeyController.text = publicKeyPath;
                  });
                },
                child: const Text('SELECCIONA'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          const Label(text: "Arxiu a encriptar"),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: fileController,
                  readOnly: true, 
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Selecciona un fitxer',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () async {
                  await arxius.loadFileWithPicker();
                  setState(() {
                    filename = arxius.getPath();
                    fileController.text = filename;
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
              onPressed: () async {
                // Encripta l'arxiu seleccionat amb la clau pública
               await arxius.encriptarArxiu(publicKeyPath, filename);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Arxiu encriptat correctament!")),
                );
              },
              child: const Text('ENCRIPTA ARXIU'),
            ),
          ),
        ],
      ),
    );
  }
}