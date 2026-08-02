import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:fl_chart/fl_chart.dart';
import '../common/learning_scaffold.dart';
import '../common/quiz_view.dart';

class GraphPlotterWidget extends StatefulWidget {
  const GraphPlotterWidget({super.key});

  @override
  State<GraphPlotterWidget> createState() => _GraphPlotterWidgetState();
}

class _GraphPlotterWidgetState extends State<GraphPlotterWidget> {
  double _slope = 1.0;     // m in y = mx + c
  double _intercept = 0.0; // c in y = mx + c

  static const List<QuizQuestion> _quizQuestions = [
    QuizQuestion(
      questionText: 'What is the y-intercept of the equation y = 3x - 5?',
      options: ['3', '-5', '5', '0'],
      correctAnswerIndex: 1,
      explanation: 'The equation is in y = mx + c form, where c is the y-intercept. Here, c = -5.',
    ),
    QuizQuestion(
      questionText: 'If the slope (m) of a line is negative, what happens as x increases?',
      options: [
        'y increases',
        'y decreases',
        'y remains constant',
        'y goes to infinity vertically',
      ],
      correctAnswerIndex: 1,
      explanation: 'A negative slope means the line goes downwards from left to right. As x increases, y decreases.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Generate data points for y = mx + c from x = -5 to x = 5
    final List<FlSpot> points = [];
    for (double x = -5; x <= 5; x += 0.5) {
      points.add(FlSpot(x, _slope * x + _intercept));
    }

    final List<String> audioTexts = [
      'Level 1: An algebraic graph plotter maps mathematical equations on a 2D grid. The equation of a straight line is y equals m x plus c, where m is the slope and c is the y intercept.',
      'Level 2: Imagine climbing a hill. The slope m represents the steepness. The intercept c represents the height you start at on the vertical line.',
      'Level 3: Look at the line graph. Drag the sliders to change slope and intercept values and note how the line tilt and crossing points update live.',
      'Level 4: Play with the controls to explore slopes of zero or negative trends. Observe the calculations at different inputs.',
      'Level 5: Take the quick algebra quiz to test your straight line graphing skills.',
    ];

    return LearningScaffold(
      title: 'Algebra: Linear Equation Grapher',
      levelAudioTexts: audioTexts,
      level1: _buildLevel1(),
      level2: _buildLevel2(),
      level3: _buildLevel3(points),
      level4: _buildLevel4(points),
      level5: const QuizView(questions: _quizQuestions),
    );
  }

  Widget _buildLevel1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Linear Equations', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(
          'A linear equation represents a straight line. Every point on the line satisfies the equation.',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Math.tex(r'y = m \cdot x + c', textStyle: const TextStyle(color: Color(0xFF10B981), fontSize: 24)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildLegendItem(r'm', 'Slope (Tilt)'),
                  _buildLegendItem(r'c', 'y-intercept (Start height)'),
                ],
              ),

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
        const Text('Visual Analogy: Slope', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildAnalogyBox('Positive Slope (m > 0)', 'Climbing uphill from left to right.', const Color(0xFF10B981)),
        const SizedBox(height: 8),
        _buildAnalogyBox('Negative Slope (m < 0)', 'Descending downhill from left to right.', const Color(0xFFEF4444)),
        const SizedBox(height: 8),
        _buildAnalogyBox('Zero Slope (m = 0)', 'Walking on flat ground.', Colors.blueAccent),
      ],
    );
  }

  Widget _buildLevel3(List<FlSpot> spots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 160,
          padding: const EdgeInsets.only(right: 16, top: 12, bottom: 4, left: 8),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                getDrawingHorizontalLine: (val) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
                getDrawingVerticalLine: (val) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  axisNameWidget: const Text('x', style: TextStyle(color: Colors.grey, fontSize: 10)),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 20,
                    interval: 2.5,
                    getTitlesWidget: (val, meta) => Text(
                      val.toStringAsFixed(0),
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9),
                    ),
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: const Text('y', style: TextStyle(color: Colors.grey, fontSize: 10)),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 2.5,
                    getTitlesWidget: (val, meta) => Text(
                      val.toStringAsFixed(0),
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9),
                    ),
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: -5,
              maxX: 5,
              minY: -5,
              maxY: 5,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: const Color(0xFF10B981),
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),

        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Slope (m): ', style: TextStyle(color: Colors.white, fontSize: 12)),
            Text(_slope.toStringAsFixed(1), style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
            Expanded(
              child: Slider(
                value: _slope,
                min: -3.0,
                max: 3.0,
                activeColor: const Color(0xFF10B981),
                onChanged: (val) => setState(() => _slope = val),
              ),
            ),
          ],
        ),
        Row(
          children: [
            const Text('Intercept (c): ', style: TextStyle(color: Colors.white, fontSize: 12)),
            Text(_intercept.toStringAsFixed(1), style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
            Expanded(
              child: Slider(
                value: _intercept,
                min: -3.0,
                max: 3.0,
                activeColor: const Color(0xFF10B981),
                onChanged: (val) => setState(() => _intercept = val),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLevel4(List<FlSpot> spots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Explore Linear Functions', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Math.tex(
                'y = (${_slope.toStringAsFixed(1)}) \\cdot x + (${_intercept.toStringAsFixed(1)})',
                textStyle: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.black),
          onPressed: () {
            setState(() {
              _slope = 1.0;
              _intercept = 0.0;
            });
          },
          child: const Text('Reset to Default', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String latex, String label) {
    return Column(
      children: [
        Math.tex(latex, textStyle: const TextStyle(color: Colors.white, fontSize: 13)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
      ],
    );
  }

  Widget _buildAnalogyBox(String title, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
        ],
      ),
    );
  }
}
