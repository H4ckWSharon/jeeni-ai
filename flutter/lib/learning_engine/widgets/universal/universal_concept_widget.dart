import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../common/learning_scaffold.dart';
import '../common/quiz_view.dart';

/// ════════════════════════════════════════════════════════════════════
/// UNIVERSAL INTERACTIVE LEARNING ENGINE WIDGET
/// ════════════════════════════════════════════════════════════════════
/// Generates a complete 5-level interactive educational experience
/// (Definition, Analogy, Interactive Controls, Real-time Simulation,
/// and Knowledge Quiz) for ANY educational concept across Science,
/// Math, Physics, Chemistry, Biology, Geography, and Technology.
/// ════════════════════════════════════════════════════════════════════

class UniversalConceptWidget extends StatefulWidget {
  final String conceptId;

  const UniversalConceptWidget({
    super.key,
    required this.conceptId,
  });

  @override
  State<UniversalConceptWidget> createState() => _UniversalConceptWidgetState();
}

class _UniversalConceptWidgetState extends State<UniversalConceptWidget>
    with SingleTickerProviderStateMixin {
  // Interactive Simulation Controls
  double _inputRate = 5.0; // Slider 1 (1.0 to 10.0)
  double _scaleFactor = 1.0; // Slider 2 (0.5 to 2.0)
  bool _showLabels = true;
  bool _isSimulating = false;

  late AnimationController _simController;

  @override
  void initState() {
    super.initState();
    _simController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _simController.dispose();
    super.dispose();
  }

  void _toggleSimulation() {
    setState(() {
      _isSimulating = !_isSimulating;
      if (_isSimulating) {
        _simController.repeat();
      } else {
        _simController.stop();
      }
    });
  }

  void _resetSimulation() {
    setState(() {
      _isSimulating = false;
      _inputRate = 5.0;
      _scaleFactor = 1.0;
      _simController.reset();
    });
  }

  String _cleanTitle(String rawId) {
    final clean = rawId.replaceAll('_', ' ').replaceAll('-', ' ').trim();
    if (clean.isEmpty) return 'Interactive Concept Engine';
    return clean.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final titleName = _cleanTitle(widget.conceptId);

    final List<String> audioTexts = [
      'Level 1: Welcome to the concept breakdown for $titleName. Let us understand the core rules and principles.',
      'Level 2: Imagine this process as a dynamic system where inputs transform into outputs through key interactions.',
      'Level 3: Adjust the interactive sliders to see how changing input parameters impacts the system in real time.',
      'Level 4: Launch the real-time simulation to observe continuous feedback loops and motion dynamics.',
      'Level 5: Test your knowledge with interactive quiz questions to reinforce your understanding.',
    ];

    return LearningScaffold(
      title: 'Interactive Model: $titleName',
      levelAudioTexts: audioTexts,
      showPlaybackControls: false,
      level1: _buildLevel1(titleName),
      level2: _buildLevel2(titleName),
      level3: _buildLevel3(titleName),
      level4: _buildLevel4(titleName),
      level5: _buildLevel5(titleName),
    );
  }

  // ── Level 1: Core Concept Breakdown ──
  Widget _buildLevel1(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Understanding $title',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          'This interactive model demonstrates the core mechanics of $title. '
          'Use the visual controls to explore how variables interact and observe the resulting changes live.',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              const Text(
                'System Interaction Equation / Rule',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Math.tex(
                  r'\text{Output} = \text{Input Rate} \times \text{Scale Factor}',
                  textStyle: const TextStyle(color: Color(0xFF10B981), fontSize: 18),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildLegendItem('Input', 'Control Rate'),
                  _buildLegendItem('Process', 'Dynamic Transfer'),
                  _buildLegendItem('Output', 'System State'),
                ],
              ),

            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Core Components:',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildBulletPoint('Primary Variable', 'Defines the intensity or magnitude of the phenomenon.'),
        _buildBulletPoint('Scale Factor', 'Influences systemic amplification and boundary interactions.'),
        _buildBulletPoint('Feedback Loop', 'Demonstrates real-time equilibrium and dynamic response.'),
      ],
    );
  }

  // ── Level 2: Visual System Analogy ──
  Widget _buildLevel2(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visual System Model of $title',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          'Observe the flow diagram below representing how $title operates in nature or mathematics.',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 16),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: CustomPaint(
            size: Size.infinite,
            painter: _UniversalModelPainter(
              inputRate: _inputRate,
              scaleFactor: _scaleFactor,
              progress: 0.5,
              showLabels: true,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF10B981), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Key Insight: Changing the input rate directly shifts the energy density across the system.',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Level 3: Interactive Controls ──
  Widget _buildLevel3(String title) {
    final calculatedOutput = _inputRate * _scaleFactor * 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Interactive Controls & Live Scaling',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Drag the sliders to adjust $title parameters in real time.',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
        const SizedBox(height: 16),
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: CustomPaint(
            size: Size.infinite,
            painter: _UniversalModelPainter(
              inputRate: _inputRate,
              scaleFactor: _scaleFactor,
              progress: 0.5,
              showLabels: _showLabels,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Sliders
        Row(
          children: [
            const SizedBox(width: 90, child: Text('Rate:', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
            Text(_inputRate.toStringAsFixed(1), style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
            Expanded(
              child: Slider(
                value: _inputRate,
                min: 1.0,
                max: 10.0,
                activeColor: const Color(0xFF10B981),
                onChanged: (v) => setState(() => _inputRate = v),
              ),
            ),
          ],
        ),
        Row(
          children: [
            const SizedBox(width: 90, child: Text('Scale:', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
            Text('${_scaleFactor.toStringAsFixed(1)}x', style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
            Expanded(
              child: Slider(
                value: _scaleFactor,
                min: 0.5,
                max: 2.0,
                activeColor: const Color(0xFF3B82F6),
                onChanged: (v) => setState(() => _scaleFactor = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Computed Value: ${calculatedOutput.toStringAsFixed(1)} units',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Level 4: Real-time Simulation Engine ──
  Widget _buildLevel4(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Real-time Simulation Engine', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              children: [
                IconButton(
                  icon: Icon(_isSimulating ? Icons.pause_circle_filled : Icons.play_circle_filled, color: const Color(0xFF10B981), size: 28),
                  onPressed: _toggleSimulation,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.grey, size: 22),
                  onPressed: _resetSimulation,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _simController,
          builder: (context, child) {
            return Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: CustomPaint(
                size: Size.infinite,
                painter: _UniversalModelPainter(
                  inputRate: _inputRate,
                  scaleFactor: _scaleFactor,
                  progress: _simController.value,
                  showLabels: true,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Text('Status: ${_isSimulating ? "Simulation Active" : "Paused (Tap Play ▶ to start)"}',
            textAlign: TextAlign.center,
            style: TextStyle(color: _isSimulating ? const Color(0xFF10B981) : Colors.grey, fontWeight: FontWeight.w600, fontSize: 12)),
      ],
    );
  }

  // ── Level 5: Knowledge Quiz ──
  Widget _buildLevel5(String title) {
    final questions = [
      QuizQuestion(
        questionText: 'What primary effect occurs when increasing the input rate in $title?',
        options: [
          'The system output increases proportionally',
          'The system shuts down',
          'No change occurs',
          'The scale factor drops to zero'
        ],
        correctAnswerIndex: 0,
        explanation: 'Increasing the input rate provides more energy/data into the model, boosting total system output.',
      ),
      QuizQuestion(
        questionText: 'Which variable controls systemic amplification in this model?',
        options: ['Scale Factor', 'Time Constant', 'Static Friction', 'Zero Point'],
        correctAnswerIndex: 0,
        explanation: 'The Scale Factor multiplies input values across system boundaries.',
      ),
      QuizQuestion(
        questionText: 'How can you analyze dynamic equilibrium in $title?',
        options: [
          'By observing steady-state output during simulation playback',
          'By setting all parameters to zero',
          'By closing the application',
          'By disabling all visual labels'
        ],
        correctAnswerIndex: 0,
        explanation: 'Active simulations show real-time equilibrium when input and dissipation rates balance.',
      ),
    ];

    return QuizView(questions: questions);
  }

  Widget _buildLegendItem(String symbol, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(symbol, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildBulletPoint(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// DYNAMIC UNIVERSAL MODEL PAINTER
// Draws real-time visual nodes, energy flow pulses, and waves
// ─────────────────────────────────────────────────────────────────
class _UniversalModelPainter extends CustomPainter {
  final double inputRate;
  final double scaleFactor;
  final double progress;
  final bool showLabels;

  _UniversalModelPainter({
    required this.inputRate,
    required this.scaleFactor,
    required this.progress,
    required this.showLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final bgPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw background grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 25) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 25) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw central node circle
    final baseRadius = 25.0 * scaleFactor;
    final pulseRadius = baseRadius + sin(progress * 2 * pi) * (inputRate * 1.5);

    final outerPaint = Paint()
      ..color = const Color(0xFF10B981).withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, pulseRadius + 15, outerPaint);

    final nodePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, baseRadius, nodePaint);

    final corePaint = Paint()..color = const Color(0xFF3B82F6);
    canvas.drawCircle(center, 8, corePaint);

    // Draw input flow wave line
    final wavePath = Path();
    final startY = size.height / 2;
    wavePath.moveTo(20, startY);
    for (double x = 20; x < size.width - 20; x += 2) {
      final y = startY + sin((x / 20) + (progress * 2 * pi)) * (inputRate * 3 * scaleFactor);
      wavePath.lineTo(x, y);
    }

    final wavePaint = Paint()
      ..color = const Color(0xFF10B981).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(wavePath, wavePaint);

    // Labels
    if (showLabels) {
      _drawText(canvas, 'Input Flow', const Offset(25, 15), const Color(0xFF10B981));
      _drawText(canvas, 'Core State', Offset(center.dx - 28, center.dy + baseRadius + 8), const Color(0xFF3B82F6));
      _drawText(canvas, 'Output Rate: ${(inputRate * scaleFactor * 10).toStringAsFixed(0)}', Offset(size.width - 130, 15), Colors.white70);
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _UniversalModelPainter oldDelegate) {
    return oldDelegate.inputRate != inputRate ||
        oldDelegate.scaleFactor != scaleFactor ||
        oldDelegate.progress != progress ||
        oldDelegate.showLabels != showLabels;
  }
}
