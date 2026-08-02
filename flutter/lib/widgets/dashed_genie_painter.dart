import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class DashedGeniePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashSpace;

  DashedGeniePainter({
    this.color = Colors.white24,
    this.strokeWidth = 1.5,
    this.dashLength = 8,
    this.dashSpace = 6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();

    // ── GENIE PATH APPROXIMATION (Based on dashed silhouette reference) ──
    // Head & Ponytail
    path.moveTo(size.width * 0.5, size.height * 0.15);
    path.quadraticBezierTo(size.width * 0.45, size.height * 0.1, size.width * 0.5, size.height * 0.05); // Ponytail
    path.quadraticBezierTo(size.width * 0.55, size.height * 0.1, size.width * 0.5, size.height * 0.15);
    
    path.addOval(Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.22),
      width: size.width * 0.12,
      height: size.height * 0.12,
    ));

    // Torso & Crossed Arms
    // Left shoulder
    path.moveTo(size.width * 0.5, size.height * 0.28);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.3, size.width * 0.15, size.height * 0.45);
    // Left arm crossed
    path.lineTo(size.width * 0.5, size.height * 0.5);
    
    // Right shoulder
    path.moveTo(size.width * 0.5, size.height * 0.28);
    path.quadraticBezierTo(size.width * 0.8, size.height * 0.3, size.width * 0.85, size.height * 0.45);
    // Right arm crossed
    path.lineTo(size.width * 0.5, size.height * 0.5);

    // Body (Vase/Smoke shape)
    path.moveTo(size.width * 0.35, size.height * 0.55);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.6, size.width * 0.65, size.height * 0.55);
    
    path.moveTo(size.width * 0.35, size.height * 0.55);
    path.quadraticBezierTo(size.width * 0.3, size.height * 0.8, size.width * 0.5, size.height * 0.95); // Bottom tip
    path.quadraticBezierTo(size.width * 0.7, size.height * 0.8, size.width * 0.65, size.height * 0.55);

    // Drawing dashed lines
    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (ui.PathMetric measure in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < measure.length) {
        final double length = dashLength;
        canvas.drawPath(
          measure.extractPath(distance, distance + length),
          paint,
        );
        distance += length + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
