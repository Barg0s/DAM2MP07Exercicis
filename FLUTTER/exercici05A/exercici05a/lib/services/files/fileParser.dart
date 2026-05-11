// services/files/file_parser.dart

class FileParser {
  List<Map<String, dynamic>> parseLs(String raw) {
    final lines = raw.split('\n');
    final items = <Map<String, dynamic>>[];

    for (final line in lines) {
      final l = line.trim();

      if (!l.startsWith('d') && !l.startsWith('-')) continue;

      final parts = l.split(RegExp(r'\s+'));
      if (parts.length < 9) continue;

      final hourIndex = parts.indexWhere((p) => p.contains(':'));

      final name = (hourIndex != -1)
          ? parts.sublist(hourIndex + 1).join(' ')
          : parts.sublist(8).join(' ');

      final clean = name.trim();
      if (clean == '.' || clean == '..') continue;

      items.add({
        'name': clean,
        'isDirectory': l.startsWith('d'),
        'permissions': parts[0],
        'size': parts[4],
        'owner': parts[2],
      });
    }

    return items;
  }
}