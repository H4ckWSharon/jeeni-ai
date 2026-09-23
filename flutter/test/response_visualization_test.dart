import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jeeni_ai/response_visualization/models/response_mode.dart';
import 'package:jeeni_ai/response_visualization/services/adaptive_response_classifier.dart';
import 'package:jeeni_ai/response_visualization/widgets/adaptive_response_view.dart';

void main() {
  group('AdaptiveResponseClassifier — Prompt Classification Tests', () {
    test('1. Simple greeting ("Hi Jeeni") -> simpleChat & verySimple', () {
      final config = AdaptiveResponseClassifier.classify(prompt: 'Hi Jeeni');
      expect(config.responseMode, ResponseMode.simpleChat);
      expect(config.visualizationType, VisualizationType.simplePulse);
      expect(config.complexity, ComplexityLevel.verySimple);
    });

    test('2. Single concept networking definition ("What is DNS?") -> networking & simple', () {
      final config = AdaptiveResponseClassifier.classify(prompt: 'What is DNS?');
      expect(config.responseMode, ResponseMode.networking);
      expect(config.visualizationType, VisualizationType.networkFlow);
      expect(config.complexity, ComplexityLevel.simple);
    });

    test('3. Moderate networking query ("Explain DNS resolution.") -> networking & moderate', () {
      final config = AdaptiveResponseClassifier.classify(prompt: 'Explain DNS resolution.');
      expect(config.responseMode, ResponseMode.networking);
      expect(config.visualizationType, VisualizationType.networkFlow);
      expect(config.complexity, ComplexityLevel.moderate);
    });

    test('4. Complex multi-part query with packet flow -> complex/veryComplex', () {
      final config = AdaptiveResponseClassifier.classify(
        prompt: 'Explain DNS resolution, compare recursive and iterative queries, and show a practical packet flow.',
      );
      expect(config.responseMode, ResponseMode.comparison);
      expect(
        config.complexity == ComplexityLevel.complex || config.complexity == ComplexityLevel.veryComplex,
        isTrue,
      );
    });

    test('5. Educational explanation ("Explain photosynthesis.") -> educationalExplanation', () {
      final config = AdaptiveResponseClassifier.classify(prompt: 'Explain photosynthesis.');
      expect(config.responseMode, ResponseMode.educationalExplanation);
      expect(config.visualizationType, VisualizationType.knowledgeFlow);
    });

    test('6. Mathematical query ("Solve this quadratic equation.") -> mathematical', () {
      final config = AdaptiveResponseClassifier.classify(prompt: 'Solve this quadratic equation.');
      expect(config.responseMode, ResponseMode.mathematical);
      expect(config.visualizationType, VisualizationType.mathFlow);
    });

    test('7. Numeric math formula ("Solve 2x + 5 = 15") -> mathematical', () {
      final config = AdaptiveResponseClassifier.classify(prompt: 'Solve 2x + 5 = 15');
      expect(config.responseMode, ResponseMode.mathematical);
      expect(config.visualizationType, VisualizationType.mathFlow);
    });

    test('8. Code generation ("Write a Python program to reverse a string.") -> codeGeneration', () {
      final config = AdaptiveResponseClassifier.classify(prompt: 'Write a Python program to reverse a string.');
      expect(config.responseMode, ResponseMode.codeGeneration);
      expect(config.visualizationType, VisualizationType.codeGeneration);
    });

    test('9. Protocol architecture ("Explain TCP three-way handshake.") -> networking', () {
      final config = AdaptiveResponseClassifier.classify(prompt: 'Explain TCP three-way handshake.');
      expect(config.responseMode, ResponseMode.networking);
      expect(config.visualizationType, VisualizationType.networkFlow);
    });

    test('10. Security analysis ("What is SQL injection?") -> cybersecurity', () {
      final config = AdaptiveResponseClassifier.classify(prompt: 'What is SQL injection?');
      expect(config.responseMode, ResponseMode.cybersecurity);
      expect(config.visualizationType, VisualizationType.securityScan);
    });

    test('11. RAG textbook retrieval ("Find the relevant chapter for Class 10 English") -> curriculumLearning', () {
      final config = AdaptiveResponseClassifier.classify(
        prompt: 'Find the relevant chapter for Class 10 English',
        ragExpected: true,
      );
      expect(config.responseMode, ResponseMode.curriculumLearning);
      expect(config.visualizationType, VisualizationType.retrievalFlow);
    });

    test('12. Comparison ("Compare TCP and UDP.") -> comparison', () {
      final config = AdaptiveResponseClassifier.classify(prompt: 'Compare TCP and UDP.');
      expect(config.responseMode, ResponseMode.comparison);
      expect(config.visualizationType, VisualizationType.comparisonFlow);
    });

    test('13. Note generation ("Create complete Class 10 notes for Chapter 1")', () {
      final config = AdaptiveResponseClassifier.classify(prompt: 'Create complete Class 10 notes for Chapter 1');
      expect(
        config.responseMode == ResponseMode.curriculumLearning ||
            config.responseMode == ResponseMode.noteGeneration ||
            config.responseMode == ResponseMode.lessonGeneration,
        isTrue,
      );
      expect(config.visualizationType, VisualizationType.retrievalFlow);
    });

    test('14. Multi-step problem ("Step by step guide to break down cellular respiration")', () {
      final config = AdaptiveResponseClassifier.classify(prompt: 'Step by step guide to break down cellular respiration');
      expect(config.responseMode, ResponseMode.multiStepProblem);
    });

    test('15. Data analysis ("Analyze this distribution chart and calculate mean and median")', () {
      final config = AdaptiveResponseClassifier.classify(
        prompt: 'Analyze this distribution chart and calculate mean and median',
      );
      expect(config.responseMode, ResponseMode.dataAnalysis);
      expect(config.visualizationType, VisualizationType.dataAnalysis);
    });

    test('16. Image attachment analysis', () {
      final config = AdaptiveResponseClassifier.classify(
        prompt: 'Explain this diagram',
        attachments: [XFile('test.png')],
      );
      expect(config.responseMode, ResponseMode.imageOrFileAnalysis);
      expect(config.visualizationType, VisualizationType.retrievalFlow);
    });

    test('17. Default fallback for unknown prompt', () {
      final config = AdaptiveResponseClassifier.classify(prompt: 'Zorblaxian hyperdrive mechanics in sector 9');
      expect(config.responseMode, isNotNull);
      expect(config.visualizationType, isNotNull);
    });
  });

  group('AdaptiveResponseView — Widget Rendering & Interaction Tests', () {
    testWidgets('Renders badge, complexity pill, and stop button', (tester) async {
      final config = AdaptiveResponseClassifier.classify(prompt: 'Solve 2x + 5 = 15');
      bool stopTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveResponseView(
              config: config,
              onStop: () => stopTapped = true,
            ),
          ),
        ),
      );

      // Verify badge text
      expect(find.text(config.badgeLabel), findsOneWidget);

      // Verify complexity pill
      expect(find.text(config.complexityLabel), findsOneWidget);

      // Verify stop button
      final stopBtn = find.text('Stop');
      expect(stopBtn, findsOneWidget);

      // Tap stop button
      await tester.tap(stopBtn);
      expect(stopTapped, isTrue);
    });

    testWidgets('Status label displays and cycles', (tester) async {
      final config = AdaptiveResponseClassifier.classify(prompt: 'Explain TCP three-way handshake.');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveResponseView(config: config),
          ),
        ),
      );

      // Initial status label should be the first in list
      expect(find.text(config.statusLabels.first), findsOneWidget);

      // Advance clock past status timer interval (2100ms)
      await tester.pump(const Duration(milliseconds: 2200));

      // Should now display next status label
      expect(find.text(config.statusLabels[1]), findsOneWidget);
    });
  });
}
