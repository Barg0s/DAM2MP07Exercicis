import 'package:flutter/material.dart';

class FileItemTile extends StatelessWidget {
  final Map<String, dynamic> item;

  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const FileItemTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        item['isDirectory']
            ? Icons.folder
            : Icons.description,

        color:
            item['isDirectory']
                ? Colors.amber
                : Colors.grey,
      ),

      title: Text(item['name']),

      subtitle: Text(
        "${item['permissions']} | ${item['size']} B",
      ),

      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}