import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// 10. DATA ANALYSIS ANIMATION
/// Dynamic bar chart columns oscillating heights with an animated spline trendline
/// ════════════════════════════════════════════════════════════════════════════
class DataAnalysisAnimation extends StatefulWidget {
  final Color primaryColor;
  final Color accentColor;
  final double speed;

  const DataAnalysisAnimation({
    super.key,
    required this.primaryColor,
    required this.accentColor,
    this.speed = 1.0,
  });

  @override
  State<DataAnalysisAnimation> createState() => _DataAnalysisAnimationState();
}

class _DataAnalysisAnimationState extends State<DataAnalysisAnimation>
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
          painter: _DataAnalysisPainter(
            progress: _ctrl.value,
            primaryColor: widget.primaryColor,
            accentColor: widget.accentColor,
          ),
        );
      },
    );
  }
}

class _DataAnalysisPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color accentColor;

  _DataAnalysisPainter({
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const baselineY = 56.0;
    const barCount = 7;
    const barWidth = 8.0;
    const spacing = 14.0;
    const totalWidth = (barCount * barWidth) + ((barCount - 1) * (spacing - barWidth));
    final startX = cx - (totalWidth / 2);

    // 1. Horizontal Chart Baseline
    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(startX - 10, baselineY), Offset(startX + totalWidth + 10, baselineY), basePaint);

    // 2. Animated Bar Chart Columns
    final barTops = <Offset>[];
    for (int i = 0; i < barCount; i++) {
      final barX = startX + (i * spacing);
      final phase = progress * 2 * math.pi + (i * 0.7);
      final heightRatio = 0.35 + (0.55 * (0.5 + 0.5 * math.sin(phase)));
      final barHeight = 36.0 * heightRatio;
      final top = baselineY - barHeight;

      barTops.add(Offset(barX + (barWidth / 2), top));

      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, top, barWidth, barHeight),
        const Radius.circular(3),
      );

      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            primaryColor.withValues(alpha: 0.3),
            accentColor.withValues(alpha: 0.8),
          ],
        ).createShader(Rect.fromLTWH(barX, top, barWidth, barHeight));
      canvas.drawRRect(barRect, barPaint);
    }

    // 3. Statistical Spline Trendline Connecting Bar Peaks
    final trendline = Path()..moveTo(barTops.first.dx, barTops.first.dy);
    for (int i = 0; i < barTops.length - 1; i++) {
      final p0 = barTops[i];
      final p1 = barTops[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      trendline.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    final trendPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(trendline, trendPaint);

    // 4. Data Points on Tops of Bars
    for (final pt in barTops) {
      final ptPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, 2.0, ptPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DataAnalysisPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
