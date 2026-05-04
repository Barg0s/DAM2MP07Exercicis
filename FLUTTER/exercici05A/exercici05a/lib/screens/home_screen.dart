import 'arxius.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final Arxius arxius = Arxius();

  final _nameController = TextEditingController();
  final _serverController = TextEditingController();
  final _portController = TextEditingController();
  final _keyController = TextEditingController();

  String publicKeyPath = '';

  Widget buildField(
    String label,
    TextEditingController controller, {
    Widget? action,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              readOnly: readOnly,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Requerit' : null,
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 10),
            action,
          ]
        ],
      ),
    );
  }

  void _connect() async {
    if (_formKey.currentState!.validate()) {
      try {
        final socket = await SSHSocket.connect(
          _serverController.text.trim(),
          int.parse(_portController.text),
        );

        final keyData = await File(_keyController.text).readAsString();
        final keys = SSHKeyPair.fromPem(keyData);

        final client = SSHClient(
          socket,
          username: _nameController.text,
          identities: keys,
        );

        final result = await client.run('ls');
        final output = String.fromCharCodes(result);

        print(output);

        client.close();
      } catch (e) {
        print("Error: $e");
      }
    }
  }

  void _favorite() {
    print("Favorito");
  }

  void _delete() {
    print("Eliminar");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Configuració SSH",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                buildField("Nom:", _nameController),
                buildField("Servidor:", _serverController),
                buildField("Port:", _portController),

                buildField(
                  "Clau:",
                  _keyController,
                  readOnly: true,
                  action: OutlinedButton(
                    onPressed: () async {
                      await arxius.loadPrivateKey();
                      setState(() {
                        publicKeyPath = arxius.getPath();
                        _keyController.text = publicKeyPath;
                      });
                    },
                    child: const Text('SELECCIONA'),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    IconButton(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                      ),
                    ),

                    const SizedBox(width: 10),

                    ElevatedButton(
                      onPressed: _favorite,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black,
                      ),
                      child: const Text("Afegir a favorits"),
                    ),

                    const Spacer(),

                    ElevatedButton(
                      onPressed: _connect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                      child: const Text("Connectar"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
