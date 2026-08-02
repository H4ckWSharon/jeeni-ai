import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  final List<AnimationController> _dots = [];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300))..forward();
    for (int i = 0; i < 3; i++) {
      final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
      _dots.add(c);
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) c.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    for (final c in _dots) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeCtrl,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(3, (i) => AnimatedBuilder(
            animation: _dots[i],
            builder: (_, __) => Container(
              margin: const EdgeInsets.only(right: 6),
              child: Transform.translate(
                offset: Offset(0, -4 * _dots[i].value),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFA1A1AA).withOpacity(0.3 + 0.6 * _dots[i].value),
                  ),
                ),
              ),
            ),
          )),
        ),
      ),
    );
  }
}
