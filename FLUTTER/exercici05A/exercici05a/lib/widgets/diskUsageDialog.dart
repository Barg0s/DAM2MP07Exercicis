import 'package:flutter/material.dart';

import '../../models/fileModel.dart';
import 'diskUsagePainter.dart';

class DiskUsageDialog extends StatelessWidget {
  final List<FileModel> data;

  const DiskUsageDialog({
    super.key,
    required this.data,
  });

  List<Color> _getColors() {
    return [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.pink,
      Colors.indigo,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();

    return AlertDialog(
      title: const Text(
        "Analitzador de disc",
      ),

      content: SizedBox(
        width: 400,
        height: 450,

        child: Column(
          children: [
            Expanded(
              flex: 2,

              child: CustomPaint(
                painter: DiskUsagePainter(
                  {
                    for (var f in data.take(5))
                      f.name: f.size,
                  },
                  colors,
                ),

                size: const Size(220, 220),
              ),
            ),

            const Divider(),

            Expanded(
              flex: 1,

              child: ListView.builder(
                itemCount:
                    data.length > 5
                        ? 5
                        : data.length,

                itemBuilder: (context, i) {
                  return ListTile(
                    dense: true,

                    leading: Icon(
                      Icons.circle,
                      color:
                          colors[i %
                              colors.length],
                      size: 12,
                    ),

                    title: Text(
                      data[i].name,

                      style:
                          const TextStyle(
                            fontSize: 11,
                          ),
                    ),

                    trailing: Text(
                      "${(data[i].size / 1024).toStringAsFixed(1)} KB",
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed:
              () => Navigator.pop(context),

          child: const Text("Tancar"),
        ),
      ],
    );
  }
}