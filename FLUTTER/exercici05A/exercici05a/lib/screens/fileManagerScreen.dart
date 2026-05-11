import 'dart:async';
import 'package:flutter/material.dart';
import '../services/files/fileManagerService.dart';
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

class _FileManagerScreenState extends State<FileManagerScreen> {
  late FileService _fileService;
  late ServerControlService _serverControlService;
  late FilemanagerService _managerService;
  late String _currentPath;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  ServerType _serverType = ServerType.generic;
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

    _managerService = FilemanagerService(
      sshService: widget.sshService,
      fileService: _fileService);

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

  // PERIODIC STATUS CHECK

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

  // SERVER STATUS

  Future<void> _updateServerStatus() async {
    if (_serverType ==
        ServerType.generic) {
      setState(() {
        _currentServerStatus =
            ServerStatus.stopped;

        _isServerReachable = false;
      });

      return;
    }

    final port =
        _serverType ==
                ServerType.nodejs
            ? 3000
            : 8080;

    _serverPort = port;

    try {
      final status =
          await _serverControlService
              .checkStatus(
                _currentPath,
                port,
              );

      setState(() {
        _currentServerStatus = status;

        _isServerReachable =
            status ==
            ServerStatus.running;
      });
    } catch (e) {
      setState(() {
        _currentServerStatus =
            ServerStatus.error;

        _isServerReachable = false;
      });
    }
  }

  Future<bool> _isPortOpenRemote(
    int port,
  ) async {
    try {
      final status =
          await _serverControlService
              .checkStatus(
                _currentPath,
                port,
              );

      return status ==
          ServerStatus.running;
    } catch (e) {
      return false;
    }
  }

  // ===================================
  // SERVER ACTIONS
  // ===================================

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
        "Error servidor: $e",
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
        _serverType ==
                ServerType.nodejs
            ? 3000
            : 8080;

    if (await _isPortOpenRemote(port)) {
      _showSnackBar(
        "Servidor ya iniciado",
      );

      setState(() {
        _currentServerStatus =
            ServerStatus.running;
      });

      return;
    }

    await _serverControlService
        .startServer(
          _currentPath,
          _serverType,
          port,
        );

    await _waitForServer(port: port);

