import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../common/learning_scaffold.dart';
import '../common/quiz_view.dart';

class UnitCircleWidget extends StatefulWidget {
  const UnitCircleWidget({super.key});

  @override
  State<UnitCircleWidget> createState() => _UnitCircleWidgetState();
}

class _UnitCircleWidgetState extends State<UnitCircleWidget> {
  double _angleDegrees = 45.0; // degrees

  static const List<QuizQuestion> _quizQuestions = [
    QuizQuestion(
      questionText: 'What are the values of sin(90\u00b0) and cos(90\u00b0)?',
      options: [
        'sin = 0, cos = 1',
        'sin = 1, cos = 0',
        'sin = 0.5, cos = 0.5',
        'sin = 1, cos = 1',
      ],
      correctAnswerIndex: 1,
      explanation: 'At 90 degrees (top of the unit circle), x is 0 and y is 1. Thus cos(90\u00b0) = 0 and sin(90\u00b0) = 1.',
    ),
    QuizQuestion(
      questionText: 'Which quadrant has both sine and cosine negative?',
      options: ['Quadrant I', 'Quadrant II', 'Quadrant III', 'Quadrant IV'],
      correctAnswerIndex: 2,
      explanation: 'In Quadrant III (bottom left), both the x-coordinate (cos) and y-coordinate (sin) are negative.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final angleRad = _angleDegrees * pi / 180.0;
    final cosVal = cos(angleRad);
    final sinVal = sin(angleRad);

    final List<String> audioTexts = [
      'Level 1: The unit circle is a circle with a radius of one centered at the origin. The coordinates on this circle represent sine and cosine values.',
      'Level 2: Imagine a clock hand sweeping around. The horizontal length of the shadow is cosine, and the vertical height is sine.',
      'Level 3: Look at the circle visualizer. Drag the slider to rotate the radius vector and observe the x and y components update live.',
      'Level 4: Play with the angles inside different quadrants. Notice that coordinate points become negative values in the left or lower hemispheres.',
      'Level 5: Solve the questions to verify your understanding of the unit circle.',
    ];

    return LearningScaffold(
      title: 'Trigonometry: The Unit Circle',
      levelAudioTexts: audioTexts,
      level1: _buildLevel1(),
      level2: _buildLevel2(),
      level3: _buildLevel3(cosVal, sinVal),
      level4: _buildLevel4(cosVal, sinVal),
      level5: const QuizView(questions: _quizQuestions),
    );
  }

  Widget _buildLevel1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('The Unit Circle', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(
          'A Unit Circle is a circle of radius 1 centered at the coordinate plane origin (0,0). '
          'For any angle \u03b8, the point where the terminal side intersects the circle is (cos \u03b8, sin \u03b8).',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              FittedBox(fit: BoxFit.scaleDown, child: Math.tex(r'(x, y) = (\cos \theta, \sin \theta)', textStyle: const TextStyle(color: Color(0xFF10B981), fontSize: 20))),
              const SizedBox(height: 8),
              FittedBox(fit: BoxFit.scaleDown, child: Math.tex(r'\cos^2 \theta + \sin^2 \theta = 1', textStyle: const TextStyle(color: Colors.amber, fontSize: 18))),

            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLevel2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('The Shadow Analogy', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(
          'Imagine a spotlight shining down vertically: the length of the shadow cast on the floor is the cosine. '
          'Imagine a spotlight shining horizontally: the shadow cast on the wall is the sine.',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildLevel3(double cosVal, double sinVal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 150,
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
          child: CustomPaint(
            size: Size.infinite,
            painter: _UnitCirclePainter(angleDegrees: _angleDegrees),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Angle (\u03b8): ', style: TextStyle(color: Colors.white, fontSize: 12)),
            Text('${_angleDegrees.toStringAsFixed(0)}\u00b2', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
            Expanded(
              child: Slider(
                value: _angleDegrees,
                min: 0.0,
                max: 360.0,
                activeColor: const Color(0xFF10B981),
                onChanged: (val) => setState(() => _angleDegrees = val),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildReadoutCard('Cosine (x)', cosVal.toStringAsFixed(3), Colors.blueAccent),
            _buildReadoutCard('Sine (y)', sinVal.toStringAsFixed(3), const Color(0xFF10B981)),
          ],
        ),
      ],
    );
  }

  Widget _buildLevel4(double cosVal, double sinVal) {
    final tangentVal = cosVal.abs() > 0.001 ? (sinVal / cosVal).toStringAsFixed(3) : 'Undefined';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Explore Trigonometric Ratios', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildMetricRow('Cosine (\u03b8)', cosVal.toStringAsFixed(3)),
        _buildMetricRow('Sine (\u03b8)', sinVal.toStringAsFixed(3)),
        _buildMetricRow('Tangent (\u03b8)', tangentVal),
      ],
    );
  }

  Widget _buildReadoutCard(String label, String val, Color highlight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(color: highlight, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
          Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

class _UnitCirclePainter extends CustomPainter {
  final double angleDegrees;
  _UnitCirclePainter({required this.angleDegrees});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final circleRadius = min(size.width, size.height) * 0.4;

    final paintStroke = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Draw Axis
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paintStroke);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), paintStroke);

    // Draw Circle
    canvas.drawCircle(center, circleRadius, paintStroke);

    // Calculate angle line
    final angleRad = angleDegrees * pi / 180.0;
    final targetPoint = Offset(
      center.dx + circleRadius * cos(angleRad),
      center.dy - circleRadius * sin(angleRad), // invert y in Canvas coordinate system
    );

    // Draw radius line
    final linePaint = Paint()
      ..color = Colors.amber
      ..strokeWidth = 2.0;
    canvas.drawLine(center, targetPoint, linePaint);

    // Draw Sine line (vertical, green)
    final sinePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(targetPoint.dx, center.dy), targetPoint, sinePaint);

    // Draw Cosine line (horizontal, blue)
    final cosinePaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 2.0;
    canvas.drawLine(center, Offset(targetPoint.dx, center.dy), cosinePaint);

    // Dot at coordinate point
    canvas.drawCircle(targetPoint, 4.0, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _UnitCirclePainter oldDelegate) {
    return oldDelegate.angleDegrees != angleDegrees;
  }
}
