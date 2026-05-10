// lib/screens/file_manager_screen.dart
import 'package:flutter/material.dart';
import '../services/sshService.dart';
import '../services/fileService.dart';
import '../models/serverModel.dart';

class FileManagerScreen extends StatefulWidget {
  final String initialPath;
  final SSHService sshService;

  const FileManagerScreen({
    super.key,
    required this.initialPath,
    required this.sshService,
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

  // Carga archivos y detecta si hay un servidor (Node/Java)
Future<void> _refreshFiles() async {
  setState(() => _isLoading = true);
  try {
    // 1. Obtenemos el listado mediante SSH
    // Usamos -la para ver todo, pero el parsing filtrará la basura
    String rawList = await _fileService.list(_currentPath);
    
    print("--- DEBUG: BRUTO RECIBIDO ---");
    print(rawList);

    final lines = rawList.split('\n');
    List<Map<String, dynamic>> tempItems = [];

    for (var line in lines) {
      String l = line.trim();

      // FILTRO CRÍTICO: 
      // Si la línea no empieza por 'd' (directorio) o '-' (archivo), es BASURA.
      // Esto eliminará los mensajes de error "ls: cannot access..." y las horas sueltas.
      if (!l.startsWith('d') && !l.startsWith('-')) {
        continue;
      }

      final parts = l.split(RegExp(r'\s+'));

      // En un 'ls -l' de Linux, el nombre real empieza en el índice 8.
      if (parts.length >= 9) {
        // Unimos el resto por si el nombre tiene espacios (ej: "Mi Proyecto.zip")
          final String name = parts.last;

        // Ignoramos los punteros al mismo directorio
        if (name == '.' || name == '..') continue;

        tempItems.add({
          'name': name,
          'isDirectory': l.startsWith('d'),
          'permissions': parts[0],
          'size': parts[4],
          'owner': parts[2],
        });
      }
    }

    // 2. DETECCIÓN DE PROYECTO
    // Esto es lo que hace tu amigo: detectar si hay package.json o .jar
    final type = await _fileService.detectServerType(_currentPath);

    setState(() {
      _items = tempItems;
      _serverType = type;
      _isLoading = false;
    });
    
    print("DEBUG: Lista procesada con ${_items.length} elementos. Tipo: $_serverType");

  } catch (e) {
    setState(() => _isLoading = false);
    print("ERROR EN REFRESH: $e");
    _showSnackBar("Error de llistat: $e", isError: true);
  }
}
  // Gestión de procesos START / STOP
  Future<void> _handleServerAction(String action) async {
    String command = '';
    String projectName = _currentPath.split('/').last;

    if (_serverType == ServerType.nodejs) {
      command = action == 'start' 
          ? 'cd $_currentPath && npm start &' 
          : 'pkill -f "$projectName"';
    } else if (_serverType == ServerType.java) {
      command = action == 'start' 
          ? 'cd $_currentPath && java -jar *.jar &' 
          : 'pkill -f "java"';
    }

    try {
      await widget.sshService.client.run(command);
      _showSnackBar("Comando ${action.toUpperCase()} enviat a $projectName");
    } catch (e) {
      _showSnackBar("Error en l'operació: $e", isError: true);
    }
  }

  void _navigateTo(String name) {
    if (name == "..") {
      List<String> parts = _currentPath.split('/');
      parts.removeLast();
      _currentPath = parts.isEmpty || (parts.length == 1 && parts[0] == "") ? "/" : parts.join('/');
    } else {
      _currentPath = _currentPath == "/" ? "/$name" : "$_currentPath/$name";
    }
    _refreshFiles();
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPath, style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
        actions: [
          IconButton(icon: const Icon(Icons.pie_chart), onPressed: () { /* Aquí irá el Baobab */ }),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshFiles),
        ],
      ),
      body: Column(
        children: [
          // PANEL DE CONTROL DE SERVIDOR (Aparece si detecta Node/Java)
          if (_serverType != ServerType.generic)
            Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.dns, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text("Projecte ${_serverType.name.toUpperCase()} detectat",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _handleServerAction('start'),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text("START"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _handleServerAction('stop'),
                    icon: const Icon(Icons.stop, size: 18),
                    label: const Text("STOP"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  ),
                ],
              ),
            ),

          // LISTA DE ARCHIVOS
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
                        color: item['isDirectory'] ? Colors.amber.shade700 : Colors.grey,
                      ),
                      title: Text(item['name']),
                      subtitle: Text("${item['permissions']} | ${item['owner']}"),
                      onTap: () => item['isDirectory'] ? _navigateTo(item['name']) : _showFileActions(item),
                    );
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () { /* Lógica de Upload ZIP */ },
        child: const Icon(Icons.upload_file),
      ),
    );
  }

  void _showFileActions(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.info_outline), title: const Text("Informació"), onTap: () {}),
            ListTile(leading: const Icon(Icons.edit), title: const Text("Reanomenar"), onTap: () {}),
            ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text("Esborrar"), onTap: () {}),
          ],
        ),
      ),
    );
  }
}