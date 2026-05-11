import 'package:flutter/material.dart';
import 'fileItemTile.dart';

class FileListWidget extends StatelessWidget {
  final bool isLoading;

  final List<Map<String, dynamic>> items;

  final String currentPath;

  final Function(Map<String, dynamic>) onFileTap;
  final Function(Map<String, dynamic>) onLongPress;

  const FileListWidget({
    super.key,
    required this.isLoading,
    required this.items,
    required this.currentPath,
    required this.onFileTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Text("Carpeta buida: $currentPath"),
      );
    }

    return ListView.builder(
      itemCount: items.length,

      itemBuilder: (context, i) {
        final item = items[i];

        return FileItemTile(
          item: item,

          onTap: () => onFileTap(item),

          onLongPress: () => onLongPress(item),
        );
      },
    );
  }
}