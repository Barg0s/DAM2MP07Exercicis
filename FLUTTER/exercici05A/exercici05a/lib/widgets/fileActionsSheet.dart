import 'package:flutter/material.dart';

class FileActionsSheet extends StatelessWidget {
  final Map<String, dynamic> item;

  final VoidCallback onInfo;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback? onDownload;

  const FileActionsSheet({
    super.key,
    required this.item,
    required this.onInfo,
    required this.onRename,
    required this.onDelete,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("Informació"),
            onTap: onInfo,
          ),

          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("Reanomenar"),
            onTap: onRename,
          ),

          ListTile(
            leading: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
            title: const Text("Esborrar"),
            onTap: onDelete,
          ),

          if (!item['isDirectory'])
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text("Descarregar"),
              onTap: onDownload,
            ),
        ],
      ),
    );
  }
}