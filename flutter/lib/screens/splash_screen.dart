import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'auth/auth_gate.dart';

// ═══════════════════════════════════════════════════
// SPLASH SCREEN — ChatGPT-style 30-second animated intro
// ═══════════════════════════════════════════════════
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // Slow 360° orbital ring rotation — lasts the full 30 seconds
  late AnimationController _orbitController;
  // A second faster inner ring
  late AnimationController _innerOrbitController;
  // Logo fade + scale in
  late AnimationController _logoController;
  // Pulse glow breath
  late AnimationController _pulseController;
  // Text fade in
  late AnimationController _textController;
  // Exit fade to black
  late AnimationController _exitController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _textSlide;
  late Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();

    // ── Outer orbital ring — one full rotation every 8s, runs 30s total ──
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // ── Inner ring — rotates opposite, every 5s ──
    _innerOrbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    // ── Logo entrance: scale + fade in over 300ms ──
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    // ── Breathing pulse glow ──
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // ── Text slide up ──
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    // ── Exit fade out ──
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    // 0.10s delay, then fade logo in
    await Future.delayed(const Duration(milliseconds: 100));
    _logoController.forward();

    // Text appears 0.20s later
    await Future.delayed(const Duration(milliseconds: 200));
    _textController.forward();

    // Sit at splash for 0.30s (ChatGPT-style fast intro)
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // Exit fade
    _exitController.forward();
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => const AuthGate(),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ),
    );
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _innerOrbitController.dispose();
    _logoController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _exitController,
        builder: (context, child) => Opacity(
          opacity: _exitFade.value,
          child: child,
        ),
        child: SizedBox.expand(
          child: Stack(
            alignment: Alignment.center,
            children: [

              // ── Ambient background radial glow (static) ──
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return Transform.scale(
                    scale: _pulseScale.value,
                    child: Container(
                      width: 340,
                      height: 340,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.045 * _pulseOpacity.value),
                            Colors.white.withOpacity(0.012 * _pulseOpacity.value),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // ── Outer orbital arc ring ──
              AnimatedBuilder(
                animation: _orbitController,
                builder: (context, _) {
                  return Transform.rotate(
                    angle: _orbitController.value * 2 * math.pi,
                    child: CustomPaint(
                      size: const Size(280, 280),
                      painter: _ArcRingPainter(
                        color: Colors.white.withOpacity(0.18),
                        strokeWidth: 1.0,
                        sweepFraction: 0.38,
                      ),
                    ),
                  );
                },
              ),

              // ── Second arc — rotates opposite direction, slightly smaller ──
              AnimatedBuilder(
                animation: _innerOrbitController,
                builder: (context, _) {
                  return Transform.rotate(
                    angle: -_innerOrbitController.value * 2 * math.pi,
                    child: CustomPaint(
                      size: const Size(230, 230),
                      painter: _ArcRingPainter(
                        color: Colors.white.withOpacity(0.12),
                        strokeWidth: 0.7,
                        sweepFraction: 0.22,
                      ),
                    ),
                  );
                },
              ),

              // ── Third arc — even slower ──
              AnimatedBuilder(
                animation: Listenable.merge([_orbitController, _pulseController]),
                builder: (context, _) {
                  return Transform.rotate(
                    angle: _orbitController.value * 2 * math.pi * 0.6,
                    child: CustomPaint(
                      size: const Size(320, 320),
                      painter: _ArcRingPainter(
                        color: Colors.white.withOpacity(0.07 * _pulseOpacity.value),
                        strokeWidth: 0.5,
                        sweepFraction: 0.55,
                      ),
                    ),
                  );
                },
              ),

              // ── Pulse glow halo behind logo ──
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.06 * _pulseOpacity.value),
                          blurRadius: 80,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  );
                },
              ),

              // ── Logo + text column ──
              AnimatedBuilder(
                animation: Listenable.merge([_logoController, _textController]),
                builder: (context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo image
                      Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: SizedBox(
                            width: 130,
                            height: 130,
                            child: Image.asset(
                              'assets/images/splash_logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 44),

                      // JEENI wordmark
                      Opacity(
                        opacity: _textOpacity.value,
                        child: Transform.translate(
                          offset: Offset(0, _textSlide.value),
                          child: Column(
                            children: [
                              const Text(
                                'JEENI',
                                style: TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                  letterSpacing: 12,
                                  fontFamily: 'serif',
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'YOUR AI COMPANION',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withOpacity(0.35),
                                  letterSpacing: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              // ── Bottom "Loading" subtle dots ──
              Positioned(
                bottom: 60,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return _BouncingDots(controller: _pulseController);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// CUSTOM PAINTER — Arc ring (like ChatGPT spinner)
// ═══════════════════════════════════════════════════
class _ArcRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double sweepFraction; // 0..1 fraction of circle to draw

  const _ArcRingPainter({
    required this.color,
    required this.strokeWidth,
    required this.sweepFraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = sweepFraction * 2 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcRingPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.sweepFraction != sweepFraction;
}

// ═══════════════════════════════════════════════════
// BOUNCING DOTS — subtle loading indicator
// ═══════════════════════════════════════════════════
class _BouncingDots extends StatelessWidget {
  final AnimationController controller;
  const _BouncingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (controller.value + i * 0.33) % 1.0;
            final opacity = (math.sin(phase * math.pi)).clamp(0.1, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(opacity * 0.4),
              ),
            );
          }),
        );
      },
    );
  }
}
