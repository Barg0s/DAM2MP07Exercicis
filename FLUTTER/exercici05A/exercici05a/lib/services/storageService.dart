// lib/services/storage_service.dart
import 'dart:convert';
import 'dart:io';
import '../models/serverModel.dart';

class StorageService {
  final String path;

  // El constructor recibe la ruta de la carpeta de documentos de la app
  StorageService(this.path);

  // Define dónde se guardará el archivo
  Future<File> get _file async {
    return File('$path/servers.json');
  }

  // Carga la lista de servidores desde el archivo JSON
  Future<List<ServerModel>> loadServers() async {
    try {
      final file = await _file;
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      final data = jsonDecode(content) as List;

      // Convierte cada mapa de JSON de nuevo a un objeto ServerModel
      return data.map((e) => ServerModel.fromJson(e)).toList();
    } catch (_) {
      // Si hay un error (archivo corrupto, etc.), devuelve una lista vacía
      return [];
    }
  }

  // Guarda la lista de servidores convirtiéndola a JSON
  Future<void> saveServers(List<ServerModel> servers) async {
    final file = await _file;
    // Convierte la lista de objetos a una cadena de texto JSON
    final data = jsonEncode(servers.map((e) => e.toJson()).toList());
    await file.writeAsString(data);
  }
}