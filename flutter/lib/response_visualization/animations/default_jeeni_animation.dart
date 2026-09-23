import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// 11. DEFAULT JEENI ANIMATION
/// Signature Jeeni geometric diamond aura with rotating nodes & breathing glow
/// ════════════════════════════════════════════════════════════════════════════
class DefaultJeeniAnimation extends StatefulWidget {
  final Color primaryColor;
  final Color accentColor;
  final double speed;

  const DefaultJeeniAnimation({
    super.key,
    required this.primaryColor,
    required this.accentColor,
    this.speed = 1.0,
  });

  @override
  State<DefaultJeeniAnimation> createState() => _DefaultJeeniAnimationState();
}

class _DefaultJeeniAnimationState extends State<DefaultJeeniAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (2800 / widget.speed).round()),
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
          painter: _DefaultJeeniPainter(
            progress: _ctrl.value,
            primaryColor: widget.primaryColor,
            accentColor: widget.accentColor,
          ),
        );
      },
    );
  }
}

class _DefaultJeeniPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color accentColor;

  _DefaultJeeniPainter({
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Ambient Breathing Aura
    final breathScale = 0.85 + (0.15 * math.sin(progress * 2 * math.pi));
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withValues(alpha: 0.35 * breathScale),
          primaryColor.withValues(alpha: 0.12 * breathScale),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 28 * breathScale));
    canvas.drawCircle(center, 28 * breathScale, auraPaint);

    // 2. Rotating Diamond Constellation Frame
    final diamondAngle = progress * 2 * math.pi;
    const radius = 18.0;

    final diamondPath = Path();
    for (int i = 0; i < 4; i++) {
      final a = diamondAngle + (i * math.pi / 2);
      final pt = center + Offset(math.cos(a) * radius, math.sin(a) * radius);
      if (i == 0) {
        diamondPath.moveTo(pt.dx, pt.dy);
      } else {
        diamondPath.lineTo(pt.dx, pt.dy);
      }
    }
    diamondPath.close();

    final diamondStroke = Paint()
      ..color = primaryColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(diamondPath, diamondStroke);

    // 3. Counter-Rotating Inner Ring
    final innerAngle = -progress * 2 * math.pi;
    const innerRadius = 9.0;
    for (int i = 0; i < 4; i++) {
      final a = innerAngle + (i * math.pi / 2);
      final pt = center + Offset(math.cos(a) * innerRadius, math.sin(a) * innerRadius);
      final dotPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, 1.8, dotPaint);
    }

    // 4. Central Brilliant Star Core
    final coreGlow = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.5, coreGlow);
  }

  @override
  bool shouldRepaint(covariant _DefaultJeeniPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
