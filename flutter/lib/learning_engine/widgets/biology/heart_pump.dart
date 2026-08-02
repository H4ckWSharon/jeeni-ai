import 'package:flutter/material.dart';
import '../common/learning_scaffold.dart';
import '../common/quiz_view.dart';

class HeartPumpWidget extends StatefulWidget {
  const HeartPumpWidget({super.key});

  @override
  State<HeartPumpWidget> createState() => _HeartPumpWidgetState();
}

class _HeartPumpWidgetState extends State<HeartPumpWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _bpm = 72;

  static const List<QuizQuestion> _quizQuestions = [
    QuizQuestion(
      questionText: 'Which chamber of the heart pumps oxygenated blood out to the rest of the body?',
      options: ['Right Atrium', 'Left Atrium', 'Right Ventricle', 'Left Ventricle'],
      correctAnswerIndex: 3,
      explanation: 'The Left Ventricle has thick muscular walls to pump oxygenated blood through the aorta to the body.',
    ),
    QuizQuestion(
      questionText: 'What is the function of the heart valves?',
      options: [
        'To speed up heart rate',
        'To prevent the backflow of blood',
        'To filter impurities from blood',
        'To generate heart electrical impulses',
      ],
      correctAnswerIndex: 1,
      explanation: 'Heart valves act as one-way gates, opening and closing to ensure blood flows only in one direction.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 833), // default 72 bpm
    )..repeat(reverse: true);
  }

  void _updateBpm(int newBpm) {
    setState(() {
      _bpm = newBpm;
      // Duration in ms = (60 / bpm) * 1000
      final durationMs = ((60 / _bpm) * 1000).round();
      _pulseController.duration = Duration(milliseconds: durationMs);
      if (_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> audioTexts = [
      'Level 1: The heart is a muscular organ that pumps blood throughout the body. It consists of four chambers, left and right atria, and left and right ventricles.',
      'Level 2: Think of a water pump. As you squeeze the pump bulb, water is forced out. The valves prevent water from slipping back down. The heart works the same way.',
      'Level 3: Look at the visual heart canvas. Adjust the beats per minute slider. Watch how the chambers expand and contract to circulate blood.',
      'Level 4: Play with different heart rates. Observe how a faster rate reduces the relaxation time between chamber contractions.',
      'Level 5: Take the quick biology practice quiz on heart chambers and valves.',
    ];

    return LearningScaffold(
      title: 'Biology: Human Heart Pump',
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
        const Text('The Cardiac Chambers', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(
          'The human heart contains 4 chambers divided into left and right sides. '
          'Atria receive incoming blood; Ventricles pump outgoing blood.',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 16),
        _buildChamberPoint('Right Atrium & Ventricle', 'Collect deoxygenated blood from the body and pump it to the lungs.'),
        _buildChamberPoint('Left Atrium & Ventricle', 'Collect oxygenated blood from the lungs and pump it out to the body.'),
      ],
    );
  }

  Widget _buildLevel2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('The One-Way Gate Analogy', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(
          'Imagine a busy subway exit with turnstiles. People can pass in only one direction. '
          'Heart valves act as biological turnstiles: they open to let blood pass forward and snap shut to block backward leakage.',
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
            animation: _pulseController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _HeartPainter(pulseScale: _pulseController.value),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Heart Rate (BPM): ', style: TextStyle(color: Colors.white, fontSize: 12)),
            Text('$_bpm', style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 13)),
            Expanded(
              child: Slider(
                value: _bpm.toDouble(),
                min: 40.0,
                max: 180.0,
                activeColor: const Color(0xFFEF4444),
                onChanged: (val) => _updateBpm(val.round()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLevel4() {
    final double cycleSec = 60 / _bpm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cardiac Dynamics', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildMetricRow('Heart Beats Per Minute', '$_bpm bpm'),
        _buildMetricRow('Single Beat Cycle Time', '${cycleSec.toStringAsFixed(2)} seconds'),
        _buildMetricRow('Systole (Squeezing)', '0.3 seconds'),
        _buildMetricRow('Diastole (Relaxation)', '${(cycleSec - 0.3).toStringAsFixed(2)} seconds'),
      ],
    );
  }

  Widget _buildChamberPoint(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, height: 1.4)),
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

class _HeartPainter extends CustomPainter {
  final double pulseScale;
  _HeartPainter({required this.pulseScale});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    const baseRadius = 35.0;
    // Scale goes from 1.0 to 1.15
    final activeRadius = baseRadius + (pulseScale * 5.0);

    final heartPaint = Paint()
      ..color = const Color(0xFFEF4444).withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw left and right ventricles as overlapping blobs
    canvas.drawCircle(Offset(center.dx - 15, center.dy), activeRadius, heartPaint);
    canvas.drawCircle(Offset(center.dx - 15, center.dy), activeRadius, borderPaint);
    
    canvas.drawCircle(Offset(center.dx + 15, center.dy), activeRadius, heartPaint);
    canvas.drawCircle(Offset(center.dx + 15, center.dy), activeRadius, borderPaint);

    // Draw Atrium circles on top
    final atriumPaint = Paint()
      ..color = const Color(0xFFDC2626).withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(center.dx - 18, center.dy - 30), activeRadius * 0.7, atriumPaint);
    canvas.drawCircle(Offset(center.dx + 18, center.dy - 30), activeRadius * 0.7, atriumPaint);

    // Valves indicator lines
    final valvePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0;
    
    // Left valve
    canvas.drawLine(Offset(center.dx - 22, center.dy - 10), Offset(center.dx - 10, center.dy - 5), valvePaint);
    // Right valve
    canvas.drawLine(Offset(center.dx + 22, center.dy - 10), Offset(center.dx + 10, center.dy - 5), valvePaint);
  }

  @override
  bool shouldRepaint(covariant _HeartPainter oldDelegate) {
    return oldDelegate.pulseScale != pulseScale;
  }
}
