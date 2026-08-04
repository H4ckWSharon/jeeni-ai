import 'package:flutter/foundation.dart';
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

  // Time-based rotating suggestions
  static const _morningSuggestions = [
    '☀️ Give me 5 warm-up maths problems to start my day',
    '📖 Explain Photosynthesis step by step',
    '🧠 Quiz me on the Periodic Table elements',
    '✍️ Help me understand Newton\'s Laws of Motion',
  ];

  static const _afternoonSuggestions = [
    '📐 Solve this: If a = 5, b = 3, find the area of a right triangle',
    '🌍 Explain how the Water Cycle works with a diagram',
    '⚗️ What is the difference between acids and bases?',
    '📊 Graph the equation y = 2x + 3',
  ];

  static const _eveningSuggestions = [
    '📝 Give me a quick revision summary of Photosynthesis',
    '🎓 Quiz me on today\'s topic with 5 practice questions',
    '🔬 Explain DNA replication in simple terms',
    '💡 What are the most important Physics formulas I should know?',
  ];

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
      name = user?.displayName?.split(' ').first ?? user?.email?.split('@').first ?? '';
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
    return name.isNotEmpty ? '$greeting, $name!' : '$greeting!';
  }

  List<String> _getTimedSuggestions() {
    final hour = DateTime.now().hour;
    if (hour < 12) return _morningSuggestions;
    if (hour < 17) return _afternoonSuggestions;
    return _eveningSuggestions;
  }

  @override
  Widget build(BuildContext context) {
    final timedSuggestions = _getTimedSuggestions();

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

                // ── Timed Suggestion Chips (Web / Desktop only) ──
                if (kIsWeb && MediaQuery.of(context).size.width > 600) ...[
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: timedSuggestions.map((s) => GestureDetector(
                      onTap: () => widget.onSuggestionTap(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
