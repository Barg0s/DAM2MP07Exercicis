// lib/screens/file_manager_screen.dart
import 'package:flutter/material.dart';
import '../services/sshService.dart';
import '../services/fileService.dart';
import '../models/serverModel.dart';
import 'arxius.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';
// Importa tus widgets personalizados aquí
// import '../widgets/custom_widgets.dart'; 
import '../widgets/IndentedListGroup.dart';
import '../widgets/PortForwardingWidget.dart';
import '../widgets/ServerStatusWidget.dart';
import '../widgets/StatusCanvasIndicator.dart';
import '../widgets/customLabeledInput.dart';

class FileManagerScreen extends StatefulWidget {
  final String initialPath;
  final SSHService sshService;

  const FileManagerScreen({
    super.key, 
    required this.initialPath, 
    required this.sshService
  });

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  late FileService _fileService;
  late String _currentPath;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  ServerType _serverType = ServerType.generic;

  @override
  void initState() {
    super.initState();
    _fileService = FileService(widget.sshService);
    _currentPath = widget.initialPath;
    _refreshFiles();
  }

  // Método principal para leer archivos reales mediante SSH
  Future<void> _refreshFiles() async {
    setState(() => _isLoading = true);
    try {
      // 1. Listar archivos
      final rawList = await _fileService.list(_currentPath);
      
      // 2. Parsear el resultado de 'ls -la' (esto es una simplificación)
      // En una app real, podrías usar comandos más limpios como 'ls -F'
      final lines = rawList.split('\n').skip(1); // Saltar la línea de 'total'
      
      List<Map<String, dynamic>> tempItems = [];
      for (var line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length < 9) continue;
        
        final name = parts.sublist(8).join(' ');
        if (name == '.') continue; // Ignorar directorio actual

        tempItems.add({
          'name': name,
          'isDirectory': line.startsWith('d'),
          'permissions': parts[0],
          'owner': '${parts[2]}:${parts[3]}',
        });
      }

      // 3. Detectar si es un servidor (NodeJS/Java)
      final type = await _fileService.detectServerType(_currentPath);

      setState(() {
        _items = tempItems;
        _serverType = type;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al llistar fitxers: $e")),
      );
    }
  }

  void _navigateTo(String name) {
    if (name == "..") {
      // Lógica para subir de nivel
      List<String> parts = _currentPath.split('/');
      parts.removeLast();
      if (parts.isEmpty || (parts.length == 1 && parts[0] == "")) {
        _currentPath = "/";
      } else {
        _currentPath = parts.join('/');
      }
    } else {
      _currentPath = _currentPath == "/" ? "/$name" : "$_currentPath/$name";
    }
    _refreshFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPath, style: const TextStyle(fontSize: 14)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshFiles),
        ],
      ),
      body: Column(
        children: [
          // Sección de servidor detectado (Requisito MD)
          if (_serverType != ServerType.generic)
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.blue.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Servidor ${_serverType.name.toUpperCase()} detectat"),
                  // Aquí iría tu ServerStatusWidget
                  const Icon(Icons.dns, color: Colors.blue),
                ],
              ),
            ),
          
          // Lista de archivos
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return ListTile(
                      leading: Icon(
                        item['isDirectory'] ? Icons.folder : Icons.insert_drive_file,
                        color: item['isDirectory'] ? Colors.orange : Colors.grey,
                      ),
                      title: Text(item['name']),
                      subtitle: Text("${item['permissions']} | ${item['owner']}"),
                      onTap: () {
                        if (item['isDirectory']) {
                          _navigateTo(item['name']);
                        } else {
                          // Mostrar información del archivo (Requisito MD)
                          _showFileActions(item);
                        }
                      },
                    );
                  },
                ),
          ),
        ],
      ),
      // Botón para subir archivos (Requisito MD)
      floatingActionButton: FloatingActionButton(
        onPressed: () { /* Lógica para llamar a FilePicker y FileService.uploadItem */ },
        child: const Icon(Icons.upload_file),
      ),
    );
  }

  void _showFileActions(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("Informació i permisos"),
            onTap: () {
              Navigator.pop(context);
              // Aquí usarías tu widget personalizado de "Camp de text amb títol"
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("Canviar nom"),
            onTap: () { /* Lógica de rename */ },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text("Esborrar"),
            onTap: () { /* Lógica de delete */ },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text("Descarregar"),
            onTap: () { /* Lógica de SFTP download */ },
          ),
        ],
      ),
    );
  }
}