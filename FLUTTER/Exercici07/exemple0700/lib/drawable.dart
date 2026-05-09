import 'package:flutter/material.dart';

abstract class Drawable {
  String id;
  Drawable({required this.id});

  void draw(Canvas canvas);
  Map<String, dynamic> toJson(); 
}

class Line extends Drawable {
  Offset start;
  Offset end;
  Color color;
  double strokeWidth;

  Line({
    required super.id,
    required this.start,
    required this.end,
    this.color = Colors.black,
    this.strokeWidth = 2.0,
  });

  @override
  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;
    canvas.drawLine(start, end, paint);
  }

  @override
  Map<String, dynamic> toJson() => {'id': id, 'type': 'line', 'startX': start.dx, 'startY': start.dy, 'endX': end.dx, 'endY': end.dy, 'color': color.value.toRadixString(16)};
}

class Rectangle extends Drawable {
  Offset topLeft;
  Offset bottomRight;
  Color color;
  double strokeWidth;
  bool fill;
  String? gradientType;
  Color? gradientColor1;
  Color? gradientColor2;

  Rectangle({
    required super.id,
    required this.topLeft,
    required this.bottomRight,
    this.color = Colors.black,
    this.strokeWidth = 2.0,
    this.fill = false,
    this.gradientType,
    this.gradientColor1,
    this.gradientColor2,
  });

  @override
  void draw(Canvas canvas) {
    final rect = Rect.fromPoints(topLeft, bottomRight);

    // FILL
    if (fill) {
      final fillPaint = Paint()..style = PaintingStyle.fill;

      if (gradientType == 'linear' &&
          gradientColor1 != null &&
          gradientColor2 != null) {
        fillPaint.shader = LinearGradient(
          colors: [gradientColor1!, gradientColor2!],
        ).createShader(rect);
      } else {
        fillPaint.color = color;
      }

      canvas.drawRect(rect, fillPaint);
    }

    // STROKE (SIEMPRE ENCIMA)
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, strokePaint);
  }

  @override
  Map<String, dynamic> toJson() => {'id': id, 'type': 'rectangle', 'topLeftX': topLeft.dx, 'topLeftY': topLeft.dy, 'bottomRightX': bottomRight.dx, 'bottomRightY': bottomRight.dy};
}

class Circle extends Drawable {
  Offset center;
  double radius;
  Color color;
  double strokeWidth;
  bool fill;
  String? gradientType;
  Color? gradientColor1;
  Color? gradientColor2;

  Circle({
    required super.id,
    required this.center,
    required this.radius,
    this.color = Colors.black,
    this.strokeWidth = 2.0,
    this.fill = false,
    this.gradientType,
    this.gradientColor1,
    this.gradientColor2,
  });

  @override
  void draw(Canvas canvas) {
    final rect = Rect.fromCircle(center: center, radius: radius);

    // FILL
    if (fill) {
      final fillPaint = Paint()..style = PaintingStyle.fill;

      if (gradientType == 'linear' &&
          gradientColor1 != null &&
          gradientColor2 != null) {
        fillPaint.shader = LinearGradient(
          colors: [gradientColor1!, gradientColor2!],
        ).createShader(rect);
      } else if (gradientType == 'radial' &&
          gradientColor1 != null &&
          gradientColor2 != null) {
        fillPaint.shader = RadialGradient(
          colors: [gradientColor1!, gradientColor2!],
        ).createShader(rect);
      } else {
        fillPaint.color = color;
      }

      canvas.drawCircle(center, radius, fillPaint);
    }

    // STROKE (SIEMPRE)
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, strokePaint);
  }

  @override
  Map<String, dynamic> toJson() => {'id': id, 'type': 'circle', 'x': center.dx, 'y': center.dy, 'radius': radius};
}

class TextElement extends Drawable {
  String text;
  Offset position;
  Color color;
  double fontSize;
  String fontFamily;
  bool isBold;
  bool isItalic;

  TextElement({
    required super.id,
    required this.text,
    required this.position,
    this.color = Colors.black,
    this.fontSize = 14.0,
    this.fontFamily = 'monospace',
    this.isBold = false,
    this.isItalic = false,
  });

  @override
  void draw(Canvas canvas) {
    final textStyle = TextStyle(
      color: color,
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
    );
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  Map<String, dynamic> toJson() => {'id': id, 'type': 'text', 'text': text, 'x': position.dx, 'y': position.dy};
}