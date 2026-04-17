import 'package:flutter/material.dart';

class ItemTile extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const ItemTile({
    super.key,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.person, color: Colors.red),
        title: Text(name),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
