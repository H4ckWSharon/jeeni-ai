import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// 4. CODE GENERATION ANIMATION
/// Structured syntax blocks progressively forming with typing cursor
/// ════════════════════════════════════════════════════════════════════════════
class CodeGenerationAnimation extends StatefulWidget {
  final Color primaryColor;
  final Color accentColor;
  final double speed;

  const CodeGenerationAnimation({
    super.key,
    required this.primaryColor,
    required this.accentColor,
    this.speed = 1.0,
  });

  @override
  State<CodeGenerationAnimation> createState() => _CodeGenerationAnimationState();
}

class _CodeGenerationAnimationState extends State<CodeGenerationAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (2400 / widget.speed).round()),
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
          painter: _CodeGenerationPainter(
            progress: _ctrl.value,
            primaryColor: widget.primaryColor,
            accentColor: widget.accentColor,
          ),
        );
      },
    );
  }
}

class _CodeGenerationPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color accentColor;

  _CodeGenerationPainter({
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final startX = (width / 2) - 100;
    const topY = 12.0;

    // 1. Code Editor Outer Frame (Subtle dark terminal container)
    final frameRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(startX, topY, 200, 48),
      const Radius.circular(8),
    );
    final framePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(frameRect, framePaint);

    final borderPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(frameRect, borderPaint);

    // 2. Terminal Header Dots
    const dotColors = [Color(0xFFEF4444), Color(0xFFF59E0B), Color(0xFF10B981)];
    for (int i = 0; i < 3; i++) {
      final dotPaint = Paint()
        ..color = dotColors[i].withValues(alpha: 0.7)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(startX + 12 + (i * 10), topY + 10), 2.5, dotPaint);
    }

    // 3. Progressively Typing Indented Syntax Lines
    final lineSpecs = [
      {'indent': 0.0, 'w': 40.0, 'time': 0.15}, // def solution(x):
      {'indent': 14.0, 'w': 65.0, 'time': 0.40}, //   result = [i * 2 ...]
      {'indent': 14.0, 'w': 50.0, 'time': 0.65}, //   return sorted(result)
    ];

    for (int i = 0; i < lineSpecs.length; i++) {
      final spec = lineSpecs[i];
      final targetTime = spec['time'] as double;
      final lineProgress = ((progress - targetTime + 1.0) % 1.0).clamp(0.0, 1.0);

      if (lineProgress > 0.1) {
        final lineY = topY + 22 + (i * 8.0);
        final lineX = startX + 12 + (spec['indent'] as double);
        final lineMaxW = spec['w'] as double;
        final currentW = lineMaxW * ((lineProgress * 2.0).clamp(0.0, 1.0));

        final linePaint = Paint()
          ..color = (i == 0 ? accentColor : primaryColor).withValues(alpha: 0.8)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 3.0;
        canvas.drawLine(Offset(lineX, lineY), Offset(lineX + currentW, lineY), linePaint);
      }
    }

    // 4. Blinking Syntax Typing Cursor "|"
    final isBlinkOn = (progress * 6).floor() % 2 == 0;
    if (isBlinkOn) {
      final activeLine = (progress * 3).floor().clamp(0, 2);
      final activeSpec = lineSpecs[activeLine];
      final cursorX = startX + 16 + (activeSpec['indent'] as double) + (activeSpec['w'] as double);
      final cursorY = topY + 22 + (activeLine * 8.0);

      final cursorPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..strokeWidth = 2.0;
      canvas.drawLine(Offset(cursorX, cursorY - 3), Offset(cursorX, cursorY + 3), cursorPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CodeGenerationPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
