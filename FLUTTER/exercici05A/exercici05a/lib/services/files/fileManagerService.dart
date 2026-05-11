import 'dart:convert';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../sshService.dart';
import '../fileService.dart';

import '../../models/serverModel.dart';

class FilemanagerService {
  final SSHService sshService;
  final FileService fileService;

  FilemanagerService({
    required this.sshService,
    required this.fileService,
  });


  Future<String> runCommand(
    String command,
  ) async {
    final result = await sshService.client.run(
      command,
    );

    return utf8.decode(result);
  }

  // ===============================
  // LOAD FILES
  // ===============================

  Future<List<Map<String, dynamic>>> loadFiles(
    String path,
  ) async {
    final bytes = await sshService.client.run(
      "ls -ll '$path'",
    );

    final rawList = utf8.decode(bytes);

    final lines = rawList.split('\n');

    List<Map<String, dynamic>> items = [];

    for (var line in lines) {
      String l = line.trim();

      if (!l.startsWith('d') &&
          !l.startsWith('-')) {
        continue;
      }

      final parts = l.split(
        RegExp(r'\s+'),
      );

      if (parts.length >= 9) {
        int hourIndex = -1;

        for (int i = 0; i < parts.length; i++) {
          if (parts[i].contains(':')) {
            hourIndex = i;
            break;
          }
        }

        String name =
            (hourIndex != -1 &&
                    hourIndex + 1 <
                        parts.length)
                ? parts
                    .sublist(hourIndex + 1)
                    .join(' ')
                : parts.sublist(8).join(' ');

        name = name.trim();

        if (name == "." || name == "..") {
          continue;
        }

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

  // DETECT SERVER TYPE

  Future<ServerType> detectServerType(
    String path,
  ) async {
    return await fileService.detectServerType(
      path,
    );
  }

  // ===============================
  // NAVIGATION
  // ===============================

  String navigateTo(
    String currentPath,
    String initialPath,
    String name,
  ) {
    if (name == "..") {
      if (currentPath == initialPath ||
          currentPath == "/") {
        return currentPath;
      }

      List<String> parts =
          currentPath.split('/');

      parts.removeLast();

      return parts.join('/') == ""
          ? "/"
          : parts.join('/');
    }

    return currentPath == "/"
        ? "/$name"
        : "$currentPath/$name";
  }

  // ===============================
  // DELETE FILE/FOLDER
  // ===============================

  Future<void> deleteItem(
    String currentPath,
    String name,
  ) async {
    await runCommand(
      "rm -rf '$currentPath/$name'",
    );
  }

  // ===============================
  // RENAME FILE/FOLDER
  // ===============================

  Future<void> renameItem(
    String currentPath,
    String oldName,
    String newName,
  ) async {
    await runCommand(
      "mv '$currentPath/$oldName' '$currentPath/$newName'",
    );
  }

  // ===============================
  // DOWNLOAD FILE
  // ===============================

  Future<String> downloadFile(
    String currentPath,
    String name,
  ) async {
    final sftp =
        await sshService.client.sftp();

    final remoteFile = await sftp.open(
      '$currentPath/$name',
    );

    final List<int> bytes = [];

    await for (var chunk in remoteFile.read()) {
      bytes.addAll(chunk);
    }

    final dir =
        await getApplicationDocumentsDirectory();

    final localPath = p.join(
      dir.path,
      name,
    );

    final localFile = File(localPath);

    await localFile.writeAsBytes(bytes);

    return localPath;
  }

  // ===============================
  // UPLOAD FILE
  // ===============================

  Future<String?> uploadFile(
    String currentPath,
  ) async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles();

    if (result == null ||
        result.files.single.path == null) {
      return null;
    }

    File localFile = File(
      result.files.single.path!,
    );

    String fileName = p.basename(
      localFile.path,
    );

    final sftp =
        await sshService.client.sftp();

    final remoteFile = await sftp.open(
      '$currentPath/$fileName',

      mode:
          SftpFileOpenMode.create |
          SftpFileOpenMode.write,
    );

    await remoteFile.write(
      localFile.openRead().cast(),
    );

    // unzip automático
    if (fileName.endsWith('.zip')) {
      await runCommand(
        "cd '$currentPath' && unzip -o '$fileName'",
      );
    }

    return fileName;
  }

  // ===============================
  // LOAD DISK USAGE
  // ===============================

  Future<List<Map<String, dynamic>>>
  loadDiskUsage(String currentPath) async {
    final bytes = await sshService.client.run(
      "cd '$currentPath' && du -sb * 2>/dev/null",
    );

    final raw = utf8.decode(bytes);

    List<Map<String, dynamic>> folders = [];

    for (var line in raw.trim().split('\n')) {
      final parts = line.split(
        RegExp(r'\s+'),
      );

      if (parts.length >= 2) {
        folders.add({
          'name': parts
              .sublist(1)
              .join(' '),

          'size':
              int.tryParse(parts[0]) ?? 0,
        });
      }
    }

    folders.sort(
      (a, b) =>
          b['size'].compareTo(a['size']),
    );

    return folders;
  }
}