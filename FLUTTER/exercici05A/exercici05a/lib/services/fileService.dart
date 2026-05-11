// lib/services/file_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'sshService.dart';
import '../models/serverModel.dart';
import '../models/fileModel.dart';
import 'package:dartssh2/dartssh2.dart';
// Algunos entornos requieren importar explícitamente el cliente para reconocer los tipos SFTP
class FileService {
  final SSHService ssh;
  FileService(this.ssh);

  // Llistar arxius amb detalls de permisos
  Future<String> list(String path) async {
    final result = await ssh.client.run('ls -ll "$path"');
    return String.fromCharCodes(result);
  }

  Future<List<Map<String, dynamic>>> getFileList(String path) async {
    var bytes = await ssh.client.run("ls -ll '$path'");
    String rawList = utf8.decode(bytes);
    final lines = rawList.split('\n');
    List<Map<String, dynamic>> items = [];

    for (var line in lines) {
      String l = line.trim();
      if (!l.startsWith('d') && !l.startsWith('-')) continue;
      final parts = l.split(RegExp(r'\s+'));
      if (parts.length >= 9) {
        int horaIndex = -1;
        for (int i = 0; i < parts.length; i++) {
          if (parts[i].contains(':')) { 
            horaIndex = i; 
            break; 
          }
        }
        String name = (horaIndex != -1 && horaIndex + 1 < parts.length)
            ? parts.sublist(horaIndex + 1).join(' ')
            : parts.sublist(8).join(' ');
        name = name.trim();
        if (name == "." || name == "..") continue;
        items.add({
          'name': name,
          'isDirectory': l.startsWith('d'),
          'permissions': parts[0],
          'size': parts[4],
          'owner': parts[2],
        });
      }
    }
    return items;
  }

  Future<void> downloadFile(String remoteBasePath, String fileName) async {
    final sftp = await ssh.client.sftp();
    final posix = p.Context(style: p.Style.posix);
    final String remotePath = posix.join(remoteBasePath, fileName);
    final remoteFile = await sftp.open(remotePath);
    final List<int> bytes = [];
    await for (var chunk in remoteFile.read()) {
      bytes.addAll(chunk);
    }
    final dir = await getApplicationDocumentsDirectory();
    final localPath = p.join(dir.path, fileName);
    final localFile = File(localPath);
    await localFile.writeAsBytes(bytes);
  }

  Future<void> deleteItem(String path, String name) async {
    await ssh.client.run("rm -rf '$path/$name'");
  }

  Future<void> renameItem(String path, String oldName, String newName) async {
    await ssh.client.run("mv '$path/$oldName' '$path/$newName'");
  }

  Future<List<FileModel>> getDiskUsage(String path) async {
    var bytes = await ssh.client.run("cd '$path' && du -sb * 2>/dev/null");
    String raw = utf8.decode(bytes);
    List<FileModel> carpetas = [];
    for (var line in raw.trim().split('\n')) {
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        carpetas.add(FileModel(
          name: parts.sublist(1).join(' '),
          size: int.tryParse(parts[0]) ?? 0,
          isDirectory: true,
        ));
      }
    }
    carpetas.sort((a, b) => b.size.compareTo(a.size));
    return carpetas;
  }

  // Puja un arxiu o carpeta (amb compressió automàtica si és carpeta)
  Future<void> uploadItem(String localPath, String remotePath) async {
    final sftp = await ssh.client.sftp();
    final isDirectory = await Directory(localPath).exists();

    if (isDirectory) {
      // 1. Comprimir carpeta localment segons l'enunciat
      final zipPath = '$localPath.zip';
      var encoder = ZipFileEncoder();
      encoder.create(zipPath);
      encoder.addDirectory(Directory(localPath));
      encoder.close();

      // 2. Pujar ZIP
      final remoteZipPath = '$remotePath/${localPath.split('/').last}.zip';
      final file = File(zipPath);
      final remoteFile = await sftp.open(remoteZipPath, mode: SftpFileOpenMode.create | SftpFileOpenMode.write);
      await remoteFile.write(file.openRead().cast());
      
      // 3. Descomprimir remotament i esborrar rastre
      await ssh.client.run('unzip $remoteZipPath -d $remotePath && rm $remoteZipPath');
      await file.delete(); // Esborrar local
    } else {
      // Puja fitxer simple
      final file = File(localPath);
      final remoteFile = await sftp.open('$remotePath/${localPath.split('/').last}', 
          mode: SftpFileOpenMode.create | SftpFileOpenMode.write);
      await remoteFile.write(file.openRead().cast());
    }
  }

  // Detectar tipus de servidor en una carpeta
  Future<ServerType> detectServerType(String path) async {
    final ls = await ssh.client.run('ls "$path"');
    final content = String.fromCharCodes(ls);
    
    if (content.contains('package.json')) return ServerType.nodejs;
    if (content.contains('pom.xml') || content.contains('build.gradle')) return ServerType.java;
    return ServerType.generic;
  }
  // lib/services/file_service.dart
Future<void> uploadAndUnzip(String localPath, String remotePath) async {
  // 1. Comprimir localmente (usando la librería 'archive')
  // 2. Subir vía SFTP
  final sftp = await ssh.client.sftp();
  final file = File(localPath);
  final remoteFile = await sftp.open('$remotePath/${file.path.split('/').last}', 
      mode: SftpFileOpenMode.create | SftpFileOpenMode.write);
  await remoteFile.write(file.openRead().cast());
  
  // 3. Descomprimir en Proxmox
  if (localPath.endsWith('.zip')) {
    await ssh.client.run('unzip $remotePath/${file.path.split('/').last} -d $remotePath');
    await ssh.client.run('rm $remotePath/${file.path.split('/').last}'); // Sin dejar rastro
  }
}
}