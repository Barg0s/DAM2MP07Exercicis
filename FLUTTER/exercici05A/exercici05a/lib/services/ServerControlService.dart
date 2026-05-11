// lib/services/server_control_service.dart
import 'dart:convert';
import 'sshService.dart';
import '../models/serverModel.dart';

class ServerControlService {
  final SSHService ssh;
  ServerControlService(this.ssh);

  /// Comprova l'estat del servidor mirant el port i el PID
  Future<ServerStatus> checkStatus(String path, int port) async {
    try {
      // 1. Mirar si el port està obert (més robust amb regex)
      final portResult = await ssh.client.run("ss -tln | grep -E ':$port\\s' || true");
      final portOutput = utf8.decode(portResult).trim();
      final portOpen = portOutput.isNotEmpty;

      // 2. Mirar si hi ha un fitxer PID i si el procés existeix
      final pidResult = await ssh.client.run("cat '$path/.app.pid' 2>/dev/null || echo ''");
      final pid = utf8.decode(pidResult).trim();

      if (pid.isNotEmpty && RegExp(r'^\d+$').hasMatch(pid)) {
        final psResult = await ssh.client.run("ps -p $pid > /dev/null && echo 'alive' || echo 'dead'");
        final isAlive = utf8.decode(psResult).trim() == 'alive';
        
        if (isAlive || portOpen) return ServerStatus.running;
      } else if (portOpen) {
        return ServerStatus.running;
      }

      return ServerStatus.stopped;
    } catch (e) {
      print("Error checkStatus: $e");
      return ServerStatus.error;
    }
  }

  Future<void> startServer(String path, ServerType type, int port) async {
    String startCmd;
    if (type == ServerType.nodejs) {
      startCmd = 'npm start';
    } else if (type == ServerType.java) {
      startCmd = 'java -jar *.jar';
    } else {
      return;
    }

    // Comanda amb shell de login per assegurar PATH (npm, node, java)
    // Redirigim tot a app.log i guardem el PID del procés realitzat
    final fullCmd = "bash -l -c 'cd \"$path\" && nohup $startCmd > app.log 2>&1 & echo \$! > .app.pid'";
    await ssh.client.run(fullCmd);
  }

  Future<void> stopServer(String path, int port) async {
    // 1. Intentar matar per PID guardat
    final pidResult = await ssh.client.run("cat '$path/.app.pid' 2>/dev/null || echo ''");
    final pid = utf8.decode(pidResult).trim();

    if (pid.isNotEmpty && RegExp(r'^\d+$').hasMatch(pid)) {
      await ssh.client.run("kill -9 $pid || true");
      await ssh.client.run("rm '$path/.app.pid' || true");
    }

    // 2. Matar qualsevol procés al port (requereix fuser o similar, fallback a pkill)
    await ssh.client.run("fuser -k $port/tcp || true");
    
    // 3. Fallback per camí del projecte
    await ssh.client.run("pkill -9 -f 'node.*$path' || pkill -9 -f 'java.*$path' || true");
  }

  // Redirecció del port 80 amb socat
  Future<void> togglePort80Redirect(int targetPort, bool enable) async {
    await ssh.client.run("pkill -f 'socat TCP-LISTEN:80'");
    if (enable) {
      await ssh.client.run("nohup socat TCP-LISTEN:80,fork TCP:localhost:$targetPort > /dev/null 2>&1 &");
    }
  }

  // Visualitzar logs
  Future<String> getServerLog(String path) async {
    final result = await ssh.client.run("cd '$path' && tail -n 100 app.log 2>/dev/null || echo 'No app.log'");
    return utf8.decode(result);
  }
}