    _showSnackBar(
      "Servidor iniciado",
    );
  }

  Future<void> _stopServer() async {
    final port =
        _serverPort ??
        (_serverType ==
                ServerType.nodejs
            ? 3000
            : 8080);

    await _serverControlService
        .stopServer(
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

    _showSnackBar("Servidor detenido");
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
    for (int i = 0;
        i < maxRetries;
        i++) {
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

  // ===================================
  // PORT 80 REDIRECT
  // ===================================

  Future<void>
  _setupPort80Redirect() async {
    final target =
        _targetPortController.text.trim();

    final targetPort =
        int.tryParse(target);

    if (targetPort == null) {
      _showSnackBar(
        "Puerto inválido",
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
        _isPort80RedirectActive =
            true;
      });

      _showSnackBar(
        "Redirección activada",
      );
    } catch (e) {
      _showSnackBar(
        "Error redirect",
        isError: true,
      );
    }
  }

  Future<void>
  _removePort80Redirect() async {
    try {
      await _serverControlService
          .togglePort80Redirect(
            0,
            false,
          );

      setState(() {
        _isPort80RedirectActive =
            false;
      });

      _showSnackBar(
        "Redirección eliminada",
      );
    } catch (e) {
      _showSnackBar(
        "Error redirect",
        isError: true,
      );
    }
  }

  // ===================================
  // FILES
  // ===================================

  Future<void> _refreshFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items =
          await _managerService.loadFiles(
            _currentPath,
          );

      final type =
          await _managerService
              .detectServerType(
                _currentPath,
              );

      setState(() {
        _items = items;

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
    _currentPath =
        _managerService.navigateTo(
          _currentPath,
          widget.initialPath,
          name,
        );

    _refreshFiles();
  }

  Future<void> _deleteItem(
    String name,
  ) async {
    await _managerService.deleteItem(
      _currentPath,
      name,
    );

    _refreshFiles();

    _showSnackBar("Eliminado");
  }

  Future<void> _downloadFile(
    String name,
  ) async {
    try {
      final path =
          await _managerService.downloadFile(
            _currentPath,
            name,
          );

      _showSnackBar(
        "Descargado:\n$path",
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
      final fileName =
          await _managerService.uploadFile(
            _currentPath,
          );

      if (fileName != null) {
        _showSnackBar(
          "Subido: $fileName",
        );

        _refreshFiles();
      }
    } catch (e) {
      _showSnackBar(
        "Error upload",
        isError: true,
      );
    }
  }

  Future<void> _renameItem(
    String oldName,
  ) async {
    final controller =
        TextEditingController(
          text: oldName,
        );

    showDialog(
      context: context,

      builder:
          (_) => AlertDialog(
            title: const Text(
              "Nuevo nombre",
            ),

            content: TextField(
              controller: controller,
            ),

            actions: [
              TextButton(
                onPressed:
                    () => Navigator.pop(
                      context,
                    ),

                child: const Text(
                  "Cancelar",
                ),
              ),

              TextButton(
                onPressed: () async {
                  await _managerService
                      .renameItem(
                        _currentPath,
                        oldName,
                        controller.text,
                      );

                  Navigator.pop(
                    context,
                  );

                  _refreshFiles();
                },

                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  // ===================================
  // DISK USAGE
  // ===================================

  Future<void> _mostrarBaobab() async {
    try {
      final folders =
          await _managerService
              .loadDiskUsage(
                _currentPath,
              );

      final data =
          folders.map((f) {
            return FileModel(
              name: f['name'],
              size: f['size'],
              isDirectory: true,
            );
          }).toList();

      showDialog(
        context: context,

        builder:
            (_) => DiskUsageDialog(
              data: data,
            ),
      );
    } catch (e) {
      _showSnackBar(
        "Error Baobab",
        isError: true,
      );
    }
  }

  // ===================================
  // FILE ACTIONS
  // ===================================

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

              _renameItem(
                item['name'],
              );
            },

            onDelete: () {
              Navigator.pop(context);

              _deleteItem(
                item['name'],
              );
            },

            onDownload: () {
              Navigator.pop(context);

              _downloadFile(
                item['name'],
              );
            },
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
            title: Text(
              item['name'],
            ),

            content: Text(
              "Size: ${item['size']} B\n"
              "Permisos: ${item['permissions']}\n"
              "Owner: ${item['owner']}",
            ),

            actions: [
              TextButton(
                onPressed:
                    () => Navigator.pop(
                      context,
                    ),

                child: const Text(
                  "Cerrar",
                ),
              ),
            ],
          ),
    );
  }

  // ===================================
  // SNACKBAR
  // ===================================

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

  // ===================================
  // UI
  // ===================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:
          _currentPath ==
          widget.initialPath,

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
            icon: const Icon(
              Icons.arrow_back,
            ),

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
              fontFamily:
                  'monospace',
            ),
          ),

          actions: [
            StatusCircle(
              isActive:
                  _isServerReachable,
            ),

            IconButton(
              icon: const Icon(
                Icons
                    .pie_chart_outline,
              ),

              onPressed:
                  _mostrarBaobab,
            ),

            IconButton(
              icon: const Icon(
                Icons.refresh,
              ),

              onPressed:
                  _refreshFiles,
            ),
          ],
        ),

        body: Column(
          children: [
            if (_serverType !=
                ServerType.generic)
              ServerControlCard(
                serverType:
                    _serverType,

                status:
                    _currentServerStatus,

                port: _serverPort,

                onStart:
                    () =>
                        _handleServerAction(
                          'start',
                        ),

                onStop:
                    () =>
                        _handleServerAction(
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
                isLoading:
                    _isLoading,

                items: _items,

                currentPath:
                    _currentPath,

                onFileTap: (
                  item,
                ) {
                  if (item['isDirectory']) {
                    _navigateTo(
                      item['name'],
                    );
                  } else {
                    _showFileActions(
                      item,
                    );
                  }
                },

                onLongPress: (
                  item,
                ) {
                  _showFileActions(
                    item,
                  );
                },
              ),
            ),
          ],
        ),

        floatingActionButton:
            FloatingActionButton(
              onPressed:
                  _uploadFile,

              child: const Icon(
                Icons.upload_file,
              ),
            ),
      ),
    );
  }
}