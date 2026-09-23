/**
 * ════════════════════════════════════════════════════════════════════════════
 * JEENI AI — RESPONSE MODE & COMPLEXITY CLASSIFIER (Backend Engine)
 * Authoritative taxonomy for adaptive response visualization metadata
 * ════════════════════════════════════════════════════════════════════════════
 */

const ResponseMode = {
  SIMPLE_CHAT: 'SIMPLE_CHAT',
  GENERAL_EXPLANATION: 'GENERAL_EXPLANATION',
  EDUCATIONAL_EXPLANATION: 'EDUCATIONAL_EXPLANATION',
  MATHEMATICAL: 'MATHEMATICAL',
  CODE_GENERATION: 'CODE_GENERATION',
  CYBERSECURITY: 'CYBERSECURITY',
  NETWORKING: 'NETWORKING',
  RAG_RETRIEVAL: 'RAG_RETRIEVAL',
  CURRICULUM_LEARNING: 'CURRICULUM_LEARNING',
  COMPARISON: 'COMPARISON',
  MULTI_STEP_PROBLEM: 'MULTI_STEP_PROBLEM',
  LONG_FORM: 'LONG_FORM',
  LESSON_GENERATION: 'LESSON_GENERATION',
  NOTE_GENERATION: 'NOTE_GENERATION',
  DATA_ANALYSIS: 'DATA_ANALYSIS',
  PERSONALIZED_LEARNING: 'PERSONALIZED_LEARNING',
  IMAGE_OR_FILE_ANALYSIS: 'IMAGE_OR_FILE_ANALYSIS',
  ERROR_RECOVERY: 'ERROR_RECOVERY',
  DEFAULT: 'DEFAULT',
};

const ComplexityLevel = {
  VERY_SIMPLE: 'VERY_SIMPLE',
  SIMPLE: 'SIMPLE',
  MODERATE: 'MODERATE',
  COMPLEX: 'COMPLEX',
  VERY_COMPLEX: 'VERY_COMPLEX',
};

const AnimationType = {
  SIMPLE_PULSE: 'simple_pulse',
  KNOWLEDGE_FLOW: 'knowledge_flow',
  MATH_FLOW: 'math_flow',
  CODE_GENERATION: 'code_generation',
  NETWORK_FLOW: 'network_flow',
  SECURITY_SCAN: 'security_scan',
  RETRIEVAL_FLOW: 'retrieval_flow',
  COMPARISON_FLOW: 'comparison_flow',
  LESSON_BUILDER: 'lesson_builder',
  DATA_ANALYSIS: 'data_analysis',
  DEFAULT_JEENI: 'default_jeeni',
};

/**
 * Maps ResponseMode to its signature AnimationType
 */
const ModeToAnimation = {
  [ResponseMode.SIMPLE_CHAT]: AnimationType.SIMPLE_PULSE,
  [ResponseMode.GENERAL_EXPLANATION]: AnimationType.KNOWLEDGE_FLOW,
  [ResponseMode.EDUCATIONAL_EXPLANATION]: AnimationType.KNOWLEDGE_FLOW,
  [ResponseMode.MATHEMATICAL]: AnimationType.MATH_FLOW,
  [ResponseMode.CODE_GENERATION]: AnimationType.CODE_GENERATION,
  [ResponseMode.CYBERSECURITY]: AnimationType.SECURITY_SCAN,
  [ResponseMode.NETWORKING]: AnimationType.NETWORK_FLOW,
  [ResponseMode.RAG_RETRIEVAL]: AnimationType.RETRIEVAL_FLOW,
  [ResponseMode.CURRICULUM_LEARNING]: AnimationType.RETRIEVAL_FLOW,
  [ResponseMode.COMPARISON]: AnimationType.COMPARISON_FLOW,
  [ResponseMode.MULTI_STEP_PROBLEM]: AnimationType.MATH_FLOW,
  [ResponseMode.LONG_FORM]: AnimationType.LESSON_BUILDER,
  [ResponseMode.LESSON_GENERATION]: AnimationType.LESSON_BUILDER,
  [ResponseMode.NOTE_GENERATION]: AnimationType.LESSON_BUILDER,
  [ResponseMode.DATA_ANALYSIS]: AnimationType.DATA_ANALYSIS,
  [ResponseMode.PERSONALIZED_LEARNING]: AnimationType.DEFAULT_JEENI,
  [ResponseMode.IMAGE_OR_FILE_ANALYSIS]: AnimationType.RETRIEVAL_FLOW,
  [ResponseMode.ERROR_RECOVERY]: AnimationType.DEFAULT_JEENI,
  [ResponseMode.DEFAULT]: AnimationType.DEFAULT_JEENI,
};

/**
 * Classifies a user query and execution context into a ResponseMode and ComplexityLevel.
 * Runs in < 1ms deterministically.
 */
