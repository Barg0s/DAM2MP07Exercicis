import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/asymmetric/api.dart' as rsa;

import 'label.dart';

class VistaDesencriptar extends StatefulWidget {
  const VistaDesencriptar({super.key});

  @override
  State<VistaDesencriptar> createState() => _VistaDesencriptarState();
}

class _VistaDesencriptarState extends State<VistaDesencriptar> {
  String clauPrivadaPath = '';
  String arxiuXifratPath = '';
  String arxiuDesxifratPath = '';

  final TextEditingController clauCtrl = TextEditingController();
  final TextEditingController xifratCtrl = TextEditingController();
  final TextEditingController desxifratCtrl = TextEditingController();

  @override
  void dispose() {
    clauCtrl.dispose();
    xifratCtrl.dispose();
    desxifratCtrl.dispose();
    super.dispose();
  }

  void desencriptar() {
    if (clauPrivadaPath.isEmpty ||
        arxiuXifratPath.isEmpty ||
        arxiuDesxifratPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Si us plau, omple tots els camps.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final clauString = File(clauPrivadaPath).readAsStringSync();
      final parser = enc.RSAKeyParser();
      final clauPrivada = parser.parse(clauString) as rsa.RSAPrivateKey;

      final encriptador = enc.Encrypter(
        enc.RSA(privateKey: clauPrivada),
      );

      final bytesXifrats = File(arxiuXifratPath).readAsBytesSync();

      final textDesxifrat =
          encriptador.decrypt(enc.Encrypted(bytesXifrats));

      File(arxiuDesxifratPath).writeAsStringSync(textDesxifrat);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arxiu desencriptat correctament!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al desencriptar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

 @override
Widget build(BuildContext context) {
  return SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Label(text: "DESENCRIPTAR ARXIU"),
          const SizedBox(height: 20),

          // CLAU PRIVADA
          const Label(text: "Clau privada (RSA):"),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: clauCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Clau privada',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () async {
                  FilePickerResult? r =
                      await FilePicker.platform.pickFiles();

                  if (r != null) {
                    setState(() {
                      clauPrivadaPath = r.files.single.path!;
                      clauCtrl.text = clauPrivadaPath;
                    });
                  }
                },
                child: const Text('SELECCIONA'),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ARXIU XIFRAT
          const Label(text: "Arxiu xifrat (.enc):"),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: xifratCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Selecciona arxiu xifrat',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () async {
                  FilePickerResult? r =
                      await FilePicker.platform.pickFiles();

                  if (r != null) {
                    setState(() {
                      arxiuXifratPath = r.files.single.path!;
                      xifratCtrl.text = arxiuXifratPath;
                    });
                  }
                },
                child: const Text('NAVEGA...'),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // DESTÍ
          const Label(text: "Ruta destí:"),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: desxifratCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Selecciona ruta destí',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () async {
                  String? r = await FilePicker.platform.saveFile(
                    fileName: 'desencriptat.txt',
                  );

                  if (r != null) {
                    setState(() {
                      arxiuDesxifratPath = r;
                      desxifratCtrl.text = r;
                    });
                  }
                },
                child: const Text('GUARDA...'),
              ),
            ],
          ),

          const SizedBox(height: 8),
          const Divider(
            thickness: 0.5,
            color: Colors.grey,
          ),

          const SizedBox(height: 60),

          Center(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: desencriptar,
              child: const Text('DESENCRIPTA ARXIU'),
            ),
          ),
        ],
      ),
    ),
  );
}
}