// lib/models/server_model.dart

enum ServerType { nodejs, java, generic }
enum ServerStatus { running, stopped, restarting, error }

class ServerModel {
  String name;
  String host;
  int port;
  String username;
  String keyPath;
  
  // Nuevos campos según el enunciado
  ServerType type;
  ServerStatus status;
  int? remotePort; // Puerto que el servidor usa internamente (ej: 3000)
  bool isPortForwarded; // Si tiene redirección del puerto 80 activa

  ServerModel({
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    required this.keyPath,
    this.type = ServerType.generic,
    this.status = ServerStatus.stopped,
    this.remotePort,
    this.isPortForwarded = false,
  });

  Map<String, dynamic> toJson() => {
        "name": name,
        "host": host,
        "port": port,
        "username": username,
        "keyPath": keyPath,
        "type": type.index,
        "status": status.index,
        "remotePort": remotePort,
        "isPortForwarded": isPortForwarded,
      };

  factory ServerModel.fromJson(Map<String, dynamic> json) {
    return ServerModel(
      name: json["name"],
      host: json["host"],
      port: json["port"],
      username: json["username"],
      keyPath: json["keyPath"],
      type: ServerType.values[json["type"] ?? 2],
      status: ServerStatus.values[json["status"] ?? 1],
      remotePort: json["remotePort"],
      isPortForwarded: json["isPortForwarded"] ?? false,
    );
  }
}