import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// 5. NETWORK FLOW ANIMATION
/// Connected network nodes with traveling data packets and handshake pulses
/// ════════════════════════════════════════════════════════════════════════════
class NetworkFlowAnimation extends StatefulWidget {
  final Color primaryColor;
  final Color accentColor;
  final double speed;

  const NetworkFlowAnimation({
    super.key,
    required this.primaryColor,
    required this.accentColor,
    this.speed = 1.0,
  });

  @override
  State<NetworkFlowAnimation> createState() => _NetworkFlowAnimationState();
}

class _NetworkFlowAnimationState extends State<NetworkFlowAnimation>
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
          painter: _NetworkFlowPainter(
            progress: _ctrl.value,
            primaryColor: widget.primaryColor,
            accentColor: widget.accentColor,
          ),
        );
      },
    );
  }
}

class _NetworkFlowPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color accentColor;

  _NetworkFlowPainter({
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // 5 Topology Nodes
    final nodes = [
      Offset(cx - 75, cy),       // Client
      Offset(cx - 25, cy - 18),  // Router / Switch
      Offset(cx - 25, cy + 18),  // Gateway
      Offset(cx + 35, cy),       // Cloud Server
      Offset(cx + 80, cy - 12),  // DNS / Database
    ];

    // Links between nodes
    final links = [
      [0, 1],
      [0, 2],
      [1, 3],
      [2, 3],
      [3, 4],
    ];

    // 1. Draw Network Links
    final linkPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.25)
      ..strokeWidth = 1.2;
    for (final l in links) {
      canvas.drawLine(nodes[l[0]], nodes[l[1]], linkPaint);
    }

    // 2. Draw Traveling Data Packets
    for (int i = 0; i < links.length; i++) {
      final l = links[i];
      final pProgress = (progress + (i * 0.2)) % 1.0;
      final start = nodes[l[0]];
      final end = nodes[l[1]];
      final packetPos = Offset(
        start.dx + (end.dx - start.dx) * pProgress,
        start.dy + (end.dy - start.dy) * pProgress,
      );

      final packetPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.95)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(packetPos, 2.2, packetPaint);

      // Packet trail
      final trailPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.3)
        ..strokeWidth = 2.0;
      final trailStart = Offset(
        start.dx + (end.dx - start.dx) * (pProgress - 0.08).clamp(0.0, 1.0),
        start.dy + (end.dy - start.dy) * (pProgress - 0.08).clamp(0.0, 1.0),
      );
      canvas.drawLine(trailStart, packetPos, trailPaint);
    }

    // 3. Draw Network Nodes
    for (int i = 0; i < nodes.length; i++) {
      final pos = nodes[i];
      final isCore = i == 0 || i == 3;
      final radius = isCore ? 5.5 : 4.0;

      // Node aura
      final nodeAura = Paint()
        ..color = primaryColor.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, radius + 2.5, nodeAura);

      // Node body
      final nodePaint = Paint()
        ..color = isCore ? Colors.white : primaryColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, radius, nodePaint);

      // Inner dot
      final innerDot = Paint()
        ..color = const Color(0xFF0F172A)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 1.8, innerDot);
    }

    // 4. Ping Pulse Collision on Core Node
    final pingProgress = (progress * 2) % 1.0;
    final pingRadius = 6.0 + (pingProgress * 12.0);
    final pingOpacity = (1.0 - pingProgress).clamp(0.0, 1.0) * 0.5;
    final pingPaint = Paint()
      ..color = accentColor.withValues(alpha: pingOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(nodes[3], pingRadius, pingPaint);
  }

  @override
  bool shouldRepaint(covariant _NetworkFlowPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
