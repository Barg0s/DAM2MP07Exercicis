import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:exercici05a/models/models.dart';


// =============================================
// Widget: Llista amb títols i items seleccionables
// =============================================
class TitledListWidget extends StatelessWidget {
  final String title;
  final List<String> items;
  final List<Color>? itemColors;
  final int? selectedIndex;
  final Function(int)? onItemTap;

  const TitledListWidget({
    super.key,
    required this.title,
    required this.items,
    this.itemColors,
    this.selectedIndex,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        ...items.asMap().entries.map((entry) {
          final isSelected = entry.key == selectedIndex;
          return InkWell(
            onTap: () => onItemTap?.call(entry.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  if (itemColors != null && itemColors!.length > entry.key)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: itemColors![entry.key],
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.blue : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// =============================================
// Widget: Cercle verd/vermell (estat booleà)
// =============================================
class StatusIndicator extends StatelessWidget {
  final bool isActive;
  final double size;

  const StatusIndicator({
    super.key,
    required this.isActive,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _StatusIndicatorPainter(isActive: isActive),
    );
  }
}

class _StatusIndicatorPainter extends CustomPainter {
  final bool isActive;

  _StatusIndicatorPainter({required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Fondo
    final bgPaint = Paint()
      ..color = isActive ? Colors.green.shade100 : Colors.red.shade100;
    canvas.drawCircle(center, radius, bgPaint);

    // Círculo principal
    final mainPaint = Paint()
      ..color = isActive ? Colors.green : Colors.red
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 2, mainPaint);

    // Brillo
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
      radius * 0.25,
      shinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// =============================================
// Widget: Camp de text amb títol
// =============================================
class LabeledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final String? hintText;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================
// Widget: Configuració de redireccions de port
// =============================================
class PortRedirectWidget extends StatelessWidget {
  final int fromPort;
  final int toPort;
  final bool isActive;
  final VoidCallback onToggle;

  const PortRedirectWidget({
    super.key,
    required this.fromPort,
    required this.toPort,
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.green : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sync_alt,
            color: isActive ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Port $fromPort → $toPort',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  isActive ? 'Redirecció activa' : 'Redirecció inactiva',
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: (_) => onToggle(),
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }
}

// =============================================
// Widget: Estat del servidor
// =============================================
class ServerStatusWidget extends StatelessWidget {
  final ServerStatus status;
  final VoidCallback? onStart;
  final VoidCallback? onStop;
  final VoidCallback? onRestart;

  const ServerStatusWidget({
    super.key,
    required this.status,
    this.onStart,
    this.onStop,
    this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (status.error != null) {
      statusColor = Colors.red;
      statusText = 'Error';
      statusIcon = Icons.error;
    } else if (status.isRunning) {
      statusColor = Colors.green;
      statusText = 'En funcionament';
      statusIcon = Icons.play_circle;
    } else {
      statusColor = Colors.grey;
      statusText = 'Aturat';
      statusIcon = Icons.stop_circle;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                status.type == 'nodejs' ? Icons.code : Icons.coffee,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tipus: ${status.type.toUpperCase()}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          if (status.port != null)
            Text(
              'Port: ${status.port}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!status.isRunning)
                ElevatedButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Iniciar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              if (status.isRunning) ...[
                ElevatedButton.icon(
                  onPressed: onStop,
                  icon: const Icon(Icons.stop, size: 16),
                  label: const Text('Aturar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reiniciar'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================
// Widget: Arbre de carpetes estil Baobab
// =============================================
class BaobabTreeWidget extends StatelessWidget {
  final DiskUsageNode rootNode;
  final double size;

  const BaobabTreeWidget({
    super.key,
    required this.rootNode,
    this.size = 300,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BaobabPainter(rootNode: rootNode),
      ),
    );
  }
}

class _BaobabPainter extends CustomPainter {
  final DiskUsageNode rootNode;
  final List<Color> colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.amber,
    Colors.cyan,
  ];

  _BaobabPainter({required this.rootNode});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2 - 10;
    final layerWidth = maxRadius / 3;
    
    _drawNode(
      canvas,
      rootNode,
      center,
      layerWidth * 0.5, // Radio interno del centro
      layerWidth,       // Radio externo del primer nivel
      0,
      2 * math.pi,
      0,
      0, // colorOffset inicial
    );
  }

  void _drawNode(
    Canvas canvas,
    DiskUsageNode node,
    Offset center,
    double innerRadius,
    double outerRadius,
    double startAngle,
    double sweepAngle,
    int depth,
    int colorOffset,
  ) {
    if (sweepAngle < 0.001) return;

    final paint = Paint()
      ..color = colors[(depth + colorOffset) % colors.length]
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(
        center.dx + innerRadius * math.cos(startAngle),
        center.dy + innerRadius * math.sin(startAngle),
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle,
        sweepAngle,
        false,
      )
      ..lineTo(
        center.dx + outerRadius * math.cos(startAngle + sweepAngle),
        center.dy + outerRadius * math.sin(startAngle + sweepAngle),
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle + sweepAngle,
        -sweepAngle,
        false,
      )
      ..close();

    canvas.drawPath(path, paint);

    // Borde más sutil para evitar líneas blancas gruesas
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawPath(path, borderPaint);

    // Dibujar hijos en el siguiente anillo
    if (node.children.isNotEmpty && depth < 2) {
      double currentAngle = startAngle;
      final step = (outerRadius - innerRadius);
      
      for (int i = 0; i < node.children.length; i++) {
        final child = node.children[i];
        final childSweep = (child.size / node.size) * sweepAngle;
        
        _drawNode(
          canvas,
          child,
          center,
          outerRadius,
          outerRadius + step,
          currentAngle,
          childSweep,
          depth + 1,
          colorOffset + i + 1, // Variar color por hermano
        );
        currentAngle += childSweep;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
