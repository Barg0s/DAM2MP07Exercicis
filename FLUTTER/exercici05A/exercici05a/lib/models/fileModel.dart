class FileModel {
  final String name;
  final int size;
  final bool isDirectory;
  final String permissions;
  final String owner;

  FileModel({
    required this.name,
    required this.size,
    required this.isDirectory,
    this.permissions = "",
    this.owner = "",
  });
}