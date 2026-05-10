import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:dartssh2/dartssh2.dart';

import '../services/sshService.dart';
import '../services/fileService.dart';
import '../models/serverModel.dart';

// --- MODELO DE DATOS ---
class FileModel {
  final String name;
  final String path;
  final int size;
  final bool isDirectory;
  final String permissions;
  final String owner;

  FileModel({
    required this.name,
    required this.path,
    required this.size,
    required this.isDirectory,
    this.permissions = "",
    this.owner = "",
  });

  double getRelativeSize(int totalSize) {
    if (totalSize == 0) return 0;
    return size / totalSize;
  }
}

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

  // --- LÓGICA DE NAVEGACIÓN Y LISTADO ---
  Future<void> _refreshFiles() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      String rawList = await _fileService.list(_currentPath);
      final lines = rawList.split('\n');
      List<Map<String, dynamic>> tempItems = [];

      for (var line in lines) {
        String l = line.trim();
        if (!l.startsWith('d') && !l.startsWith('-')) continue;

        final parts = l.split(RegExp(r'\s+'));
        if (parts.length >= 9) {
          // Buscamos la hora para limpiar el nombre del archivo
          int horaIndex = -1;
          for (int i = 0; i < parts.length; i++) {
            if (parts[i].contains(':')) {
              horaIndex = i;
              break;
            }
          }

          String name = (horaIndex != -1 && horaIndex + 1 < parts.length)
              ? parts.sublist(horaIndex + 1).join(' ')
              : parts.sublist(8).join(' ');

          name = name.trim();
          if (name == "." || name == "..") continue;

          tempItems.add({
            'name': name,
            'isDirectory': l.startsWith('d'),
            'permissions': parts[0],
            'size': parts[4],
            'owner': parts[2],
          });
        }
      }

      final type = await _fileService.detectServerType(_currentPath);

      setState(() {
        _items = tempItems;
        _serverType = type;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Error: $e", isError: true);
    }
  }

  // --- LÓGICA DEL BAOBAB ---
  void _mostrarBaobab() async {
    setState(() => _isLoading = true);
    try {
      var bytes = await widget.sshService.client.run("cd '$_currentPath' && du -sb *");
      String raw = utf8.decode(bytes);
      
      List<FileModel> carpetas = [];
      for (var line in raw.trim().split('\n')) {
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          carpetas.add(FileModel(
            name: parts.sublist(1).join(' '),
            size: int.tryParse(parts[0]) ?? 0,
            path: "",
            isDirectory: true,
          ));
        }
      }
      carpetas.sort((a, b) => b.size.compareTo(a.size));

      setState(() => _isLoading = false);
      _abrirDialogoBaobab(carpetas);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Error Baobab: $e", isError: true);
    }
  }

  void _abrirDialogoBaobab(List<FileModel> datos) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ús del disc (Baobab)"),
        content: SizedBox(
          width: 400,
          height: 400,
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: CustomPaint(
                  painter: DiskUsagePainter({for (var f in datos.take(6)) f.name: f.size}),
                  size: const Size(200, 200),
                ),
              ),
              const Divider(),
              Expanded(
                flex: 1,
                child: ListView.builder(
                  itemCount: datos.take(5).length,
                  itemBuilder: (context, i) => ListTile(
                    dense: true,
                    leading: Icon(Icons.circle, color: _getColors()[i % _getColors().length], size: 12),
                    title: Text(datos[i].name, overflow: TextOverflow.ellipsis),
                    trailing: Text("${(datos[i].size / 1024).toStringAsFixed(1)} KB"),
                  ),
                ),
              )
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tancar"))],
      ),
    );
  }

  // --- LÓGICA DE UPLOAD ---
  Future<void> _uploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        setState(() => _isLoading = true);
        File localFile = File(result.files.single.path!);
        String fileName = p.basename(localFile.path);
        
        final sftp = await widget.sshService.client.sftp();
        final remoteFile = await sftp.open('$_currentPath/$fileName', 
            mode: SftpFileOpenMode.create | SftpFileOpenMode.write);
        
        await remoteFile.write(localFile.openRead().cast());
        _showSnackBar("Fitxer '$fileName' pujat.");
        _refreshFiles();
      }
    } catch (e) {
      _showSnackBar("Error upload: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- ACCIONES DE ARCHIVO (Borrar/Renombrar/Info) ---
  void _showFileActions(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text("Informació"),
              onTap: () {
                Navigator.pop(context);
                _showDetails(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Reanomenar"),
              onTap: () {
                Navigator.pop(context);
                _renameItem(item['name']);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Esborrar"),
              onTap: () {
                Navigator.pop(context);
                _deleteItem(item['name']);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteItem(String name) async {
    await widget.sshService.client.run("rm -rf '$_currentPath/$name'");
    _refreshFiles();
  }

  Future<void> _renameItem(String oldName) async {
    TextEditingController c = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nou nom"),
        content: TextField(controller: c),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(onPressed: () async {
            await widget.sshService.client.run("mv '$_currentPath/$oldName' '$_currentPath/${c.text}'");
            Navigator.pop(context);
            _refreshFiles();
          }, child: const Text("Ok")),
        ],
      ),
    );
  }

  void _showDetails(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['name']),
        content: Text("Mida: ${item['size']} bytes\nPermisos: ${item['permissions']}\nPropietari: ${item['owner']}"),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tancar"))],
      ),
    );
  }

  // --- ACCIONES DE SERVIDOR ---
  Future<void> _handleServerAction(String action) async {
    String cmd = "";
    if (_serverType == ServerType.nodejs) {
      cmd = action == 'start' ? "cd '$_currentPath' && npm start &" : "pkill -f node";
    } else if (_serverType == ServerType.java) {
      cmd = action == 'start' ? "cd '$_currentPath' && java -jar *.jar &" : "pkill -f java";
    }
    await widget.sshService.client.run(cmd);
    _showSnackBar("Comanda $action enviada");
  }

  void _navigateTo(String name) {
    if (name == "..") {
      List<String> parts = _currentPath.split('/');
      parts.removeLast();
      _currentPath = parts.join('/') == "" ? "/" : parts.join('/');
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
        title: Text(_currentPath, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
        actions: [
          IconButton(icon: const Icon(Icons.pie_chart), onPressed: _mostrarBaobab),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshFiles),
        ],
      ),
      body: Column(
        children: [
          if (_serverType != ServerType.generic)
            Card(
              margin: const EdgeInsets.all(8),
              color: Colors.blue.shade50,
              child: ListTile(
                title: Text("Projecte ${_serverType.name.toUpperCase()}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(onPressed: () => _handleServerAction('start'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("START")),
                    const SizedBox(width: 5),
                    ElevatedButton(onPressed: () => _handleServerAction('stop'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("STOP")),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final item = _items[i];
                    return ListTile(
                      leading: Icon(item['isDirectory'] ? Icons.folder : Icons.description, 
                                    color: item['isDirectory'] ? Colors.amber : Colors.grey),
                      title: Text(item['name']),
                      subtitle: Text(item['permissions']),
                      onTap: () => item['isDirectory'] ? _navigateTo(item['name']) : _showFileActions(item),
                      onLongPress: () => _showFileActions(item),
                    );
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadFile,
        child: const Icon(Icons.upload_file),
      ),
    );
  }
}

// --- PAINTER ---
List<Color> _getColors() => [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple, Colors.cyan];

class DiskUsagePainter extends CustomPainter {
  final Map<String, int> folderSizes;
  DiskUsagePainter(this.folderSizes);

  @override
  void paint(Canvas canvas, Size size) {
    if (folderSizes.isEmpty) return;
    double total = folderSizes.values.fold(0, (s, i) => s + i);
    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = min(size.width, size.height) / 2;
    double startAngle = -pi / 2;

    int i = 0;
    folderSizes.forEach((name, bytes) {
      double sweep = (bytes / total) * 2 * pi;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep, true, 
                     Paint()..color = _getColors()[i % _getColors().length]);
      startAngle += sweep;
      i++;
    });
    canvas.drawCircle(center, radius * 0.4, Paint()..color = Colors.white);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}