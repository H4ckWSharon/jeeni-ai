import 'package:flutter/material.dart';

/// The nine purpose-tuned states from Schoolees/thinking-orbs.
enum OrbState {
  idle,
  working,
  connecting,
  searching,
  solving,
  listening,
  composing,
  responding,
  shaping,
}

/// Visual representation variant.
enum OrbVariant {
  classic, // Halftone stippled 3D dot cloud
  contour, // Motion-matched contour line loops
}

/// Metadata and styling configuration for each Thinking Orb state.
class OrbStateConfig {
  final OrbState state;
  final String label;
  final String description;
  final Color primaryColor;
  final Color glowColor;
  final List<String> statusPhrases;
  final IconData icon;

  const OrbStateConfig({
    required this.state,
    required this.label,
    required this.description,
    required this.primaryColor,
    required this.glowColor,
    required this.statusPhrases,
    required this.icon,
  });

  Color get secondaryColor => glowColor;
  Color get accentColor => primaryColor;
  List<String> get phrases => statusPhrases;

  static OrbStateConfig forState(OrbState state) => of(state);

  static const Map<OrbState, OrbStateConfig> configs = {
    OrbState.idle: OrbStateConfig(
      state: OrbState.idle,
      label: 'Ready',
      description: 'Jeeni is resting and ready',
      primaryColor: Color(0xFF10A37F),
      glowColor: Color(0x3310A37F),
      statusPhrases: ['Ready to learn...', 'Awaiting prompt...'],
      icon: Icons.auto_awesome_rounded,
    ),
    OrbState.working: OrbStateConfig(
      state: OrbState.working,
      label: 'Working',
      description: 'Active task execution and synthesis',
      primaryColor: Color(0xFF6366F1), // Indigo
      glowColor: Color(0x336366F1),
      statusPhrases: [
        'Processing request...',
        'Orchestrating learning flow...',
        'Synthesizing pedagogical model...'
      ],
      icon: Icons.auto_awesome_rounded,
    ),
    OrbState.connecting: OrbStateConfig(
      state: OrbState.connecting,
      label: 'Connecting',
      description: 'Establishing gateway connection',
      primaryColor: Color(0xFF06B6D4), // Cyan
      glowColor: Color(0x3306B6D4),
      statusPhrases: [
        'Connecting to Jeeni gateway...',
        'Establishing secure stream...',
        'Synchronizing learning context...'
      ],
      icon: Icons.hub_rounded,
    ),
    OrbState.searching: OrbStateConfig(
      state: OrbState.searching,
      label: 'Searching',
      description: 'Verified curriculum knowledge retrieval',
      primaryColor: Color(0xFF38BDF8), // Sky Blue
      glowColor: Color(0x3338BDF8),
      statusPhrases: [
        'Searching textbook curriculum...',
        'Validating syllabus index...',
        'Retrieving verified chapter material...'
      ],
      icon: Icons.menu_book_rounded,
    ),
    OrbState.solving: OrbStateConfig(
      state: OrbState.solving,
      label: 'Solving',
      description: 'Mathematical and logical deduction',
      primaryColor: Color(0xFF3B82F6), // Blue
      glowColor: Color(0x333B82F6),
      statusPhrases: [
        'Working through algebraic steps...',
        'Evaluating formula constraints...',
        'Verifying mathematical logic...'
      ],
      icon: Icons.functions_rounded,
    ),
    OrbState.listening: OrbStateConfig(
      state: OrbState.listening,
      label: 'Listening',
      description: 'Capturing speech and audio waveforms',
      primaryColor: Color(0xFFEC4899), // Pink
      glowColor: Color(0x33EC4899),
      statusPhrases: [
        'Listening to your question...',
        'Transcribing speech waveform...',
        'Understanding verbal inquiry...'
      ],
      icon: Icons.mic_rounded,
    ),
    OrbState.composing: OrbStateConfig(
      state: OrbState.composing,
      label: 'Composing',
      description: 'Structuring explanations and narratives',
      primaryColor: Color(0xFF8B5CF6), // Purple
      glowColor: Color(0x338B5CF6),
      statusPhrases: [
        'Composing conceptual explanation...',
        'Structuring pedagogical narrative...',
        'Formulating clear analogies...'
      ],
      icon: Icons.edit_note_rounded,
    ),
    OrbState.responding: OrbStateConfig(
      state: OrbState.responding,
      label: 'Responding',
      description: 'Streaming live answer tokens',
      primaryColor: Color(0xFF10B981), // Emerald
      glowColor: Color(0x3310B981),
      statusPhrases: [
        'Delivering response...',
        'Finalizing answer...',
        'Complete'
      ],
      icon: Icons.chat_bubble_outline_rounded,
    ),
    OrbState.shaping: OrbStateConfig(
      state: OrbState.shaping,
      label: 'Shaping',
      description: 'Building structured lesson, code or notes',
      primaryColor: Color(0xFFF59E0B), // Amber
      glowColor: Color(0x33F59E0B),
      statusPhrases: [
        'Shaping document structure...',
        'Formatting code and bullet tiers...',
        'Compiling revision lesson...'
      ],
      icon: Icons.category_rounded,
    ),
  };

  static OrbStateConfig of(OrbState state) {
    return configs[state] ?? configs[OrbState.working]!;
  }
}
