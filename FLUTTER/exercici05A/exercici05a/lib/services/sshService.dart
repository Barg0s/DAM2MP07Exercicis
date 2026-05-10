// lib/services/ssh_service.dart
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';

class SSHService {
  SSHClient? _client;

  Future<bool> connect({
    required String host,
    required int port,
    required String username,
    required String keyPath,
  }) async {
    try {
      final socket = await SSHSocket.connect(host, port, timeout: const Duration(seconds: 10));
      final key = SSHKeyPair.fromPem(await File(keyPath).readAsString());

      _client = SSHClient(
        socket,
        username: username,
        identities: key,
      );
      return true;
    } catch (e) {
      print("Error de conexión: $e");
      return false;
    }
  }

  SSHClient get client {
    if (_client == null) throw Exception("No connectat al servidor");
    return _client!;
  }

  bool get isConnected => _client != null;

  void disconnect() {
    _client?.close();
    _client = null;
  }
}