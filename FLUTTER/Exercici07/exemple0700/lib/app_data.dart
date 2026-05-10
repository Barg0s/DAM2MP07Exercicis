import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'drawable.dart';

const functionCallingModel = 'granite4:3b';

class AppData extends ChangeNotifier {
  String _responseText = "";
  bool _isLoading = false;
  bool _isInitial = true;

  final List<Drawable> drawables = [];

  String get responseText =>
      _isInitial ? "..." : (_isLoading ? "Esperant a Ollama..." : _responseText);

  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void addDrawable(Drawable drawable) {
    drawables.add(drawable);
    notifyListeners();
  }
  // --- FUNCIONS D'AJUDA ---
  
  double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Color parseColor(dynamic value) {
    if (value != null && value is String) {
      String hex = value.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    }
    return Colors.black; 
  }

  bool parseBool(dynamic value) {
    if (value != null) {
      if (value is bool) return value;
      if (value.toString().toLowerCase() == 'true') return true;
    }
    return false;
  }

  double _randomBetween(double min, double max) {
    return min + Random().nextDouble() * (max - min);
  }

  Future<void> callWithCustomTools({required String userPrompt}) async {
    const apiUrl = 'http://localhost:11434/api/chat';

    _responseText = "Enviant petició...";
    _isInitial = false;
    setLoading(true);

    String currentShapes = drawables.map((d) => jsonEncode(d.toJson())).toList().toString();

    final body = {
      "model": functionCallingModel,
      "stream": false,
      "messages": [
              {
                "role": "system",
                "content": """You are an AI drawing assistant. IMPORTANT INSTRUCTIONS:
                1. The canvas size is exactly WIDTH: 400 and HEIGHT: 500 pixels. 
                2. Calculate percentages explicitly (e.g., '10% of width' = 40, 'half height' = 250).
                3. CURRENT SHAPES ON CANVAS: $currentShapes.
                4. To modify or delete an existing shape, you MUST use its 'id' and call modify_shape or delete_shape.
                5. Do not draw outside bounds X:[0, 400] and Y:[0, 500]."""
              },
              {"role": "user", "content": userPrompt}
            ],
      "tools": tools
    };
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final message = jsonResponse['message'];

        if (message != null) {
          //  LLEGIR RESPOSTA O DIBUIXAR
          if (message['tool_calls'] != null) {
            _responseText = "Drawing...\n";
            final toolCalls = message['tool_calls'] as List<dynamic>;
            for (final toolCall in toolCalls) {
              if (toolCall['function'] != null) {
                _processFunctionCall(toolCall['function']);
              }
            }
          } else if (message['content'] != null && message['content'].toString().isNotEmpty) {
            _responseText = message['content'];
          } else {
            _responseText = "La IA ha processat la petició però no ha retornat res.";
          }
        }
      } else {
        _responseText = "Error HTTP: ${response.statusCode}";
      }
    } catch (e) {
      print("Error during API call: $e");
      _responseText = "Error de connexió: Assegura't que Ollama està encès.";
    } finally {
      setLoading(false);
    }
  }

  void clearCanvas() {
      drawables.clear();
      _responseText = "Llenç netejat.";
      notifyListeners();
    }

  // --- PROCESSAR EINES  ---

