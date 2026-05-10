import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p; 
import 'package:dartssh2/dartssh2.dart';
import 'package:path_provider/path_provider.dart';

import '../services/sshService.dart';
import '../services/fileService.dart';
import '../models/serverModel.dart';

// --- CONTEXTO DE RUTA LINUX (Evita el error de las barras \ en Windows) ---
final linuxPath = p.Context(style: p.Style.posix);

// --- WIDGET PERSONALIZADO: CÍRCULO CANVAS (Requisito Enunciado) ---
class StatusCanvasIndicator extends StatelessWidget {
  final bool isOnline;
  final double size;
  const StatusCanvasIndicator({super.key, required this.isOnline, this.size = 20.0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _StatusPainter(isOnline: isOnline),
    );
  }
}

class _StatusPainter extends CustomPainter {
  final bool isOnline;
  _StatusPainter({required this.isOnline});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isOnline ? Colors.green : Colors.red
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- PANTALLA PRINCIPAL ---
class FileManagerScreen extends StatefulWidget {
  final String initialPath;
  final SSHService sshService;
  const FileManagerScreen({super.key, required this.initialPath, required this.sshService});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}


class _FileManagerScreenState extends State<FileManagerScreen> {
  late FileService _fileService;
  late String _currentPath;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  ServerType _serverType = ServerType.generic;

  bool _isServerRunning = false;
  bool _isPortForwarded = false;
  dynamic _forwardHandle;

  @override
  void initState() {
    super.initState();
    _fileService = FileService(widget.sshService);
    _currentPath = widget.initialPath;
    _refreshFiles();
  }

  // --- NAVEGACIÓN (Forzando Estilo Linux) ---
  void _navigateTo(String name) {
    if (name == "..") {
      if (_currentPath == widget.initialPath || _currentPath == "/") return;
      _currentPath = linuxPath.dirname(_currentPath);
    } else {
      _currentPath = linuxPath.join(_currentPath, name);
    }
    _refreshFiles();
  }

  // --- CONTROL DE SERVIDOR MEJORADO ---
  Future<void> _checkServerStatus() async {
    String cmd = _serverType == ServerType.nodejs ? "pgrep -f node" : "pgrep -f java";
    try {
      final result = await widget.sshService.client.run(cmd);
      final output = utf8.decode(result).trim();
      if (mounted) setState(() => _isServerRunning = output.isNotEmpty);
    } catch (e) {
      if (mounted) setState(() => _isServerRunning = false);
    }
  }

  Future<void> _handleServerAction(String action) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const AlertDialog(
        content: Row(children: [CircularProgressIndicator(), SizedBox(width: 20), Text("Processant...")]),
      ),
    );

