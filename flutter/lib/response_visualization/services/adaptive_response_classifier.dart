import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/response_mode.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// ADAPTIVE RESPONSE CLASSIFIER (Client-Side Instant Resolver)
/// Runs in < 1ms to select the exact visual animation and progressive UX states
/// ════════════════════════════════════════════════════════════════════════════
class AdaptiveResponseClassifier {
  /// Analyzes query, active model, and attachments to produce the animation configuration
  static AdaptiveAnimationConfig classify({
    required String prompt,
    String? mode,
    List<XFile> attachments = const [],
    bool ragExpected = false,
  }) {
    final query = prompt.trim();
    final qLower = query.toLowerCase();

    // 1. Files / Images Attached
    if (attachments.isNotEmpty) {
      final complexity = _computeComplexity(query, ResponseMode.imageOrFileAnalysis);
      return _buildConfig(
        mode: ResponseMode.imageOrFileAnalysis,
        complexity: complexity,
        type: VisualizationType.retrievalFlow,
        badgeLabel: 'Visual Analysis',
        badgeIcon: Icons.image_search_rounded,
        primaryColor: const Color(0xFF8B5CF6), // Purple
        accentColor: const Color(0xFFA78BFA),
        statusLabels: [
          'Scanning image features...',
          'Examining visual structure...',
          'Preparing visual explanation...',
        ],
      );
    }

    // 2. Casual / Greeting (Very Simple)
    const greetings = ['hi', 'hello', 'hey', 'greetings', 'good morning', 'good evening', 'good afternoon', 'bye', 'goodbye', 'thanks', 'thank you'];
    if (greetings.contains(qLower) || (query.length < 10 && (qLower.startsWith('hi ') || qLower.startsWith('hey ') || qLower.startsWith('hello ')))) {
      return _buildConfig(
        mode: ResponseMode.simpleChat,
        complexity: ComplexityLevel.verySimple,
        type: VisualizationType.simplePulse,
        badgeLabel: 'Jeeni Chat',
        badgeIcon: Icons.auto_awesome_rounded,
        primaryColor: const Color(0xFF6366F1), // Indigo
        accentColor: const Color(0xFF818CF8),
        statusLabels: [
          'Saying hello...',
          'Ready to learn together...',
        ],
      );
    }

    // 2.5 Web Search Mode
    if (mode == 'Web Search' || mode == 'web_search') {
      return _buildConfig(
        mode: ResponseMode.ragRetrieval,
        complexity: ComplexityLevel.moderate,
        type: VisualizationType.retrievalFlow,
        badgeLabel: 'Web Search',
        badgeIcon: Icons.travel_explore_rounded,
        primaryColor: const Color(0xFF0EA5E9),
        accentColor: const Color(0xFF38BDF8),
        statusLabels: [
          'Searching the live web...',
          'Aggregating real-time sources...',
          'Synthesizing web findings...',
        ],
      );
    }

    // 3. Curriculum & Textbook RAG
    if (ragExpected ||
        (mode == 'Deep Research' || mode == 'Deep Learning' || mode == 'deep_learning') && (qLower.contains('chapter') || qLower.contains('textbook')) ||
        RegExp(r'\b(chapter\s+\d+|class\s+(?:9|10|8|11|12)|ncert|scert|cbse|textbook|syllabus)\b', caseSensitive: false).hasMatch(qLower)) {
      final complexity = _computeComplexity(query, ResponseMode.curriculumLearning);
      return _buildConfig(
        mode: ResponseMode.curriculumLearning,
        complexity: complexity,
        type: VisualizationType.retrievalFlow,
        badgeLabel: 'Curriculum Knowledge',
        badgeIcon: Icons.menu_book_rounded,
        primaryColor: const Color(0xFF0EA5E9), // Sky
        accentColor: const Color(0xFF38BDF8),
        statusLabels: [
          'Searching curriculum material...',
          'Indexing relevant textbook sections...',
          'Preparing grounded explanation...',
        ],
      );
    }

    // 4. Comparison (Evaluated before domain topics when user asks to compare)
    if (RegExp(r'\b(compare|difference\s+between|versus|\bvs\b|pros\s+and\s+cons|advantages\s+and\s+disadvantages|contrast)\b', caseSensitive: false).hasMatch(qLower)) {
      final complexity = _computeComplexity(query, ResponseMode.comparison);
      return _buildConfig(
        mode: ResponseMode.comparison,
        complexity: complexity,
        type: VisualizationType.comparisonFlow,
        badgeLabel: 'Concept Comparison',
        badgeIcon: Icons.compare_arrows_rounded,
        primaryColor: const Color(0xFFF59E0B), // Amber
        accentColor: const Color(0xFFFBBF24),
        statusLabels: [
          'Comparing key concepts...',
          'Analyzing differences & trade-offs...',
          'Synthesizing comparison matrix...',
        ],
      );
    }

    // 5. Cybersecurity & Information Security
    if (RegExp(r'\b(cybersecurity|security|sql\s+injection|sqli|xss|csrf|buffer\s+overflow|exploit|vulnerability|firewall|pentest|malware|ransomware|encryption|hash|sha256|aes|rsa|zero-day|phishing)\b', caseSensitive: false).hasMatch(qLower)) {
      final complexity = _computeComplexity(query, ResponseMode.cybersecurity);
      return _buildConfig(
        mode: ResponseMode.cybersecurity,
        complexity: complexity,
        type: VisualizationType.securityScan,
        badgeLabel: 'Security Analysis',
        badgeIcon: Icons.security_rounded,
        primaryColor: const Color(0xFFEF4444), // Crimson/Red
        accentColor: const Color(0xFFF87171),
        statusLabels: [
          'Scanning security concepts...',
          'Analyzing vulnerability patterns...',
          'Preparing defensive breakdown...',
        ],
      );
    }

    // 6. Networking & Protocols
    if (RegExp(r'\b(tcp|udp|ip\s+address|ipv4|ipv6|dns|dhcp|osi\s+model|packet|handshake|three-way\s+handshake|http|https|subnet|router|switch|gateway|ping|traceroute|socket|lan|wan)\b', caseSensitive: false).hasMatch(qLower)) {
      final complexity = _computeComplexity(query, ResponseMode.networking);
      return _buildConfig(
        mode: ResponseMode.networking,
        complexity: complexity,
        type: VisualizationType.networkFlow,
        badgeLabel: 'Network Flow',
        badgeIcon: Icons.hub_rounded,
        primaryColor: const Color(0xFF06B6D4), // Cyan
        accentColor: const Color(0xFF22D3EE),
        statusLabels: [
          'Connecting network nodes...',
          'Tracing packet routing & handshake...',
          'Synthesizing protocol architecture...',
        ],
      );
    }

    // 7. Code Generation & Programming
    if (RegExp(r'\b(code|python|javascript|typescript|c\+\+|java|rust|html|css|\bsql\b|function|def\s+\w+|class\s+\w+|debug|compile|regex|algorithm|script|api\s+endpoint|git)\b', caseSensitive: false).hasMatch(qLower) ||
        query.contains('```') ||
        RegExp(r'[{}();=><]{3,}').hasMatch(query)) {
      final complexity = _computeComplexity(query, ResponseMode.codeGeneration);
      return _buildConfig(
        mode: ResponseMode.codeGeneration,
        complexity: complexity,
        type: VisualizationType.codeGeneration,
        badgeLabel: 'Code Engine',
        badgeIcon: Icons.code_rounded,
        primaryColor: const Color(0xFF10B981), // Emerald
        accentColor: const Color(0xFF34D399),
        statusLabels: [
          'Structuring code logic...',
          'Formatting syntax & algorithm...',
          'Preparing clean implementation...',
        ],
      );
    }

    // 8. Data Analysis & Statistics (Evaluated before general Math)
    if (RegExp(r'\b(statistics|data\s+analysis|distribution|mean|median|mode|standard\s+deviation|correlation|regression|histogram|scatter\s+plot|pie\s+chart|bar\s+chart)\b', caseSensitive: false).hasMatch(qLower)) {
      final complexity = _computeComplexity(query, ResponseMode.dataAnalysis);
      return _buildConfig(
        mode: ResponseMode.dataAnalysis,
        complexity: complexity,
        type: VisualizationType.dataAnalysis,
        badgeLabel: 'Data Analysis',
        badgeIcon: Icons.bar_chart_rounded,
        primaryColor: const Color(0xFF8B5CF6), // Violet
        accentColor: const Color(0xFFA78BFA),
        statusLabels: [
          'Analyzing statistical data...',
          'Evaluating distribution patterns...',
          'Generating insights & charts...',
        ],
      );
    }

    // 9. Mathematical & Numerical Calculation
    if (RegExp(r'\b(solve|equation|formula|calculate|integral|derivative|algebra|geometry|trigonometry|matrix|quadratic|polynomial|fraction|logarithm|arithmetic|square\s+root)\b', caseSensitive: false).hasMatch(qLower) ||
        RegExp(r'[0-9]+\s*[\+\-\*\/=^]\s*[0-9]+').hasMatch(query) ||
        RegExp(r'\b[xXyYzZ]\s*[\+\-\*\/=]').hasMatch(query)) {
      final complexity = _computeComplexity(query, ResponseMode.mathematical);
      return _buildConfig(
        mode: ResponseMode.mathematical,
        complexity: complexity,
        type: VisualizationType.mathFlow,
        badgeLabel: 'Mathematical Engine',
        badgeIcon: Icons.functions_rounded,
        primaryColor: const Color(0xFF3B82F6), // Blue
        accentColor: const Color(0xFF60A5FA),
        statusLabels: [
          'Parsing mathematical variables...',
          'Working through algebraic steps...',
          'Formulating structured solution...',
        ],
      );
    }

    // 10. Lesson Generation & Syllabus Planning
    if (RegExp(r'\b(lesson\s+plan|study\s+plan|teach\s+me|course\s+outline|full\s+lesson|complete\s+guide|curriculum\s+guide)\b', caseSensitive: false).hasMatch(qLower)) {
      final complexity = _computeComplexity(query, ResponseMode.lessonGeneration);
      return _buildConfig(
        mode: ResponseMode.lessonGeneration,
        complexity: complexity,
        type: VisualizationType.lessonBuilder,
        badgeLabel: 'Lesson Builder',
        badgeIcon: Icons.assignment_rounded,
        primaryColor: const Color(0xFFF97316), // Orange
        accentColor: const Color(0xFFFB923C),
        statusLabels: [
          'Building structured lesson outline...',
          'Organizing learning objectives & stages...',
          'Preparing lesson document...',
        ],
      );
    }

    // 11. Note Generation & Revision Cheatsheets
    if (RegExp(r'\b(notes|make\s+notes|summary\s+notes|cheat\s*sheet|revision\s+notes|flashcard|key\s+points)\b', caseSensitive: false).hasMatch(qLower)) {
      final complexity = _computeComplexity(query, ResponseMode.noteGeneration);
      return _buildConfig(
        mode: ResponseMode.noteGeneration,
        complexity: complexity,
        type: VisualizationType.lessonBuilder,
        badgeLabel: 'Revision Notes',
        badgeIcon: Icons.sticky_note_2_rounded,
        primaryColor: const Color(0xFFEAB308), // Yellow
        accentColor: const Color(0xFFFACC15),
        statusLabels: [
          'Extracting essential concepts...',
          'Structuring bulleted revision notes...',
          'Formatting key takeaways...',
        ],
      );
    }

    // 12. Multi-Step Problem
    if (RegExp(r'\b(step\s+by\s+step|multi-step|break\s+down|stages|process\s+of|first.*?then.*?finally)\b', caseSensitive: false).hasMatch(qLower)) {
      final complexity = _computeComplexity(query, ResponseMode.multiStepProblem);
      return _buildConfig(
        mode: ResponseMode.multiStepProblem,
        complexity: complexity,
        type: VisualizationType.mathFlow,
        badgeLabel: 'Step-by-Step Solver',
        badgeIcon: Icons.format_list_numbered_rounded,
        primaryColor: const Color(0xFF6366F1), // Indigo
        accentColor: const Color(0xFF818CF8),
        statusLabels: [
          'Breaking problem into discrete stages...',
          'Working through sequential steps...',
          'Synthesizing final solution...',
        ],
      );
    }

    // 13. Deep Learning / Deep Research Mode
    if (mode == 'Deep Learning' || mode == 'deep_learning' || mode == 'Deep Research' || RegExp(r'\b(exhaustive|detailed\s+essay|comprehensive\s+report|in-depth\s+analysis)\b', caseSensitive: false).hasMatch(qLower)) {
      return _buildConfig(
        mode: ResponseMode.longForm,
        complexity: ComplexityLevel.complex,
        type: VisualizationType.lessonBuilder,
        badgeLabel: 'Deep Learning',
        badgeIcon: Icons.psychology_rounded,
        primaryColor: const Color(0xFFA855F7), // Purple
        accentColor: const Color(0xFFC084FC),
        statusLabels: [
          'Conducting in-depth inquiry...',
          'Unpacking core principles & analogies...',
          'Synthesizing deep conceptual guide...',
        ],
      );
    }

    // 13.5 Guide Mode (Socratic Step-by-Step)
    if (mode == 'Guide' || mode == 'guide') {
      return _buildConfig(
        mode: ResponseMode.educationalExplanation,
        complexity: ComplexityLevel.simple,
        type: VisualizationType.knowledgeFlow,
        badgeLabel: 'Step-by-Step Guide',
        badgeIcon: Icons.explore_rounded,
        primaryColor: const Color(0xFF10B981), // Emerald
        accentColor: const Color(0xFF34D399),
        statusLabels: [
          'Structuring guided breakdown...',
          'Preparing Socratic checkpoint...',
          'Guiding step-by-step...',
        ],
      );
    }

    // 13.6 Homework Mode
    if (mode == 'Homework' || mode == 'homework') {
      return _buildConfig(
        mode: ResponseMode.multiStepProblem,
        complexity: ComplexityLevel.moderate,
        type: VisualizationType.mathFlow,
        badgeLabel: 'Homework Helper',
        badgeIcon: Icons.edit_note_rounded,
        primaryColor: const Color(0xFFF97316), // Orange
        accentColor: const Color(0xFFFB923C),
        statusLabels: [
          'Understanding homework problem...',
          'Identifying knowns & hints...',
          'Guiding solution steps...',
        ],
      );
    }

    // 14. Exam Prep / Personalized Learning Mode
    if (mode == 'Exam Prep' || mode == 'exam_prep' || RegExp(r'\b(quiz\s+me|test\s+my\s+knowledge|my\s+weakness|personalize|help\s+me\s+improve)\b', caseSensitive: false).hasMatch(qLower)) {
      return _buildConfig(
        mode: ResponseMode.personalizedLearning,
        complexity: ComplexityLevel.moderate,
        type: VisualizationType.defaultJeeni,
        badgeLabel: 'Exam Prep',
        badgeIcon: Icons.flag_rounded,
        primaryColor: const Color(0xFFF59E0B), // Amber
        accentColor: const Color(0xFFFBBF24),
        statusLabels: [
          'Calibrating question difficulty...',
          'Preparing Socratic challenge...',
          'Formulating exam drill...',
        ],
      );
    }

    // 15. Science & Educational Explanation
    if (RegExp(r'\b(photosynthesis|mitosis|meiosis|newton|gravity|energy|atom|molecule|velocity|ecosystem|cell|organism|plate\s+tectonics|respiration|evolution|reaction|acid|base)\b', caseSensitive: false).hasMatch(qLower)) {
      final complexity = _computeComplexity(query, ResponseMode.educationalExplanation);
      return _buildConfig(
        mode: ResponseMode.educationalExplanation,
        complexity: complexity,
        type: VisualizationType.knowledgeFlow,
        badgeLabel: 'Science & Discovery',
        badgeIcon: Icons.science_rounded,
        primaryColor: const Color(0xFF10B981), // Emerald
        accentColor: const Color(0xFF34D399),
        statusLabels: [
          'Exploring scientific principles...',
          'Visualizing concept dynamics...',
          'Preparing educational breakdown...',
        ],
      );
    }

    // 16. General Explanation
    if (RegExp(r'\b(explain|what\s+is|how\s+does|why\s+is|describe|define)\b', caseSensitive: false).hasMatch(qLower)) {
      final complexity = _computeComplexity(query, ResponseMode.generalExplanation);
      return _buildConfig(
        mode: ResponseMode.generalExplanation,
        complexity: complexity,
        type: VisualizationType.knowledgeFlow,
        badgeLabel: 'Knowledge Guide',
        badgeIcon: Icons.lightbulb_rounded,
        primaryColor: const Color(0xFF6366F1), // Indigo
        accentColor: const Color(0xFF818CF8),
        statusLabels: [
          'Understanding request...',
          'Gathering core concepts...',
          'Preparing clear explanation...',
        ],
      );
    }

    // 17. Default Signature Jeeni
    final complexity = _computeComplexity(query, ResponseMode.defaultMode);
    return _buildConfig(
      mode: ResponseMode.defaultMode,
      complexity: complexity,
      type: VisualizationType.defaultJeeni,
      badgeLabel: 'Jeeni Tutor',
      badgeIcon: Icons.psychology_rounded,
      primaryColor: const Color(0xFF8B5CF6), // Violet
      accentColor: const Color(0xFFA78BFA),
      statusLabels: [
        'Understanding your question...',
        'Synthesizing helpful answer...',
        'Formulating response...',
      ],
    );
  }

