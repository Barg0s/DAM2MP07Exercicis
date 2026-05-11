import 'package:flutter/material.dart';
import 'dart:async';
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

import '../widgets/StatusCircle.dart';

import '../widgets/serverControlCard.dart';
import '../widgets/portRedirectWidget.dart';

import '../widgets/fileListWidget.dart';
import '../widgets/fileActionsSheet.dart';

import '../widgets/diskUsageDialog.dart';

class FileManagerScreen extends StatefulWidget {
  final String initialPath;
  final SSHService sshService;

  const FileManagerScreen({
    super.key,
    required this.initialPath,
    required this.sshService,
  });

  @override
  State<FileManagerScreen> createState() =>
      _FileManagerScreenState();
}

class _FileManagerScreenState
    extends State<FileManagerScreen> {
  late FileService _fileService;
  late ServerControlService _serverControlService;

  late String _currentPath;

  List<Map<String, dynamic>> _items = [];

  bool _isLoading = true;

  ServerType _serverType = ServerType.generic;

  // SERVER STATUS
  bool _isServerReachable = false;

  bool _isPort80RedirectActive = false;

  final TextEditingController
  _targetPortController =
      TextEditingController(text: "8080");

  ServerStatus _currentServerStatus =
      ServerStatus.stopped;

  int? _serverPort;

  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();

    _fileService = FileService(widget.sshService);

    _serverControlService =
        ServerControlService(widget.sshService);

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
    _statusTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        if (mounted) {
          _updateServerStatus();
        }
      },
    );
  }

  Future<String> runCommand(String command) async {
    final result = await widget.sshService.client.run(
      command,
    );

    return utf8.decode(result);
  }

  Future<bool> _isPortOpenRemote(int port) async {
    try {
      final status =
          await _serverControlService.checkStatus(
            _currentPath,
            port,
          );

      return status == ServerStatus.running;
    } catch (e) {
      return false;
    }
  }

  Future<void> _handleServerAction(
    String action,
  ) async {
    setState(() {
      _currentServerStatus =
          ServerStatus.restarting;
    });

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

      await Future.delayed(
        const Duration(seconds: 2),
      );

      await _updateServerStatus();
    } catch (e) {
      _showSnackBar(
        "Error $action servidor: $e",
        isError: true,
      );

      setState(() {
        _currentServerStatus =
            ServerStatus.error;
      });
    }
  }

  Future<void> _startServer() async {
    final port =
        _serverType == ServerType.nodejs
            ? 3000
            : 8080;

    if (await _isPortOpenRemote(port)) {
      _showSnackBar(
        "Servidor ya está corriendo",
      );

      setState(() {
        _currentServerStatus =
            ServerStatus.running;
      });

      return;
    }

    await _serverControlService.startServer(
      _currentPath,
      _serverType,
      port,
    );

    await _waitForServer(port: port);

    _showSnackBar(
      "Servidor arrancado",
    );
  }

  Future<void> _stopServer() async {
    final port =
        _serverPort ??
        (_serverType == ServerType.nodejs
            ? 3000
            : 8080);

    await _serverControlService.stopServer(
      _currentPath,
      port,
    );

    await Future.delayed(
      const Duration(seconds: 2),
    );

    setState(() {
      _currentServerStatus =
          ServerStatus.stopped;
    });

    _showSnackBar("Servidor parado");
  }

  Future<void> _restartServer() async {
    await _stopServer();

    await Future.delayed(
      const Duration(seconds: 2),
    );

    await _startServer();
  }

  Future<void> _waitForServer({
    required int port,
    int maxRetries = 30,
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      if (await _isPortOpenRemote(port)) {
        return;
      }

      await Future.delayed(
        const Duration(seconds: 1),
      );
    }

    throw Exception(
      "Servidor no responde",
    );
  }

  Future<void> _updateServerStatus() async {
    if (_serverType == ServerType.generic) {
      setState(() {
        _currentServerStatus =
            ServerStatus.stopped;

        _isServerReachable = false;
      });

      return;
    }

    final port =
        _serverType == ServerType.nodejs
            ? 3000
            : 8080;

    _serverPort = port;

    try {
      final status =
          await _serverControlService.checkStatus(
            _currentPath,
            port,
          );

      setState(() {
        _currentServerStatus = status;

        _isServerReachable =
            status == ServerStatus.running;
      });
    } catch (e) {
      setState(() {
        _currentServerStatus =
            ServerStatus.error;

        _isServerReachable = false;
      });
    }
  }

  Future<void> _setupPort80Redirect() async {
    final target =
        _targetPortController.text.trim();

    final targetPort = int.tryParse(target);

    if (targetPort == null) {
      _showSnackBar(
        "Port no válido",
        isError: true,
      );

      return;
    }

    try {
      await _serverControlService
          .togglePort80Redirect(
            targetPort,
            true,
          );

      setState(() {
        _isPort80RedirectActive = true;
      });

      _showSnackBar(
        "Redirección activada",
      );
    } catch (e) {
      _showSnackBar(
        "Error: $e",
        isError: true,
      );
    }
  }

  Future<void> _removePort80Redirect() async {
    try {
      await _serverControlService
          .togglePort80Redirect(0, false);

      setState(() {
        _isPort80RedirectActive = false;
      });

      _showSnackBar(
        "Redirección desactivada",
      );
    } catch (e) {
      _showSnackBar(
        "Error: $e",
        isError: true,
      );
    }
  }

  Future<void> _refreshFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var bytes = await widget.sshService.client.run(
        "ls -ll '$_currentPath'",
      );

      String rawList = utf8.decode(bytes);

      final lines = rawList.split('\n');

      List<Map<String, dynamic>> tempItems = [];

      for (var line in lines) {
        String l = line.trim();

        if (!l.startsWith('d') &&
            !l.startsWith('-')) {
          continue;
        }

        final parts = l.split(
          RegExp(r'\s+'),
        );

        if (parts.length >= 9) {
          int horaIndex = -1;

          for (int i = 0; i < parts.length; i++) {
            if (parts[i].contains(':')) {
              horaIndex = i;
              break;
            }
          }

          String name =
              (horaIndex != -1 &&
                      horaIndex + 1 <
                          parts.length)
                  ? parts
                      .sublist(horaIndex + 1)
                      .join(' ')
                  : parts.sublist(8).join(' ');

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

      await _updateServerStatus();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _showSnackBar(
        "Error: $e",
        isError: true,
      );
    }
  }

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
    } else {
      _currentPath =
          _currentPath == "/"
              ? "/$name"
              : "$_currentPath/$name";
    }

    _refreshFiles();
  }

  Future<void> _downloadFile(String name) async {
    try {
      final sftp =
          await widget.sshService.client.sftp();

      final remoteFile = await sftp.open(
        '$_currentPath/$name',
      );

      final List<int> bytes = [];

      await for (var chunk in remoteFile.read()) {
        bytes.addAll(chunk);
      }

      final dir =
          await getApplicationDocumentsDirectory();

      final localPath = p.join(
        dir.path,
        name,
      );

      await File(localPath).writeAsBytes(bytes);

      _showSnackBar(
        "Descargado: $name",
      );
    } catch (e) {
      _showSnackBar(
        "Error descarga",
        isError: true,
      );
    }
  }

  Future<void> _uploadFile() async {
    try {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles();

      if (result != null &&
          result.files.single.path != null) {
        File localFile = File(
          result.files.single.path!,
        );

        String fileName = p.basename(
          localFile.path,
        );

        final sftp =
            await widget.sshService.client.sftp();

        final remoteFile = await sftp.open(
          '$_currentPath/$fileName',
          mode:
              SftpFileOpenMode.create |
              SftpFileOpenMode.write,
        );

        await remoteFile.write(
          localFile.openRead().cast(),
        );

        _showSnackBar("Subido");

        _refreshFiles();
      }
    } catch (e) {
      _showSnackBar(
        "Error upload",
        isError: true,
      );
    }
  }

  void _showFileActions(
    Map<String, dynamic> item,
  ) {
    showModalBottomSheet(
      context: context,

      builder:
          (_) => FileActionsSheet(
            item: item,

            onInfo: () {
              Navigator.pop(context);

              _showDetails(item);
            },

            onRename: () {
              Navigator.pop(context);

              _renameItem(item['name']);
            },

            onDelete: () {
              Navigator.pop(context);

              _deleteItem(item['name']);
            },

            onDownload: () {
              Navigator.pop(context);

              _downloadFile(item['name']);
            },
          ),
    );
  }

  Future<void> _deleteItem(String name) async {
    await runCommand(
      "rm -rf '$_currentPath/$name'",
    );

    _refreshFiles();
  }

  Future<void> _renameItem(
    String oldName,
  ) async {
    final controller =
        TextEditingController(text: oldName);

    showDialog(
      context: context,

      builder:
          (_) => AlertDialog(
            title: const Text("Nuevo nombre"),

            content: TextField(
              controller: controller,
            ),

            actions: [
              TextButton(
                onPressed:
                    () => Navigator.pop(context),

                child: const Text("Cancelar"),
              ),

              TextButton(
                onPressed: () async {
                  await runCommand(
                    "mv '$_currentPath/$oldName' '$_currentPath/${controller.text}'",
                  );

                  Navigator.pop(context);

                  _refreshFiles();
                },

                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  void _showDetails(
    Map<String, dynamic> item,
  ) {
    showDialog(
      context: context,

      builder:
          (_) => AlertDialog(
            title: Text(item['name']),

            content: Text(
              "Size: ${item['size']} B\n"
              "Permisos: ${item['permissions']}\n"
              "Owner: ${item['owner']}",
            ),

            actions: [
              TextButton(
                onPressed:
                    () => Navigator.pop(context),

                child: const Text("Cerrar"),
              ),
            ],
          ),
    );
  }

  Future<void> _mostrarBaobab() async {
    try {
      var bytes = await widget.sshService.client.run(
        "cd '$_currentPath' && du -sb * 2>/dev/null",
      );

      String raw = utf8.decode(bytes);

      List<FileModel> carpetas = [];

      for (var line in raw.trim().split('\n')) {
        final parts = line.split(
          RegExp(r'\s+'),
        );

        if (parts.length >= 2) {
          carpetas.add(
            FileModel(
              name: parts
                  .sublist(1)
                  .join(' '),

              size:
                  int.tryParse(parts[0]) ?? 0,

              isDirectory: true,
            ),
          );
        }
      }

      carpetas.sort(
        (a, b) => b.size.compareTo(a.size),
      );

      showDialog(
        context: context,

        builder:
            (_) => DiskUsageDialog(
              data: carpetas,
            ),
      );
    } catch (e) {
      _showSnackBar(
        "Error Baobab",
        isError: true,
      );
    }
  }

  void _showSnackBar(
    String msg, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),

        backgroundColor:
            isError
                ? Colors.red
                : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:
          _currentPath == widget.initialPath,

      onPopInvokedWithResult: (
        didPop,
        result,
      ) {
        if (!didPop) {
          _navigateTo("..");
        }
      },

      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),

            onPressed: () {
              if (_currentPath ==
                  widget.initialPath) {
                Navigator.pop(context);
              } else {
                _navigateTo("..");
              }
            },
          ),

          title: Text(
            _currentPath,
            style: const TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),

          actions: [
            StatusCircle(
              isActive: _isServerReachable,
            ),

            IconButton(
              icon: const Icon(
                Icons.pie_chart_outline,
              ),
              onPressed: _mostrarBaobab,
            ),

            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshFiles,
            ),
          ],
        ),

        body: Column(
          children: [
            if (_serverType !=
                ServerType.generic)
              ServerControlCard(
                serverType: _serverType,

                status: _currentServerStatus,

                port: _serverPort,

                onStart:
                    () => _handleServerAction(
                      'start',
                    ),

                onStop:
                    () => _handleServerAction(
                      'stop',
                    ),
              ),

            PortRedirectWidget(
              controller:
                  _targetPortController,

              isActive:
                  _isPort80RedirectActive,

              onToggle: (val) {
                if (val) {
                  _setupPort80Redirect();
                } else {
                  _removePort80Redirect();
                }
              },
            ),

            Expanded(
              child: FileListWidget(
                isLoading: _isLoading,

                items: _items,

                currentPath: _currentPath,

                onFileTap: (item) {
                  if (item['isDirectory']) {
                    _navigateTo(item['name']);
                  } else {
                    _showFileActions(item);
                  }
                },

                onLongPress: (item) {
                  _showFileActions(item);
                },
              ),
            ),
          ],
        ),

        floatingActionButton:
            FloatingActionButton(
              onPressed: _uploadFile,

              child: const Icon(
                Icons.upload_file,
              ),
            ),
      ),
    );
  }
}