import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// JEENI AI — RESPONSE VISUALIZATION TAXONOMY & CONFIGURATION
/// Central data model for adaptive, context-aware AI response animations.
/// ════════════════════════════════════════════════════════════════════════════

/// All 19 supported response modes from specification
enum ResponseMode {
  simpleChat,
  generalExplanation,
  educationalExplanation,
  mathematical,
  codeGeneration,
  cybersecurity,
  networking,
  ragRetrieval,
  curriculumLearning,
  comparison,
  multiStepProblem,
  longForm,
  lessonGeneration,
  noteGeneration,
  dataAnalysis,
  personalizedLearning,
  imageOrFileAnalysis,
  errorRecovery,
  defaultMode,
}

/// 5 cognitive and procedural complexity levels
enum ComplexityLevel {
  verySimple,
  simple,
  moderate,
  complex,
  veryComplex,
}

/// Lifecycle states of the response visualization state machine
enum AnimationLifecycleState {
  idle,
  classifying,
  preparing,
  processing,
  streaming,
  complete,
  error,
  stopped,
}

/// Genuinely distinct visual animation families
enum VisualizationType {
  simplePulse,
  knowledgeFlow,
  mathFlow,
  codeGeneration,
  networkFlow,
  securityScan,
  retrievalFlow,
  comparisonFlow,
  lessonBuilder,
  dataAnalysis,
  defaultJeeni,
}

/// Full visualization configuration holding aesthetic tokens & UX status labels
class AdaptiveAnimationConfig {
  final ResponseMode responseMode;
  final ComplexityLevel complexity;
  final VisualizationType visualizationType;
  final String badgeLabel;
  final IconData badgeIcon;
  final Color primaryColor;
  final Color accentColor;
  final List<String> statusLabels;
  final double speedMultiplier;

  const AdaptiveAnimationConfig({
    required this.responseMode,
    required this.complexity,
    required this.visualizationType,
    required this.badgeLabel,
    required this.badgeIcon,
    required this.primaryColor,
    required this.accentColor,
    required this.statusLabels,
    this.speedMultiplier = 1.0,
  });

  /// Human-readable complexity badge text
  String get complexityLabel {
    switch (complexity) {
      case ComplexityLevel.verySimple:
        return 'Quick';
      case ComplexityLevel.simple:
        return 'Standard';
      case ComplexityLevel.moderate:
        return 'Detailed';
      case ComplexityLevel.complex:
        return 'Multi-part';
      case ComplexityLevel.veryComplex:
        return 'Deep Analysis';
    }
  }

  /// Color associated with complexity pill
  Color get complexityColor {
    switch (complexity) {
      case ComplexityLevel.verySimple:
      case ComplexityLevel.simple:
        return const Color(0xFF10B981); // Emerald
      case ComplexityLevel.moderate:
        return const Color(0xFF0EA5E9); // Sky
      case ComplexityLevel.complex:
        return const Color(0xFFF59E0B); // Amber
      case ComplexityLevel.veryComplex:
        return const Color(0xFFEC4899); // Rose
    }
  }
}
