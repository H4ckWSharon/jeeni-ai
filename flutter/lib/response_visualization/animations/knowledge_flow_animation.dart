import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// 2. KNOWLEDGE FLOW ANIMATION
/// Orbital knowledge nodes orbiting along harmonic geometric rings
/// ════════════════════════════════════════════════════════════════════════════
class KnowledgeFlowAnimation extends StatefulWidget {
  final Color primaryColor;
  final Color accentColor;
  final double speed;

  const KnowledgeFlowAnimation({
    super.key,
    required this.primaryColor,
    required this.accentColor,
    this.speed = 1.0,
  });

  @override
  State<KnowledgeFlowAnimation> createState() => _KnowledgeFlowAnimationState();
}

class _KnowledgeFlowAnimationState extends State<KnowledgeFlowAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (3000 / widget.speed).round()),
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
          painter: _KnowledgeFlowPainter(
            progress: _ctrl.value,
            primaryColor: widget.primaryColor,
            accentColor: widget.accentColor,
          ),
        );
      },
    );
  }
}

class _KnowledgeFlowPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color accentColor;

  _KnowledgeFlowPainter({
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Dual Inclined Orbital Ellipses
    final orbitPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 7);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 90, height: 32), orbitPaint);
    canvas.restore();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.pi / 7);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 90, height: 32), orbitPaint);
    canvas.restore();

    // 2. Central Core Nucleus
    final nucleusGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withValues(alpha: 0.8),
          primaryColor.withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 14));
    canvas.drawCircle(center, 14, nucleusGlow);

    final nucleusDot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.0, nucleusDot);

    // 3. Orbiting Knowledge Nodes (Electrons/Concepts)
    for (int i = 0; i < 3; i++) {
      final t = (progress + (i * 0.33)) % 1.0;
      final angle = t * 2 * math.pi;
      const rx = 45.0;
      const ry = 16.0;
      final tilt = (i % 2 == 0) ? -math.pi / 7 : math.pi / 7;

      final ox = math.cos(angle) * rx;
      final oy = math.sin(angle) * ry;

      final rotatedX = ox * math.cos(tilt) - oy * math.sin(tilt);
      final rotatedY = ox * math.sin(tilt) + oy * math.cos(tilt);
      final nodePos = center + Offset(rotatedX, rotatedY);

      // Trailing glow
      final nodePaint = Paint()
        ..color = accentColor.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(nodePos, 2.5, nodePaint);

      final auraPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(nodePos, 4.5, auraPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _KnowledgeFlowPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
