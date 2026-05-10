import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:dartssh2/dartssh2.dart';
import 'package:path_provider/path_provider.dart';

import '../services/sshService.dart';
import '../services/fileService.dart';
import '../models/serverModel.dart';

import '../models/fileModel.dart';
import '../widgets/diskUsagePainter.dart';

// --- MODELO DE DATOS INTERNO ---


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
Future<void> _downloadFile(String name) async {
    // 1. Mostramos indicador de carga o SnackBar de inicio
    _showSnackBar("Iniciant descàrrega: $name...");
    
    try {
      // 2. Abrimos conexión SFTP
      final sftp = await widget.sshService.client.sftp();
      
      // 3. Construimos la ruta remota absoluta usando el contexto POSIX
      // Esto evita problemas con las barras (\ vs /)
      final posix = p.Context(style: p.Style.posix);
      final String remotePath = posix.join(_currentPath, name);
      
      // 4. Abrimos el archivo remoto
      final remoteFile = await sftp.open(remotePath);
      
      // 5. Leemos los bytes (en chunks para no colapsar la memoria)
      final List<int> bytes = [];
      await for (var chunk in remoteFile.read()) {
        bytes.addAll(chunk);
      }
      
      // 6. Obtenemos la ruta local (Downloads es difícil en iOS/Android, mejor Documents)
      final dir = await getApplicationDocumentsDirectory();
      final localPath = p.join(dir.path, name);
      
      // 7. Escribimos el archivo en el móvil
      final localFile = File(localPath);
      await localFile.writeAsBytes(bytes);
      
      _showSnackBar("Fet! Descarregat a Documents/$name");
    } catch (e) {
      print("Error detallado SFTP: $e");
      _showSnackBar("Error: No s'ha trobat el fitxer al servidor", isError: true);
    }
  }
  // --- NAVEGACIÓN Y LISTADO ---
  Future<void> _refreshFiles() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Obtenemos el listado y decodificamos bytes a String
      var bytes = await widget.sshService.client.run("ls -ll '$_currentPath'");
      String rawList = utf8.decode(bytes);
      
      final lines = rawList.split('\n');
      List<Map<String, dynamic>> tempItems = [];

      for (var line in lines) {
        String l = line.trim();
        if (!l.startsWith('d') && !l.startsWith('-')) continue;

        final parts = l.split(RegExp(r'\s+'));
        if (parts.length >= 9) {
          // Buscamos la hora para saltarla y obtener el nombre limpio
          int horaIndex = -1;
          for (int i = 0; i < parts.length; i++) {
            if (parts[i].contains(':')) { horaIndex = i; break; }
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

  void _navigateTo(String name) {
    if (name == "..") {
      if (_currentPath == widget.initialPath || _currentPath == "/") return;
      List<String> parts = _currentPath.split('/');
      parts.removeLast();
      _currentPath = parts.join('/') == "" ? "/" : parts.join('/');
    } else {
      _currentPath = _currentPath == "/" ? "/$name" : "$_currentPath/$name";
    }
    _refreshFiles();
  }

  // --- ANALIZADOR BAOBAB ---
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
            isDirectory: true,
          ));
        }
      }
      carpetas.sort((a, b) => b.size.compareTo(a.size));

      setState(() => _isLoading = false);
      _dialogoBaobab(carpetas);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Error Baobab: $e", isError: true);
    }
  }
    List<Color> _getColors() => [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple, Colors.cyan];


  void _dialogoBaobab(List<FileModel> datos) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Analitzador de disc"),
        content: SizedBox(
          width: 400,
          height: 450,
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: CustomPaint(
                  painter: DiskUsagePainter({for (var f in datos.take(5)) f.name: f.size}),
                  size: const Size(200, 200),
                ),
              ),
              const Divider(),
              Expanded(
                flex: 1,
                child: ListView.builder(
                  itemCount: datos.length > 5 ? 5 : datos.length,
                  itemBuilder: (context, i) => ListTile(
                    dense: true,
                    leading: Icon(Icons.circle, color: _getColors()[i % _getColors().length], size: 12),
                    title: Text(datos[i].name, style: const TextStyle(fontSize: 11)),
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

  // --- GESTIÓN DE ARCHIVOS ---
Future<void> _uploadFile() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    
    if (result != null && result.files.single.path != null) {
      setState(() => _isLoading = true);
      
      File localFile = File(result.files.single.path!);
      String fileName = p.basename(localFile.path); // Se declara aquí
      
      final sftp = await widget.sshService.client.sftp();
      final remoteFile = await sftp.open('$_currentPath/$fileName', 
          mode: SftpFileOpenMode.create | SftpFileOpenMode.write);
      
      await remoteFile.write(localFile.openRead().cast());
      _showSnackBar("Pujat: $fileName");

      // EL UNZIP DEBE IR AQUÍ DENTRO (donde fileName existe)
      if (fileName.endsWith('.zip')) {
        // Ejecutamos unzip en el servidor
        await widget.sshService.client.run("cd '$_currentPath' && unzip -o '$fileName'");
        _showSnackBar("Arxiu descomprimit automàticament");
      }
      
      // Refrescamos una sola vez al final de todo el proceso
      _refreshFiles();
    }
  } catch (e) {
    _showSnackBar("Error upload: $e", isError: true);
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
  void _showFileActions(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text("Informació"),
              onTap: () { Navigator.pop(context); _showDetails(item); },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Reanomenar"),
              onTap: () { Navigator.pop(context); _renameItem(item['name']); },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Esborrar"),
              onTap: () { Navigator.pop(context); _deleteItem(item['name']); },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text("Descarregar"),
              onTap: () { Navigator.pop(context); _downloadFile(item['name']); },
            ),	
          ],
        ),
      ),
    );
  }

  Future<void> _deleteItem(String name) async {
    await widget.sshService.client.run("rm -rf '$_currentPath/$name'");
    _refreshFiles();
    _showSnackBar("Eliminat: $name");
  }

  Future<void> _renameItem(String oldName) async {
    TextEditingController c = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nou nom"),
        content: TextField(controller: c),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancela")),
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
        content: Text("Mida: ${item['size']} B\nPermisos: ${item['permissions']}\nPropietari: ${item['owner']}"),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tancar"))],
      ),
    );
  }

  // --- CONTROL SERVIDOR ---
  Future<void> _handleServerAction(String action) async {
    String cmd = "";
    if (_serverType == ServerType.nodejs) {
      cmd = action == 'start' ? "cd '$_currentPath' && npm start &" : "pkill -f node";
    } else if (_serverType == ServerType.java) {
      cmd = action == 'start' ? "cd '$_currentPath' && java -jar *.jar &" : "pkill -f java";
    }
    await widget.sshService.client.run(cmd);
    _showSnackBar("Acció $action enviada");
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentPath == widget.initialPath,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _navigateTo("..");
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_currentPath == widget.initialPath) Navigator.pop(context);
              else _navigateTo("..");
            },
          ),
          title: Text(_currentPath, style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
          actions: [
            IconButton(icon: const Icon(Icons.pie_chart_outline), onPressed: _mostrarBaobab),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshFiles),
          ],
        ),
        body: Column(
          children: [
            if (_serverType != ServerType.generic)
              Card(
                margin: const EdgeInsets.all(10),
                color: Colors.orange.shade50,
                child: ListTile(
                  leading: const Icon(Icons.dns, color: Colors.orange),
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
                        subtitle: Text("${item['permissions']} | ${item['size']} B"),
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
      ),
    );
  }
}
