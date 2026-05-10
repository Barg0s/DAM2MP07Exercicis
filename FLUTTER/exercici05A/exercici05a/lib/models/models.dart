
class ServerConfig {
  String name;
  String host;
  int port;
  String username;
  String? password;
  String? privateKeyPath;
  
  ServerConfig({
    required this.name,
    required this.host,
    this.port = 22,
    required this.username,
    this.password,
    this.privateKeyPath,
  });
  
  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      name: json['name'] ?? '',
      host: json['host'] ?? '',
      port: json['port'] ?? 22,
      username: json['username'] ?? '',
      password: json['password'],
      privateKeyPath: json['privateKeyPath'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'password': password,
      'privateKeyPath': privateKeyPath,
    };
  }
}

class FileItem {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final String permissions;
  final String owner;
  final String group;
  final DateTime? modifiedDate;
  
  FileItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size = 0,
    this.permissions = '',
    this.owner = '',
    this.group = '',
    this.modifiedDate,
  });
  
  factory FileItem.fromLsLine(String line, String basePath) {
    // Ejemplo de línea ls -la:
    // drwxr-xr-x 2 user group 4096 Jan 15 10:30 dirname
    // -rw-r--r-- 1 user group 1234 Jan 15 10:30 filename
    final parts = line.split(RegExp(r'\s+'));
    if (parts.length < 9) {
      return FileItem(name: line, path: basePath, isDirectory: false);
    }
    
    final permissions = parts[0];
    final owner = parts[2];
    final group = parts[3];
    final size = int.tryParse(parts[4]) ?? 0;
    final name = parts.sublist(8).join(' ');
    final isDir = permissions.startsWith('d');
    
    return FileItem(
      name: name,
      path: '$basePath/$name',
      isDirectory: isDir,
      size: size,
      permissions: permissions,
      owner: owner,
      group: group,
    );
  }
  
  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class ServerStatus {
  final bool isRunning;
  final String type; // 'nodejs', 'java', 'unknown'
  final String name;
  final int? port;
  final String? error;
  
  ServerStatus({
    required this.isRunning,
    required this.type,
    required this.name,
    this.port,
    this.error,
  });
}

class DiskUsageNode {
  final String name;
  final String path;
  final int size;
  final bool isDirectory;
  final List<DiskUsageNode> children;
  
  DiskUsageNode({
    required this.name,
    required this.path,
    required this.size,
    required this.isDirectory,
    this.children = const [],
  });
  
  double get sizeRatio {
    if (children.isEmpty) return 1.0;
    return size > 0 ? 1.0 : 0.0;
  }
}
