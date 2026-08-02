import 'package:flutter/material.dart';
import 'dart:math';
import 'auth/welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _page = 0;

  late AnimationController _contentAnim;
  late AnimationController _floatAnim;
  late Animation<double> _contentFade;
  late Animation<double> _contentSlide;

  @override
  void initState() {
    super.initState();
    _contentAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _contentFade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _contentAnim, curve: Curves.easeOut));
    _contentSlide = Tween(begin: 50.0, end: 0.0).animate(CurvedAnimation(parent: _contentAnim, curve: Curves.easeOutCubic));
    _contentAnim.forward();

    _floatAnim = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _contentAnim.dispose();
    _floatAnim.dispose();
    super.dispose();
  }

  void _onPage(int i) {
    setState(() => _page = i);
    _contentAnim.forward(from: 0);
  }

  void _next() {
    if (_page < 2) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOutCubic);
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => const WelcomeScreen(),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        ),
      );
    }
  }

  void _skip() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const WelcomeScreen(),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ),
    );
  }

  static const _titles = [
    'Your Personal\nAI Genie',
    'Ask Anything,\nLearn Instantly',
    'Track & Achieve\nYour Goals',
  ];

  static const _subs = [
    'Jeeni understands you. Ask any question and get clear, magical answers in seconds.',
    'Physics, Maths, Chemistry, Biology — step-by-step explanations for every subject.',
    'Set targets, track your learning streaks, and watch yourself grow smarter every day.',
  ];

  static const _accents = [Color(0xFFB388FF), Color(0xFF818CF8), Color(0xFF22D3EE)];

  static const _icons = [Icons.auto_awesome, Icons.school_rounded, Icons.emoji_events_rounded];

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final accent = _accents[_page];

    return Scaffold(
      backgroundColor: const Color(0xFF070D1A),
      body: Stack(
        children: [
          // ── Background animated gradient blobs ──
          AnimatedBuilder(
            animation: _floatAnim,
            builder: (context, _) {
              final v = _floatAnim.value;
              return Stack(
                children: [
                  Positioned(
                    top: -60 + v * 30,
                    right: -40 + v * 20,
                    child: Container(width: 280, height: 280,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [accent.withOpacity(0.12), Colors.transparent]),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 200 - v * 20,
                    left: -60 + v * 15,
                    child: Container(width: 220, height: 220,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [const Color(0xFF8B5CF6).withOpacity(0.08), Colors.transparent]),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // ── Page view for illustrations ──
          PageView.builder(
            controller: _pageCtrl,
            onPageChanged: _onPage,
            itemCount: 3,
            itemBuilder: (ctx, i) => _IllustrationPage(
              index: i, floatAnim: _floatAnim, accent: _accents[i],
            ),
          ),

          // ── Bottom content overlay ──
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF070D1A).withOpacity(0.0),
                    const Color(0xFF070D1A).withOpacity(0.85),
                    const Color(0xFF070D1A),
                  ],
                  stops: const [0.0, 0.3, 0.6],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 80, 28, 20),
                  child: AnimatedBuilder(
                    animation: _contentAnim,
                    builder: (context, child) => Opacity(
                      opacity: _contentFade.value,
                      child: Transform.translate(
                        offset: Offset(0, _contentSlide.value),
                        child: child,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Accent tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: accent.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_icons[_page], size: 14, color: accent),
                              const SizedBox(width: 6),
                              Text(
                                _page == 0 ? 'WELCOME' : _page == 1 ? 'LEARN' : 'GROW',
                                style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Title
                        Text(_titles[_page], style: const TextStyle(
                          fontSize: 36, fontWeight: FontWeight.w800,
                          color: Colors.white, height: 1.1, letterSpacing: -1.0,
                        )),

                        const SizedBox(height: 14),

                        // Subtitle
                        Text(_subs[_page], style: TextStyle(
                          fontSize: 15, color: Colors.white.withOpacity(0.55),
                          height: 1.6, fontWeight: FontWeight.w400,
                        )),

                        const SizedBox(height: 36),

                        // Dots + Button
                        Row(
                          children: [
                            ...List.generate(3, (i) {
                              final active = i == _page;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                                margin: const EdgeInsets.only(right: 6),
                                width: active ? 32 : 8, height: 8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: active ? accent : Colors.white.withOpacity(0.18),
                                  boxShadow: active ? [BoxShadow(color: accent.withOpacity(0.5), blurRadius: 10)] : null,
                                ),
                              );
                            }),
                            const Spacer(),
                            _CTAButton(
                              label: _page == 2 ? 'Get Started' : 'Continue',
                              color: accent,
                              onTap: _next,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Skip ──
          if (_page < 2)
            Positioned(
              top: mq.padding.top + 14, right: 20,
              child: GestureDetector(
                onTap: _skip,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  child: Text('Skip', style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w500,
                  )),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// ILLUSTRATION PAGE — pure code, no images
// ═══════════════════════════════════════════════════

class _IllustrationPage extends StatelessWidget {
  final int index;
  final AnimationController floatAnim;
  final Color accent;

  const _IllustrationPage({required this.index, required this.floatAnim, required this.accent});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return SizedBox(
      height: mq.size.height * 0.55,
      child: AnimatedBuilder(
        animation: floatAnim,
        builder: (ctx, _) {
          final v = floatAnim.value;
          switch (index) {
            case 0: return _buildPage1(v, mq.size);
            case 1: return _buildPage2(v, mq.size);
            case 2: return _buildPage3(v, mq.size);
            default: return const SizedBox();
          }
        },
      ),
    );
  }

  // ── Page 1: Big logo with magic rings ──
  Widget _buildPage1(double v, Size size) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: size.height * 0.18),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring 3
            Transform.scale(
              scale: 0.9 + v * 0.15,
              child: Container(
                width: 280, height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withOpacity(0.08 + v * 0.06), width: 1),
                ),
              ),
            ),
            // Outer ring 2
            Transform.scale(
              scale: 0.95 + v * 0.08,
              child: Container(
                width: 240, height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withOpacity(0.12 + v * 0.08), width: 1.5),
                ),
              ),
            ),
            // Glow
            Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: accent.withOpacity(0.25 + v * 0.15), blurRadius: 70, spreadRadius: 20),
                  BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.1 + v * 0.05), blurRadius: 100, spreadRadius: 30),
                ],
              ),
            ),
            // Logo
            Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: const DecorationImage(image: AssetImage('assets/images/logo.png'), fit: BoxFit.cover),
                boxShadow: [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 40, spreadRadius: 5)],
              ),
            ),
            // Floating sparkle dots
            ..._sparkles(v, 280, accent),
          ],
        ),
      ),
    );
  }

  // ── Page 2: Animated chat bubbles ──
  Widget _buildPage2(double v, Size size) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: size.height * 0.18),
        child: SizedBox(
          width: 300, height: 340,
          child: Stack(
            children: [
              // User bubble
              Positioned(
                right: 10, top: 20 + v * 8,
                child: _chatBubble('What is Newton\'s 2nd law?', true, accent, 0.9 + v * 0.1),
              ),
              // AI response bubble
              Positioned(
                left: 10, top: 90 - v * 5,
                child: _chatBubble('F = ma\nForce equals mass\ntimes acceleration ✨', false, accent, 0.85 + v * 0.15),
              ),
              // Typing indicator
              Positioned(
                left: 10, top: 230 + v * 6,
                child: _typingIndicator(v, accent),
              ),
              // Floating subject pills
              Positioned(
                right: 0, top: 265 - v * 10,
                child: _subjectPill('⚛️ Physics', const Color(0xFF818CF8), 0.8 + v * 0.2),
              ),
              Positioned(
                right: 80, top: 295 + v * 8,
                child: _subjectPill('📐 Maths', const Color(0xFF22D3EE), 0.85 + v * 0.15),
              ),
              Positioned(
                left: 10, top: 290 - v * 4,
                child: _subjectPill('🧬 Biology', const Color(0xFF10B981), 0.9 + v * 0.1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Page 3: Achievement / Progress ──
  Widget _buildPage3(double v, Size size) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: size.height * 0.18),
        child: SizedBox(
          width: 300, height: 340,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Progress ring
              Transform.scale(
                scale: 0.9 + v * 0.1,
                child: SizedBox(
                  width: 180, height: 180,
                  child: CustomPaint(
                    painter: _ProgressRingPainter(
                      progress: 0.78,
                      color: accent,
                      bgColor: Colors.white.withOpacity(0.06),
                    ),
                  ),
                ),
              ),
              // Center text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('78%', style: TextStyle(
                    fontSize: 52, fontWeight: FontWeight.w800, color: accent, height: 1,
                  )),
                  const SizedBox(height: 4),
                  Text('Progress', style: TextStyle(
                    fontSize: 14, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w500,
                  )),
                ],
              ),
              // Floating achievement badges
              Positioned(
                left: 20, top: 30 + v * 12,
                child: _badge('🔥', '7 Day\nStreak', const Color(0xFFF59E0B), 0.85 + v * 0.15),
              ),
              Positioned(
                right: 20, top: 50 - v * 8,
                child: _badge('⭐', 'Top\nLearner', const Color(0xFFB388FF), 0.9 + v * 0.1),
              ),
              Positioned(
                left: 50, bottom: 30 + v * 10,
                child: _badge('🏆', '100\nAnswers', const Color(0xFF22D3EE), 0.8 + v * 0.2),
              ),
              Positioned(
                right: 40, bottom: 45 - v * 6,
                child: _badge('📚', '5\nSubjects', const Color(0xFF10B981), 0.92 + v * 0.08),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──
  Widget _chatBubble(String text, bool isUser, Color accent, double opacity) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? accent.withOpacity(0.2) : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: Border.all(
            color: isUser ? accent.withOpacity(0.35) : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Text(text, style: TextStyle(
          color: isUser ? accent : Colors.white.withOpacity(0.8),
          fontSize: 14, fontWeight: FontWeight.w500, height: 1.4,
        )),
      ),
    );
  }

  Widget _typingIndicator(double v, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final dotV = sin((v * 2 * pi) + i * 0.8).abs();
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.3 + dotV * 0.5),
            ),
          );
        }),
      ),
    );
  }

  Widget _subjectPill(String label, Color color, double opacity) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _badge(String emoji, String label, Color color, double opacity) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 12)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600, height: 1.2)),
          ],
        ),
      ),
    );
  }

  List<Widget> _sparkles(double v, double radius, Color color) {
    final rng = Random(42);
    return List.generate(12, (i) {
      final angle = (i / 12) * 2 * pi + v * pi;
      final dist = radius / 2 + rng.nextDouble() * 30;
      final x = cos(angle) * dist;
      final y = sin(angle) * dist;
      final size = 2.0 + rng.nextDouble() * 3;
      final opac = (sin(v * 2 * pi + i) * 0.5 + 0.5).clamp(0.0, 1.0);
      return Positioned(
        left: 140 + x - size / 2,
        top: 140 + y - size / 2,
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(opac * 0.7),
            boxShadow: [BoxShadow(color: color.withOpacity(opac * 0.4), blurRadius: 6)],
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════
// PROGRESS RING PAINTER
// ═══════════════════════════════════════════════════

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;
  _ProgressRingPainter({required this.progress, required this.color, required this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeW = 10.0;

    // Background ring
    canvas.drawCircle(center, radius, Paint()
      ..color = bgColor ..style = PaintingStyle.stroke ..strokeWidth = strokeW);

    // Progress arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: [color.withOpacity(0.3), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );

    // End dot glow
    final endAngle = -pi / 2 + 2 * pi * progress;
    final dotPos = Offset(center.dx + radius * cos(endAngle), center.dy + radius * sin(endAngle));
    canvas.drawCircle(dotPos, 6, Paint()..color = color);
    canvas.drawCircle(dotPos, 12, Paint()..color = color.withOpacity(0.2));
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════
// CTA BUTTON
// ═══════════════════════════════════════════════════

class _CTAButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _CTAButton({required this.label, required this.color, required this.onTap});

  @override
  State<_CTAButton> createState() => _CTAButtonState();
}

class _CTAButtonState extends State<_CTAButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 80),
      lowerBound: 0.94, upperBound: 1.0, value: 1.0);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) { _ctrl.forward(); widget.onTap(); },
      onTapCancel: () => _ctrl.forward(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(scale: _ctrl.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [widget.color, widget.color.withOpacity(0.8)]),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [BoxShadow(color: widget.color.withOpacity(0.45), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label, style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.3,
              )),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
