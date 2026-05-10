class FileModel {
  final String name;
  final String path;
  final int size;
  final bool isDirectory;

  FileModel({
    required this.name,
    required this.path,
    required this.size,
    required this.isDirectory,
  });

  double getRelativeSize(int totalSize) {
    if (totalSize == 0) return 0;
    return size / totalSize;
  }
}