import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ═══════════════════════════════════════════════════
// EMPTY CHAT STATE — ChatGPT-style welcome page
// ═══════════════════════════════════════════════════

class EmptyChatState extends StatefulWidget {
  final List<String> suggestions;
  final void Function(String) onSuggestionTap;

  const EmptyChatState({
    super.key,
    required this.suggestions,
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
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.split(' ').first ?? '';
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
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // ── Greeting ──
                Text(
                  _getGreeting(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 8),

                // ── Main heading ──
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
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
                ),

                const SizedBox(height: 28),

                // ── Suggestion chips ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: widget.suggestions.map((s) {
                      // Strip [interactive:xxx] tag — show only the clean label
                      final label = s
                          .replaceAll(RegExp(r'\[interactive:[a-zA-Z0-9_-]+\]'), '')
                          .trim();
                      return _SuggestionChip(
                        text: label,
                        onTap: () => widget.onSuggestionTap(s),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 36),

                // ── Feature row ──
                _FeatureRow(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// SUGGESTION CHIP
// ═══════════════════════════════════════════════════

class _SuggestionChip extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  const _SuggestionChip({required this.text, required this.onTap});

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _pressed
              ? Colors.white.withOpacity(0.12)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _pressed
                ? Colors.white.withOpacity(0.25)
                : Colors.white.withOpacity(0.10),
          ),
        ),
        child: Text(
          widget.text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// FEATURE ROW — 3 items with dividers
// ═══════════════════════════════════════════════════

class _FeatureRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _featureItem(Icons.chat_bubble_outline_rounded, 'Ask Anything'),
          _divider(),
          _featureItem(Icons.hub_outlined, 'Learn Faster'),
          _divider(),
          _featureItem(Icons.track_changes_rounded, 'Achieve More'),
        ],
      ),
    );
  }

  Widget _featureItem(IconData icon, String label) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Icon(icon, size: 15, color: Colors.white.withOpacity(0.45)),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label, style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12, fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
            )),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1, height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white.withOpacity(0.06),
    );
  }
}