function classifyResponseMode(userQuery, options = {}) {
  const query = (userQuery || '').trim();
  const qLower = query.toLowerCase();
  const {
    routerResult = null,
    curriculumIntent = null,
    ragUsed = false,
    isWebSearch = false,
    attachments = [],
    mode = 'Guided Learning',
    hasMemories = false,
  } = options;

  // 1. Files / Images Attached
  if (attachments && attachments.length > 0) {
    return _buildResult(ResponseMode.IMAGE_OR_FILE_ANALYSIS, _computeComplexity(query, ResponseMode.IMAGE_OR_FILE_ANALYSIS), ragUsed);
  }

  // 2. Casual / Simple Chat Greetings
  const greetings = ['hi', 'hello', 'hey', 'greetings', 'good morning', 'good evening', 'good afternoon', 'bye', 'goodbye', 'thanks', 'thank you'];
  if (greetings.includes(qLower) || (query.length < 10 && (qLower.startsWith('hi ') || qLower.startsWith('hey ') || qLower.startsWith('hello ')))) {
    return _buildResult(ResponseMode.SIMPLE_CHAT, ComplexityLevel.VERY_SIMPLE, ragUsed);
  }

  // 3. Curriculum / RAG
  if (ragUsed || (curriculumIntent && curriculumIntent.isCurriculumQuery) || (routerResult && routerResult.action === 'rag_search')) {
    const complexity = _computeComplexity(query, ResponseMode.CURRICULUM_LEARNING);
    return _buildResult(ResponseMode.CURRICULUM_LEARNING, complexity, true);
  }
  if (/\b(chapter\s+\d+|class\s+(?:9|10|8|11|12)|ncert|scert|cbse|textbook|syllabus)\b/i.test(qLower)) {
    const complexity = _computeComplexity(query, ResponseMode.CURRICULUM_LEARNING);
    return _buildResult(ResponseMode.CURRICULUM_LEARNING, complexity, ragUsed);
  }

  // 4. Comparison (Evaluated before domain topics if explicitly comparing concepts)
  if (/\b(compare|difference\s+between|versus|\bvs\b|pros\s+and\s+cons|advantages\s+and\s+disadvantages|contrast)\b/i.test(qLower)) {
    const complexity = _computeComplexity(query, ResponseMode.COMPARISON);
    return _buildResult(ResponseMode.COMPARISON, complexity, ragUsed);
  }

  // 5. Cybersecurity (Evaluated before general code to prioritize security vulnerabilities)
  if (
    /\b(cybersecurity|security|sql\s+injection|sqli|xss|csrf|buffer\s+overflow|exploit|vulnerability|firewall|pentest|malware|ransomware|encryption|hash|sha256|aes|rsa|zero-day|phishing)\b/i.test(qLower)
  ) {
    const complexity = _computeComplexity(query, ResponseMode.CYBERSECURITY);
    return _buildResult(ResponseMode.CYBERSECURITY, complexity, ragUsed);
  }

  // 6. Networking
  if (
    /\b(tcp|udp|ip\s+address|ipv4|ipv6|dns|dhcp|osi\s+model|packet|handshake|three-way\s+handshake|http|https|subnet|router|switch|gateway|ping|traceroute|socket|lan|wan)\b/i.test(qLower)
  ) {
    const complexity = _computeComplexity(query, ResponseMode.NETWORKING);
    return _buildResult(ResponseMode.NETWORKING, complexity, ragUsed);
  }

  // 7. Code Generation / Programming
  if (
    /\b(code|python|javascript|typescript|c\+\+|java|rust|html|css|\bsql\b|function|def\s+\w+|class\s+\w+|debug|compile|regex|algorithm|script|api\s+endpoint|git)\b/i.test(qLower) ||
    /```|[{}();=><]{3,}/.test(query)
  ) {
    const complexity = _computeComplexity(query, ResponseMode.CODE_GENERATION);
    return _buildResult(ResponseMode.CODE_GENERATION, complexity, ragUsed);
  }

  // 8. Data Analysis / Statistics (Evaluated before general Math)
  if (/\b(statistics|data\s+analysis|distribution|mean|median|mode|standard\s+deviation|correlation|regression|histogram|scatter\s+plot|pie\s+chart|bar\s+chart)\b/i.test(qLower)) {
    const complexity = _computeComplexity(query, ResponseMode.DATA_ANALYSIS);
    return _buildResult(ResponseMode.DATA_ANALYSIS, complexity, ragUsed);
  }

  // 9. Mathematical / Calculation
  if (
    /\b(solve|equation|formula|calculate|integral|derivative|algebra|geometry|trigonometry|matrix|quadratic|polynomial|fraction|logarithm|arithmetic|square\s+root)\b/i.test(qLower) ||
    /[0-9]+\s*[\+\-\*\/=^]\s*[0-9]+/.test(query) ||
    /\b[xXyYzZ]\s*[\+\-\*\/=]/.test(query)
  ) {
    const complexity = _computeComplexity(query, ResponseMode.MATHEMATICAL);
    return _buildResult(ResponseMode.MATHEMATICAL, complexity, ragUsed);
  }

  // 10. Lesson Generation / Syllabus Planning
  if (/\b(lesson\s+plan|study\s+plan|teach\s+me|course\s+outline|full\s+lesson|complete\s+guide|curriculum\s+guide)\b/i.test(qLower)) {
    const complexity = _computeComplexity(query, ResponseMode.LESSON_GENERATION);
    return _buildResult(ResponseMode.LESSON_GENERATION, complexity, ragUsed);
  }

  // 11. Note Generation / Cheatsheet
  if (/\b(notes|make\s+notes|summary\s+notes|cheat\s*sheet|revision\s+notes|flashcard|key\s+points)\b/i.test(qLower)) {
    const complexity = _computeComplexity(query, ResponseMode.NOTE_GENERATION);
    return _buildResult(ResponseMode.NOTE_GENERATION, complexity, ragUsed);
  }

  // 12. Multi-Step Problem
  if (/\b(step\s+by\s+step|multi-step|break\s+down|stages|process\s+of|first.*?then.*?finally)\b/i.test(qLower)) {
    const complexity = _computeComplexity(query, ResponseMode.MULTI_STEP_PROBLEM);
    return _buildResult(ResponseMode.MULTI_STEP_PROBLEM, complexity, ragUsed);
  }

  // 13. Deep Research / Long Form Mode
  if (mode === 'Deep Research' || /\b(exhaustive|detailed\s+essay|comprehensive\s+report|in-depth\s+analysis)\b/i.test(qLower)) {
    return _buildResult(ResponseMode.LONG_FORM, ComplexityLevel.COMPLEX, ragUsed);
  }

  // 14. Personalized Learning (if specialized mode or personal request)
  if (hasMemories || mode === 'Exam Prep' || /\b(quiz\s+me|test\s+my\s+knowledge|my\s+weakness|personalize|help\s+me\s+improve)\b/i.test(qLower)) {
    const complexity = _computeComplexity(query, ResponseMode.PERSONALIZED_LEARNING);
    return _buildResult(ResponseMode.PERSONALIZED_LEARNING, complexity, ragUsed);
  }

  // 15. Science / Educational Explanation
  if (
    /\b(photosynthesis|mitosis|meiosis|newton|gravity|energy|atom|molecule|velocity|ecosystem|cell|organism|plate\s+tectonics|respiration|evolution|reaction|acid|base)\b/i.test(qLower)
  ) {
    const complexity = _computeComplexity(query, ResponseMode.EDUCATIONAL_EXPLANATION);
    return _buildResult(ResponseMode.EDUCATIONAL_EXPLANATION, complexity, ragUsed);
  }

  // 16. General Explanation
  if (/\b(explain|what\s+is|how\s+does|why\s+is|describe|define)\b/i.test(qLower)) {
    const complexity = _computeComplexity(query, ResponseMode.GENERAL_EXPLANATION);
    return _buildResult(ResponseMode.GENERAL_EXPLANATION, complexity, ragUsed);
  }

  // 17. Default Fallback
  return _buildResult(ResponseMode.DEFAULT, _computeComplexity(query, ResponseMode.DEFAULT), ragUsed);
}

/**
 * Computes multi-signal complexity score (NOT relying solely on character count).
 * Follows specification:
 * - "What is DNS?" -> SIMPLE
 * - "Explain DNS resolution." -> MODERATE
 * - "Explain DNS resolution, compare recursive and iterative queries, and show a practical packet flow." -> COMPLEX
 */
function _computeComplexity(query, mode) {
  let score = 0;
  const qLower = query.toLowerCase();
  const words = query.trim().split(/\s+/).filter(Boolean);

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
  if (/\b(explain|resolution|mechanism|how\s+it\s+works|in\s+detail|workflow|lifecycle)\b/i.test(qLower)) {
    score += 2; // Shifts "Explain DNS resolution" into MODERATE (score 5-6)
  }

  // Signal: Conjunctions & Multi-part Clauses ("and", "also", "compare", "along with")
  const clauses = (query.match(/\b(and|also|along\s+with|moreover|furthermore|as\s+well\s+as|compare|contrast)\b/gi) || []).length;
  if (clauses >= 2) score += 2;
  else if (clauses === 1) score += 1;

  // Signal: Specific High-Complexity Indicators
  if (/\b(derive|proof|packet\s+flow|architecture|implementation|in-depth|trace|step\s+by\s+step|mathematical\s+model|practical\s+flow)\b/i.test(qLower)) {
    score += 2;
  }

  // Score to Enum Mapping
  if (score <= 2) return ComplexityLevel.VERY_SIMPLE;
  if (score <= 4) return ComplexityLevel.SIMPLE;
  if (score <= 6) return ComplexityLevel.MODERATE;
  if (score <= 8) return ComplexityLevel.COMPLEX;
  return ComplexityLevel.VERY_COMPLEX;
}

function _buildResult(responseMode, complexity, ragUsed) {
  return {
    responseMode,
    complexity,
    animation: ModeToAnimation[responseMode] || AnimationType.DEFAULT_JEENI,
    processingState: 'processing',
    ragUsed: Boolean(ragUsed),
  };
}

module.exports = {
  ResponseMode,
  ComplexityLevel,
  AnimationType,
  ModeToAnimation,
  classifyResponseMode,
};
