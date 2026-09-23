import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// 1. SIMPLE PULSE ANIMATION
/// Soft breathing aura with gentle harmonic sparkle particles
/// ════════════════════════════════════════════════════════════════════════════
class SimplePulseAnimation extends StatefulWidget {
  final Color primaryColor;
  final Color accentColor;
  final double speed;

  const SimplePulseAnimation({
    super.key,
    required this.primaryColor,
    required this.accentColor,
    this.speed = 1.0,
  });

  @override
  State<SimplePulseAnimation> createState() => _SimplePulseAnimationState();
}

class _SimplePulseAnimationState extends State<SimplePulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (2200 / widget.speed).round()),
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
          painter: _SimplePulsePainter(
            progress: _ctrl.value,
            primaryColor: widget.primaryColor,
            accentColor: widget.accentColor,
          ),
        );
      },
    );
  }
}

class _SimplePulsePainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color accentColor;

  _SimplePulsePainter({
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Expanding Ripple Rings
    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress + (i * 0.33)) % 1.0;
      final radius = 10.0 + (ringProgress * 28.0);
      final opacity = (1.0 - ringProgress).clamp(0.0, 1.0) * 0.45;
      final ringPaint = Paint()
        ..color = primaryColor.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius, ringPaint);
    }

    // 2. Central Soft Breathing Core
    final coreScale = 0.85 + (0.15 * math.sin(progress * 2 * math.pi));
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withValues(alpha: 0.9),
          primaryColor.withValues(alpha: 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 16.0 * coreScale));
    canvas.drawCircle(center, 16.0 * coreScale, corePaint);

    // 3. Orbiting Sparkles
    for (int i = 0; i < 4; i++) {
      final angle = (progress * 2 * math.pi) + (i * math.pi / 2);
      final dist = 24.0 + (4.0 * math.sin(progress * 4 * math.pi + i));
      final spPos = center + Offset(math.cos(angle) * dist, math.sin(angle) * (dist * 0.6));
      final spPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.7 + (0.3 * math.sin(progress * 2 * math.pi + i)))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(spPos, 1.8, spPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SimplePulsePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
