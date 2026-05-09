import 'package:flutter/material.dart';

abstract class Drawable {
  String id;
  Color color; // stroke color

  Drawable({required this.id, required this.color});

  void draw(Canvas canvas);
  Map<String, dynamic> toJson();
}

class Line extends Drawable {
  Offset start;
  Offset end;
  double strokeWidth;

  Line({
    required super.id,
    required super.color,
    required this.start,
    required this.end,
    this.strokeWidth = 2.0,
  });

  @override
  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, end, paint);
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'line',
        'startX': start.dx,
        'startY': start.dy,
        'endX': end.dx,
        'endY': end.dy,
        'color': color.value,
      };
}

class Rectangle extends Drawable {
  Offset topLeft;
  Offset bottomRight;

  double strokeWidth;
  bool fill;

  Color? fillColor;

  String? gradientType;
  Color? gradientColor1;
  Color? gradientColor2;

  Rectangle({
    required super.id,
    required super.color,
    required this.topLeft,
    required this.bottomRight,
    this.strokeWidth = 2.0,
    this.fill = false,
    this.fillColor,
    this.gradientType,
    this.gradientColor1,
    this.gradientColor2,
  });

  @override
  void draw(Canvas canvas) {
    final rect = Rect.fromPoints(topLeft, bottomRight);

    if (fill) {
      final fillPaint = Paint()..style = PaintingStyle.fill;

      if (gradientType == 'linear' &&
          gradientColor1 != null &&
          gradientColor2 != null) {
        fillPaint.shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientColor1!, gradientColor2!],
        ).createShader(rect);
      } else {
        fillPaint.color = fillColor ?? color;
      }

      canvas.drawRect(rect, fillPaint);
    }

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, strokePaint);
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'rectangle',
        'topLeftX': topLeft.dx,
        'topLeftY': topLeft.dy,
        'bottomRightX': bottomRight.dx,
        'bottomRightY': bottomRight.dy,
      };
}

class Circle extends Drawable {
  Offset center;
  double radius;

  double strokeWidth;
  bool fill;

  Color? fillColor;

  String? gradientType;
  Color? gradientColor1;
  Color? gradientColor2;

  Circle({
    required super.id,
    required super.color,
    required this.center,
    required this.radius,
    this.strokeWidth = 2.0,
    this.fill = false,
    this.fillColor,
    this.gradientType,
    this.gradientColor1,
    this.gradientColor2,
  });

  @override
  void draw(Canvas canvas) {
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (fill) {
      final fillPaint = Paint()..style = PaintingStyle.fill;

      if (gradientType == 'linear' &&
          gradientColor1 != null &&
          gradientColor2 != null) {
        fillPaint.shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientColor1!, gradientColor2!],
        ).createShader(rect);
      } else if (gradientType == 'radial' &&
          gradientColor1 != null &&
          gradientColor2 != null) {
        fillPaint.shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [gradientColor1!, gradientColor2!],
        ).createShader(rect);
      } else {
        fillPaint.color = fillColor ?? color;
      }

      canvas.drawCircle(center, radius, fillPaint);
    }

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, strokePaint);
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'circle',
        'x': center.dx,
        'y': center.dy,
        'radius': radius,
      };
}

class TextElement extends Drawable {
  String text;
  Offset position;

  double fontSize;
  String fontFamily;
  bool isBold;
  bool isItalic;

  TextElement({
    required super.id,
    required this.text,
    required this.position,
    required super.color,
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
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': 'text',
        'text': text,
        'x': position.dx,
        'y': position.dy,
        'color': color.value,
      };
}