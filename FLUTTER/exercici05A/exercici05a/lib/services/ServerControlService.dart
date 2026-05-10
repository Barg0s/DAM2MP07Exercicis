// lib/services/server_control_service.dart
import 'sshService.dart';
import '../models/serverModel.dart';

class ServerControlService {
  final SSHService ssh;
  ServerControlService(this.ssh);

  Future<void> startServer(String path, ServerType type) async {
    if (type == ServerType.nodejs) {
      await ssh.client.run('cd $path && npm start &');
    } else if (type == ServerType.java) {
      await ssh.client.run('cd $path && java -jar *.jar &');
    }
  }

  Future<void> stopServer(ServerType type) async {
    final cmd = type == ServerType.nodejs ? 'pkill node' : 'pkill java';
    await ssh.client.run(cmd);
  }

  // Configurar redirecció del port 80 cap al port de l'aplicació
  Future<void> togglePortForwarding(int appPort, bool enable) async {
    final action = enable ? '-A' : '-D';
    final cmd = 'sudo iptables -t nat $action PREROUTING -p tcp --dport 80 -j REDIRECT --to-port $appPort';
    await ssh.client.run(cmd);
  }
}