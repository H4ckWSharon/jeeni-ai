import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// 6. CYBERSECURITY SCAN ANIMATION
/// Circular perimeter shield with rotating radar sweep line and scan pulse
/// ════════════════════════════════════════════════════════════════════════════
class CybersecurityScanAnimation extends StatefulWidget {
  final Color primaryColor;
  final Color accentColor;
  final double speed;

  const CybersecurityScanAnimation({
    super.key,
    required this.primaryColor,
    required this.accentColor,
    this.speed = 1.0,
  });

  @override
  State<CybersecurityScanAnimation> createState() => _CybersecurityScanAnimationState();
}

class _CybersecurityScanAnimationState extends State<CybersecurityScanAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (2500 / widget.speed).round()),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(double.infinity, 70),
          painter: _CybersecurityScanPainter(
            progress: _ctrl.value,
            primaryColor: widget.primaryColor,
            accentColor: widget.accentColor,
          ),
        );
      },
    );
  }
}

class _CybersecurityScanPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color accentColor;

  _CybersecurityScanPainter({
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const maxRadius = 26.0;

    // 1. Concentric Radar Rings
    for (int r = 1; r <= 3; r++) {
      final ringRadius = (maxRadius / 3) * r;
      final ringPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, ringRadius, ringPaint);
    }

    // 2. Crosshair Grid Lines
    final crossPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.15)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(center.dx - maxRadius, center.dy), Offset(center.dx + maxRadius, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy - maxRadius), Offset(center.dx, center.dy + maxRadius), crossPaint);

    // 3. Rotating Radar Sweep Beam (Sweep Gradient Cone)
    final sweepAngle = progress * 2 * math.pi;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: sweepAngle - 0.7,
        endAngle: sweepAngle,
        colors: [
          Colors.transparent,
          primaryColor.withValues(alpha: 0.05),
          accentColor.withValues(alpha: 0.45),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, maxRadius, sweepPaint);

    // 4. Radar Sweep Leading Line
    final sweepEdge = center + Offset(math.cos(sweepAngle) * maxRadius, math.sin(sweepAngle) * maxRadius);
    final linePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.85)
      ..strokeWidth = 1.5;
    canvas.drawLine(center, sweepEdge, linePaint);

    // 5. Shield Node Blips (Detected perimeter nodes)
    final blipPositions = [
      Offset(center.dx + 15, center.dy - 12),
      Offset(center.dx - 14, center.dy + 16),
      Offset(center.dx + 18, center.dy + 10),
    ];

    for (int i = 0; i < blipPositions.length; i++) {
      final bPos = blipPositions[i];
      final bAngle = math.atan2(bPos.dy - center.dy, bPos.dx - center.dx);
      final normBAngle = (bAngle + (2 * math.pi)) % (2 * math.pi);
      final diff = ((sweepAngle - normBAngle + (2 * math.pi)) % (2 * math.pi));
      final blipAlpha = diff < 1.2 ? (1.0 - (diff / 1.2)).clamp(0.1, 1.0) : 0.1;

      final blipPaint = Paint()
        ..color = accentColor.withValues(alpha: blipAlpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(bPos, 2.2, blipPaint);
    }

    // 6. Central Shield Core
    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.5, corePaint);
  }

  @override
  bool shouldRepaint(covariant _CybersecurityScanPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
