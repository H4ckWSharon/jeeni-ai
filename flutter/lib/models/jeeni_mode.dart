import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// JEENI PRODUCT MODES (User-Facing AI Modes)
/// These are experiential educational modes, NOT raw provider LLM models.
/// ════════════════════════════════════════════════════════════════════════════
enum JeeniMode {
  webSearch,
  deepLearning,
  guide,
  learning,
  homework,
  examPrep;

  String get id {
    switch (this) {
      case JeeniMode.webSearch:
        return 'web_search';
      case JeeniMode.deepLearning:
        return 'deep_learning';
      case JeeniMode.guide:
        return 'guide';
      case JeeniMode.learning:
        return 'learning';
      case JeeniMode.homework:
        return 'homework';
      case JeeniMode.examPrep:
        return 'exam_prep';
    }
  }

  String get label {
    switch (this) {
      case JeeniMode.webSearch:
        return 'Web Search';
      case JeeniMode.deepLearning:
        return 'Deep Learning';
      case JeeniMode.guide:
        return 'Guide';
      case JeeniMode.learning:
        return 'Learning';
      case JeeniMode.homework:
        return 'Homework';
      case JeeniMode.examPrep:
        return 'Exam Prep';
    }
  }

  String get emoji {
    switch (this) {
      case JeeniMode.webSearch:
        return '🔎';
      case JeeniMode.deepLearning:
        return '🧠';
      case JeeniMode.guide:
        return '🧭';
      case JeeniMode.learning:
        return '📚';
      case JeeniMode.homework:
        return '📝';
      case JeeniMode.examPrep:
        return '🎯';
    }
  }

  IconData get icon {
    switch (this) {
      case JeeniMode.webSearch:
        return Icons.travel_explore_rounded;
      case JeeniMode.deepLearning:
        return Icons.psychology_rounded;
      case JeeniMode.guide:
        return Icons.explore_rounded;
      case JeeniMode.learning:
        return Icons.school_rounded;
      case JeeniMode.homework:
        return Icons.edit_note_rounded;
      case JeeniMode.examPrep:
        return Icons.flag_rounded;
    }
  }

  String get description {
    switch (this) {
      case JeeniMode.webSearch:
        return 'Search the web for current info';
      case JeeniMode.deepLearning:
        return 'Deeply understand a topic';
      case JeeniMode.guide:
        return 'Step-by-step guided help';
      case JeeniMode.learning:
        return 'Learn concepts interactively';
      case JeeniMode.homework:
        return 'Work through homework problems';
      case JeeniMode.examPrep:
        return 'Prepare, practice and revise';
    }
  }

  Color get color {
    switch (this) {
      case JeeniMode.webSearch:
        return const Color(0xFF0EA5E9); // Sky
      case JeeniMode.deepLearning:
        return const Color(0xFFA855F7); // Purple
      case JeeniMode.guide:
        return const Color(0xFF10B981); // Emerald
      case JeeniMode.learning:
        return const Color(0xFF6366F1); // Indigo
      case JeeniMode.homework:
        return const Color(0xFFF97316); // Orange
      case JeeniMode.examPrep:
        return const Color(0xFFF59E0B); // Amber
    }
  }

  /// Resolve from id or label (case-insensitive, fallback to learning)
  static JeeniMode fromString(String? value) {
    if (value == null) return JeeniMode.learning;
    final v = value.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    for (final mode in JeeniMode.values) {
      if (mode.id == v || mode.label.toLowerCase() == value.trim().toLowerCase()) {
        return mode;
      }
    }
    // Backward compatibility aliases
    if (v.contains('web')) return JeeniMode.webSearch;
    if (v.contains('deep') || v.contains('research')) return JeeniMode.deepLearning;
    if (v.contains('guide')) return JeeniMode.guide;
    if (v.contains('home')) return JeeniMode.homework;
    if (v.contains('exam')) return JeeniMode.examPrep;
    return JeeniMode.learning;
  }

  /// Filters modes based on search query (case-insensitive).
  /// If query is empty or '@', returns all modes.
  static List<JeeniMode> filter(String query) {
    var q = query.trim().toLowerCase();
    if (q.startsWith('@')) {
      q = q.substring(1).trim();
    }
    if (q.isEmpty) {
      return JeeniMode.values;
    }
    return JeeniMode.values.where((m) {
      return m.label.toLowerCase().contains(q) ||
          m.id.toLowerCase().contains(q) ||
          m.description.toLowerCase().contains(q);
    }).toList();
  }
}
