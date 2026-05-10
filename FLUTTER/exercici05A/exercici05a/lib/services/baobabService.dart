// lib/services/baobab_service.dart

import 'sshService.dart';

class BaobabService {
  final SSHService ssh;
  BaobabService(this.ssh);

  Future<Map<String, int>> getDirectorySizes(String path) async {
    // Executa 'du' per obtenir mides en bytes de subcarpetes
    final result = await ssh.client.run('du -sb $path/*');
    final output = String.fromCharCodes(result);
    
    Map<String, int> sizes = {};
    for (var line in output.trim().split('\n')) {
      if (line.isEmpty) continue;
      var parts = line.split('\t');
      if (parts.length == 2) {
        sizes[parts[1].split('/').last] = int.tryParse(parts[0]) ?? 0;
      }
    }
    return sizes;
  }
}