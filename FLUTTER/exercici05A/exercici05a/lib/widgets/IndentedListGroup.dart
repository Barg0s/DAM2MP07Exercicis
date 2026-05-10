import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:exercici05a/models/models.dart';
import 'package:flutter/material.dart';
class IndentedListGroup extends StatelessWidget {
  final String title;
  final List<String> items;
  final Function(String) onItemSelected;

  const IndentedListGroup({
    super.key,
    required this.title,
    required this.items,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        ...items.map((item) => InkWell(
          onTap: () => onItemSelected(item),
          child: Padding(
            padding: const EdgeInsets.only(left: 24.0, top: 4.0, bottom: 4.0),
            child: Text(item, style: const TextStyle(fontSize: 14, color: Colors.blueGrey)),
          ),
        )),
      ],
    );
  }
}