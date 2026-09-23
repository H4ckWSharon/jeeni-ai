import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/orb_state.dart';

/// Internal representation of a 3D projected dot in the Thinking Orb field.
class _OrbDot {
  final double x;
  final double y;
  final double z;
  final double r;
  final double alpha;
  final Color color;

  _OrbDot({
    required this.x,
    required this.y,
    required this.z,
    required this.r,
    required this.alpha,
    required this.color,
  });
}

/// Native Flutter CustomPainter faithfully porting the 3D Canvas mathematics
/// of Schoolees/thinking-orbs across all 9 purpose-tuned states:
/// idle, working, connecting, searching, solving, listening, composing, responding, shaping.
///
/// Supports both:
/// - [isInlineSmall == true]: Tiny, minimalist ~20dp inline chat tuning (crisp, subtle, transparent).
/// - [isInlineSmall == false]: Standard full-size presentation.
class ThinkingOrbPainter extends CustomPainter {
  final OrbState state;
  final OrbVariant variant;
  final double progress; // 0.0 to 1.0 continuous animation loop
  final bool isDark;
  final Color primaryColor;
  final bool isInlineSmall;

  static const double _goldenRatioAngle = 2.39996322972865332; // pi * (3 - sqrt(5))

  ThinkingOrbPainter({
    required this.state,
    this.variant = OrbVariant.classic,
    required this.progress,
    this.isDark = true,
    required this.primaryColor,
    this.isInlineSmall = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(cx, cy) * (isInlineSmall ? 0.90 : 0.85);
    final t = progress * math.pi * 4; // Continuous phase timer

    // Background radial glow (only for full-size; omitted or minimal for tiny inline)
    if (!isInlineSmall) {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            primaryColor.withValues(alpha: isDark ? 0.22 : 0.12),
            primaryColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius * 1.3));
      canvas.drawCircle(Offset(cx, cy), radius * 1.3, glowPaint);
    } else {
      // Extremely subtle, tight 1.5px core luminescence for 20dp inline indicator
      final microGlow = Paint()
        ..color = (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A))
            .withValues(alpha: isDark ? 0.08 : 0.04)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawCircle(Offset(cx, cy), radius * 0.7, microGlow);
    }

    final dots = <_OrbDot>[];

    switch (state) {
      case OrbState.idle:
        _buildIdleDots(dots, cx, cy, radius, t);
        break;
      case OrbState.working:
        _buildWorkingDots(dots, cx, cy, radius, t);
        break;
      case OrbState.connecting:
        _buildConnectingDots(dots, cx, cy, radius, t);
        break;
      case OrbState.searching:
        _buildSearchingDots(dots, cx, cy, radius, t);
        break;
      case OrbState.solving:
        _buildSolvingDots(dots, cx, cy, radius, t);
        break;
      case OrbState.listening:
        _buildListeningDots(dots, cx, cy, radius, t);
        break;
      case OrbState.composing:
        _buildComposingDots(dots, cx, cy, radius, t);
        break;
      case OrbState.responding:
        _buildRespondingDots(dots, cx, cy, radius, t);
        break;
      case OrbState.shaping:
        _buildShapingDots(dots, cx, cy, radius, t);
        break;
    }

    // Sort dots by Z depth (back-to-front painter's algorithm)
    dots.sort((a, b) => a.z.compareTo(b.z));

    final paintDot = Paint()..style = PaintingStyle.fill;

    // Render sorted dots
    for (final d in dots) {
      if (d.r <= 0.1 || d.alpha <= 0.01) continue;
      paintDot.color = d.color.withValues(alpha: d.alpha.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(d.x, d.y), d.r, paintDot);
    }

    // Optional contour line overlays if contour variant is selected
    if (variant == OrbVariant.contour) {
      _drawContourOverlay(canvas, cx, cy, radius, t);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 1. IDLE: Breathing spherical Fibonacci halo
  // ─────────────────────────────────────────────────────────────
  void _buildIdleDots(List<_OrbDot> dots, double cx, double cy, double R, double t) {
    final n = isInlineSmall ? 28 : 120;
    final breathe = 0.92 + 0.08 * math.sin(t * 0.8);
    final rotY = t * 0.15;
    const rotX = 0.25;

    for (int i = 0; i < n; i++) {
      final dir = _fibDir(i, n);
      final rCurr = R * breathe;
      final proj = _project(dir[0] * rCurr, dir[1] * rCurr, dir[2] * rCurr, rotY, rotX, cx, cy);
      final depth = (proj[2] / rCurr + 1) / 2; // [0, 1]

      dots.add(_OrbDot(
        x: proj[0],
        y: proj[1],
        z: proj[2],
        r: isInlineSmall ? (0.55 + 0.65 * depth) : (1.0 + 2.2 * depth),
        alpha: 0.25 + 0.70 * depth,
        color: _depthColor(depth),
      ));
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 2. WORKING: Dual counter-rotating woven orbital ribbon bands
  // ─────────────────────────────────────────────────────────────
  void _buildWorkingDots(List<_OrbDot> dots, double cx, double cy, double R, double t) {
    // Faint quiet sphere core
    final shellCount = isInlineSmall ? 10 : 60;
    final rotY = t * 0.25;
    const rotX = 0.3;

    for (int i = 0; i < shellCount; i++) {
      final dir = _fibDir(i, shellCount);
      final proj = _project(dir[0] * R * 0.65, dir[1] * R * 0.65, dir[2] * R * 0.65, rotY, rotX, cx, cy);
      final depth = (proj[2] / (R * 0.65) + 1) / 2;
      dots.add(_OrbDot(
        x: proj[0],
        y: proj[1],
        z: proj[2],
        r: isInlineSmall ? (0.45 + 0.45 * depth) : (0.8 + 1.2 * depth),
        alpha: 0.15 + 0.40 * depth,
        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
      ));
    }

    // Two crossing counter-rotating ribbons
    final ribbonDots = isInlineSmall ? 18 : 70;
    final leadColor = isInlineSmall ? const Color(0xFFFFFFFF) : primaryColor;

    for (int band = 0; band < 2; band++) {
      final sign = band == 0 ? 1.0 : -1.0;
      final tilt = band == 0 ? 0.65 : -0.65;
      final speed = t * 1.4 * sign;

      for (int i = 0; i < ribbonDots; i++) {
        final u = (i / ribbonDots) * math.pi * 2;
        final x0 = R * 0.9 * math.cos(u + speed);
        final y0 = R * 0.9 * math.sin(u + speed) * math.cos(tilt);
        final z0 = R * 0.9 * math.sin(u + speed) * math.sin(tilt);

        final proj = _project(x0, y0, z0, rotY * 0.5, rotX, cx, cy);
        final depth = (proj[2] / R + 1) / 2;
        final isLead = (i % (isInlineSmall ? 4 : 8) == 0);

        dots.add(_OrbDot(
          x: proj[0],
          y: proj[1],
          z: proj[2],
          r: isInlineSmall
              ? ((isLead ? 1.1 : 0.6) + 0.5 * depth)
              : ((isLead ? 2.5 : 1.3) + 1.8 * depth),
          alpha: isLead ? 0.95 : (0.30 + 0.65 * depth),
          color: isLead ? leadColor : _depthColor(depth),
        ));
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 3. CONNECTING: Pulsing network bridge between hubs
  // ─────────────────────────────────────────────────────────────
  void _buildConnectingDots(List<_OrbDot> dots, double cx, double cy, double R, double t) {
    final hubNodes = isInlineSmall ? 8 : 40;
    final hubOffset = R * 0.50;

    // Left and Right hubs
    for (int h = 0; h < 2; h++) {
      final sign = h == 0 ? -1.0 : 1.0;
      final hx = cx + sign * hubOffset;
      final hy = cy;
      final hRot = t * 0.8 * sign;

      for (int i = 0; i < hubNodes; i++) {
        final dir = _fibDir(i, hubNodes);
        final subR = R * 0.35;
        final proj = _project(dir[0] * subR, dir[1] * subR, dir[2] * subR, hRot, 0.2, hx, hy);
        final depth = (proj[2] / subR + 1) / 2;
        dots.add(_OrbDot(
          x: proj[0],
          y: proj[1],
          z: proj[2],
          r: isInlineSmall ? (0.5 + 0.5 * depth) : (1.0 + 1.6 * depth),
          alpha: 0.25 + 0.7 * depth,
          color: _depthColor(depth),
        ));
      }
    }

    // Connecting bridge packets traveling between hubs
    final bridgeDots = isInlineSmall ? 6 : 24;
    final packetColor = isInlineSmall ? const Color(0xFFFFFFFF) : primaryColor;

    for (int i = 0; i < bridgeDots; i++) {
      final frac = i / (bridgeDots - 1);
      final bx = (cx - hubOffset) + frac * (2 * hubOffset);
      final wave = math.sin(frac * math.pi * 3 - t * 2.5) * (R * 0.18);
      final by = cy + wave;
      final z = math.cos(frac * math.pi * 2 - t * 2.0) * (R * 0.25);
      final depth = (z / (R * 0.25) + 1) / 2;

      dots.add(_OrbDot(
        x: bx,
        y: by,
        z: z,
        r: isInlineSmall ? (0.7 + 0.5 * depth) : (1.5 + 2.0 * depth),
        alpha: 0.40 + 0.6 * depth,
        color: packetColor,
      ));
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 4. SEARCHING: High-speed rotating planetary globe (RAG)
  // ─────────────────────────────────────────────────────────────
  void _buildSearchingDots(List<_OrbDot> dots, double cx, double cy, double R, double t) {
    final latLines = isInlineSmall ? 4 : 8;
    final dotsPerLat = isInlineSmall ? 8 : 22;
    final rotY = t * 1.8; // Rapid search rotation
    const rotX = 0.35;
    final beamColor = isInlineSmall ? const Color(0xFFFFFFFF) : primaryColor;

    for (int l = 1; l <= latLines; l++) {
      final phi = (l / (latLines + 1)) * math.pi - math.pi / 2;
      final cosPhi = math.cos(phi);
      final sinPhi = math.sin(phi);

      for (int d = 0; d < dotsPerLat; d++) {
        final theta = (d / dotsPerLat) * math.pi * 2;
        final x0 = R * 0.9 * cosPhi * math.cos(theta);
        final y0 = R * 0.9 * sinPhi;
        final z0 = R * 0.9 * cosPhi * math.sin(theta);

        final proj = _project(x0, y0, z0, rotY, rotX, cx, cy);
        final depth = (proj[2] / R + 1) / 2;

        // Equator scanning beam light highlight
        final isEquator = (l == latLines ~/ 2 || l == latLines ~/ 2 + 1);
        final beam = math.sin(theta * 2 - t * 3.0);
        final isHighlight = isEquator && beam > 0.5;

        dots.add(_OrbDot(
          x: proj[0],
          y: proj[1],
          z: proj[2],
          r: isInlineSmall
              ? ((isHighlight ? 1.1 : 0.55) + 0.55 * depth)
              : ((isHighlight ? 2.8 : 1.1) + 1.6 * depth),
          alpha: isHighlight ? 0.95 : (0.22 + 0.65 * depth),
          color: isHighlight ? beamColor : _depthColor(depth),
        ));
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 5. SOLVING: 3D Rubik's cube lattice scramble/unscramble (Math)
  // ─────────────────────────────────────────────────────────────
  void _buildSolvingDots(List<_OrbDot> dots, double cx, double cy, double R, double t) {
    const n = 3;
    final spacing = (R * 1.3) / (n - 1);
    final half = (R * 1.3) / 2;

    final cycleTime = t % (math.pi * 4);
    final movePhase = (cycleTime / (math.pi * 4)) * 3;
    final activeStage = movePhase.floor();
    final stageFrac = (movePhase - activeStage).clamp(0.0, 1.0);
    final ease = stageFrac < 0.5
        ? 4 * stageFrac * stageFrac * stageFrac
        : 1 - math.pow(-2 * stageFrac + 2, 3) / 2;

    final rotY = t * 0.35;
    final rotX = 0.35 + 0.1 * math.sin(t * 0.5);

    for (int ix = 0; ix < n; ix++) {
      for (int iy = 0; iy < n; iy++) {
        for (int iz = 0; iz < n; iz++) {
          // In small inline mode, only draw corner/edge nodes (skip inside center)
          if (isInlineSmall && ix == 1 && iy == 1 && iz == 1) continue;

          double x0 = ix * spacing - half;
          double y0 = iy * spacing - half;
          double z0 = iz * spacing - half;

          if (activeStage == 0 && iy == 0) {
            final ang = ease * (math.pi / 2);
            final rx = x0 * math.cos(ang) - z0 * math.sin(ang);
            final rz = x0 * math.sin(ang) + z0 * math.cos(ang);
            x0 = rx;
            z0 = rz;
          } else if (activeStage == 1 && ix == 2) {
            final ang = ease * (math.pi / 2);
            final ry = y0 * math.cos(ang) - z0 * math.sin(ang);
            final rz = y0 * math.sin(ang) + z0 * math.cos(ang);
            y0 = ry;
            z0 = rz;
          } else if (activeStage == 2 && iz == 2) {
            final ang = ease * (math.pi / 2);
            final rx = x0 * math.cos(ang) - y0 * math.sin(ang);
            final ry = x0 * math.sin(ang) + y0 * math.cos(ang);
            x0 = rx;
            y0 = ry;
          }

          final proj = _project(x0, y0, z0, rotY, rotX, cx, cy);
          final depth = (proj[2] / half + 1) / 2;

          dots.add(_OrbDot(
            x: proj[0],
            y: proj[1],
            z: proj[2],
            r: isInlineSmall ? (0.6 + 0.6 * depth) : (1.6 + 2.2 * depth),
            alpha: 0.35 + 0.65 * depth,
            color: _depthColor(depth),
          ));
        }
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 6. LISTENING: Audio wave undulations across spherical surface
  // ─────────────────────────────────────────────────────────────
  void _buildListeningDots(List<_OrbDot> dots, double cx, double cy, double R, double t) {
    final n = isInlineSmall ? 28 : 150;
    final rotY = t * 0.4;
    const rotX = 0.25;
    final waveColor = isInlineSmall ? const Color(0xFFFFFFFF) : primaryColor;

    for (int i = 0; i < n; i++) {
      final dir = _fibDir(i, n);
      final wave = math.sin(dir[1] * 8.0 - t * 4.0) * math.cos(dir[0] * 6.0 + t * 2.0);
      final rCurr = R * (0.8 + 0.25 * wave);

      final proj = _project(dir[0] * rCurr, dir[1] * rCurr, dir[2] * rCurr, rotY, rotX, cx, cy);
      final depth = (proj[2] / R + 1) / 2;

      dots.add(_OrbDot(
        x: proj[0],
        y: proj[1],
        z: proj[2],
        r: isInlineSmall ? (0.55 + 0.65 * depth) : (1.2 + 2.4 * depth),
        alpha: 0.3 + 0.7 * depth,
        color: wave > 0.4 ? waveColor : _depthColor(depth),
      ));
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 7. COMPOSING: Flowing Lissajous ribbon with traveling harmonics
  // ─────────────────────────────────────────────────────────────
  void _buildComposingDots(List<_OrbDot> dots, double cx, double cy, double R, double t) {
    // Ambient quiet Fibonacci ghost shell (skip or 6 dots for small)
    final ghostN = isInlineSmall ? 6 : 50;
    for (int i = 0; i < ghostN; i++) {
      final dir = _fibDir(i, ghostN);
      final proj = _project(dir[0] * R * 0.7, dir[1] * R * 0.7, dir[2] * R * 0.7, t * 0.1, 0.3, cx, cy);
      final depth = (proj[2] / (R * 0.7) + 1) / 2;
      dots.add(_OrbDot(
        x: proj[0],
        y: proj[1],
        z: proj[2],
        r: isInlineSmall ? 0.45 : (0.8 + 1.0 * depth),
        alpha: 0.15 + 0.25 * depth,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
      ));
    }

    // Lissajous 3D ribbon path
    final ribbonSamples = isInlineSmall ? 24 : 130;
    final shimmerColor = isInlineSmall ? const Color(0xFFFFFFFF) : primaryColor;

    for (int i = 0; i < ribbonSamples; i++) {
      final u = (i / ribbonSamples) * math.pi * 2;
      final x0 = R * 0.85 * math.sin(u + t * 0.7);
      final y0 = R * 0.55 * math.sin(2 * u + t * 1.1);
      final z0 = R * 0.85 * math.cos(u + t * 0.7);

      final proj = _project(x0, y0, z0, t * 0.2, 0.2, cx, cy);
      final depth = (proj[2] / R + 1) / 2;
      final shimmer = (math.sin(u * 5 - t * 3) > 0.5);

      dots.add(_OrbDot(
        x: proj[0],
        y: proj[1],
        z: proj[2],
        r: isInlineSmall
            ? ((shimmer ? 1.0 : 0.6) + 0.5 * depth)
            : ((shimmer ? 2.6 : 1.4) + 1.8 * depth),
        alpha: shimmer ? 0.95 : (0.30 + 0.68 * depth),
        color: shimmer ? shimmerColor : _depthColor(depth),
      ));
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 8. RESPONDING: Radiating particle field with light shimmer
  // ─────────────────────────────────────────────────────────────
  void _buildRespondingDots(List<_OrbDot> dots, double cx, double cy, double R, double t) {
    final total = isInlineSmall ? 24 : 160;
    final rotY = t * 0.35;
    final rotX = 0.34 + 0.05 * math.sin(t * 0.6);
    final shimmerColor = isInlineSmall ? const Color(0xFFFFFFFF) : primaryColor;

    for (int i = 0; i < total; i++) {
      final dir = _fibDir(i, total);
      final pulse = 0.85 + 0.15 * math.sin(t * 3.0 + i * 0.1);
      final rCurr = R * pulse;

      final proj = _project(dir[0] * rCurr, dir[1] * rCurr, dir[2] * rCurr, rotY, rotX, cx, cy);
      final depth = (proj[2] / rCurr + 1) / 2;
      final shimmer = depth > 0.6 && math.sin(t * 4.0 + i * 0.5) > 0.5;

      dots.add(_OrbDot(
        x: proj[0],
        y: proj[1],
        z: proj[2],
        r: isInlineSmall
            ? ((shimmer ? 1.1 : 0.55) + 0.55 * depth)
            : ((shimmer ? 2.9 : 1.2) + 2.0 * depth),
        alpha: shimmer ? 1.0 : (0.25 + 0.7 * depth),
        color: shimmer ? shimmerColor : _depthColor(depth),
      ));
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 9. SHAPING: Topological polygon morph (Circle → Triangle → Square)
  // ─────────────────────────────────────────────────────────────
  void _buildShapingDots(List<_OrbDot> dots, double cx, double cy, double R, double t) {
    final nDots = isInlineSmall ? 24 : 80;
    final cycle = (t * 0.6) % (math.pi * 3);
    final stage = (cycle / math.pi).floor();
    final p = (cycle / math.pi - stage).clamp(0.0, 1.0);
    final ease = p * p * (3 - 2 * p);
    final leadColor = isInlineSmall ? const Color(0xFFFFFFFF) : primaryColor;

    for (int i = 0; i < nDots; i++) {
      final frac = i / nDots;
      final ang = frac * math.pi * 2 - math.pi / 2;

      final cX = math.cos(ang) * R * 0.85;
      final cY = math.sin(ang) * R * 0.85;
      final tri = _triangleCoord(frac, R * 0.85);
      final sq = _squareCoord(frac, R * 0.85);

      double x0, y0;
      if (stage == 0) {
        x0 = cX * (1 - ease) + tri[0] * ease;
        y0 = cY * (1 - ease) + tri[1] * ease;
      } else if (stage == 1) {
        x0 = tri[0] * (1 - ease) + sq[0] * ease;
        y0 = tri[1] * (1 - ease) + sq[1] * ease;
      } else {
        x0 = sq[0] * (1 - ease) + cX * ease;
        y0 = sq[1] * (1 - ease) + cY * ease;
      }

      final z0 = math.sin(ang * 2 + t) * (R * 0.25);
      final proj = _project(x0, y0, z0, t * 0.1, 0.2, cx, cy);
      final depth = (proj[2] / (R * 0.25) + 1) / 2;
      final isLead = (i % (isInlineSmall ? 4 : 6) == 0);

      dots.add(_OrbDot(
        x: proj[0],
        y: proj[1],
        z: proj[2],
        r: isInlineSmall ? (0.6 + 0.6 * depth) : (1.6 + 2.0 * depth),
        alpha: 0.35 + 0.65 * depth,
        color: isLead ? leadColor : _depthColor(depth),
      ));
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Helper Math Functions
  // ─────────────────────────────────────────────────────────────

  /// Stable Fibonacci sphere lattice point
  List<double> _fibDir(int i, int n) {
    final y = 1.0 - (2.0 * (i + 0.5)) / n;
    final rad = math.sqrt(math.max(0.0, 1.0 - y * y));
    final a = i * _goldenRatioAngle;
    return [rad * math.cos(a), y, rad * math.sin(a)];
  }

  /// 3D Projection to 2D screen coordinates with Z depth
  List<double> _project(double x, double y, double z, double rotY, double rotX, double cx, double cy) {
    final cosY = math.cos(rotY);
    final sinY = math.sin(rotY);
    final x1 = x * cosY + z * sinY;
    final z1 = -x * sinY + z * cosY;

    final cosX = math.cos(rotX);
    final sinX = math.sin(rotX);
    final y2 = y * cosX - z1 * sinX;
    final z2 = y * sinX + z1 * cosX;

    return [cx + x1, cy + y2, z2];
  }

  /// Color shading by depth with theme awareness
  Color _depthColor(double depth) {
    if (isDark) {
      // In dark theme, front dots are crisp white, rear dots are soft twilight slate
      return Color.lerp(
        const Color(0xFF64748B),
        const Color(0xFFFFFFFF),
        depth,
      )!;
    } else {
      // Light theme: dark ink depth
      return Color.lerp(
        const Color(0xFF94A3B8),
        const Color(0xFF0F172A),
        depth,
      )!;
    }
  }

  /// Optional contour lines connecting orbital rings
  void _drawContourOverlay(Canvas canvas, double cx, double cy, double R, double t) {
    final contourPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isInlineSmall ? 0.8 : 1.2
      ..color = primaryColor.withValues(alpha: isDark ? 0.35 : 0.2);

    canvas.drawCircle(Offset(cx, cy), R * 0.9, contourPaint);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: R * 1.8, height: R * 0.6),
      contourPaint,
    );
  }

  List<double> _triangleCoord(double frac, double R) {
    final side = (frac * 3).floor();
    final p = (frac * 3) - side;
    final p0 = [0.0, -R];
    final p1 = [R * 0.866, R * 0.5];
    final p2 = [-R * 0.866, R * 0.5];

    if (side == 0) return [p0[0] + (p1[0] - p0[0]) * p, p0[1] + (p1[1] - p0[1]) * p];
    if (side == 1) return [p1[0] + (p2[0] - p1[0]) * p, p1[1] + (p2[1] - p1[1]) * p];
    return [p2[0] + (p0[0] - p2[0]) * p, p2[1] + (p0[1] - p2[1]) * p];
  }

  List<double> _squareCoord(double frac, double R) {
    final side = (frac * 4).floor();
    final p = (frac * 4) - side;
    final half = R * 0.707;
    if (side == 0) return [-half + 2 * half * p, -half];
    if (side == 1) return [half, -half + 2 * half * p];
    if (side == 2) return [half - 2 * half * p, half];
    return [-half, half - 2 * half * p];
  }

  @override
  bool shouldRepaint(covariant ThinkingOrbPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.state != state ||
        oldDelegate.variant != variant ||
        oldDelegate.isDark != isDark ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.isInlineSmall != isInlineSmall;
  }
}
