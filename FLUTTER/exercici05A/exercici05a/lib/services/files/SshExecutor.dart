// services/ssh/ssh_executor.dart

import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';

class SshExecutor {
  final SSHClient client;

  SshExecutor(this.client);

  Future<String> run(String command) async {
    final result = await client.run(command);
    return utf8.decode(result);
  }
}