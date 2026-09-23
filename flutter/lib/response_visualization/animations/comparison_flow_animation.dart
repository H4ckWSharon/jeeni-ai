import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// 8. COMPARISON FLOW ANIMATION
/// Dual opposing knowledge streams converging and synthesizing at a central node
/// ════════════════════════════════════════════════════════════════════════════
class ComparisonFlowAnimation extends StatefulWidget {
  final Color primaryColor;
  final Color accentColor;
  final double speed;

  const ComparisonFlowAnimation({
    super.key,
    required this.primaryColor,
    required this.accentColor,
    this.speed = 1.0,
  });

  @override
  State<ComparisonFlowAnimation> createState() => _ComparisonFlowAnimationState();
}

class _ComparisonFlowAnimationState extends State<ComparisonFlowAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (2600 / widget.speed).round()),
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
          painter: _ComparisonFlowPainter(
            progress: _ctrl.value,
            primaryColor: widget.primaryColor,
            accentColor: widget.accentColor,
          ),
        );
      },
    );
  }
}

class _ComparisonFlowPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color accentColor;

  _ComparisonFlowPainter({
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const span = 85.0;

    // 1. Dual Source Node Endpoints (Left = Stream A, Right = Stream B)
    final leftNode = Offset(cx - span, cy);
    final rightNode = Offset(cx + span, cy);
    final centerNode = Offset(cx, cy);

    final endNodePaintA = Paint()
      ..color = const Color(0xFF3B82F6) // Blue for Option A
      ..style = PaintingStyle.fill;
    final endNodePaintB = Paint()
      ..color = const Color(0xFFF59E0B) // Amber for Option B
      ..style = PaintingStyle.fill;

    canvas.drawCircle(leftNode, 4.0, endNodePaintA);
    canvas.drawCircle(rightNode, 4.0, endNodePaintB);

    // 2. Converging Curved Guide Paths
    final pathA = Path()
      ..moveTo(leftNode.dx, leftNode.dy)
      ..cubicTo(cx - (span * 0.5), cy - 18, cx - (span * 0.2), cy - 6, cx, cy);

    final pathB = Path()
      ..moveTo(rightNode.dx, rightNode.dy)
      ..cubicTo(cx + (span * 0.5), cy + 18, cx + (span * 0.2), cy + 6, cx, cy);

    final guidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(pathA, guidePaint);
    canvas.drawPath(pathB, guidePaint);

    // 3. Particles Flowing Inwards Along Both Paths
    for (int i = 0; i < 4; i++) {
      final pA = (progress + (i * 0.25)) % 1.0;
      final pB = (progress + (i * 0.25)) % 1.0;

      // Interpolate Stream A
      final ax = leftNode.dx + (cx - leftNode.dx) * pA;
      final ay = cy - (16.0 * math.sin(pA * math.pi));
      final particleA = Paint()
        ..color = const Color(0xFF60A5FA).withValues(alpha: 0.9 * (1.0 - (pA * 0.2)))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(ax, ay), 2.2, particleA);

      // Interpolate Stream B
      final bx = rightNode.dx - (rightNode.dx - cx) * pB;
      final by = cy + (16.0 * math.sin(pB * math.pi));
      final particleB = Paint()
        ..color = const Color(0xFFFBBF24).withValues(alpha: 0.9 * (1.0 - (pB * 0.2)))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(bx, by), 2.2, particleB);
    }

    // 4. Central Synthesis Convergence Vortex
    final vortexScale = 0.85 + (0.25 * math.sin(progress * 4 * math.pi));
    final vortexGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          accentColor.withValues(alpha: 0.8),
          primaryColor.withValues(alpha: 0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: centerNode, radius: 16.0 * vortexScale));
    canvas.drawCircle(centerNode, 16.0 * vortexScale, vortexGlow);

    final coreDot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(centerNode, 2.5, coreDot);
  }

  @override
  bool shouldRepaint(covariant _ComparisonFlowPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
