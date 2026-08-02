import 'dart:math';
import 'package:flutter/material.dart';
import '../common/learning_scaffold.dart';
import '../common/quiz_view.dart';

class AtomBuilderWidget extends StatefulWidget {
  const AtomBuilderWidget({super.key});

  @override
  State<AtomBuilderWidget> createState() => _AtomBuilderWidgetState();
}

class _AtomBuilderWidgetState extends State<AtomBuilderWidget> with SingleTickerProviderStateMixin {
  int _protons = 1;
  int _neutrons = 0;
  int _electrons = 1;

  late AnimationController _orbitsController;

  static const List<QuizQuestion> _quizQuestions = [
    QuizQuestion(
      questionText: 'What element is formed when an atom has 2 Protons, 2 Neutrons, and 2 Electrons?',
      options: ['Hydrogen', 'Helium', 'Lithium', 'Beryllium'],
      correctAnswerIndex: 1,
      explanation: 'An atom with 2 protons represents Helium (atomic number 2).',
    ),
    QuizQuestion(
      questionText: 'Which particle determines the identity of an element (atomic number)?',
      options: ['Neutrons', 'Protons', 'Electrons', 'Photons'],
      correctAnswerIndex: 1,
      explanation: 'The number of protons in the nucleus uniquely defines the chemical identity of the element.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _orbitsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _orbitsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> audioTexts = [
      'Level 1: Atoms are the basic building blocks of matter. They consist of protons, neutrons, and electrons.',
      'Level 2: Imagine a tiny solar system. The central sun is the nucleus, made of protons and neutrons. The tiny orbiting planets are electrons.',
      'Level 3: Look at the visual atom canvas. Adjust the sliders to change particle counts and watch the nucleus expand and electrons orbit.',
      'Level 4: Play with different particle balances. Try to make a stable Helium atom by selecting two protons, two neutrons, and two electrons.',
      'Level 5: Solve the chemistry questions to prove your mastery over atomic particles.',
    ];

    return LearningScaffold(
      title: 'Chemistry: Dynamic Atom Builder',
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
        const Text('Atomic Structures', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(
          'Atoms contain a dense central core called the Nucleus containing Protons and Neutrons, surrounded by a cloud of orbiting Electrons.',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 12),
        _buildParticleBadge('Protons', 'Positive Charge (+1). Found in the nucleus.', const Color(0xFFEF4444)),
        _buildParticleBadge('Neutrons', 'Neutral Charge (0). Found in the nucleus.', Colors.grey),
        _buildParticleBadge('Electrons', 'Negative Charge (-1). Orbiting the nucleus.', Colors.blueAccent),
      ],
    );
  }

  Widget _buildLevel2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('The Solar System Analogy', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(
          'Just as the sun holds the planets in orbit through gravity, the positively-charged nucleus holds the negatively-charged electrons in orbit via electrostatic force.',
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
            animation: _orbitsController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _AtomPainter(
                  protons: _protons,
                  neutrons: _neutrons,
                  electrons: _electrons,
                  orbitProgress: _orbitsController.value,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildSlider('Protons (P): ', _protons.toDouble(), 1.0, 6.0, (val) => setState(() => _protons = val.round()), const Color(0xFFEF4444)),
        _buildSlider('Neutrons (N): ', _neutrons.toDouble(), 0.0, 6.0, (val) => setState(() => _neutrons = val.round()), Colors.grey),
        _buildSlider('Electrons (e): ', _electrons.toDouble(), 0.0, 6.0, (val) => setState(() => _electrons = val.round()), Colors.blueAccent),
      ],
    );
  }

  Widget _buildLevel4() {
    final elementName = _getElementName(_protons);
    final isNeutral = _protons == _electrons;
    final netCharge = _protons - _electrons;
    final massNumber = _protons + _neutrons;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Atomic Status: $elementName', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildMetricRow('Element Name', elementName),
        _buildMetricRow('Mass Number (Protons + Neutrons)', '$massNumber'),
        _buildMetricRow('Net Charge', '${netCharge > 0 ? "+" : ""}$netCharge (${isNeutral ? "Neutral Atom" : "Ion"})'),
      ],
    );
  }

  Widget _buildParticleBadge(String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  TextSpan(text: desc, style: TextStyle(color: Colors.white.withOpacity(0.5))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double val, double minVal, double maxVal, ValueChanged<double> onChanged, Color color) {
    return Row(
      children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11))),
        Text('${val.round()}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        Expanded(
          child: Slider(
            value: val,
            min: minVal,
            max: maxVal,
            activeColor: color,
            onChanged: onChanged,
          ),
        ),
      ],
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

  String _getElementName(int protons) {
    switch (protons) {
      case 1:
        return 'Hydrogen (H)';
      case 2:
        return 'Helium (He)';
      case 3:
        return 'Lithium (Li)';
      case 4:
        return 'Beryllium (Be)';
      case 5:
        return 'Boron (B)';
      case 6:
        return 'Carbon (C)';
      default:
        return 'Unknown';
    }
  }
}

class _AtomPainter extends CustomPainter {
  final int protons;
  final int neutrons;
  final int electrons;
  final double orbitProgress;

  _AtomPainter({
    required this.protons,
    required this.neutrons,
    required this.electrons,
    required this.orbitProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);

    // Orbit Ring paints
    final orbitPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Draw orbits
    const double baseRadius = 40.0;
    canvas.drawCircle(center, baseRadius, orbitPaint);
    canvas.drawCircle(center, baseRadius * 1.5, orbitPaint);

    // Draw Nucleus
    final random = Random(42);
    final totalNucleons = protons + neutrons;
    for (int i = 0; i < totalNucleons; i++) {
      final isProton = i < protons;
      // random dispersion inside nucleus boundary
      final dist = random.nextDouble() * 12.0;
      final angle = random.nextDouble() * 2 * pi;
      final particleCenter = Offset(
        center.dx + dist * cos(angle),
        center.dy + dist * sin(angle),
      );

      final particlePaint = Paint()
        ..color = isProton ? const Color(0xFFEF4444) : Colors.grey
        ..style = PaintingStyle.fill;
      canvas.drawCircle(particleCenter, 4.0, particlePaint);
    }

    // Draw Electrons orbiting
    final electronPaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < electrons; i++) {
      final isOuterShell = i >= 2;
      final shellRadius = isOuterShell ? baseRadius * 1.5 : baseRadius;
      final angleOffset = (i * (2 * pi / max(1, electrons))) + (orbitProgress * 2 * pi);
      
      final eOffset = Offset(
        center.dx + shellRadius * cos(angleOffset),
        center.dy + shellRadius * sin(angleOffset),
      );
      canvas.drawCircle(eOffset, 3.0, electronPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AtomPainter oldDelegate) {
    return oldDelegate.protons != protons ||
        oldDelegate.neutrons != neutrons ||
        oldDelegate.electrons != electrons ||
        oldDelegate.orbitProgress != orbitProgress;
  }
}
