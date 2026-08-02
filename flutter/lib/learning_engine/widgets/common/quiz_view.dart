import 'package:flutter/material.dart';

class QuizQuestion {
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  const QuizQuestion({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  });
}

class QuizView extends StatefulWidget {
  final List<QuizQuestion> questions;
  final VoidCallback? onComplete;

  const QuizView({
    super.key,
    required this.questions,
    this.onComplete,
  });

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  int _currentIndex = 0;
  int? _selectedAnswerIndex;
  bool _answered = false;
  int _score = 0;
  bool _quizCompleted = false;

  void _submitAnswer(int index) {
    if (_answered) return;
    setState(() {
      _selectedAnswerIndex = index;
      _answered = true;
      if (index == widget.questions[_currentIndex].correctAnswerIndex) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswerIndex = null;
        _answered = false;
      });
    } else {
      setState(() {
        _quizCompleted = true;
      });
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    }
  }

  void _resetQuiz() {
    setState(() {
      _currentIndex = 0;
      _selectedAnswerIndex = null;
      _answered = false;
      _score = 0;
      _quizCompleted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return const Center(
        child: Text(
          'No quiz questions available.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    if (_quizCompleted) {
      return _buildScoreSummary();
    }

    final question = widget.questions[_currentIndex];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: ValueKey<int>(_currentIndex),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Progress Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentIndex + 1} of ${widget.questions.length}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Score: $_score / ${_currentIndex + (_answered ? 1 : 0)}',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.questions.length,
              backgroundColor: Colors.white.withOpacity(0.05),
              color: const Color(0xFF10B981),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 20),

          // Question Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Text(
              question.questionText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Options
          ...List.generate(question.options.length, (index) {
            final option = question.options[index];
            return _buildOptionButton(index, option, question);
          }),

          // Feedback panel
          if (_answered) ...[
            const SizedBox(height: 20),
            _buildFeedbackPanel(question),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: _nextQuestion,
              child: Text(
                _currentIndex == widget.questions.length - 1
                    ? 'Finish Quiz'
                    : 'Next Question',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionButton(int index, String option, QuizQuestion question) {
    Color buttonColor = const Color(0xFF161616);
    Color borderColor = Colors.white.withOpacity(0.05);
    Color textColor = Colors.white;
    IconData? icon;

    if (_answered) {
      if (index == question.correctAnswerIndex) {
        buttonColor = const Color(0xFF10B981).withOpacity(0.1);
        borderColor = const Color(0xFF10B981).withOpacity(0.4);
        textColor = const Color(0xFF10B981);
        icon = Icons.check_circle_rounded;
      } else if (index == _selectedAnswerIndex) {
        buttonColor = const Color(0xFFEF4444).withOpacity(0.1);
        borderColor = const Color(0xFFEF4444).withOpacity(0.4);
        textColor = const Color(0xFFEF4444);
        icon = Icons.cancel_rounded;
      } else {
        textColor = Colors.white.withOpacity(0.4);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _submitAnswer(index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, color: textColor, size: 20),
              ] else if (!_answered) ...[
                const SizedBox(width: 8),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackPanel(QuizQuestion question) {
    final isCorrect = _selectedAnswerIndex == question.correctAnswerIndex;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? const Color(0xFF10B981).withOpacity(0.05)
            : const Color(0xFFEF4444).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect
              ? const Color(0xFF10B981).withOpacity(0.2)
              : const Color(0xFFEF4444).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.info_rounded,
                color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Correct!' : 'Incorrect',
                style: TextStyle(
                  color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.explanation,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSummary() {
    final double percentage = widget.questions.isNotEmpty
        ? (_score / widget.questions.length) * 100
        : 0.0;
    String feedbackText = 'Good effort! Try again to get a perfect score.';
    if (percentage == 100) {
      feedbackText = 'Perfect score! You\'ve completely mastered this concept.';
    } else if (percentage >= 70) {
      feedbackText = 'Great job! You have a solid understanding.';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            color: Color(0xFFFFD700),
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Quiz Completed!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You scored $_score out of ${widget.questions.length}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Text(
              feedbackText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _resetQuiz,
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