void _processFunctionCall(Map<String, dynamic> functionCall) {
  final name = functionCall['name'];
  final parameters = functionCall['arguments'] ?? {};

  final String newId = "${name}_${DateTime.now().microsecondsSinceEpoch}";

  final strokeWidth = parameters['thickness'] != null
      ? parseDouble(parameters['thickness'])
      : 2.0;

  final fill = parseBool(parameters['fill']);

  final strokeColor = parseColor(parameters['color']);
  final fillColor = parameters['fillColor'] != null
      ? parseColor(parameters['fillColor'])
      : Colors.transparent;

  // 🔥 FIX GRADIENT (IMPORTANTE)
  String? gradientType = parameters['gradientType']
      ?.toString()
      .trim()
      .toLowerCase();

  if (gradientType != 'linear' && gradientType != 'radial') {
    gradientType = null;
  }

  Color? gradientColor1 = parameters['gradientColor1'] != null
      ? parseColor(parameters['gradientColor1'])
      : null;

  Color? gradientColor2 = parameters['gradientColor2'] != null
      ? parseColor(parameters['gradientColor2'])
      : null;

  switch (name) {

    case 'draw_circle':
      final x = parameters['x'] != null
          ? parseDouble(parameters['x'])
          : _randomBetween(10.0, 390.0);

      final y = parameters['y'] != null
          ? parseDouble(parameters['y'])
          : _randomBetween(10.0, 490.0);

      final radius = parameters['radius'] != null
          ? parseDouble(parameters['radius'])
          : _randomBetween(10.0, 25.0);

      addDrawable(Circle(
        id: newId,
        center: Offset(x, y),
        radius: radius < 0 ? 0 : radius,
        color: strokeColor,
        fillColor: fillColor,
        strokeWidth: strokeWidth,
        fill: fill,
        gradientType: gradientType,
        gradientColor1: gradientColor1,
        gradientColor2: gradientColor2,
      ));
      break;

    case 'draw_line':
      final startX = parameters['startX'] != null
          ? parseDouble(parameters['startX'])
          : _randomBetween(10.0, 390.0);

      final startY = parameters['startY'] != null
          ? parseDouble(parameters['startY'])
          : _randomBetween(10.0, 490.0);

      final endX = parameters['endX'] != null
          ? parseDouble(parameters['endX'])
          : _randomBetween(10.0, 390.0);

      final endY = parameters['endY'] != null
          ? parseDouble(parameters['endY'])
          : _randomBetween(10.0, 490.0);

      addDrawable(Line(
        id: newId,
        start: Offset(startX, startY),
        end: Offset(endX, endY),
        color: strokeColor,
        strokeWidth: strokeWidth,
      ));
      break;

    case 'draw_rectangle':
      if (parameters['topLeftX'] != null &&
          parameters['topLeftY'] != null &&
          parameters['bottomRightX'] != null &&
          parameters['bottomRightY'] != null) {

        addDrawable(Rectangle(
          id: newId,
          topLeft: Offset(
            parseDouble(parameters['topLeftX']),
            parseDouble(parameters['topLeftY']),
          ),
          bottomRight: Offset(
            parseDouble(parameters['bottomRightX']),
            parseDouble(parameters['bottomRightY']),
          ),
          color: strokeColor,
          fillColor: fillColor,
          strokeWidth: strokeWidth,
          fill: fill,
          gradientType: gradientType,
          gradientColor1: gradientColor1,
          gradientColor2: gradientColor2,
        ));
      }
      break;

    case 'draw_text':
      final text = parameters['text'] ?? "Text IA";

      final x = parameters['x'] != null
          ? parseDouble(parameters['x'])
          : 50.0;

      final y = parameters['y'] != null
          ? parseDouble(parameters['y'])
          : 50.0;

      addDrawable(TextElement(
        id: newId,
        text: text,
        position: Offset(x, y),
        color: strokeColor,
        fontSize: parameters['fontSize'] != null
            ? parseDouble(parameters['fontSize'])
            : 14.0,
        fontFamily: parameters['fontFamily'] ?? 'monospace',
        isBold: parseBool(parameters['isBold']),
        isItalic: parseBool(parameters['isItalic']),
      ));
      break;

    case 'delete_shape':
      final idToRemove = parameters['id'];
      drawables.removeWhere((d) => d.id == idToRemove);
      _responseText = "Figura esborrada.";
      break;

    case 'modify_shape':
      final idToModify = parameters['id'];
      final index = drawables.indexWhere((d) => d.id == idToModify);

      if (index != -1) {
        final shape = drawables[index];

        if (parameters['color'] != null) {
          shape.color = parseColor(parameters['color']);
        }

        if (shape is Rectangle && parameters['fillColor'] != null) {
          shape.fillColor = parseColor(parameters['fillColor']);
        }

        if (shape is Circle) {
          if (parameters['radius'] != null) {
            shape.radius = parseDouble(parameters['radius']);
          }

          shape.center = Offset(
            parameters['x'] != null
                ? parseDouble(parameters['x'])
                : shape.center.dx,
            parameters['y'] != null
                ? parseDouble(parameters['y'])
                : shape.center.dy,
          );
        }

        _responseText = "Figura modificada.";
        notifyListeners();
      }
      break;

    default:
      _responseText = "Funció desconeguda: $name";
  }

  notifyListeners();
}
  void cancelRequests() {
    _responseText += "\nRequest cancelled.";
    setLoading(false);
    notifyListeners();
  }

}