    try {
      String cmd = "";
      if (_serverType == ServerType.nodejs) {
        cmd = (action == 'start') 
            ? "cd '$_currentPath' && nohup npm start > /dev/null 2>&1 &" 
            : "pkill -f node";
      } else {
        cmd = (action == 'start') 
            ? "cd '$_currentPath' && nohup java -jar *.jar > /dev/null 2>&1 &" 
            : "pkill -f java";
      }

      await widget.sshService.client.run(cmd);
      await Future.delayed(const Duration(seconds: 3)); // Espera para que Linux registre el proceso
      await _checkServerStatus();

      if (mounted) Navigator.pop(context);
      _showSnackBar("Servidor ${action == 'start' ? 'encès' : 'aturat'}");
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar("Error: $e", isError: true);
    }
  }

  // --- REDIRECCIÓN Y DESCARGAS ---
  Future<void> _togglePortForwarding(bool value) async {
    try {
      if (value) {
        _forwardHandle = await widget.sshService.client.forwardLocal('127.0.0.1', 80);
        _showSnackBar("Túnel obert a localhost:8080");
      } else {
        await _forwardHandle?.close();
        _forwardHandle = null;
        _showSnackBar("Túnel tancat");
      }
      setState(() => _isPortForwarded = value);
    } catch (e) {
      _showSnackBar("Error: El servidor ha d'estar START", isError: true);
      setState(() => _isPortForwarded = false);
    }
  }

  Future<void> _downloadFile(String name) async {
    try {
      _showSnackBar("Baixant $name...");
      final sftp = await widget.sshService.client.sftp();
      final remoteFile = await sftp.open(linuxPath.join(_currentPath, name));
      
      final List<int> bytes = [];
      await for (var chunk in remoteFile.read()) { bytes.addAll(chunk); }
      
      final dir = await getApplicationDocumentsDirectory();
      final localFile = File(p.join(dir.path, name)); 
      await localFile.writeAsBytes(bytes);
      _showSnackBar("Guardat a Documents de l'App");
    } catch (e) { _showSnackBar("Error: $e", isError: true); }
  }

  // --- GESTIÓN DE ARCHIVOS ---
  Future<void> _refreshFiles() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      var bytes = await widget.sshService.client.run("ls -ll '$_currentPath'");
      String raw = utf8.decode(bytes);
      final lines = raw.split('\n');
      List<Map<String, dynamic>> temp = [];

      for (var line in lines) {
        String l = line.trim();
        if (!l.startsWith('d') && !l.startsWith('-')) continue;
        final parts = l.split(RegExp(r'\s+'));
        if (parts.length >= 9) {
          int hIdx = -1;
          for (int i = 0; i < parts.length; i++) { if (parts[i].contains(':')) { hIdx = i; break; } }
          String name = (hIdx != -1 && hIdx + 1 < parts.length) ? parts.sublist(hIdx+1).join(' ') : parts.sublist(8).join(' ');
          if (name.trim() == "." || name.trim() == "..") continue;
          temp.add({'name': name.trim(), 'isDirectory': l.startsWith('d'), 'permissions': parts[0], 'size': parts[4], 'owner': parts[2]});
        }
      }
      _serverType = await _fileService.detectServerType(_currentPath);
      if (_serverType != ServerType.generic) _checkServerStatus();
      setState(() { _items = temp; _isLoading = false; });
    } catch (e) { setState(() => _isLoading = false); }
  }

  Future<void> _uploadFile() async {
    FilePickerResult? res = await FilePicker.platform.pickFiles();
    if (res != null && res.files.single.path != null) {
      setState(() => _isLoading = true);
      File local = File(res.files.single.path!);
      String name = p.basename(local.path);
      final sftp = await widget.sshService.client.sftp();
      final remote = await sftp.open(linuxPath.join(_currentPath, name), mode: SftpFileOpenMode.create | SftpFileOpenMode.write);
      await remote.write(local.openRead().cast());
      if (name.endsWith('.zip')) await widget.sshService.client.run("cd '$_currentPath' && unzip -o '$name'");
      _refreshFiles();
    }
  }

  void _showFileActions(Map<String, dynamic> item) {
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Wrap(children: [
      ListTile(leading: const Icon(Icons.download), title: const Text("Descarregar"), onTap: () { Navigator.pop(ctx); _downloadFile(item['name']); }),
      ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text("Esborrar"), onTap: () { Navigator.pop(ctx); _deleteItem(item['name']); }),
    ])));
  }

  Future<void> _deleteItem(String name) async {
    await widget.sshService.client.run("rm -rf '${linuxPath.join(_currentPath, name)}'");
    _refreshFiles();
  }

  void _showSnackBar(String m, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: isError ? Colors.red : Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentPath == widget.initialPath,
      onPopInvokedWithResult: (didPop, res) { if (!didPop) _navigateTo(".."); },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => _currentPath == widget.initialPath ? Navigator.pop(context) : _navigateTo("..")),
          title: Text(_currentPath, style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshFiles)],
        ),
        body: Column(children: [
          if (_serverType != ServerType.generic)
            Card(
              margin: const EdgeInsets.all(10),
              elevation: 4,
              child: Column(children: [
                ListTile(
                  leading: StatusCanvasIndicator(isOnline: _isServerRunning),
                  title: Text("Projecte ${_serverType == ServerType.nodejs ? 'NODEJS' : 'JAVA'}"),
                  subtitle: Text(_isServerRunning ? "ESTAT: EN FUNCIONAMENT" : "ESTAT: ATURAT"),
                  trailing: ElevatedButton(
                    onPressed: () => _handleServerAction(_isServerRunning ? 'stop' : 'start'),
                    style: ElevatedButton.styleFrom(backgroundColor: _isServerRunning ? Colors.red : Colors.green),
                    child: Text(_isServerRunning ? "STOP" : "START"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text("Redirecció Port 80 -> Local", style: TextStyle(fontSize: 12)),
                    Switch(value: _isPortForwarded, onChanged: _isServerRunning ? _togglePortForwarding : null)
                  ]),
                )
              ]),
            ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, i) => ListTile(
                    leading: Icon(_items[i]['isDirectory'] ? Icons.folder : Icons.description, color: _items[i]['isDirectory'] ? Colors.amber : Colors.grey),
                    title: Text(_items[i]['name']),
                    onTap: () => _items[i]['isDirectory'] ? _navigateTo(_items[i]['name']) : _showFileActions(_items[i]),
                  ),
                ),
          )
        ]),
        floatingActionButton: FloatingActionButton(onPressed: _uploadFile, child: const Icon(Icons.upload_file)),
      ),
    );
  }
}