import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'models/models.dart';
import 'services/services.dart';
import 'widgets/widgets.dart';

void main() {
  runApp(const GestorProxmoxApp());
}

class GestorProxmoxApp extends StatelessWidget {
  const GestorProxmoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor Proxmox',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final SSHService _ssh = SSHService();
  final ConfigService _config = ConfigService();
  
  List<ServerConfig> _servers = [];
  ServerConfig? _selectedServer;
  List<FileItem> _files = [];
  FileItem? _selectedFile;
  ServerStatus? _serverStatus;
  bool _isLoading = false;
  bool _portRedirectActive = false;
  String _statusMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadServers();
  }
  
  Future<void> _loadServers() async {
    final servers = await _config.loadServers();
    setState(() => _servers = servers);
  }
  
  void _setLoading(bool value, [String message = '']) {
    setState(() {
      _isLoading = value;
      _statusMessage = message;
    });
  }
  
  Future<void> _connectToServer(ServerConfig server) async {
    _setLoading(true, 'Connectant a ${server.name}...');
    try {
      await _ssh.connect(server);
      await _refreshFiles();
      setState(() => _selectedServer = server);
      _setLoading(false, 'Connectat a ${server.name}');
    } catch (e) {
      _setLoading(false, 'Error: $e');
    }
  }
  
  Future<void> _disconnect() async {
    await _ssh.disconnect();
    setState(() {
      _selectedServer = null;
      _files = [];
      _selectedFile = null;
    });
    _setLoading(false, 'Desconnectat');
  }
  
  Future<void> _refreshFiles() async {
    try {
      final files = await _ssh.listDirectory();
      setState(() {
        _files = files;
        _selectedFile = null;
      });
      await _detectServer();
    } catch (e) {
      _setLoading(false, 'Error: $e');
    }
  }
  
  Future<void> _detectServer() async {
    final status = await _ssh.detectServer(_ssh.currentPath);
    setState(() => _serverStatus = status);
  }
  
  Future<void> _navigateToFolder(String path) async {
    _setLoading(true, 'Navegant...');
    try {
      await _ssh.changeDirectory(path);
      await _refreshFiles();
      _setLoading(false);
    } catch (e) {
      _setLoading(false, 'Error: $e');
    }
  }
  
  Future<void> _deleteSelected() async {
    if (_selectedFile == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminació'),
        content: Text('Vols eliminar "${_selectedFile!.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel·lar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      _setLoading(true, 'Eliminant...');
      try {
        await _ssh.deleteFile(_selectedFile!.name);
        await _refreshFiles();
        _setLoading(false, 'Eliminat correctament');
      } catch (e) {
        _setLoading(false, 'Error: $e');
      }
    }
  }
  
  Future<void> _renameSelected() async {
    if (_selectedFile == null) return;
    
    final controller = TextEditingController(text: _selectedFile!.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Canviar nom'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nou nom'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel·lar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Canviar'),
          ),
        ],
      ),
    );
    
    if (newName != null && newName.isNotEmpty) {
      _setLoading(true, 'Canviant nom...');
      try {
        await _ssh.renameFile(_selectedFile!.name, newName);
        await _refreshFiles();
        _setLoading(false, 'Nom canviat');
      } catch (e) {
        _setLoading(false, 'Error: $e');
      }
    }
  }
  
  Future<void> _showFileInfo() async {
    if (_selectedFile == null) return;
    
    _setLoading(true, 'Obtenint informació...');
    try {
      final info = await _ssh.getFileInfo(_selectedFile!.name);
      _setLoading(false);
      
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(_selectedFile!.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Permisos: ${_selectedFile!.permissions}'),
                Text('Propietari: ${_selectedFile!.owner}'),
                Text('Grup: ${_selectedFile!.group}'),
                Text('Mida: ${_selectedFile!.sizeFormatted}'),
                const Divider(),
                Text(info, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tancar'),
            ),
          ],
        ),
      );
    } catch (e) {
      _setLoading(false, 'Error: $e');
    }
  }
  
  Future<void> _downloadSelected() async {
    if (_selectedFile == null) return;
    
    _setLoading(true, 'Descarregant...');
    try {
      final dir = await getDownloadsDirectory() ?? await getTemporaryDirectory();
      
      if (_selectedFile!.isDirectory) {
        final localPath = '${dir.path}/${_selectedFile!.name}.zip';
        await _ssh.downloadFolderAsZip(_selectedFile!.name, localPath);
        _setLoading(false, 'Carpeta descarregada com a ZIP a: $localPath');
      } else {
        final localPath = '${dir.path}/${_selectedFile!.name}';
        await _ssh.downloadFile(_selectedFile!.name, localPath);
        _setLoading(false, 'Arxiu descarregat a: $localPath');
      }
    } catch (e) {
      _setLoading(false, 'Error: $e');
    }
  }
  
  Future<void> _createFolder() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova carpeta'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nom de la carpeta'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel·lar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    
    if (name != null && name.isNotEmpty) {
      _setLoading(true, 'Creant carpeta...');
      try {
        await _ssh.createDirectory(name);
        await _refreshFiles();
        _setLoading(false, 'Carpeta creada');
      } catch (e) {
        _setLoading(false, 'Error: $e');
      }
    }
  }
  
  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      _setLoading(true, 'Pujant ${file.name}...');
      try {
        await _ssh.uploadFile(file.path!, file.name);
        await _refreshFiles();
        _setLoading(false, 'Arxiu pujat');
      } catch (e) {
        _setLoading(false, 'Error pujant: $e');
      }
    }
  }

  Future<void> _uploadFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      final dirName = result.split(Platform.pathSeparator).last;
      _setLoading(true, 'Comprimint i pujant carpeta $dirName...');
      try {
        await _ssh.uploadFolderAsZip(result, dirName);
        await _refreshFiles();
        _setLoading(false, 'Carpeta pujada i descomprimida');
      } catch (e) {
        _setLoading(false, 'Error pujant carpeta: $e');
      }
    }
  }

  Future<void> _extractSelected() async {
    if (_selectedFile == null || !_selectedFile!.name.endsWith('.zip')) return;
    
    _setLoading(true, 'Descomprimint ${_selectedFile!.name}...');
    try {
      await _ssh.extractZip(_selectedFile!.name);
      await _refreshFiles();
      _setLoading(false, 'Arxiu descomprimit');
    } catch (e) {
      _setLoading(false, 'Error descomprimint: $e');
    }
  }
  
  Future<void> _showDiskUsage() async {
    _setLoading(true, 'Analitzant disc (Baobab)...');
    try {
      final rootNode = await _ssh.getDiskUsage(_ssh.currentPath);
      _setLoading(false);
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Ús de Disc: ${_ssh.currentPath}'),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BaobabTreeWidget(rootNode: rootNode, size: 300),
              const SizedBox(width: 24),
              Expanded(
                child: TitledListWidget(
                  title: 'Carpetes',
                  items: rootNode.children.map((c) => '${c.name} (${(c.size / 1024 / 1024).toStringAsFixed(1)} MB)').toList(),
                  itemColors: List.generate(rootNode.children.length, (i) {
                    final List<Color> colors = [
                      Colors.blue, Colors.green, Colors.orange, Colors.purple,
                      Colors.red, Colors.teal, Colors.amber, Colors.cyan
                    ];
                    return colors[(2 + i) % colors.length];
                  }),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tancar'),
            ),
          ],
        ),
      );
    } catch (e) {
      _setLoading(false, 'Error analitzant disc: $e');
    }
  }
  
  void _showAddServerDialog() {
    final nameCtrl = TextEditingController();
    final hostCtrl = TextEditingController();
    final portCtrl = TextEditingController(text: '22');
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final keyCtrl = TextEditingController(text: r'C:\Users\Denis\.ssh\id_rsa');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Afegir servidor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LabeledTextField(label: 'Nom', controller: nameCtrl),
              const SizedBox(height: 12),
              LabeledTextField(label: 'Host', controller: hostCtrl),
              const SizedBox(height: 12),
              LabeledTextField(label: 'Port', controller: portCtrl),
              const SizedBox(height: 12),
              LabeledTextField(label: 'Usuari', controller: userCtrl),
              const SizedBox(height: 12),
              LabeledTextField(
                label: 'Contrasenya (Opcional)',
                controller: passCtrl,
                obscureText: true,
              ),
              const SizedBox(height: 12),
              LabeledTextField(
                label: 'Ruta Clau Privada (Opcional)',
                controller: keyCtrl,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel·lar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final server = ServerConfig(
                name: nameCtrl.text,
                host: hostCtrl.text,
                port: int.tryParse(portCtrl.text) ?? 22,
                username: userCtrl.text,
                password: passCtrl.text,
                privateKeyPath: keyCtrl.text,
              );
              await _config.addServer(server);
              await _loadServers();
              Navigator.pop(ctx);
            },
            child: const Text('Afegir'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.storage),
            const SizedBox(width: 8),
            const Text('Gestor Proxmox'),
            if (_ssh.isConnected) ...[
              const SizedBox(width: 16),
              StatusIndicator(isActive: true),
              const SizedBox(width: 8),
              Text(
                _selectedServer?.name ?? '',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
        actions: [
          if (_ssh.isConnected)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _disconnect,
              tooltip: 'Desconnectar',
            ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar - Servidors
          Container(
            width: 220,
            color: Colors.grey.shade100,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Text(
                        'SERVIDORS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: _showAddServerDialog,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _servers.length,
                    itemBuilder: (ctx, i) {
                      final server = _servers[i];
                      final isSelected = server == _selectedServer;
                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        leading: StatusIndicator(
                          isActive: isSelected && _ssh.isConnected,
                          size: 12,
                        ),
                        title: Text(server.name),
                        subtitle: Text(server.host, style: const TextStyle(fontSize: 11)),
                        onTap: () => _connectToServer(server),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, size: 16),
                          onPressed: () async {
                            await _config.removeServer(server.name);
                            await _loadServers();
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Main content
          Expanded(
            child: Column(
              children: [
                // Path bar
                if (_ssh.isConnected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.indigo.shade50,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => _navigateToFolder('..'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _refreshFiles,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _ssh.currentPath,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.create_new_folder),
                          onPressed: _createFolder,
                          tooltip: 'Nova carpeta',
                        ),
                        IconButton(
                          icon: const Icon(Icons.upload_file),
                          onPressed: _uploadFile,
                          tooltip: 'Pujar arxiu',
                        ),
                        IconButton(
                          icon: const Icon(Icons.drive_folder_upload),
                          onPressed: _uploadFolder,
                          tooltip: 'Pujar carpeta (Zip)',
                        ),
                        IconButton(
                          icon: const Icon(Icons.pie_chart),
                          onPressed: _showDiskUsage,
                          tooltip: 'Ús de disc (Baobab)',
                        ),
                      ],
                    ),
                  ),
                
                // Files list
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(),
                              if (_statusMessage.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(_statusMessage),
                              ],
                            ],
                          ),
                        )
                      : !_ssh.isConnected
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('Selecciona un servidor per connectar'),
                                ],
                              ),
                            )
                          : Row(
                              children: [
                                // File list
                                Expanded(
                                  flex: 2,
                                  child: ListView.builder(
                                    itemCount: _files.length,
                                    itemBuilder: (ctx, i) {
                                      final file = _files[i];
                                      final isSelected = file == _selectedFile;
                                      return ListTile(
                                        selected: isSelected,
                                        selectedTileColor: Colors.indigo.shade50,
                                        leading: Icon(
                                          file.isDirectory
                                              ? Icons.folder
                                              : Icons.insert_drive_file,
                                          color: file.isDirectory
                                              ? Colors.amber
                                              : Colors.grey,
                                        ),
                                        title: Text(file.name),
                                        subtitle: Text(
                                          file.isDirectory
                                              ? 'Carpeta'
                                              : file.sizeFormatted,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        trailing: Text(
                                          file.permissions,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                        onTap: () {
                                          if (_selectedFile == file && file.isDirectory) {
                                            _navigateToFolder(file.name);
                                          } else {
                                            setState(() => _selectedFile = file);
                                          }
                                        },
                                        onLongPress: () {
                                          if (file.isDirectory) {
                                            _navigateToFolder(file.name);
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ),
                                
                                // Details panel
                                Container(
                                  width: 280,
                                  color: Colors.grey.shade50,
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                      const Text(
                                        'ACCIONS',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          if (_selectedFile != null && _selectedFile!.isDirectory)
                                            ElevatedButton.icon(
                                              onPressed: () => _navigateToFolder(_selectedFile!.name),
                                              icon: const Icon(Icons.folder_open, size: 16),
                                              label: const Text('Obrir'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.amber.shade100,
                                              ),
                                            ),
                                          ElevatedButton.icon(
                                            onPressed: _selectedFile != null
                                                ? _showFileInfo
                                                : null,
                                            icon: const Icon(Icons.info, size: 16),
                                            label: const Text('Info'),
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: _selectedFile != null
                                                ? _renameSelected
                                                : null,
                                            icon: const Icon(Icons.edit, size: 16),
                                            label: const Text('Canviar nom'),
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: _selectedFile != null
                                                ? _downloadSelected
                                                : null,
                                            icon: const Icon(Icons.download, size: 16),
                                            label: const Text('Descarregar'),
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: _selectedFile != null
                                                ? _deleteSelected
                                                : null,
                                            icon: const Icon(Icons.delete, size: 16),
                                            label: const Text('Eliminar'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red.shade100,
                                            ),
                                          ),
                                          if (_selectedFile != null && _selectedFile!.name.endsWith('.zip'))
                                            ElevatedButton.icon(
                                              onPressed: _extractSelected,
                                              icon: const Icon(Icons.folder_zip, size: 16),
                                              label: const Text('Descomprimir'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange.shade100,
                                              ),
                                            ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 24),
                                      const Text(
                                        'SERVIDOR',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      if (_serverStatus != null)
                                        ServerStatusWidget(
                                          status: _serverStatus!,
                                          onStart: () async {
                                            await _ssh.startNodeServer(_ssh.currentPath);
                                            await _detectServer();
                                          },
                                          onStop: () async {
                                            await _ssh.stopNodeServer(_ssh.currentPath);
                                            await _detectServer();
                                          },
                                          onRestart: () async {
                                            await _ssh.restartNodeServer(_ssh.currentPath);
                                            await _detectServer();
                                          },
                                        ),
                                      
                                      const SizedBox(height: 24),
                                      const Text(
                                        'REDIRECCIÓ PORT',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      PortRedirectWidget(
                                        fromPort: 80,
                                        toPort: 3000,
                                        isActive: _portRedirectActive,
                                        onToggle: () async {
                                          if (_portRedirectActive) {
                                            await _ssh.removePortRedirect(80, 3000);
                                          } else {
                                            await _ssh.setupPortRedirect(80, 3000);
                                          }
                                          setState(() {
                                            _portRedirectActive = !_portRedirectActive;
                                          });
                                        },
                                      ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                
                // Status bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.grey.shade200,
                  child: Row(
                    children: [
                      Text(
                        _statusMessage,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const Spacer(),
                      if (_ssh.isConnected)
                        Text(
                          '${_files.length} elements',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
