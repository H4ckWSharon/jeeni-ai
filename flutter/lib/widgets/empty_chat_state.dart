import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ═══════════════════════════════════════════════════
// MINIMAL CLEAN EMPTY CHAT STATE — Greeting Only (No Logo)
// ═══════════════════════════════════════════════════

class EmptyChatState extends StatefulWidget {
  final List<String> suggestions;
  final void Function(String) onSuggestionTap;

  const EmptyChatState({
    super.key,
    this.suggestions = const [],
    required this.onSuggestionTap,
  });

  @override
  State<EmptyChatState> createState() => _EmptyChatStateState();
}

class _EmptyChatStateState extends State<EmptyChatState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<double>(begin: 16, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getGreeting() {
    String name = '';
    try {
      final user = FirebaseAuth.instance.currentUser;
      name = user?.displayName?.split(' ').first ?? '';
    } catch (_) {}

    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }
    return name.isNotEmpty ? '$greeting, $name!' : greeting;
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: AnimatedBuilder(
        animation: _slideUp,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _slideUp.value),
          child: child,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Greeting Subtitle ──
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 8),

                // ── Clean Main Heading ──
                const Text(
                  'How can I help you today?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
