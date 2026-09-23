import '../../response_visualization/models/response_mode.dart';
import '../models/orb_state.dart';

/// Centralized resolver that deterministically maps Jeeni's response mode
/// and actual operational state to the appropriate Thinking Orb state.
///
/// CRITICAL: Adheres to strict non-fabrication principles:
/// - Only maps to [OrbState.searching] if curriculum retrieval actually occurred.
/// - Only maps to [OrbState.solving] if algebraic or mathematical deduction is required.
class OrbStateResolver {
  /// Resolves the [OrbState] based on the active [AdaptiveAnimationConfig].
  static OrbState resolveFromConfig(
    AdaptiveAnimationConfig? config, {
    bool ragUsed = true,
    bool isStreaming = false,
  }) {
    if (isStreaming) {
      return OrbState.responding;
    }

    if (config == null) {
      return OrbState.idle;
    }

    // Mode-specific mapping
    switch (config.responseMode) {
      case ResponseMode.simpleChat:
        return OrbState.idle;

      case ResponseMode.mathematical:
        return OrbState.solving;

      case ResponseMode.ragRetrieval:
      case ResponseMode.curriculumLearning:
        // Only show searching if RAG is actually active/intended
        return ragUsed ? OrbState.searching : OrbState.working;

      case ResponseMode.lessonGeneration:
      case ResponseMode.noteGeneration:
      case ResponseMode.multiStepProblem:
      case ResponseMode.dataAnalysis:
        return OrbState.shaping;

      case ResponseMode.codeGeneration:
      case ResponseMode.comparison:
      case ResponseMode.generalExplanation:
      case ResponseMode.educationalExplanation:
      case ResponseMode.personalizedLearning:
      case ResponseMode.longForm:
        return OrbState.composing;

      case ResponseMode.networking:
      case ResponseMode.cybersecurity:
      case ResponseMode.errorRecovery:
        return OrbState.connecting;

      case ResponseMode.imageOrFileAnalysis:
        return OrbState.searching;

      case ResponseMode.defaultMode:
        return OrbState.working;
    }
  }

  /// Direct state resolver for operational states (audio recording, gateway connection, streaming).
  static OrbState resolveFromState({
    bool isListening = false,
    bool isConnecting = false,
    bool isStreaming = false,
    AdaptiveAnimationConfig? config,
    bool ragUsed = true,
  }) {
    if (isListening) return OrbState.listening;
    if (isConnecting) return OrbState.connecting;
    if (isStreaming) return OrbState.responding;
    return resolveFromConfig(config, ragUsed: ragUsed, isStreaming: isStreaming);
  }

  /// Maps voice listening state directly.
  static OrbState forListening() => OrbState.listening;

  /// Maps connection establishment phase.
  static OrbState forConnecting() => OrbState.connecting;

  /// Maps streaming transition.
  static OrbState forResponding() => OrbState.responding;
}
