import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// 9. LESSON BUILDER ANIMATION
/// Blueprint document skeleton assembling structural headers and outline blocks
/// ════════════════════════════════════════════════════════════════════════════
class LessonBuilderAnimation extends StatefulWidget {
  final Color primaryColor;
  final Color accentColor;
  final double speed;

  const LessonBuilderAnimation({
    super.key,
    required this.primaryColor,
    required this.accentColor,
    this.speed = 1.0,
  });

  @override
  State<LessonBuilderAnimation> createState() => _LessonBuilderAnimationState();
}

class _LessonBuilderAnimationState extends State<LessonBuilderAnimation>
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
          painter: _LessonBuilderPainter(
            progress: _ctrl.value,
            primaryColor: widget.primaryColor,
            accentColor: widget.accentColor,
          ),
        );
      },
    );
  }
}

class _LessonBuilderPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color accentColor;

  _LessonBuilderPainter({
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const topY = 12.0;
    const docWidth = 140.0;
    const docHeight = 48.0;

    // 1. Document Blueprint Outline
    final docRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - (docWidth / 2), topY, docWidth, docHeight),
      const Radius.circular(8),
    );

    final bgPaint = Paint()
      ..color = const Color(0xFF1E1E24).withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(docRect, bgPaint);

    final borderPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(docRect, borderPaint);

    // 2. Main Title Bar Line (Unit / Chapter Title)
    final titleWidth = (docWidth - 36) * ((progress * 1.5).clamp(0.0, 1.0));
    final titlePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.9)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;
    canvas.drawLine(
      Offset(cx - (docWidth / 2) + 16, topY + 12),
      Offset(cx - (docWidth / 2) + 16 + titleWidth, topY + 12),
      titlePaint,
    );

    // 3. Hierarchical Outline Sections & Bullet Tiers
    final outlineRows = [
      {'indent': 0.0, 'w': 80.0, 'start': 0.25}, // 1. Key Concept
      {'indent': 12.0, 'w': 55.0, 'start': 0.45}, //   - Definition
      {'indent': 12.0, 'w': 68.0, 'start': 0.65}, //   - Core Principles
      {'indent': 0.0, 'w': 45.0, 'start': 0.82}, // 2. Practice & Summary
    ];

    for (int i = 0; i < outlineRows.length; i++) {
      final row = outlineRows[i];
      final startTime = row['start'] as double;
      final rowProgress = ((progress - startTime + 1.0) % 1.0).clamp(0.0, 1.0);

      if (rowProgress > 0.1) {
        final rowY = topY + 20 + (i * 7.0);
        final rowX = cx - (docWidth / 2) + 16 + (row['indent'] as double);
        final maxW = row['w'] as double;
        final currentW = maxW * ((rowProgress * 2.0).clamp(0.0, 1.0));

        // Draw bullet point
        final isSub = (row['indent'] as double) > 0;
        final bulletPaint = Paint()
          ..color = (isSub ? primaryColor : accentColor).withValues(alpha: 0.7)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(rowX - 4, rowY), isSub ? 1.0 : 1.5, bulletPaint);

        // Draw text placeholder line
        final linePaint = Paint()
          ..color = (isSub ? Colors.white.withValues(alpha: 0.35) : primaryColor.withValues(alpha: 0.8))
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.2;
        canvas.drawLine(Offset(rowX, rowY), Offset(rowX + currentW, rowY), linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LessonBuilderPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
