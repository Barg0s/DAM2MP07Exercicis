import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:exercici05a/models/models.dart';


class SSHService {
  SSHClient? _client;
  SftpClient? _sftp;
  ServerConfig? _currentServer;
  String _currentPath = '/';
  
  bool get isConnected => _client != null;
  String get currentPath => _currentPath;
  ServerConfig? get currentServer => _currentServer;
  
  Future<void> connect(ServerConfig server) async {
    try {
      final socket = await SSHSocket.connect(
        server.host,
        server.port,
        timeout: const Duration(seconds: 10),
      );
      List<SSHKeyPair>? identities;
      if (server.privateKeyPath != null && server.privateKeyPath!.isNotEmpty) {
        final pemFile = File(server.privateKeyPath!);
        if (await pemFile.exists()) {
          final pemContent = await pemFile.readAsString();
          identities = SSHKeyPair.fromPem(pemContent);
        } else {
          throw Exception('Arxiu de clau privada no trobat: ${server.privateKeyPath}');
        }
      }

      _client = SSHClient(
        socket,
        username: server.username,
        onPasswordRequest: (server.password != null && server.password!.isNotEmpty) 
            ? () => server.password! 
            : null,
        identities: identities,
      );
      
      await _client!.authenticated;
      _sftp = await _client!.sftp();
      _currentServer = server;
      
      // Obtener el directorio inicial real del usuario remoto
      try {
        final session = await _client!.execute('pwd');
        final pwdStr = await utf8.decodeStream(session.stdout);
        _currentPath = pwdStr.trim();
        if (_currentPath.isEmpty) _currentPath = '/';
      } catch (e) {
        _currentPath = '/home/${server.username}';
      }
    } catch (e) {
      throw Exception('Error conectando: $e');
    }
  }
  
  Future<void> disconnect() async {
    _sftp?.close();
    _client?.close();
    _sftp = null;
    _client = null;
    _currentServer = null;
  }
  
  Future<List<FileItem>> listDirectory([String? path]) async {
    if (_client == null) throw Exception('No conectado');
    
    final targetPath = path ?? _currentPath;
    final result = await runCommand('LC_ALL=C ls -la "$targetPath"');
    
    final lines = result.split('\n')
        .where((l) => l.isNotEmpty && !l.startsWith('total'))
        .where((l) => !l.endsWith('.') && !l.endsWith('..'))
        .toList();
    
    return lines.map((l) => FileItem.fromLsLine(l, targetPath)).toList();
  }
  
  Future<String> runCommand(String command) async {
    if (_client == null) throw Exception('No conectado');
    
    final session = await _client!.execute(command);
    final stdout = await utf8.decodeStream(session.stdout);
    await session.done;
    return stdout;
  }
  
  Future<void> changeDirectory(String path) async {
    if (path.startsWith('/')) {
      _currentPath = path;
    } else if (path == '..') {
      final parts = _currentPath.split('/');
      if (parts.length > 1) {
        parts.removeLast();
        _currentPath = parts.isEmpty ? '/' : parts.join('/');
      }
    } else {
      _currentPath = '$_currentPath/$path';
    }
    _currentPath = _currentPath.replaceAll('//', '/');
  }
  
  Future<void> createDirectory(String name) async {
    await runCommand('mkdir -p "$_currentPath/$name"');
  }
  
  Future<void> deleteFile(String filename) async {
    if (_sftp == null) throw Exception('No conectado');
    await runCommand('rm -rf "$_currentPath/$filename"');
  }
  
  Future<void> renameFile(String oldName, String newName) async {
    await runCommand('mv "$_currentPath/$oldName" "$_currentPath/$newName"');
  }
  
  Future<String> getFileInfo(String name) async {
    return await runCommand('stat "$_currentPath/$name"');
  }
  
  Future<void> downloadFile(String remoteName, String localPath) async {
    if (_sftp == null) throw Exception('SFTP no disponible');
    
    final remoteFile = await _sftp!.open('$_currentPath/$remoteName');
    final localFile = File(localPath);
    final sink = localFile.openWrite();
    
    await for (final chunk in remoteFile.read()) {
      sink.add(chunk);
    }
    
    await sink.close();
    await remoteFile.close();
  }

  Future<void> downloadFolderAsZip(String remoteFolderName, String localPath) async {
    final zipName = '${remoteFolderName}_download.zip';
    // Comprimir en el servidor
    await runCommand('cd "$_currentPath" && zip -r "$zipName" "$remoteFolderName"');
    
    try {
      // Descargar el zip resultante
      await downloadFile(zipName, localPath);
    } finally {
      // Eliminar el zip temporal del servidor
      await runCommand('rm "$_currentPath/$zipName"');
    }
  }
  
  Future<void> uploadFile(String localPath, String remoteName) async {
    if (_sftp == null) throw Exception('SFTP no disponible');
    
    final localFile = File(localPath);
    final remoteFile = await _sftp!.open(
      '$_currentPath/$remoteName',
      mode: SftpFileOpenMode.create | SftpFileOpenMode.write,
    );
    
    await remoteFile.write(localFile.openRead().cast());
    await remoteFile.close();
  }
  
  Future<void> extractZip(String zipName) async {
    // Intentar unzip primero, luego python3 como fallback
    final cmd = 'unzip -o "$zipName" 2>&1 || python3 -m zipfile -e "$zipName" . 2>&1';
    final result = await runCommand('cd "$_currentPath" && $cmd');
    
    if (result.contains('not found') && result.contains('python3')) {
      throw Exception('Cal instal·lar "unzip" al servidor.');
    }
  }
  
