import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:fl_chart/fl_chart.dart';
import '../common/learning_scaffold.dart';
import '../common/quiz_view.dart';

class NewtonSecondLawWidget extends StatefulWidget {
  const NewtonSecondLawWidget({super.key});

  @override
  State<NewtonSecondLawWidget> createState() => _NewtonSecondLawWidgetState();
}

class _NewtonSecondLawWidgetState extends State<NewtonSecondLawWidget> with SingleTickerProviderStateMixin {
  // Simulator State
  double _force = 40.0; // N
  double _mass = 5.0;  // kg
  
  // Animation state
  late AnimationController _animController;
  double _elapsedTime = 0.0; // seconds
  bool _isPlaying = false;
  
  // Data points for the chart plotting velocity vs time
  final List<FlSpot> _velocityPoints = [const FlSpot(0, 0)];

  // Quiz questions
  static const List<QuizQuestion> _quizQuestions = [
    QuizQuestion(
      questionText: 'According to Newton\'s Second Law, if you double the force applied to an object while keeping its mass constant, what happens to its acceleration?',
      options: [
        'Acceleration is halved',
        'Acceleration remains the same',
        'Acceleration is doubled',
        'Acceleration is quadrupled',
      ],
      correctAnswerIndex: 2,
      explanation: 'Newton\'s Second Law is F = ma, which means a = F / m. If F doubles and m is constant, acceleration (a) must double.',
    ),
    QuizQuestion(
      questionText: 'An object of mass 10 kg is accelerating at 3 m/s\u00b2. What is the net force acting on the object?',
      options: [
        '30 N',
        '3.3 N',
        '0.3 N',
        '13 N',
      ],
      correctAnswerIndex: 0,
      explanation: 'Using F = ma, F = 10 kg * 3 m/s\u00b2 = 30 N.',
    ),
    QuizQuestion(
      questionText: 'You push a heavy box of mass 20 kg with a force of 100 N. If there is a friction force of 20 N opposing the movement, what is the net acceleration?',
      options: [
        '5 m/s\u00b2',
        '6 m/s\u00b2',
        '4 m/s\u00b2',
        '1.2 m/s\u00b2',
      ],
      correctAnswerIndex: 2,
      explanation: 'First, find the net force: F_net = Applied Force - Friction = 100 N - 20 N = 80 N. Next, use a = F_net / m = 80 N / 20 kg = 4 m/s\u00b2.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Simulate over 3.0 seconds
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _animController.addListener(_onSimulationTick);
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  void _onSimulationTick() {
    if (!mounted) return;
    final progress = _animController.value;
    const totalDuration = 3.0; // seconds
    final acceleration = _force / _mass;
    
    setState(() {
      _elapsedTime = progress * totalDuration;
      final currentVelocity = acceleration * _elapsedTime;
      
      // Update chart points — cap at 100 to prevent unbounded memory growth
      if (_animController.isAnimating) {
        if (_velocityPoints.length >= 100) {
          _velocityPoints.removeAt(0);
        }
        _velocityPoints.add(FlSpot(_elapsedTime, currentVelocity));
      }
    });
  }


  void _runSimulation() {
    _resetSimulation();
    setState(() {
      _isPlaying = true;
    });
    _animController.forward();
  }

  void _pauseSimulation() {
    setState(() {
      _isPlaying = false;
    });
    _animController.stop();
  }

  void _stepForward() {
    if (_animController.value < 1.0) {
      _animController.value = min(1.0, _animController.value + 0.05);
    }
  }

  void _stepBackward() {
    if (_animController.value > 0.0) {
      _animController.value = max(0.0, _animController.value - 0.05);
      // Recalculate chart points
      _recalculateChartPoints();
    }
  }

  void _recalculateChartPoints() {
    final progress = _animController.value;
    const totalDuration = 3.0;
    final acceleration = _force / _mass;
    _velocityPoints.clear();
    _velocityPoints.add(const FlSpot(0, 0));
    
    final steps = (progress * 20).round();
    for (int i = 1; i <= steps; i++) {
      final t = (i / 20) * totalDuration;
      final v = acceleration * t;
      _velocityPoints.add(FlSpot(t, v));
    }
  }

  void _resetSimulation() {
    _animController.reset();
    setState(() {
      _elapsedTime = 0.0;
      _isPlaying = false;
      _velocityPoints.clear();
      _velocityPoints.add(const FlSpot(0, 0));
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final acceleration = _force / _mass;
    final velocity = acceleration * _elapsedTime;
    final distance = 0.5 * acceleration * _elapsedTime * _elapsedTime;

    // Audio narration texts for levels 1-5
    final List<String> audioTexts = [
      'Level 1: Newton\'s second law states that the acceleration of an object depends on the net force acting upon the object and the mass of the object. Force equals mass times acceleration.',
      'Level 2: Imagine pushing a light empty shopping cart versus pushing a heavy car. The empty cart accelerates quickly because its mass is small. The car accelerates slowly because its mass is large.',
      'Level 3: Look at the velocity graph. Notice that under a constant force, the velocity increases at a constant straight slope. This slope represents the acceleration.',
      'Level 4: Adjust the Force and Mass sliders, and tap Play. Watch how the block slides along the track and note how its acceleration vectors and displacement update live.',
      'Level 5: Test your knowledge of forces, mass, and acceleration with a series of practice questions.',
    ];

    return LearningScaffold(
      title: 'Physics: Newton\'s 2nd Law (F = ma)',
      levelAudioTexts: audioTexts,
      showPlaybackControls: true,
      isPlaying: _isPlaying,
      onPlay: _runSimulation,
      onPause: _pauseSimulation,
      onReset: _resetSimulation,
      onStepForward: _stepForward,
      onStepBackward: _stepBackward,
      level1: _buildLevel1(),
      level2: _buildLevel2(),
      level3: _buildLevel3(acceleration),
      level4: _buildLevel4(acceleration, velocity, distance),
      level5: _buildLevel5(),
    );
  }

  // ── Level 1: Definition ──
  Widget _buildLevel1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Newton\'s Second Law',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          'Newton’s Second Law of Motion describes how the velocity of an object changes when it is subjected to an external force. '
          'It tells us that acceleration is directly proportional to force and inversely proportional to mass.',
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
                r'F = m \cdot a',
                textStyle: const TextStyle(color: Color(0xFF10B981), fontSize: 24),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildLegendItem(r'F', 'Force (Newtons, N)'),
                  _buildLegendItem(r'm', 'Mass (Kilograms, kg)'),
                  _buildLegendItem(r'a', 'Acceleration (m/s²)'),
                ],
              ),

            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Core Concept Summary:',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildBulletPoint('More Force = More Acceleration', 'If you push an object harder, it speeds up faster.'),
        _buildBulletPoint('More Mass = Less Acceleration', 'Heavy objects are harder to speed up than lighter ones.'),
      ],
    );
  }

  // ── Level 2: Analogy ──
  Widget _buildLevel2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'The Shopping Cart Analogy',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          'Think about pushing a shopping cart at the grocery store:',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 16),
        _buildAnalogyRow(
          icon: Icons.shopping_cart_outlined,
          title: 'Empty Cart (Low Mass)',
          desc: 'When the cart is empty, you only need a small push (Force) to make it move fast (High Acceleration).',
          color: const Color(0xFF10B981),
        ),
        const SizedBox(height: 12),
        _buildAnalogyRow(
          icon: Icons.local_shipping_outlined,
          title: 'Loaded Cart (High Mass)',
          desc: 'Fill the cart with heavy groceries. Now, pushing with the exact same effort (Force) results in sluggish movement (Low Acceleration).',
          color: const Color(0xFFEF4444),
        ),
        const SizedBox(height: 16),
        Text(
          'This demonstrates the inverse relationship between mass and acceleration. When mass is higher, acceleration is lower for a given force.',
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.4),
        ),
      ],
    );
  }

  // ── Level 3: Graphing ──
  Widget _buildLevel3(double acceleration) {
    // Determine maximum values for chart axes
    const maxTime = 3.0;
    const maxVelocity = (100.0 / 1.0) * maxTime; // max possible velocity in sim context

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Velocity-Time Graph',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Under constant net force, velocity rises in a straight line. The slope equals acceleration (${acceleration.toStringAsFixed(1)} m/s\u00b2).',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
        const SizedBox(height: 16),
        // Line Chart
        Container(
          height: 160,
          padding: const EdgeInsets.only(right: 16, top: 12, bottom: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                getDrawingHorizontalLine: (val) => FlLine(color: Colors.white.withOpacity(0.03), strokeWidth: 1),
                getDrawingVerticalLine: (val) => FlLine(color: Colors.white.withOpacity(0.03), strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  axisNameWidget: const Text('Time (s)', style: TextStyle(color: Colors.grey, fontSize: 10)),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 1.0,
                    getTitlesWidget: (val, meta) => Text(
                      val.toStringAsFixed(0),
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9),
                    ),
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: const Text('Velocity (m/s)', style: TextStyle(color: Colors.grey, fontSize: 10)),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (val, meta) => Text(
                      val.toStringAsFixed(0),
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9),
                    ),
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: maxTime,
              minY: 0,
              maxY: max(10, acceleration * maxTime),
              lineBarsData: [
                LineChartBarData(
                  spots: _velocityPoints,
                  isCurved: false,
                  color: const Color(0xFF10B981),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF10B981).withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Run trigger remind
        Text(
          'Tip: Go to Level 4 (Simulation), adjust sliders, and tap Play to see the graph animate!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.amber.withOpacity(0.8), fontSize: 11, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  // ── Level 4: Simulator ──
  Widget _buildLevel4(double acceleration, double velocity, double distance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Interactive Sandbox',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Sim Canvas
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: ClipRect(
            child: CustomPaint(
              size: Size.infinite,
              painter: _NewtonSimPainter(
                force: _force,
                mass: _mass,
                distance: distance,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Sliders
        Row(
          children: [
            const SizedBox(
              width: 70,
              child: Text('Force (F):', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            Text('${_force.toStringAsFixed(0)} N', style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
            Expanded(
              child: Slider(
                value: _force,
                min: 5.0,
                max: 100.0,
                activeColor: const Color(0xFF10B981),
                inactiveColor: Colors.white.withOpacity(0.1),
                onChanged: (val) {
                  setState(() {
                    _force = val;
                    if (!_isPlaying) _recalculateChartPoints();
                  });
                },
              ),
            ),
          ],
        ),
        Row(
          children: [
            const SizedBox(
              width: 70,
              child: Text('Mass (m):', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            Text('${_mass.toStringAsFixed(1)} kg', style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
            Expanded(
              child: Slider(
                value: _mass,
                min: 1.0,
                max: 20.0,
                activeColor: const Color(0xFF10B981),
                inactiveColor: Colors.white.withOpacity(0.1),
                onChanged: (val) {
                  setState(() {
                    _mass = val;
                    if (!_isPlaying) _recalculateChartPoints();
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Telemetry readout
        Row(
          children: [
            Expanded(child: _buildTelemetryItem('Acceleration (a = F/m)', '${acceleration.toStringAsFixed(2)} m/s\u00b2', const Color(0xFF10B981))),
            const SizedBox(width: 8),
            Expanded(child: _buildTelemetryItem('Velocity (v = a*t)', '${velocity.toStringAsFixed(1)} m/s', Colors.amber)),
            const SizedBox(width: 8),
            Expanded(child: _buildTelemetryItem('Distance (d = \u00bd*a*t\u00b2)', '${distance.toStringAsFixed(1)} m', Colors.blueAccent)),
          ],
        ),
        const SizedBox(height: 12),
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
              const SizedBox(height: 6),
              _buildMistakeRow('Thinking Mass and Acceleration are directly proportional', 'Double mass leads to HALF acceleration, not double. (a = F/m)'),
              _buildMistakeRow('Ignoring friction in calculations', 'In the real world, net force equals applied force minus friction.'),
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

  // Helper widgets
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

  Widget _buildAnalogyRow({required IconData icon, required String title, required String desc, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryItem(String title, String val, Color highlight) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9)),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(color: highlight, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMistakeRow(String error, String fix) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(error, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          Text(fix, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, height: 1.4)),
        ],
      ),
    );
  }
}

// ── Newton Simulator Painter ──

class _NewtonSimPainter extends CustomPainter {
  final double force;
  final double mass;
  final double distance;

  _NewtonSimPainter({
    required this.force,
    required this.mass,
    required this.distance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackY = size.height * 0.7;
    
    // Draw Ground Track
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(0, trackY), Offset(size.width, trackY), trackPaint);

    // Track hash lines
    final hashPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, trackY), Offset(x - 5, trackY + 8), hashPaint);
    }

    // Block dimensions based on mass
    // Mass goes 1.0 to 20.0 -> map to size 30 to 60 pixels
    final blockSize = 30.0 + (mass - 1.0) * (30.0 / 19.0);
    
    // Compute animated position
    // Map distance (which grows quad) to loop across the track screen
    const scaleDistance = 6.0; // scale meters to pixels
    final rawX = distance * scaleDistance;
    final blockX = (rawX % (size.width - blockSize - 40)) + 20.0;
    final blockY = trackY - blockSize;

    // Draw Block
    final blockPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    final blockBorder = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    final blockRect = Rect.fromLTWH(blockX, blockY, blockSize, blockSize);
    canvas.drawRect(blockRect, blockPaint);
    canvas.drawRect(blockRect, blockBorder);

    // Draw mass label inside block
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${mass.toStringAsFixed(0)} kg',
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        blockX + (blockSize - textPainter.width) * 0.5,
        blockY + (blockSize - textPainter.height) * 0.5,
      ),
    );

    // Draw Force Vector Arrow pushing the block from left
    // Force goes 5 to 100 -> map arrow length to 20 to 60 pixels
    final arrowLength = 20.0 + (force - 5.0) * (40.0 / 95.0);
    final arrowStartX = blockX - arrowLength - 5.0;
    final arrowY = blockY + blockSize * 0.5;

    final arrowPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    
    // Draw shaft
    canvas.drawLine(Offset(arrowStartX, arrowY), Offset(blockX - 5.0, arrowY), arrowPaint);
    // Draw arrowhead pointing right
    const headSize = 6.0;
    final path = Path()
      ..moveTo(blockX - 5.0, arrowY)
      ..lineTo(blockX - 5.0 - headSize, arrowY - headSize * 0.7)
      ..lineTo(blockX - 5.0 - headSize, arrowY + headSize * 0.7)
      ..close();
    
    final headPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, headPaint);

    // Draw Force Label above arrow
    final forcePainter = TextPainter(
      text: TextSpan(
        text: '${force.toStringAsFixed(0)} N',
        style: const TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    forcePainter.paint(
      canvas,
      Offset(arrowStartX + (arrowLength - forcePainter.width) * 0.5, arrowY - 14),
    );
  }

  @override
  bool shouldRepaint(covariant _NewtonSimPainter oldDelegate) {
    return oldDelegate.force != force ||
        oldDelegate.mass != mass ||
        oldDelegate.distance != distance;
  }
}
