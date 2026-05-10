// lib/models/file_node_model.dart

class FileModel {
  final String name;
  final String path;
  final int size; // Tamaño en bytes para el cálculo del Canvas
  final bool isDirectory;
  final List<FileModel> children;
  final String permissions; // Para el requisito de "Mostrar informació i permissos"

  FileModel({
    required this.name,
    required this.path,
    required this.size,
    required this.isDirectory,
    this.children = const [],
    this.permissions = "",
  });

  // Calcula el porcentaje que ocupa este nodo respecto al total del padre
  double getRelativeSize(int totalSize) {
    if (totalSize == 0) return 0;
    return size / totalSize;
  }
}