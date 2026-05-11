// services/files/file_transfer_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';

class fileDescargar {
  final SSHClient client;

  fileDescargar(this.client);

  Future<List<int>> download(String remotePath) async {
    final sftp = await client.sftp();
    final file = await sftp.open(remotePath);

    final bytes = <int>[];

    await for (final chunk in file.read()) {
      bytes.addAll(chunk);
    }

    return bytes;
  }


  Future<void> upload(String remotePath, File file) async {
    final sftp = await client.sftp();

    final remote = await sftp.open(
      remotePath,
      mode: SftpFileOpenMode.create | SftpFileOpenMode.write,
    );

    await remote.write(file.openRead().cast());
  }
}