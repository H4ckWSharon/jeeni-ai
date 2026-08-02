import 'dart:math';
import 'package:flutter/material.dart';
import '../common/learning_scaffold.dart';
import '../common/quiz_view.dart';

class EarthRotationWidget extends StatefulWidget {
  const EarthRotationWidget({super.key});

  @override
  State<EarthRotationWidget> createState() => _EarthRotationWidgetState();
}

class _EarthRotationWidgetState extends State<EarthRotationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  double _tiltAngle = 23.5; // degrees

  static const List<QuizQuestion> _quizQuestions = [
    QuizQuestion(
      questionText: 'What is the primary cause of seasons on Earth?',
      options: [
        'The changing distance between Earth and the Sun',
        'The tilt of the Earth\'s axis as it orbits the Sun',
        'The speed of the Earth\'s rotation',
        'Solar flares and sunspots',
      ],
      correctAnswerIndex: 1,
      explanation: 'The 23.5-degree axial tilt means different hemispheres receive varying amounts of direct sunlight during our year-long orbit.',
    ),
    QuizQuestion(
      questionText: 'How long does it take for Earth to complete one full rotation on its axis?',
      options: ['12 hours', '24 hours', '365 days', '28 days'],
      correctAnswerIndex: 1,
      explanation: 'One complete axial rotation takes approximately 24 hours, giving us our day and night cycle.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> audioTexts = [
      'Level 1: Earth rotates on its axis from west to east once every twenty-four hours, creating the day and night cycle.',
      'Level 2: Imagine a spinning top. The top does not stand perfectly straight; it tilts slightly. Earth behaves the same, tilting at twenty-three point five degrees.',
      'Level 3: Look at the visual solar canvas. Drag the tilt slider to adjust the axial angle, and watch how it alters daylight distribution.',
      'Level 4: Play with the controls. Observe how a tilt of zero degrees results in equal day and night durations across all latitudes.',
      'Level 5: Take the geography quiz to check your understanding of rotations and tilts.',
    ];

    return LearningScaffold(
      title: 'Geography: Earth Rotation & Tilt',
      levelAudioTexts: audioTexts,
      level1: _buildLevel1(),
      level2: _buildLevel2(),
      level3: _buildLevel3(),
      level4: _buildLevel4(),
      level5: const QuizView(questions: _quizQuestions),
    );
  }

  Widget _buildLevel1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Axial Rotation', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(
          'Earth rotates on its central axis, which connects the North and South poles. '
          'This movement explains the daylight cycles, temperature fluctuations, and Coriolis effects.',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 16),
        _buildDetailRow('Period', '24 hours (1 Solar Day)'),
        _buildDetailRow('Direction', 'West to East (Prograde)'),
        _buildDetailRow('Axial Tilt', '23.5 degrees relative to the orbital plane'),
      ],
    );
  }

  Widget _buildLevel2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('The Spinning Globe Analogy', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(
          'Imagine standing in front of a campfire on a cold night. When you turn your back, your front cools down, and your back warms up. '
          'Earth does this continuously. The side facing the Sun heats up (Day), while the side facing away cools down (Night).',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildLevel3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 150,
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _SpacePainter(
                  rotationProgress: _rotationController.value,
                  tiltAngle: _tiltAngle,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Axial Tilt: ', style: TextStyle(color: Colors.white, fontSize: 12)),
            Text('${_tiltAngle.toStringAsFixed(1)}\u00b2', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
            Expanded(
              child: Slider(
                value: _tiltAngle,
                min: 0.0,
                max: 45.0,
                activeColor: Colors.amber,
                onChanged: (val) => setState(() => _tiltAngle = val),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLevel4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tilt Impact Details', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildDetailRow('Current Selected Tilt', '${_tiltAngle.toStringAsFixed(1)}\u00b2'),
        _buildDetailRow('Northern Equinox Condition', 'Both hemispheres receive equal light.'),
        _buildDetailRow('Solstice Extremes', 'Hemisphere tilted towards the Sun experiences long days and summer.'),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SpacePainter extends CustomPainter {
  final double rotationProgress;
  final double tiltAngle;

  _SpacePainter({
    required this.rotationProgress,
    required this.tiltAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.55, size.height * 0.5);
    const earthRadius = 30.0;

    // 1. Draw Sun on the far left
    final sunCenter = Offset(size.width * 0.1, size.height * 0.5);
    final sunPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;
    canvas.drawCircle(sunCenter, 18.0, sunPaint);

    // Draw light rays
    final rayPaint = Paint()
      ..color = Colors.amber.withOpacity(0.3)
      ..strokeWidth = 1.5;
    canvas.drawLine(sunCenter, center, rayPaint);

    // 2. Draw Earth
    final tiltRad = tiltAngle * pi / 180.0;
    
    // Draw day hemisphere (facing Sun)
    final dayPaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.fill;
    
    // Draw night hemisphere (shadow side)
    final nightPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    // Simple halves division
    canvas.drawCircle(center, earthRadius, nightPaint);
    
    // Day clip
    final dayPath = Path()
      ..addArc(Rect.fromCircle(center: center, radius: earthRadius), pi / 2, pi);
    canvas.drawPath(dayPath, dayPaint);

    // 3. Draw Axis line
    const axisLength = 40.0;
    final axisPaint = Paint()
      ..color = Colors.amber
      ..strokeWidth = 1.5;
    
    final axisDx = axisLength * sin(tiltRad);
    final axisDy = axisLength * cos(tiltRad);
    
    canvas.drawLine(
      Offset(center.dx - axisDx, center.dy - axisDy),
      Offset(center.dx + axisDx, center.dy + axisDy),
      axisPaint,
    );

    // 4. Draw continents (simple rotating dots on globe)
    final continentPaint = Paint()
      ..color = Colors.green.withOpacity(0.6)
      ..strokeWidth = 2.0;
    
    final rotationAngle = rotationProgress * 2 * pi;
    for (int i = 0; i < 3; i++) {
      final latOffset = -10.0 + (i * 10.0);
      final cAngle = rotationAngle + (i * (pi / 3));
      final cx = center.dx + earthRadius * 0.6 * cos(cAngle) * cos(tiltRad);
      final cy = center.dy + latOffset + earthRadius * 0.3 * cos(cAngle) * sin(tiltRad);
      
      if (cos(cAngle) > 0) {
        canvas.drawCircle(Offset(cx, cy), 3.0, continentPaint);
      }
    }

    // 5. Draw text labels for Sun, Day, Night
    void drawLabel(String text, Offset position, Color color) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(position.dx - tp.width / 2, position.dy - tp.height / 2));
    }

    drawLabel('☀ SUN', Offset(sunCenter.dx, sunCenter.dy + 24), Colors.amber);
    drawLabel('DAY', Offset(center.dx - earthRadius * 0.5, center.dy), Colors.blueAccent);
    drawLabel('NIGHT', Offset(center.dx + earthRadius * 0.6, center.dy), const Color(0xFF94A3B8));
  }


  @override
  bool shouldRepaint(covariant _SpacePainter oldDelegate) {
    return oldDelegate.rotationProgress != rotationProgress ||
        oldDelegate.tiltAngle != tiltAngle;
  }
}
