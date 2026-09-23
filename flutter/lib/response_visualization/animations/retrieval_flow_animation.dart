import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// 7. RETRIEVAL FLOW ANIMATION
/// Multi-tier textbook index cards with vertical scanning laser bar
/// ════════════════════════════════════════════════════════════════════════════
class RetrievalFlowAnimation extends StatefulWidget {
  final Color primaryColor;
  final Color accentColor;
  final double speed;

  const RetrievalFlowAnimation({
    super.key,
    required this.primaryColor,
    required this.accentColor,
    this.speed = 1.0,
  });

  @override
  State<RetrievalFlowAnimation> createState() => _RetrievalFlowAnimationState();
}

class _RetrievalFlowAnimationState extends State<RetrievalFlowAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (2200 / widget.speed).round()),
    )..repeat(reverse: true);
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
          painter: _RetrievalFlowPainter(
            progress: _ctrl.value,
            primaryColor: widget.primaryColor,
            accentColor: widget.accentColor,
          ),
        );
      },
    );
  }
}

class _RetrievalFlowPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color accentColor;

  _RetrievalFlowPainter({
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // 3 Stacked Index Cards (Simulating textbook chapters)
    const cardWidth = 130.0;
    const cardHeight = 36.0;

    for (int i = 0; i < 3; i++) {
      final cardOffset = Offset(cx - (cardWidth / 2) + ((i - 1) * 8), cy - (cardHeight / 2) + ((i - 1) * 6));
      final cardRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cardOffset.dx, cardOffset.dy, cardWidth, cardHeight),
        const Radius.circular(6),
      );

      final isTopCard = i == 2;
      final cardFill = Paint()
        ..color = Color.lerp(const Color(0xFF1E293B), const Color(0xFF0F172A), i * 0.3)!
            .withValues(alpha: isTopCard ? 0.85 : 0.5)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(cardRect, cardFill);

      final cardBorder = Paint()
        ..color = primaryColor.withValues(alpha: isTopCard ? 0.35 : 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRRect(cardRect, cardBorder);

      // Bookmark / Subject Tab on card
      final tabRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cardOffset.dx + 12, cardOffset.dy + 8, 22, 4),
        const Radius.circular(2),
      );
      final tabPaint = Paint()
        ..color = accentColor.withValues(alpha: isTopCard ? 0.7 : 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(tabRect, tabPaint);

      // Skeleton paragraph lines
      final line1 = Rect.fromLTWH(cardOffset.dx + 40, cardOffset.dy + 8, cardWidth - 55, 3);
      final line2 = Rect.fromLTWH(cardOffset.dx + 12, cardOffset.dy + 18, cardWidth - 40, 3);
      final linePaint = Paint()
        ..color = Colors.white.withValues(alpha: isTopCard ? 0.15 : 0.08)
        ..style = PaintingStyle.fill;
      canvas.drawRect(line1, linePaint);
      canvas.drawRect(line2, linePaint);
    }

    // Vertical Scanning Laser Bar
    final topCardX = cx - (cardWidth / 2) + 8;
    final topCardY = cy - (cardHeight / 2) + 6;
    final scanX = topCardX + (progress * cardWidth);

    final laserGlow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          accentColor.withValues(alpha: 0.8),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(scanX - 4, topCardY - 4, 8, cardHeight + 8))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(scanX, topCardY - 4), Offset(scanX, topCardY + cardHeight + 4), laserGlow);

    final laserCore = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(scanX, topCardY), Offset(scanX, topCardY + cardHeight), laserCore);

    // Pulse highlight when beam passes bookmark
    if (progress > 0.05 && progress < 0.35) {
      final sparklePos = Offset(topCardX + 23, topCardY + 10);
      final sparklePaint = Paint()
        ..color = Colors.white.withValues(alpha: math.sin(progress * math.pi) * 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(sparklePos, 2.5, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RetrievalFlowPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
