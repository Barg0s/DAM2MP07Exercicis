// lib/screens/file_manager_screen.dart
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert'; // NECESARIO PARA utf8.decode()
import '../services/sshService.dart';
import '../services/fileService.dart';
import '../models/serverModel.dart';
import '../models/fileModel.dart';
// --- MODELO DE DATOS PARA EL BAOBAB ---


class FileManagerScreen extends StatefulWidget {
  final String initialPath;
  final SSHService sshService;

  const FileManagerScreen({
    super.key,
    required this.initialPath,
    required this.sshService,
  });

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  late FileService _fileService;
  late String _currentPath;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  ServerType _serverType = ServerType.generic;

  @override
  void initState() {
    super.initState();
    _fileService = FileService(widget.sshService);
    _currentPath = widget.initialPath;
    _refreshFiles();
  }

  Future<void> _refreshFiles() async {
  if (!mounted) return;
  setState(() => _isLoading = true);
  
  try {
    String rawList = await _fileService.list(_currentPath);
    final lines = rawList.split('\n');
    List<Map<String, dynamic>> tempItems = [];

    for (var line in lines) {
      String l = line.trim();
      
      // 1. FILTRO DE SEGURIDAD: Solo líneas que empiecen por 'd' o '-'
      if (!l.startsWith('d') && !l.startsWith('-')) continue;

      final parts = l.split(RegExp(r'\s+'));

      if (parts.length >= 9) {
        // 2. BUSCAR EL ÍNDICE DE LA HORA (ej. 15:42)
        int horaIndex = -1;
        for (int i = 0; i < parts.length; i++) {
          if (parts[i].contains(':')) {
            horaIndex = i;
            break;
          }
        }

        String name = "";
        // 3. SI ENCONTRAMOS LA HORA: El nombre empieza en la siguiente posición
        if (horaIndex != -1 && horaIndex + 1 < parts.length) {
          name = parts.sublist(horaIndex + 1).join(' ');
        } else {
          // Si no hay ':' (porque es un archivo viejo y sale el año), suele ser el índice 8
          name = parts.sublist(8).join(' ');
        }

        // Limpiar espacios y filtrar carpetas del sistema
        name = name.trim();
        if (name == '.' || name == '..') continue;

        tempItems.add({
          'name': name,
          'isDirectory': l.startsWith('d'),
          'permissions': parts[0],
          'size': parts[4],
          'owner': parts[2],
        });
      }
    }

    final type = await _fileService.detectServerType(_currentPath);

    if (!mounted) return;
    setState(() {
      _items = tempItems;
      _serverType = type;
      _isLoading = false;
    });
  } catch (e) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    _showSnackBar("Error: $e", isError: true);
  }
}
  // --- LÓGICA DEL BAOBAB CON SOLUCIÓN A Uint8List ---
  void _mostrarBaobab() async {
    setState(() => _isLoading = true);
    try {
      // 1. Ejecutar comando (obtenemos bytes)
      var bytes = await widget.sshService.client.run("cd $_currentPath && du -sb *");
      
      // 2. Decodificar bytes a String
      String raw = utf8.decode(bytes);
      
      List<FileModel> carpetas = [];
      final lines = raw.trim().split('\n');
      
      for (var line in lines) {
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          carpetas.add(FileModel(
            name: parts[1],
            size: int.parse(parts[0]),
            path: "$_currentPath/${parts[1]}",
            isDirectory: true,
          ));
        }
      }

      carpetas.sort((a, b) => b.size.compareTo(a.size));
      setState(() => _isLoading = false);

      if (!mounted) return;
      _abrirDialogoGrafico(carpetas);

    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Error en Baobab: $e", isError: true);
    }
  }

  void _abrirDialogoGrafico(List<FileModel> datos) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Analitzador d'espai"),
        content: SizedBox(
          width: 400,
          height: 450,
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  painter: DiskUsagePainter({for (var f in datos) f.name: f.size}),
                  size: const Size(200, 200),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Top 5 elements més pesats:", style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: datos.length > 5 ? 5 : datos.length,
                  itemBuilder: (context, i) => ListTile(
                    dense: true,
                    leading: Icon(Icons.circle, color: _getColors()[i % _getColors().length], size: 12),
                    title: Text(datos[i].name, style: const TextStyle(fontSize: 12)),
                    trailing: Text("${(datos[i].size / 1024).toStringAsFixed(1)} KB"),
                  ),
                ),
              )
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("TANCAR"))],
      ),
    );
  }

  Future<void> _handleServerAction(String action) async {
    String command = '';
    if (_serverType == ServerType.nodejs) {
      command = action == 'start' ? 'cd $_currentPath && npm start &' : 'pkill -f node';
    } else if (_serverType == ServerType.java) {
      command = action == 'start' ? 'cd $_currentPath && java -jar *.jar &' : 'pkill -f java';
    }

    try {
      await widget.sshService.client.run(command);
      _showSnackBar("Acció $action executada");
    } catch (e) {
      _showSnackBar("Error SSH: $e", isError: true);
    }
  }

  void _navigateTo(String name) {
    if (name == "..") {
      List<String> parts = _currentPath.split('/');
      parts.removeLast();
      _currentPath = parts.isEmpty || (parts.length == 1 && parts[0] == "") ? "/" : parts.join('/');
    } else {
      _currentPath = _currentPath == "/" ? "/$name" : "$_currentPath/$name";
    }
    _refreshFiles();
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPath, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
        actions: [
          IconButton(icon: const Icon(Icons.pie_chart), onPressed: _mostrarBaobab),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshFiles),
        ],
      ),
      body: Column(
        children: [
          if (_serverType != ServerType.generic)
            Card(
              margin: const EdgeInsets.all(10),
              color: Colors.blue.shade50,
              child: ListTile(
                leading: const Icon(Icons.settings_input_component),
                title: Text("Servidor ${_serverType.name.toUpperCase()} detectat"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(onPressed: () => _handleServerAction('start'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("START")),
                    const SizedBox(width: 5),
                    ElevatedButton(onPressed: () => _handleServerAction('stop'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("STOP")),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return ListTile(
                      leading: Icon(item['isDirectory'] ? Icons.folder : Icons.description, color: item['isDirectory'] ? Colors.amber : Colors.grey),
                      title: Text(item['name']),
                      subtitle: Text("${item['permissions']} | ${item['size']} bytes"),
                      onTap: () => item['isDirectory'] ? _navigateTo(item['name']) : null,
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

// --- PINTORES Y COLORES ---

List<Color> _getColors() => [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple, Colors.cyan];

class DiskUsagePainter extends CustomPainter {
  final Map<String, int> folderSizes;
  DiskUsagePainter(this.folderSizes);

  @override
  void paint(Canvas canvas, Size size) {
    if (folderSizes.isEmpty) return;
    final double totalSize = folderSizes.values.fold(0, (sum, item) => sum + item);
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = min(size.width, size.height) / 2;
    double startAngle = -pi / 2;

    int i = 0;
    folderSizes.forEach((name, bytes) {
      final sweepAngle = (bytes / totalSize) * 2 * pi;
      final paint = Paint()..color = _getColors()[i % _getColors().length]..style = PaintingStyle.fill;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
      i++;
    });
    // Agujero central para el Donut
    canvas.drawCircle(center, radius * 0.4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}