import 'dart:math';
import 'package:flutter/material.dart';

class FlashcardItem {
  final String question;
  final String answer;

  const FlashcardItem({
    required this.question,
    required this.answer,
  });
}

class FlashcardView extends StatefulWidget {
  final List<FlashcardItem> flashcards;

  const FlashcardView({
    super.key,
    required this.flashcards,
  });

  @override
  State<FlashcardView> createState() => _FlashcardViewState();
}

class _FlashcardViewState extends State<FlashcardView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _currentIndex = 0;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0, end: pi).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_showFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _showFront = !_showFront;
    });
  }

  void _nextCard() {
    if (_currentIndex < widget.flashcards.length - 1) {
      setState(() {
        _currentIndex++;
        _showFront = true;
      });
      _controller.reset();
    }
  }

  void _prevCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showFront = true;
      });
      _controller.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.flashcards.isEmpty) {
      return const Center(
        child: Text('No flashcards available.', style: TextStyle(color: Colors.white)),
      );
    }

    final card = widget.flashcards[_currentIndex];

    return Column(
      children: [
        // Progress indicator
        Text(
          'Card ${_currentIndex + 1} of ${widget.flashcards.length}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),

        // Flip Card Box
        GestureDetector(
          onTap: _flipCard,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final angle = _animation.value;
              final isBack = angle >= pi / 2;

              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // perspective
                  ..rotateY(angle),
                alignment: Alignment.center,
                child: isBack
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(pi), // correct mirror inversion
                        child: _buildCardFace(card.answer, 'ANSWER', const Color(0xFF10B981)),
                      )
                    : _buildCardFace(card.question, 'QUESTION', const Color(0xFFFFB020)),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Navigation Controllers
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              onPressed: _currentIndex > 0 ? _prevCard : null,
              disabledColor: Colors.white.withOpacity(0.15),
            ),
            const SizedBox(width: 24),
            Text(
              'Tap card to flip',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 24),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
              onPressed: _currentIndex < widget.flashcards.length - 1 ? _nextCard : null,
              disabledColor: Colors.white.withOpacity(0.15),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardFace(String text, String tag, Color accentColor) {
    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
