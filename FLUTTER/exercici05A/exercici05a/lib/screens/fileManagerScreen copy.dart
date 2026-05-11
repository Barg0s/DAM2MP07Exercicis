// ================================
// FILE MANAGER SCREEN COMPLETO
// ================================

import 'package:flutter/material.dart';
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

// ================================
// ENUM STATUS
// ================================

enum ServerStatus {
  running,
  stopped,
  restarting,
  error,
}

// ================================
// CÍRCULO VERDE/ROJO
// ================================

class StatusIndicatorPainter extends CustomPainter {
  final bool isOnline;

  StatusIndicatorPainter(this.isOnline);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isOnline ? Colors.green : Colors.red
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ServerIndicator extends StatelessWidget {
  final bool online;

  const ServerIndicator({
    super.key,
    required this.online,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(
        painter: StatusIndicatorPainter(online),
      ),
    );
  }
}

// ================================
// WIDGET STATUS
// ================================

class ServerStatusWidget extends StatelessWidget {
  final ServerStatus status;

  const ServerStatusWidget({
    super.key,
    required this.status,
  });

  Color _getColor() {
    switch (status) {
      case ServerStatus.running:
        return Colors.green;

      case ServerStatus.stopped:
        return Colors.grey;

      case ServerStatus.restarting:
        return Colors.orange;

      case ServerStatus.error:
        return Colors.red;
    }
  }

  String _getText() {
    switch (status) {
      case ServerStatus.running:
        return "Servidor activo";

      case ServerStatus.stopped:
        return "Servidor detenido";

      case ServerStatus.restarting:
        return "Reiniciando";

      case ServerStatus.error:
        return "Error";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.dns,
          color: _getColor(),
        ),
        title: Text(_getText()),
      ),
    );
  }
}

// ================================
// MAIN SCREEN
// ================================

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

  ServerStatus _serverStatus = ServerStatus.stopped;

  bool _serverOnline = false;

  bool _redirectEnabled = false;

  TextEditingController _redirectController =
      TextEditingController(text: "3000");

  // ================================
  // INIT
  // ================================

  @override
  void initState() {
    super.initState();

    _fileService = FileService(widget.sshService);

    _currentPath = widget.initialPath;

    _refreshFiles();
  }

  @override
  void dispose() {
    _redirectController.dispose();
    super.dispose();
  }

  // ================================
  // DETECTAR SERVER ACTIVO
  // ================================

  Future<bool> _isServerRunning() async {
    try {
      String cmd = "";

      if (_serverType == ServerType.nodejs) {
        cmd = "pgrep -f node";
      }

      else if (_serverType == ServerType.java) {
        cmd = "pgrep -f java";
      }

      else {
        return false;
      }

      final result =
          await widget.sshService.client.run(cmd);

      return utf8.decode(result).trim().isNotEmpty;
    }

    catch (_) {
      return false;
    }
  }

  // ================================
  // ESPERAR SERVER
  // ================================

  Future<void> _waitForServerReady() async {
    for (int i = 0; i < 15; i++) {
      final running = await _isServerRunning();

      if (running) {
        setState(() {
          _serverOnline = true;
          _serverStatus = ServerStatus.running;
        });

        return;
      }

      await Future.delayed(
        const Duration(seconds: 1),
      );
    }

    setState(() {
      _serverOnline = false;
      _serverStatus = ServerStatus.error;
    });

    throw Exception("Servidor no iniciado");
  }

  // ================================
  // SINCRONIZAR STATUS
  // ================================

  Future<void> _syncServerStatus() async {
    final running = await _isServerRunning();

    setState(() {
      _serverOnline = running;

      _serverStatus = running
          ? ServerStatus.running
          : ServerStatus.stopped;
    });
  }

  // ================================
  // START / STOP SERVER
  // ================================

  Future<void> _handleServerAction(String action) async {
    String basePath = "cd '$_currentPath'";

    String cmd = "";

    if (_serverType == ServerType.nodejs) {
      if (action == 'start') {
        cmd =
            "$basePath && "
            "nohup npm start > app.log 2>&1 &";
      }

      else {
        cmd = "pkill -f node";
      }
    }

    else if (_serverType == ServerType.java) {
      if (action == 'start') {
        cmd =
            "$basePath && "
            "nohup java -jar *.jar > app.log 2>&1 &";
      }

      else {
        cmd = "pkill -f java";
      }
    }

    try {
      if (action == 'start') {
        setState(() {
          _serverStatus = ServerStatus.restarting;
        });

        await widget.sshService.client.run(cmd);

        await _waitForServerReady();

        _showSnackBar("Servidor iniciado ✅");
      }

      else {
        await widget.sshService.client.run(cmd);

        setState(() {
          _serverOnline = false;
          _serverStatus = ServerStatus.stopped;
        });

        _showSnackBar("Servidor detenido 🛑");
      }
    }

    catch (e) {
      setState(() {
        _serverOnline = false;
        _serverStatus = ServerStatus.error;
      });

      _showSnackBar(
        "Error servidor: $e",
        isError: true,
      );
    }
  }

  // ================================
  // REDIRECT PORT 80
  // ================================

  Future<void> _enablePortRedirect() async {
    try {
      final port = _redirectController.text;

      await widget.sshService.client.run(
        "sudo iptables -t nat -A PREROUTING "
        "-p tcp --dport 80 "
        "-j REDIRECT --to-port $port",
      );

      setState(() {
        _redirectEnabled = true;
      });

      _showSnackBar(
        "Redirección activa → puerto $port",
      );
    }

    catch (e) {
      _showSnackBar(
        "Error redirect: $e",
        isError: true,
      );
    }
  }

  Future<void> _disablePortRedirect() async {
    try {
      final port = _redirectController.text;

      await widget.sshService.client.run(
        "sudo iptables -t nat -D PREROUTING "
        "-p tcp --dport 80 "
        "-j REDIRECT --to-port $port",
      );

      setState(() {
        _redirectEnabled = false;
      });

      _showSnackBar("Redirección desactivada");
    }

    catch (e) {
      _showSnackBar(
        "Error redirect: $e",
        isError: true,
      );
    }
  }

  // ================================
  // WIDGET REDIRECT
  // ================================

  Widget _buildRedirectWidget() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              "Port Redirect",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _redirectController,
              keyboardType:
                  TextInputType.number,
              decoration:
                  const InputDecoration(
                labelText:
                    "Puerto destino",
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _enablePortRedirect,
                    child:
                        const Text("ON"),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _disablePortRedirect,
                    child:
                        const Text("OFF"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              _redirectEnabled
                  ? "Redirect activo"
                  : "Sin redirect",
            ),
          ],
        ),
      ),
    );
  }

  // ================================
  // REFRESH FILES
  // ================================

  Future<void> _refreshFiles() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      var bytes =
          await widget.sshService.client.run(
        "ls -ll '$_currentPath'",
      );

      String rawList = utf8.decode(bytes);

      final lines = rawList.split('\n');

      List<Map<String, dynamic>>
          tempItems = [];

