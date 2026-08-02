import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../common/learning_scaffold.dart';
import '../common/quiz_view.dart';

class CircleAreaWidget extends StatefulWidget {
  const CircleAreaWidget({super.key});

  @override
  State<CircleAreaWidget> createState() => _CircleAreaWidgetState();
}

class _CircleAreaWidgetState extends State<CircleAreaWidget> {
  // Level 3 & 4 Simulation State
  double _radius = 5.0;
  bool _showGrid = true;
  bool _showCircumference = false;

  // Mini quiz questions
  static const List<QuizQuestion> _quizQuestions = [
    QuizQuestion(
      questionText: 'If a circle has a radius of 3 units, what is its area? (Take \u03c0 \u2248 3.14)',
      options: [
        '9.42 square units',
        '28.26 square units',
        '18.84 square units',
        '6.28 square units',
      ],
      correctAnswerIndex: 1,
      explanation: 'The area formula is A = \u03c0 * r\u00b2. Here, A = 3.14 * 3\u00b2 = 3.14 * 9 = 28.26 square units.',
    ),
    QuizQuestion(
      questionText: 'Which of the following describes the relationship between the radius (r) and the circumference (C) of a circle?',
      options: [
        'C = \u03c0 * r',
        'C = \u03c0 * r\u00b2',
        'C = 2 * \u03c0 * r',
        'C = \u03c0 * d\u00b2',
      ],
      correctAnswerIndex: 2,
      explanation: 'Circumference is the distance around the circle, calculated as C = 2 * \u03c0 * r (or \u03c0 * d).',
    ),
    QuizQuestion(
      questionText: 'A common mistake is confusing radius with diameter. If a circle has a diameter of 10 cm, what is its radius and area?',
      options: [
        'Radius is 10 cm, Area is 314 cm\u00b2',
        'Radius is 5 cm, Area is 78.5 cm\u00b2',
        'Radius is 5 cm, Area is 31.4 cm\u00b2',
        'Radius is 20 cm, Area is 1256 cm\u00b2',
      ],
      correctAnswerIndex: 1,
      explanation: 'The radius is half the diameter: r = d / 2 = 10 / 2 = 5 cm. Then Area A = \u03c0 * 5\u00b2 = 3.14 * 25 = 78.5 cm\u00b2.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Math rendering values
    final calculatedArea = pi * _radius * _radius;
    final calculatedCircumference = 2 * pi * _radius;

    // Audio narration texts for levels 1-5
    final List<String> audioTexts = [
      'Level 1: The area of a circle represents the size of the region enclosed inside it. It is calculated by multiplying pi with the square of the radius.',
      'Level 2: Imagine slicing a pizza into many thin triangles. If you align them up alternating, they form a rectangle. The width is half the circumference, and the height is the radius. Since area is width times height, it equals pi times radius squared.',
      'Level 3: Move the slider to see how the circle grows. As the radius increases, the area increases quadratically, which means doubling the radius multiplies the area by four.',
      'Level 4: Adjust parameters like turning on grid lines and circumference. Try to observe the relationship between the boundary length and the interior region.',
      'Level 5: Time to test your skills! Solve the math questions using the formulas we discussed.',
    ];

    return LearningScaffold(
      title: 'Geometry: Area of a Circle',
      levelAudioTexts: audioTexts,
      showPlaybackControls: false,
      level1: _buildLevel1(),
      level2: _buildLevel2(),
      level3: _buildLevel3(calculatedArea),
      level4: _buildLevel4(calculatedArea, calculatedCircumference),
      level5: _buildLevel5(),
    );
  }

  // ── Level 1: Definition ──
  Widget _buildLevel1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What is Circle Area?',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          'The Area of a circle is the total region or space enclosed inside its boundary (circumference). '
          'Unlike shapes with straight edges, a circle’s curved border makes measuring its area unique.',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              const Text(
                'The Mathematical Formula',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Math.tex(
                r'A = \pi \cdot r^2',
                textStyle: const TextStyle(color: Color(0xFF10B981), fontSize: 24),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildLegendItem(r'A', 'Area'),
                  _buildLegendItem(r'\pi', 'Pi (\u2248 3.14159)'),
                  _buildLegendItem(r'r', 'Radius'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Key Terms:',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildBulletPoint('Radius (r)', 'The distance from the center of the circle to any point on its boundary.'),
        _buildBulletPoint('Diameter (d)', 'The distance across the circle passing through the center. (d = 2r)'),
        _buildBulletPoint('Circumference (C)', 'The total length of the circle\'s boundary. (C = 2\u03c0r)'),
      ],
    );
  }

  // ── Level 2: Analogy ──
  Widget _buildLevel2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'The Pizza Analogy',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          'How did mathematicians discover that A = \u03c0r\u00b2? They used a process called "rearrangement method". '
          'Imagine slicing a pizza into 8 or more identical wedges.',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 16),
        // Slicing animation graphic
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: CustomPaint(
            size: Size.infinite,
            painter: _PizzaRearrangementPainter(),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'If we arrange these slices side-by-side alternating pointing up and down, they start to look like a parallelogram/rectangle!',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 10),
        _buildBulletPoint('Height of the rectangle', 'Equals the radius (r) of the circle.'),
        _buildBulletPoint('Base width of the rectangle', 'Equals half of the circumference (\u03c0r).'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.15)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Math.tex(
              r'\text{Area} = \text{Base} \times \text{Height} = (\pi r) \times r = \pi r^2',
              textStyle: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),

      ],
    );
  }

  // ── Level 3: Interactive Visualization ──
  Widget _buildLevel3(double area) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Interactive Scaling',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Drag the slider to change the radius and observe how the area scales.',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
        const SizedBox(height: 16),
        // Custom Painter Circle Area
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: CustomPaint(
            size: Size.infinite,
            painter: _CircleSimPainter(radius: _radius, drawGrid: false, drawCircumference: false),
          ),
        ),
        const SizedBox(height: 16),
        // Radius Slider
        Row(
          children: [
            const Text(
              'Radius (r):',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text(
              _radius.toStringAsFixed(1),
              style: const TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Slider(
                value: _radius,
                min: 1.0,
                max: 10.0,
                activeColor: const Color(0xFF10B981),
                inactiveColor: Colors.white.withOpacity(0.1),
                onChanged: (val) {
                  setState(() {
                    _radius = val;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Real-time formula values
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('FORMULA', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Math.tex(r'A = \pi \cdot r^2', textStyle: const TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
              Column(
                children: [
                  const Text('CALCULATION', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Math.tex(
                    'A \\approx 3.14 \\times ${_radius.toStringAsFixed(1)}^2',
                    textStyle: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text('RESULT', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    '${area.toStringAsFixed(2)} u\u00b2',
                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Level 4: Simulation & Common Mistakes ──
  Widget _buildLevel4(double area, double circumference) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Simulation Playroom',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Interactive visual options
        Row(
          children: [
            Expanded(
              child: _buildToggleOption(
                label: 'Show Grid',
                value: _showGrid,
                onChanged: (val) => setState(() => _showGrid = val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildToggleOption(
                label: 'Show Boundary',
                value: _showCircumference,
                onChanged: (val) => setState(() => _showCircumference = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Sim Canvas
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: CustomPaint(
            size: Size.infinite,
            painter: _CircleSimPainter(
              radius: _radius,
              drawGrid: _showGrid,
              drawCircumference: _showCircumference,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text(
              'Radius (r):',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text(
              _radius.toStringAsFixed(1),
              style: const TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Slider(
                value: _radius,
                min: 1.0,
                max: 10.0,
                activeColor: const Color(0xFF10B981),
                inactiveColor: Colors.white.withOpacity(0.1),
                onChanged: (val) => setState(() => _radius = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Math readout
        Row(
          children: [
            Expanded(
              child: _buildMetricCard('Area (Square Units)', area.toStringAsFixed(2), const Color(0xFF10B981)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard('Circumference', circumference.toStringAsFixed(2), Colors.blueAccent),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Common Mistakes Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Common Student Mistakes:',
                    style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildMistakeRow('Squaring Diameter instead of Radius', 'A circle with d=6 has r=3. Area is \u03c0*3\u00b2=9\u03c0, NOT \u03c0*6\u00b2=36\u03c0.'),
              _buildMistakeRow('Confusing Area vs. Circumference', 'Area (\u03c0r\u00b2) measures internal region. Circumference (2\u03c0r) measures border length.'),
            ],
          ),
        ),
      ],
    );
  }

  // ── Level 5: Quiz ──
  Widget _buildLevel5() {
    return const QuizView(questions: _quizQuestions);
  }

  // Helpers
  Widget _buildLegendItem(String latex, String label) {
    return Column(
      children: [
        Math.tex(latex, textStyle: const TextStyle(color: Colors.white, fontSize: 13)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
      ],
    );
  }

  Widget _buildBulletPoint(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.circle, size: 5, color: Color(0xFF10B981)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, height: 1.4),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  TextSpan(text: desc, style: TextStyle(color: Colors.white.withOpacity(0.6))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({required String label, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF10B981),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String val, Color highlight) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
          const SizedBox(height: 6),
          Text(val, style: TextStyle(color: highlight, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMistakeRow(String error, String fix) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(error, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          Text(fix, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, height: 1.4)),
        ],
      ),
    );
  }
}

// ── Custom Painters ──

class _PizzaRearrangementPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerCircle = Offset(size.width * 0.25, size.height * 0.5);
    const circleRadius = 40.0;

    final paintCircle = Paint()
      ..color = Colors.amber.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    final paintStroke = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw sliced circle on the left
    const int slices = 8;
    for (int i = 0; i < slices; i++) {
      final startAngle = i * (2 * pi / slices);
      paintCircle.color = (i % 2 == 0) ? const Color(0xFFF59E0B) : const Color(0xFFD97706);
      canvas.drawArc(
        Rect.fromCircle(center: centerCircle, radius: circleRadius),
        startAngle,
        2 * pi / slices,
        true,
        paintCircle,
      );
      canvas.drawArc(
        Rect.fromCircle(center: centerCircle, radius: circleRadius),
        startAngle,
        2 * pi / slices,
        true,
        paintStroke,
      );
    }

    // Draw text indicator
    final textPainter = TextPainter(
      text: const TextSpan(text: "Circle", style: TextStyle(color: Colors.white, fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, centerCircle - Offset(textPainter.width * 0.5, circleRadius + 18));

    // Draw connecting arrow
    final arrowPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(size.width * 0.45, size.height * 0.5), Offset(size.width * 0.55, size.height * 0.5), arrowPaint);
    // Draw arrow head
    canvas.drawLine(Offset(size.width * 0.55, size.height * 0.5), Offset(size.width * 0.52, size.height * 0.45), arrowPaint);
    canvas.drawLine(Offset(size.width * 0.55, size.height * 0.5), Offset(size.width * 0.52, size.height * 0.55), arrowPaint);

    // Draw rearranged slices on the right
    final startOffset = Offset(size.width * 0.65, size.height * 0.5 - circleRadius * 0.5);
    const sliceWidth = 12.0;

    for (int i = 0; i < slices; i++) {
      final isUp = i % 2 == 0;
      final x = startOffset.dx + (i * sliceWidth);
      final y = isUp ? startOffset.dy : startOffset.dy + circleRadius;
      
      final wedgePath = Path();
      if (isUp) {
        wedgePath.moveTo(x, y + circleRadius);
        wedgePath.lineTo(x + sliceWidth * 0.5, y);
        wedgePath.lineTo(x + sliceWidth, y + circleRadius);
        wedgePath.quadraticBezierTo(x + sliceWidth * 0.5, y + circleRadius + 4, x, y + circleRadius);
      } else {
        wedgePath.moveTo(x, y - circleRadius);
        wedgePath.lineTo(x + sliceWidth * 0.5, y);
        wedgePath.lineTo(x + sliceWidth, y - circleRadius);
        wedgePath.quadraticBezierTo(x + sliceWidth * 0.5, y - circleRadius - 4, x, y - circleRadius);
      }

      paintCircle.color = isUp ? const Color(0xFFF59E0B) : const Color(0xFFD97706);
      canvas.drawPath(wedgePath, paintCircle);
      canvas.drawPath(wedgePath, paintStroke);
    }

    final rectTextPainter = TextPainter(
      text: const TextSpan(text: "Rearranged as Parallelogram", style: TextStyle(color: Colors.white, fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    rectTextPainter.paint(canvas, Offset(startOffset.dx - 10, startOffset.dy - 20));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CircleSimPainter extends CustomPainter {
  final double radius;
  final bool drawGrid;
  final bool drawCircumference;

  _CircleSimPainter({
    required this.radius,
    required this.drawGrid,
    required this.drawCircumference,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    // Grid scaling: 1 radius unit = 6 pixels
    const scale = 6.0;
    final pixelRadius = radius * scale;

    // 1. Grid
    if (drawGrid) {
      final gridPaint = Paint()
        ..color = Colors.white.withOpacity(0.03)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      const spacing = 12.0;
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    // 2. Area Enclosed (Fills the circle)
    final areaPaint = Paint()
      ..color = const Color(0xFF10B981).withOpacity(0.12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, pixelRadius, areaPaint);

    // 3. Circumference Border
    final borderPaint = Paint()
      ..color = drawCircumference ? const Color(0xFF10B981) : Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = drawCircumference ? 2.5 : 1.2;
    canvas.drawCircle(center, pixelRadius, borderPaint);

    // 4. Center dot
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 3.0, dotPaint);

    // 5. Radius line (horizontal)
    final linePaint = Paint()
      ..color = Colors.amber
      ..strokeWidth = 2.0;
    canvas.drawLine(center, Offset(center.dx + pixelRadius, center.dy), linePaint);

    // 6. Label markers
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'r = ${radius.toStringAsFixed(1)}',
        style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx + (pixelRadius * 0.5) - (textPainter.width * 0.5), center.dy - 16),
    );
  }

  @override
  bool shouldRepaint(covariant _CircleSimPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.drawGrid != drawGrid ||
        oldDelegate.drawCircumference != drawCircumference;
  }
}
