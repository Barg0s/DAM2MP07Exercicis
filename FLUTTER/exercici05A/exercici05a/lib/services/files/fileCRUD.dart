// services/files/file_operations_service.dart

import 'sshExecutor.dart';

class fileCRUD {
  final SshExecutor ssh;

  fileCRUD(this.ssh);

  Future<void> delete(String path, String name) async {
    await ssh.run("rm -rf '$path/$name'");
  }

  Future<void> rename(
    String path,
    String oldName,
    String newName,
  ) async {
    await ssh.run("mv '$path/$oldName' '$path/$newName'");
  }

  Future<void> createFolder(String path, String name) async {
    await ssh.run("mkdir '$path/$name'");
  }

  Future<void> move(String from, String to) async {
    await ssh.run("mv '$from' '$to'");
  }
}