for (var line in lines) {
  String l = line.trim();

  if (!l.startsWith('d') && !l.startsWith('-')) {
    continue;
  }

  final parts = l.split(RegExp(r'\s+'));

  if (parts.length >= 9) {

    int horaIndex = -1;

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].contains(':')) {
        horaIndex = i;
        break;
      }
    }

    String name =
        (horaIndex != -1 && horaIndex + 1 < parts.length)
            ? parts.sublist(horaIndex + 1).join(' ')
            : parts.sublist(8).join(' ');

    name = name.trim();

    if (name == "." || name == "..") {
      continue;
    }

    tempItems.add({
      'name': name,
      'isDirectory': l.startsWith('d'),
      'permissions': parts[0],
      'size': parts[4],
      'owner': parts[2],
    });
  }
}

      final type =
          await _fileService.detectServerType(
        _currentPath,
      );

      setState(() {
        _items = tempItems;
        _serverType = type;
        _isLoading = false;
      });

      await _syncServerStatus();
    }

    catch (e) {
      setState(() => _isLoading = false);

      _showSnackBar(
        "Error: $e",
        isError: true,
      );
    }
  }

  // ================================
  // NAVIGATION
  // ================================

  void _navigateTo(String name) {
    if (name == "..") {
      if (_currentPath ==
              widget.initialPath ||
          _currentPath == "/") {
        return;
      }

      List<String> parts =
          _currentPath.split('/');

      parts.removeLast();

      _currentPath =
          parts.join('/') == ""
              ? "/"
              : parts.join('/');
    }

    else {
      _currentPath = _currentPath == "/"
          ? "/$name"
          : "$_currentPath/$name";
    }

    _refreshFiles();
  }

  // ================================
  // SNACKBAR
  // ================================

  void _showSnackBar(
    String msg, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError
                ? Colors.red
                : Colors.green,
      ),
    );
  }

  // ================================
  // BUILD
  // ================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPath),
      ),

      body: Column(
        children: [

          // ====================
          // STATUS BAR
          // ====================

          Padding(
            padding:
                const EdgeInsets.all(10),
            child: Row(
              children: [

                ServerIndicator(
                  online:
                      _serverOnline,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child:
                      ServerStatusWidget(
                    status:
                        _serverStatus,
                  ),
                ),
              ],
            ),
          ),

          // ====================
          // REDIRECT
          // ====================

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            child:
                _buildRedirectWidget(),
          ),

          // ====================
          // SERVER CARD
          // ====================

          if (_serverType !=
              ServerType.generic)
            Card(
              margin:
                  const EdgeInsets.all(10),

              child: ListTile(
                leading:
                    const Icon(Icons.dns),

                title: Text(
                  "Proyecto ${_serverType.name.toUpperCase()}",
                ),

                trailing: Row(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [

                    ElevatedButton(
                      onPressed: () =>
                          _handleServerAction(
                        'start',
                      ),

                      child:
                          const Text(
                        "START",
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    ElevatedButton(
                      onPressed: () =>
                          _handleServerAction(
                        'stop',
                      ),

                      child:
                          const Text(
                        "STOP",
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ====================
          // FILES
          // ====================

          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : ListView.builder(
                    itemCount:
                        _items.length,

                    itemBuilder:
                        (context, i) {
                      final item =
                          _items[i];

                      return ListTile(
                        leading: Icon(
                          item[
                                  'isDirectory']
                              ? Icons
                                  .folder
                              : Icons
                                  .description,
                        ),

                        title:
                            Text(
                          item['name'],
                        ),

                        subtitle:
                            Text(
                          "${item['permissions']} | ${item['size']} B",
                        ),

                        onTap: () {
                          if (item[
                              'isDirectory']) {
                            _navigateTo(
                              item['name'],
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}