  /// Multi-signal complexity score matching:
  /// - "What is DNS?" -> SIMPLE
  /// - "Explain DNS resolution." -> MODERATE
  /// - "Explain DNS resolution, compare recursive and iterative queries, and show a practical packet flow." -> COMPLEX
  static ComplexityLevel _computeComplexity(String query, ResponseMode mode) {
    int score = 0;
    final qLower = query.toLowerCase();
    final words = query.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    // Baseline from length & structure
    if (words.length <= 3 && (qLower.startsWith('what is') || qLower.startsWith('who is') || qLower.startsWith('define'))) {
      score = 3; // Direct definition -> SIMPLE
    } else if (words.length <= 4) {
      score = 3; // Short query
    } else if (words.length <= 8) {
      score = 4; // Standard query
    } else if (words.length <= 15) {
      score = 5; // MODERATE
    } else {
      score = 7; // COMPLEX
    }

    // Signal: Inquiry Depth Keywords
    if (RegExp(r'\b(explain|resolution|mechanism|how\s+it\s+works|in\s+detail|workflow|lifecycle)\b', caseSensitive: false).hasMatch(qLower)) {
      score += 2; // Shifts "Explain DNS resolution" into MODERATE
    }

    // Signal: Conjunctions & Multi-part Clauses ("and", "also", "compare", "along with")
    final clauses = RegExp(r'\b(and|also|along\s+with|moreover|furthermore|as\s+well\s+as|compare|contrast)\b', caseSensitive: false)
        .allMatches(query)
        .length;
    if (clauses >= 2) {
      score += 2;
    } else if (clauses == 1) {
      score += 1;
    }

    // Signal: Specific High-Complexity Indicators
    if (RegExp(r'\b(derive|proof|packet\s+flow|architecture|implementation|in-depth|trace|step\s+by\s+step|mathematical\s+model|practical\s+flow)\b', caseSensitive: false).hasMatch(qLower)) {
      score += 2;
    }

    // Score to Enum Mapping
    if (score <= 2) return ComplexityLevel.verySimple;
    if (score <= 4) return ComplexityLevel.simple;
    if (score <= 6) return ComplexityLevel.moderate;
    if (score <= 8) return ComplexityLevel.complex;
    return ComplexityLevel.veryComplex;
  }

  static AdaptiveAnimationConfig _buildConfig({
    required ResponseMode mode,
    required ComplexityLevel complexity,
    required VisualizationType type,
    required String badgeLabel,
    required IconData badgeIcon,
    required Color primaryColor,
    required Color accentColor,
    required List<String> statusLabels,
  }) {
    // Complexity affects animation speed slightly (e.g. complex problems have a more deliberate cadence)
    double speedMultiplier = 1.0;
    if (complexity == ComplexityLevel.verySimple) speedMultiplier = 1.25;
    if (complexity == ComplexityLevel.complex || complexity == ComplexityLevel.veryComplex) speedMultiplier = 0.85;

    return AdaptiveAnimationConfig(
      responseMode: mode,
      complexity: complexity,
      visualizationType: type,
      badgeLabel: badgeLabel,
      badgeIcon: badgeIcon,
      primaryColor: primaryColor,
      accentColor: accentColor,
      statusLabels: statusLabels,
      speedMultiplier: speedMultiplier,
    );
  }
}
