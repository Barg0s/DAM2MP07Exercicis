import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:dartssh2/dartssh2.dart';
import 'package:path_provider/path_provider.dart';

import '../services/sshService.dart';
import '../services/fileService.dart';
import '../services/ServerControlService.dart';
import '../models/serverModel.dart';
import '../models/fileModel.dart';
import '../widgets/diskUsagePainter.dart';

import '../widgets/StatusCircle.dart';
import '../widgets/ServerStatusWidget.dart';



// ================== CLASSE PRINCIPAL ==================
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
  late ServerControlService _serverControlService;
  late String _currentPath;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  ServerType _serverType = ServerType.generic;

  // ---------- VARIABLES PER ALS WIDGETS ----------
  bool _isServerReachable = false;
  bool _isPort80RedirectActive = false;
  final TextEditingController _targetPortController = TextEditingController(text: "8080");
  ServerStatus _currentServerStatus = ServerStatus.stopped;
  int? _serverPort;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _fileService = FileService(widget.sshService);
    _serverControlService = ServerControlService(widget.sshService);
    _currentPath = widget.initialPath;
    _refreshFiles();
    _updateServerStatus();
    _startPeriodicStatusCheck();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _targetPortController.dispose();
    super.dispose();
  }

  void _startPeriodicStatusCheck() {
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) _updateServerStatus();
    });
  }

  Future<String> runCommand(String command) async {
    final result = await widget.sshService.client.run(command);
    return utf8.decode(result);
  }

  Future<bool> _isPortOpenRemote(int port) async {
    try {
      final status = await _serverControlService.checkStatus(_currentPath, port);
      return status == ServerStatus.running;
    } catch (e) {
      print("Error checking port $port: $e");
      return false;
    }
  }
  Future<void> _handleServerAction(String action) async {
    setState(() => _currentServerStatus = ServerStatus.restarting);
    
    try {
      switch (action) {
        case 'start':
          await _startServer();
          break;
        case 'stop':
          await _stopServer();
          break;
        case 'restart':
          await _restartServer();
          break;
      }
      await Future.delayed(const Duration(seconds: 2));
      await _updateServerStatus();
    } catch (e) {
      _showSnackBar("Error $action servidor: $e", isError: true);
      setState(() => _currentServerStatus = ServerStatus.error);
    }
  }

  Future<void> _startServer() async {
    final port = _serverType == ServerType.nodejs ? 3000 : 8080;
    
    if (await _isPortOpenRemote(port)) {
      _showSnackBar("Servidor ya está corriendo en puerto $port");
      setState(() => _currentServerStatus = ServerStatus.running);
      return;
    }
    
    await _serverControlService.startServer(_currentPath, _serverType, port);
    
    await _waitForServer(port: port);
    _showSnackBar("Servidor arrancado en puerto $port");
  }

  Future<void> _stopServer() async {
    final port = _serverPort ?? (_serverType == ServerType.nodejs ? 3000 : 8080);
    
    await _serverControlService.stopServer(_currentPath, port);
    await Future.delayed(const Duration(seconds: 2));
    
    if (!(await _isPortOpenRemote(port))) {
      _showSnackBar("Servidor parado");
      setState(() => _currentServerStatus = ServerStatus.stopped);
    } else {
      _showSnackBar("Algunos procesos siguen corriendo", isError: true);
    }
  }

  Future<void> _restartServer() async {
    await _stopServer();
    await Future.delayed(const Duration(seconds: 3));
    await _startServer();
  }

  Future<void> _waitForServer({required int port, int maxRetries = 30}) async {
    _showSnackBar("Esperant servidor... (port $port)");
    for (int i = 0; i < maxRetries; i++) {
      if (await _isPortOpenRemote(port)) {
        _showSnackBar(" Servidor actiu!");
        return;
      }
      await Future.delayed(const Duration(seconds: 1));
    }
    throw Exception("Servidor no responde en puerto $port después de ${maxRetries}s");
  }

  // ==================== MÉTODOS DE LA UI ====================
  Future<void> _updateServerStatus() async {
    if (_serverType == ServerType.generic) {
      if (mounted) {
        setState(() {
          _currentServerStatus = ServerStatus.stopped;
          _isServerReachable = false;
        });
      }
      return;
    }
    
    final port = _serverType == ServerType.nodejs ? 3000 : 8080;
    _serverPort = port;
    
    try {
      final status = await _serverControlService.checkStatus(_currentPath, port);
      if (mounted) {
        setState(() {
          _currentServerStatus = status;
          _isServerReachable = status == ServerStatus.running;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentServerStatus = ServerStatus.error;
          _isServerReachable = false;
        });
      }
    }
  }

  Widget _buildServerStatusWidget() {
    Color color;
    String text;
    IconData icon;
    switch (_currentServerStatus) {
      case ServerStatus.running:
        color = Colors.green;
        text = "En funcionament";
        icon = Icons.check_circle;
        break;
      case ServerStatus.stopped:
        color = Colors.red;
        text = "Aturat";
        icon = Icons.stop_circle;
        break;
      case ServerStatus.restarting:
        color = Colors.orange;
        text = "Reiniciant...";
        icon = Icons.autorenew;
        break;
      case ServerStatus.error:
        color = Colors.grey;
        text = "Error";
        icon = Icons.error;
        break;
    }
    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(text, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withOpacity(0.2),
    );
  }

  // ==================== REDIRECCIÓ PORT 80 ====================
  Future<void> _setupPort80Redirect() async {
    final target = _targetPortController.text.trim();
    if (target.isEmpty) {
      _showSnackBar("Indica un port destí", isError: true);
      return;
    }
    final targetPort = int.tryParse(target);
    if (targetPort == null) {
      _showSnackBar("Port no vàlid", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _serverControlService.togglePort80Redirect(targetPort, true);
      setState(() => _isPort80RedirectActive = true);
      _showSnackBar(" Redirecció 80 → $target activada");
    } catch (e) {
      _showSnackBar("Error activant redirecció: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removePort80Redirect() async {
    setState(() => _isLoading = true);
    try {
      await _serverControlService.togglePort80Redirect(0, false);
      setState(() => _isPort80RedirectActive = false);
      _showSnackBar("❌ Redirecció 80 desactivada");
    } catch (e) {
      _showSnackBar("Error desactivant redirecció: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ==================== VISUALITZAR LOGS ====================
  Future<void> _viewServerLog() async {
    try {
      // Nota: runCommand ja fa el decode de utf8, no cal fer-lo de nou
      final log = await runCommand("cd '$_currentPath' && tail -n 100 app.log 2>/dev/null || echo 'No app.log'");

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Server log"),
          content: SizedBox(
            height: 400,
            width: 500,
            child: SingleChildScrollView(child: Text(log)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tancar"),
            )
          ],
        ),
      );
    } catch (e) {
      _showSnackBar("Error llegint log: $e", isError: true);
    }
  }
  Future<void> _refreshFiles() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      var bytes = await widget.sshService.client.run("ls -ll '$_currentPath'");
      String rawList = utf8.decode(bytes);
      final lines = rawList.split('\n');
      List<Map<String, dynamic>> tempItems = [];

      for (var line in lines) {
        String l = line.trim();
        if (!l.startsWith('d') && !l.startsWith('-')) continue;
        final parts = l.split(RegExp(r'\s+'));
        if (parts.length >= 9) {
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
      await _updateServerStatus();
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

  Future<void> _downloadFile(String name) async {
    _showSnackBar("Iniciant descàrrega: $name...");
    try {
      final sftp = await widget.sshService.client.sftp();
      final posix = p.Context(style: p.Style.posix);
      final String remotePath = posix.join(_currentPath, name);
      final remoteFile = await sftp.open(remotePath);
      final List<int> bytes = [];
      await for (var chunk in remoteFile.read()) {
        bytes.addAll(chunk);
      }
      final dir = await getApplicationDocumentsDirectory();
      final localPath = p.join(dir.path, name);
      final localFile = File(localPath);
      await localFile.writeAsBytes(bytes);
      _showSnackBar("Fet! Descarregat a Documents/$name");
    } catch (e) {
      print("Error detallat SFTP: $e");
      _showSnackBar("Error: No s'ha trobat el fitxer al servidor", isError: true);
    }
  }

  void _mostrarBaobab() async {
    setState(() => _isLoading = true);
    try {
      var bytes = await widget.sshService.client.run("cd '$_currentPath' && du -sb * 2>/dev/null");
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
        _showSnackBar("Pujat: $fileName");
        if (fileName.endsWith('.zip')) {
          await runCommand("cd '$_currentPath' && unzip -o '$fileName'");
          _showSnackBar("Arxiu descomprimit automàticament");
        }
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
            if (!item['isDirectory'])
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
    await runCommand("rm -rf '$_currentPath/$name'");
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
            await runCommand("mv '$_currentPath/$oldName' '$_currentPath/${c.text}'");
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
        content: Text(
          "Mida: ${item['size']} B\n"
          "Permisos: ${item['permissions']}\n"
          "Propietari: ${item['owner']}"
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tancar"))],
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
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
          title: Text(
            _currentPath, 
            style: const TextStyle(fontSize: 10, fontFamily: 'monospace')
          ),
          actions: [
            StatusCircle(isActive: _isServerReachable),
            IconButton(icon: const Icon(Icons.pie_chart_outline), onPressed: _mostrarBaobab),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshFiles),
            IconButton(icon: const Icon(Icons.article), onPressed: _viewServerLog),
          ],
        ),
        body: Column(
          children: [
            // ========== CARD DEL SERVIDOR ==========
            if (_serverType != ServerType.generic)
              Card(
                margin: const EdgeInsets.all(10),
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.dns, color: Colors.orange),
                                const SizedBox(width: 8),
                                Text("Projecte ${_serverType.name.toUpperCase()}"),
                                const SizedBox(width: 8),
                                _buildServerStatusWidget(),
                              ],
                            ),
                            if (_serverPort != null)
                              Text("Port: $_serverPort", style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _currentServerStatus == ServerStatus.running 
                                ? null 
                                : () => _handleServerAction('start'),
                            icon: const Icon(Icons.play_arrow, size: 16),
                            label: const Text("START"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _currentServerStatus == ServerStatus.stopped 
                                ? null 
                                : () => _handleServerAction('stop'),
                            icon: const Icon(Icons.stop, size: 16),
                            label: const Text("STOP"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            
            // ========== REDIRECCIÓ PORT 80 ==========
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Icon(Icons.switch_access_shortcut),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _targetPortController,
                        decoration: const InputDecoration(
                          labelText: "Port destí",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _isPort80RedirectActive,
                      onChanged: (val) {
                        if (val) _setupPort80Redirect();
                        else _removePort80Redirect();
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // ========== LLISTAT D'ARXIUS ==========
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? Center(child: Text("Carpeta buida: $_currentPath"))
                      : ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (context, i) {
                            final item = _items[i];
                            return ListTile(
                              leading: Icon(
                                item['isDirectory'] ? Icons.folder : Icons.description,
                                color: item['isDirectory'] ? Colors.amber : Colors.grey,
                              ),
                              title: Text(item['name']),
                              subtitle: Text("${item['permissions']} | ${item['size']} B"),
                              onTap: () => item['isDirectory'] 
                                  ? _navigateTo(item['name']) 
                                  : _showFileActions(item),
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