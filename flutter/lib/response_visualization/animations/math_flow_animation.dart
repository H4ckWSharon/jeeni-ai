import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// 3. MATH FLOW ANIMATION
/// Coordinate grid axes with floating animated symbols (∑, ∫, π, √x, Δ) & sine wave
/// ════════════════════════════════════════════════════════════════════════════
class MathFlowAnimation extends StatefulWidget {
  final Color primaryColor;
  final Color accentColor;
  final double speed;

  const MathFlowAnimation({
    super.key,
    required this.primaryColor,
    required this.accentColor,
    this.speed = 1.0,
  });

  @override
  State<MathFlowAnimation> createState() => _MathFlowAnimationState();
}

class _MathFlowAnimationState extends State<MathFlowAnimation>
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
          painter: _MathFlowPainter(
            progress: _ctrl.value,
            primaryColor: widget.primaryColor,
            accentColor: widget.accentColor,
          ),
        );
      },
    );
  }
}

class _MathFlowPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color accentColor;

  _MathFlowPainter({
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final width = size.width;

    // 1. Coordinate Grid Line (X-Axis)
    final axisPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(width * 0.1, centerY), Offset(width * 0.9, centerY), axisPaint);

    // 2. Animated Trigonometric / Calculus Curve Wave
    final wavePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          primaryColor.withValues(alpha: 0.1),
          accentColor.withValues(alpha: 0.85),
          primaryColor.withValues(alpha: 0.1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    bool first = true;
    for (double x = width * 0.15; x <= width * 0.85; x += 3.0) {
      final normX = (x - width * 0.15) / (width * 0.7);
      final y = centerY + (16.0 * math.sin((normX * 3.5 * math.pi) - (progress * 2 * math.pi)));
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, wavePaint);

    // 3. Floating Mathematical Glyphs (∑, ∫, π, √x, Δ)
    const symbols = ['∑', '∫', 'π', '√x', 'Δ'];
    final textStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.65),
      fontSize: 12,
      fontFamily: 'serif',
      fontWeight: FontWeight.bold,
    );

    for (int i = 0; i < symbols.length; i++) {
      final symX = (width * 0.2) + (i * (width * 0.15));
      final floatY = centerY + (18.0 * math.cos((progress * 2 * math.pi) + (i * 1.2)));
      final tp = TextPainter(
        text: TextSpan(text: symbols[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(symX - (tp.width / 2), floatY - (tp.height / 2)));
    }

    // 4. Moving Calculation Cursor Point on the Sine Curve
    final ptNormX = (progress * 0.7) + 0.15;
    final ptX = width * ptNormX;
    final ptNormRel = (ptX - width * 0.15) / (width * 0.7);
    final ptY = centerY + (16.0 * math.sin((ptNormRel * 3.5 * math.pi) - (progress * 2 * math.pi)));

    final cursorDot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(ptX, ptY), 3.0, cursorDot);

    final cursorAura = Paint()
      ..color = accentColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(ptX, ptY), 7.0, cursorAura);
  }

  @override
  bool shouldRepaint(covariant _MathFlowPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
