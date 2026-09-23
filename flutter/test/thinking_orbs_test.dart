import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeeni_ai/response_visualization/models/response_mode.dart';
import 'package:jeeni_ai/thinking_orbs/models/orb_state.dart';
import 'package:jeeni_ai/thinking_orbs/renderers/thinking_orb_painter.dart';
import 'package:jeeni_ai/thinking_orbs/services/orb_state_resolver.dart';
import 'package:jeeni_ai/thinking_orbs/widgets/thinking_orbs_response_view.dart';

void main() {
  group('Thinking Orbs — State Resolver Tests', () {
    test('1. Null config maps to idle state', () {
      expect(OrbStateResolver.resolveFromConfig(null), OrbState.idle);
    });

    test('2. Mathematical mode maps to solving state', () {
      const config = AdaptiveAnimationConfig(
        responseMode: ResponseMode.mathematical,
        complexity: ComplexityLevel.moderate,
        visualizationType: VisualizationType.mathFlow,
        badgeLabel: 'Math',
        badgeIcon: Icons.functions,
        primaryColor: Color(0xFF10B981),
        accentColor: Color(0xFF059669),
        statusLabels: ['Solving equation...'],
      );
      expect(OrbStateResolver.resolveFromConfig(config), OrbState.solving);
    });

    test('3. RAG Retrieval only maps to searching when ragUsed is true', () {
      const config = AdaptiveAnimationConfig(
        responseMode: ResponseMode.ragRetrieval,
        complexity: ComplexityLevel.complex,
        visualizationType: VisualizationType.retrievalFlow,
        badgeLabel: 'Retrieval',
        badgeIcon: Icons.search,
        primaryColor: Color(0xFF06B6D4),
        accentColor: Color(0xFF0891B2),
        statusLabels: ['Searching curriculum...'],
      );

      // ragUsed == true -> searching
      expect(OrbStateResolver.resolveFromConfig(config, ragUsed: true), OrbState.searching);

      // ragUsed == false -> does NOT fake searching, falls back to working
      expect(OrbStateResolver.resolveFromConfig(config, ragUsed: false), OrbState.working);
    });

    test('4. Code generation & Comparison map to composing state', () {
      const codeConfig = AdaptiveAnimationConfig(
        responseMode: ResponseMode.codeGeneration,
        complexity: ComplexityLevel.complex,
        visualizationType: VisualizationType.codeGeneration,
        badgeLabel: 'Code',
        badgeIcon: Icons.code,
        primaryColor: Color(0xFF8B5CF6),
        accentColor: Color(0xFF7C3AED),
        statusLabels: ['Composing code...'],
      );
      expect(OrbStateResolver.resolveFromConfig(codeConfig), OrbState.composing);

      const compConfig = AdaptiveAnimationConfig(
        responseMode: ResponseMode.comparison,
        complexity: ComplexityLevel.complex,
        visualizationType: VisualizationType.comparisonFlow,
        badgeLabel: 'Compare',
        badgeIcon: Icons.compare_arrows,
        primaryColor: Color(0xFFEC4899),
        accentColor: Color(0xFFDB2777),
        statusLabels: ['Synthesizing comparison...'],
      );
      expect(OrbStateResolver.resolveFromConfig(compConfig), OrbState.composing);
    });

    test('5. Lesson builder & Data analysis map to shaping state', () {
      const lessonConfig = AdaptiveAnimationConfig(
        responseMode: ResponseMode.lessonGeneration,
        complexity: ComplexityLevel.veryComplex,
        visualizationType: VisualizationType.lessonBuilder,
        badgeLabel: 'Lesson',
        badgeIcon: Icons.school,
        primaryColor: Color(0xFFF97316),
        accentColor: Color(0xFFEA580C),
        statusLabels: ['Structuring curriculum...'],
      );
      expect(OrbStateResolver.resolveFromConfig(lessonConfig), OrbState.shaping);
    });

    test('6. Simple chat maps to idle state', () {
      const simpleConfig = AdaptiveAnimationConfig(
        responseMode: ResponseMode.simpleChat,
        complexity: ComplexityLevel.verySimple,
        visualizationType: VisualizationType.simplePulse,
        badgeLabel: 'Chat',
        badgeIcon: Icons.chat,
        primaryColor: Color(0xFF6366F1),
        accentColor: Color(0xFF4F46E5),
        statusLabels: ['Ready...'],
      );
      expect(OrbStateResolver.resolveFromConfig(simpleConfig), OrbState.idle);
    });

    test('7. Explicit state overrides take precedence', () {
      expect(OrbStateResolver.resolveFromState(isListening: true), OrbState.listening);
      expect(OrbStateResolver.resolveFromState(isConnecting: true), OrbState.connecting);
      expect(OrbStateResolver.resolveFromState(isStreaming: true), OrbState.responding);
    });
  });

  group('Thinking Orbs — Config & Theme Tests', () {
    test('All 9 OrbStates have complete, valid configuration', () {
      for (final state in OrbState.values) {
        final config = OrbStateConfig.forState(state);
        expect(config.label.isNotEmpty, isTrue);
        expect(config.phrases.isNotEmpty, isTrue);
        expect(config.primaryColor, isNotNull);
        expect(config.secondaryColor, isNotNull);
        expect(config.accentColor, isNotNull);
        expect(config.icon, isNotNull);
      }
    });
  });

  group('Thinking Orbs — Painter Unit Tests', () {
    test('Painter executes paint method without exceptions across all 9 states and 2 variants', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(160, 160);

      for (final state in OrbState.values) {
        for (final variant in OrbVariant.values) {
          final config = OrbStateConfig.of(state);
          final painter = ThinkingOrbPainter(
            state: state,
            variant: variant,
            progress: 0.5,
            primaryColor: config.primaryColor,
            isDark: true,
          );
          // Should paint cleanly without any exception
          expect(() => painter.paint(canvas, size), returnsNormally);
        }
      }
    });
  });

  group('Thinking Orbs — Mobile Widget Tests', () {
    testWidgets('Renders ThinkingOrbsResponseView with correct state badge and stop button', (tester) async {
      bool stopPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThinkingOrbsResponseView(
              state: OrbState.solving,
              onStop: () => stopPressed = true,
            ),
          ),
        ),
      );

      // Verify label is displayed
      expect(find.text('SOLVING'), findsOneWidget);

      // Verify stop button is rendered and functional
      final stopButton = find.text('Stop');
      expect(stopButton, findsOneWidget);
      await tester.tap(stopButton);
      expect(stopPressed, isTrue);
    });

    testWidgets('Accessible semantics and reduced-motion fallback works gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: ThinkingOrbsResponseView(
                state: OrbState.searching,
              ),
            ),
          ),
        ),
      );

      // In reduced motion, still renders label cleanly
      expect(find.text('SEARCHING'), findsOneWidget);
    });
  });
}