  Future<void> uploadFolderAsZip(String localFolderPath, String remoteName) async {
    if (_sftp == null) throw Exception('No conectado');
    final encoder = ZipFileEncoder();
    final tempDir = await getTemporaryDirectory();
    final zipPath = '${tempDir.path}/$remoteName.zip';
    encoder.zipDirectory(Directory(localFolderPath), filename: zipPath);
    
    await uploadFile(zipPath, '$remoteName.zip');
    
    // Unzip y limpiar en remoto
    await runCommand('cd "$_currentPath" && unzip -o "$remoteName.zip"');
    await runCommand('rm "$_currentPath/$remoteName.zip"');
    
    // Limpiar local
    File(zipPath).deleteSync();
  }
  
  Future<DiskUsageNode> getDiskUsage(String path) async {
    // Usamos --max-depth=1 para no saturar el comando
    final result = await runCommand('du --max-depth=1 -k "$path"');
    
    final Map<String, int> sizes = {};
    int rootSize = 0;
    
    for (final line in result.split('\n')) {
      if (line.trim().isEmpty) continue;
      final parts = line.trim().split(RegExp(r'\t|\s+'));
      if (parts.length >= 2) {
        final sizeKb = int.tryParse(parts[0]) ?? 0;
        var folderPath = parts.sublist(1).join(' ').trim();
        
        // Normalizar rutas para comparar
        final normPath = path.endsWith('/') ? path.substring(0, path.length - 1) : path;
        var normFolder = folderPath.endsWith('/') ? folderPath.substring(0, folderPath.length - 1) : folderPath;
        
        // Si es ruta relativa al directorio actual
        if (normFolder == '.' || normFolder == './' || normFolder == normPath) {
          rootSize = sizeKb;
        } else {
          // Si la ruta es relativa (empieza por ./), convertirla a absoluta para el modelo
          if (normFolder.startsWith('./')) {
            folderPath = '$normPath/${normFolder.substring(2)}';
          }
          sizes[folderPath] = sizeKb;
        }
      }
    }
    
    List<DiskUsageNode> children = [];
    sizes.forEach((k, v) {
      final name = k.replaceAll(RegExp(r'/+$'), '').split('/').last;
      children.add(DiskUsageNode(
        name: name.isEmpty ? k : name,
        path: k,
        size: v * 1024,
        isDirectory: true,
      ));
    });
    
    // Si no se detectó el rootSize, sumar hijos
    if (rootSize == 0 && children.isNotEmpty) {
      rootSize = children.fold<int>(0, (sum, child) => sum + (child.size ~/ 1024).toInt());
    }
    if (rootSize == 0) rootSize = 1;

    final rootName = path.replaceAll(RegExp(r'/+$'), '').split('/').last;
    
    return DiskUsageNode(
      name: rootName.isEmpty ? '/' : rootName,
      path: path,
      size: rootSize * 1024,
      isDirectory: true,
      children: children,
    );
  }
  
  Future<ServerStatus?> detectServer(String path) async {
    // Detectar package.json para Node.js
    final hasPackageJson = await runCommand('test -f "$path/package.json" && echo "yes"');
    if (hasPackageJson.trim() == 'yes') {
      final isRunning = await runCommand('pgrep -f "node.*$path" || true');
      return ServerStatus(
        isRunning: isRunning.trim().isNotEmpty,
        type: 'nodejs',
        name: path.split('/').last,
        port: 3000,
      );
    }
    
    // Detectar pom.xml o build.gradle para Java
    final hasJava = await runCommand('test -f "$path/pom.xml" -o -f "$path/build.gradle" && echo "yes"');
    if (hasJava.trim() == 'yes') {
      final isRunning = await runCommand('pgrep -f "java.*$path" || true');
      return ServerStatus(
        isRunning: isRunning.trim().isNotEmpty,
        type: 'java',
        name: path.split('/').last,
        port: 8080,
      );
    }
    
    return null;
  }
  
  Future<void> startNodeServer(String path) async {
    await runCommand('cd "$path" && nohup npm start > /dev/null 2>&1 &');
  }
  
  Future<void> stopNodeServer(String path) async {
    await runCommand('pkill -f "node.*$path" || true');
  }
  
  Future<void> restartNodeServer(String path) async {
    await stopNodeServer(path);
    await Future.delayed(const Duration(seconds: 1));
    await startNodeServer(path);
  }
  
  Future<void> setupPortRedirect(int fromPort, int toPort) async {
    await runCommand(
      'sudo iptables -t nat -A PREROUTING -p tcp --dport $fromPort -j REDIRECT --to-port $toPort'
    );
  }
  
  Future<void> removePortRedirect(int fromPort, int toPort) async {
    await runCommand(
      'sudo iptables -t nat -D PREROUTING -p tcp --dport $fromPort -j REDIRECT --to-port $toPort || true'
    );
  }
  

}

class ConfigService {
  static const String _configFileName = 'servers.json';
  
  Future<String> get _configPath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_configFileName';
  }
  
  Future<List<ServerConfig>> loadServers() async {
    try {
      final file = File(await _configPath);
      if (!await file.exists()) return [];
      
      final content = await file.readAsString();
      final List<dynamic> json = jsonDecode(content);
      return json.map((j) => ServerConfig.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<void> saveServers(List<ServerConfig> servers) async {
    final file = File(await _configPath);
    final json = servers.map((s) => s.toJson()).toList();
    await file.writeAsString(jsonEncode(json));
  }
  
  Future<void> addServer(ServerConfig server) async {
    final servers = await loadServers();
    servers.add(server);
    await saveServers(servers);
  }
  
  Future<void> removeServer(String name) async {
    final servers = await loadServers();
    servers.removeWhere((s) => s.name == name);
    await saveServers(servers);
  }
}
