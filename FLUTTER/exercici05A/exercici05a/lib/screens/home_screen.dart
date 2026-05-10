import 'arxius.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'fileManagerScreen.dart';
import '../services/sshService.dart';
import '../services/storageService.dart';
import '../models/serverModel.dart';

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
  final _userController = TextEditingController();

  List<ServerModel> _favorites = []; // Lista para mostrar los favoritos
  String publicKeyPath = '';

  @override
  void initState() {
    super.initState();
    _loadFavorites(); // Cargar favoritos al iniciar
  }

  // Carga los servidores del archivo JSON
  Future<void> _loadFavorites() async {
    final path = await arxius.getDefaultDirectoryPath();
    final storage = StorageService(path);
    final servers = await storage.loadServers();
    setState(() {
      _favorites = servers;
    });
  }

  void _showError(String message, {Color color = Colors.red}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

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
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Requerit' : null,
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final sshService = SSHService();
        await sshService.connect(
          host: _serverController.text.trim(),
          port: int.parse(_portController.text),
          username: _userController.text.trim(), 
          keyPath: _keyController.text,
        );

        if (!mounted) return;
        Navigator.pop(context); // Cerrar loading

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FileManagerScreen(
              initialPath: '/',
              sshService: sshService,
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        _showError("Error de connexió: $e");
      }
    }
  }

  void _favorite() async {
    if (_formKey.currentState!.validate()) {
      final path = await arxius.getDefaultDirectoryPath();
      final storage = StorageService(path);
      
      final newServer = ServerModel(
        name: _nameController.text,
        host: _serverController.text.trim(),
        port: int.parse(_portController.text),
        username: _nameController.text, // Usando el nombre como usuario por defecto
        keyPath: _keyController.text,
      );

      _favorites.add(newServer);
      await storage.saveServers(_favorites);
      _loadFavorites(); // Recargar lista
      _showError("Servidor guardat!", color: Colors.green);
    }
  }

  void _delete() async {
    final path = await arxius.getDefaultDirectoryPath();
    final storage = StorageService(path);
    setState(() {
      _favorites.clear();
      _nameController.clear();
      _serverController.clear();
      _portController.clear();
      _keyController.clear();
    });
    await storage.saveServers([]);
    _showError("Favorits esborrats");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Contenedor del Formulario
            Container(
              width: 450,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: Form(
                key: _formKey,
                child: Column(

                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Configuració SSH", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    buildField("Nom Favorit:", _nameController), 
                    buildField("Usuari SSH:", _userController),  
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
                          icon: const Icon(Icons.delete_forever, color: Colors.red),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _favorite,
                          child: const Text("Afegir a favorits"),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: _connect,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                          child: const Text("Connectar"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text("SERVIDORS GUARDATS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const Divider(),
            // Lista de Favoritos
            Expanded(
              child: SizedBox(
                width: 450,
                child: _favorites.isEmpty
                    ? const Center(child: Text("No hi ha servidors guardats"))
                    : ListView.builder(
                        itemCount: _favorites.length,
                        itemBuilder: (context, index) {
                          final s = _favorites[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.dns, color: Colors.blue),
                              title: Text(s.name),
                              subtitle: Text("${s.host}:${s.port}"),
                              onTap: () {
                                setState(() {
                                  _nameController.text = s.name;
                                  _serverController.text = s.host;
                                  _portController.text = s.port.toString();
                                  _keyController.text = s.keyPath;
                                });
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}