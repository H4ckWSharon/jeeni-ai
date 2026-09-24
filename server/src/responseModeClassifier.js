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

  // 2.5 Web Search Mode
  if (isWebSearch || mode === 'Web Search' || mode === 'web_search') {
    return _buildResult(ResponseMode.RAG_RETRIEVAL, ComplexityLevel.MODERATE, false);
  }

  // 2.6 Guide Mode (Explicit Guide mode: simplified step-by-step guidance)
  if (mode === 'Guide' || mode === 'guide') {
    return _buildResult(ResponseMode.EDUCATIONAL_EXPLANATION, ComplexityLevel.SIMPLE, ragUsed);
  }

  // 3. Curriculum / RAG
  if (ragUsed || (curriculumIntent && curriculumIntent.isCurriculumQuery)) {
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
    /\b(code|python|javascript|typescript|c\+\+|java|rust|html|css|\bsql\b|function|def\s+\w+|class\s+\w+|debug|compile|regex|recursion|binary\s+search|linked\s+list|algorithm|script|api\s+endpoint|git)\b/i.test(qLower) ||
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

  // 12.5 Homework Mode
  if (mode === 'Homework' || mode === 'homework') {
    return _buildResult(ResponseMode.MULTI_STEP_PROBLEM, ComplexityLevel.MODERATE, ragUsed);
  }

  // 13. Deep Learning / Long Form Mode
  if (mode === 'Deep Learning' || mode === 'deep_learning' || mode === 'Deep Research' || /\b(exhaustive|detailed\s+essay|comprehensive\s+report|in-depth\s+analysis)\b/i.test(qLower)) {
    return _buildResult(ResponseMode.LONG_FORM, ComplexityLevel.COMPLEX, ragUsed);
  }

  // 14. Personalized Learning & Exam Prep
  if (hasMemories || mode === 'Exam Prep' || mode === 'exam_prep' || /\b(quiz\s+me|test\s+my\s+knowledge|my\s+weakness|personalize|help\s+me\s+improve)\b/i.test(qLower)) {
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

/**
 * ════════════════════════════════════════════════════════════════════════════
 * REQUEST INTENT TAXONOMY & DETERMINISTIC TASK CLASSIFICATION (Requirement 6)
 * Separates "What the user wants" (Task) from "How to explain" (Personalization)
 * ════════════════════════════════════════════════════════════════════════════
 */
const RequestIntent = {
  GREETING: 'GREETING',
  IDENTITY_OR_PROFILE: 'IDENTITY_OR_PROFILE',
  DEFINITION: 'DEFINITION',
  EXPLANATION: 'EXPLANATION',
  WHY_QUESTION: 'WHY_QUESTION',
  HOW_TO: 'HOW_TO',
  CODE_EXPLANATION: 'CODE_EXPLANATION',
  CODE_DEBUGGING: 'CODE_DEBUGGING',
  PROGRAMMING: 'PROGRAMMING',
  CYBERSECURITY: 'CYBERSECURITY',
  NETWORKING: 'NETWORKING',
  MATHEMATICS: 'MATHEMATICS',
  SCIENCE: 'SCIENCE',
  CURRICULUM: 'CURRICULUM',
  RAG_QUESTION: 'RAG_QUESTION',
  HOMEWORK: 'HOMEWORK',
  EXAM_PREP: 'EXAM_PREP',
  STUDY_PLAN: 'STUDY_PLAN',
  NOTES: 'NOTES',
  QUIZ: 'QUIZ',
  COMPARISON: 'COMPARISON',
  SUMMARIZATION: 'SUMMARIZATION',
  IMAGE_ANALYSIS: 'IMAGE_ANALYSIS',
  DOCUMENT_ANALYSIS: 'DOCUMENT_ANALYSIS',
  WEB_SEARCH: 'WEB_SEARCH',
  MULTI_STEP_PROBLEM: 'MULTI_STEP_PROBLEM',
  GENERAL_CHAT: 'GENERAL_CHAT',
  OTHER: 'OTHER',
};

/**
 * Classifies the primary task intent of the user query.
 * Must run BEFORE and INDEPENDENTLY of student personalization.
 */
function classifyRequestIntent(userQuery = '', options = {}) {
  const query = String(userQuery || '').trim();
  const qLower = query.toLowerCase();
  const { attachments = [], isWebSearch = false, mode = 'learning', curriculumIntent = null } = options;

  // 1. Files / Media
  if (attachments && attachments.length > 0) {
    const hasImage = attachments.some(a => {
      const name = (a.name || '').toLowerCase();
      return name.endsWith('.png') || name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.webp') || a.type === 'image_url';
    });
    if (hasImage) {
      return RequestIntent.IMAGE_ANALYSIS;
    }
    return RequestIntent.DOCUMENT_ANALYSIS;
  }

  // 2. Identity or Profile Inquiries (Requirement 4 & 20 Case 7)
  const isIdentity = /(which|what|tell me|do you know).*?(class|grade|standard|name|board|syllabus|subject|goal|profile|about me|know about me|remember)/i.test(qLower) ||
    /^(who am i|my class|my grade|my name|my profile|my goal|my subjects|what am i studying|what subjects do i study)\??$/i.test(qLower) ||
    /\bwhat is my name\b/i.test(qLower);
  if (isIdentity) {
    return RequestIntent.IDENTITY_OR_PROFILE;
  }

  // 3. Pure Greeting (Requirement 5 & 21)
  const pureGreetingRegex = /^(hi|hello|hey|greetings|good\s+(morning|afternoon|evening)|howdy)(\s+jeeni)?[\s!.,?]*$/i;
  if (pureGreetingRegex.test(query)) {
    return RequestIntent.GREETING;
  }

  // 4. Web Search Intent or Mode
  if (isWebSearch || mode === 'web_search' || mode === 'Web Search') {
    return RequestIntent.WEB_SEARCH;
  }

  // 5. Explicit Curriculum / Textbook Retrieval
  if (curriculumIntent?.isCurriculumQuery || /\b(chapter\s+\d+|ch\.\s*\d+|lesson\s+\d+|exercise\s+\d+|textbook|syllabus|scert|cbse|ncert)\b/i.test(qLower)) {
    return RequestIntent.CURRICULUM;
  }

  // 6. Code Debugging
  if (
    /\b(error|exception|traceback|syntaxerror|typeerror|undefined|nullpointer|failed|bug)\b/i.test(qLower) ||
    /\b(why\s+(does|is|did)\s+.*?\b(fail|error|not\s+working|crash|break))\b/i.test(qLower) ||
    /\b(debug|fix)\s+(this|the|my)?\s*(\w+\s+)?(code|script|function|program|query|bug|error)?\b/i.test(qLower) ||
    (/```/.test(query) && /\b(why|fix|error|wrong|fail|bug)\b/i.test(qLower))
  ) {
    return RequestIntent.CODE_DEBUGGING;
  }

  // 7. Code Explanation
  if (
    /\bexplain\s+(this|the|my)?\s*(\w+\s+)?(code|script|function|program|snippet|algorithm)\b/i.test(qLower) ||
    /\bhow\s+(does|to)\s+(this|the|my)?\s*(\w+\s+)?(code|function|script|algorithm)\s+work\b/i.test(qLower)
  ) {
    return RequestIntent.CODE_EXPLANATION;
  }

  // 8. Cybersecurity
  if (
    /\b(cybersecurity|security|sql\s+injection|sqli|xss|csrf|buffer\s+overflow|exploit|vulnerability|firewall|pentest|malware|ransomware|encryption|hash|sha256|aes|rsa|zero-day|phishing|port\s+443|port\s+80)\b/i.test(qLower)
  ) {
    return RequestIntent.CYBERSECURITY;
  }

  // 9. Networking
  if (
    /\b(tcp|udp|ip\s+address|ipv4|ipv6|dns|dhcp|osi\s+model|packet|handshake|three-way\s+handshake|http|https|subnet|router|switch|gateway|ping|traceroute|socket|lan|wan)\b/i.test(qLower)
  ) {
    return RequestIntent.NETWORKING;
  }

  // 10. General Programming / Coding
  if (
    /\b(code|python|javascript|typescript|c\+\+|java|rust|html|css|\bsql\b|function|def\s+\w+|recursion|binary\s+search|linked\s+list|regex|algorithm|script|api\s+endpoint|git)\b/i.test(qLower) ||
    /```|[{}();=><]{3,}/.test(query)
  ) {
    return RequestIntent.PROGRAMMING;
  }

  // 11. Mathematics / Calculations
  if (
    /\b(solve|equation|formula|calculate|integral|derivative|algebra|geometry|trigonometry|matrix|quadratic|polynomial|fraction|logarithm|arithmetic|square\s+root)\b/i.test(qLower) ||
    /[0-9]+\s*[\+\-\*\/=^]\s*[0-9]+/.test(query)
  ) {
    return RequestIntent.MATHEMATICS;
  }

  // 12. Science
  if (
    /\b(photosynthesis|mitosis|meiosis|newton|gravity|energy|atom|molecule|velocity|ecosystem|cell|organism|plate\s+tectonics|respiration|evolution|reaction|acid|base|physics|chemistry|biology)\b/i.test(qLower)
  ) {
    return RequestIntent.SCIENCE;
  }

  // 13. Comparison
  if (/\b(compare|difference\s+between|versus|\bvs\b|pros\s+and\s+cons|advantages\s+and\s+disadvantages|contrast)\b/i.test(qLower)) {
    return RequestIntent.COMPARISON;
  }

  // 14. Study Plan / Syllabus Planning
  if (/\b(lesson\s+plan|study\s+plan|timetable|syllabus\s+plan|schedule|revision\s+plan)\b/i.test(qLower)) {
    return RequestIntent.STUDY_PLAN;
  }

  // 15. Notes
  if (/\b(notes|make\s+notes|summary\s+notes|cheat\s*sheet|revision\s+notes|flashcard|key\s+points)\b/i.test(qLower)) {
    return RequestIntent.NOTES;
  }

  // 16. Quiz
  if (/\b(quiz|quiz\s+me|test\s+me|mcq|practice\s+questions)\b/i.test(qLower)) {
    return RequestIntent.QUIZ;
  }

  // 17. Homework Mode
  if (mode === 'homework' || mode === 'Homework' || /\b(homework|assignment|help\s+with\s+my\s+problem)\b/i.test(qLower)) {
    return RequestIntent.HOMEWORK;
  }

  // 18. Exam Prep Mode
  if (mode === 'exam_prep' || mode === 'Exam Prep' || /\b(exam\s+prep|board\s+exam|pyq|previous\s+year)\b/i.test(qLower)) {
    return RequestIntent.EXAM_PREP;
  }

  // 19. Inquiry Formats
  if (/^why\b/i.test(qLower)) return RequestIntent.WHY_QUESTION;
  if (/^how\s+(to|do|can)\b/i.test(qLower)) return RequestIntent.HOW_TO;
  if (/^what\s+is\b|^define\b/i.test(qLower)) return RequestIntent.DEFINITION;
  if (/^explain\b/i.test(qLower)) return RequestIntent.EXPLANATION;

  return RequestIntent.GENERAL_CHAT;
}

/**
 * ════════════════════════════════════════════════════════════════════════════
 * GREETING STATE MACHINE (Requirement 5 & 21)
 * Enforces NO_AUTOMATIC_GREETING on normal questions.
 * ════════════════════════════════════════════════════════════════════════════
 */
function determineGreetingPolicy(userQuery = '', conversationHistory = []) {
  const query = String(userQuery || '').trim();
  const pureGreetingRegex = /^(hi|hello|hey|greetings|good\s+(morning|afternoon|evening)|howdy)(\s+jeeni)?[\s!.,?]*$/i;
  
  if (pureGreetingRegex.test(query)) {
    return 'ALLOW_GREETING';
  }

  // For any message containing an inquiry, request, or substantive content:
  return 'NO_AUTOMATIC_GREETING';
}

/**
 * ════════════════════════════════════════════════════════════════════════════
 * PROFILE RELEVANCE FILTER (Requirement 3, 4, 10, 16)
 * Separates Task Understanding from Response Adaptation.
 * Name and enrolled subjects are STRIPPED on general questions so they
 * cannot hijack the conversation. Personalization is INVISIBLE by default.
 * ════════════════════════════════════════════════════════════════════════════
 */
function filterProfileRelevance(studentProfile, intent, userQuery = '', relevantMemories = []) {
  if (!studentProfile || studentProfile.personalization_enabled === false) {
    return {
      isIdentityQuery: false,
      personalizationUsed: false,
      personalizationFieldsUsed: [],
      systemPromptSnippet: 'Provide a direct, authoritative, and objective educational explanation.',
    };
  }

  const isIdentity = intent === RequestIntent.IDENTITY_OR_PROFILE;
  const fieldsUsed = [];

  if (isIdentity) {
    // Identity/Profile query: Student specifically asked who they are, their name, or their class
    fieldsUsed.push('display_name', 'class', 'board', 'syllabus', 'subjects');
    if (studentProfile.learning_goal) fieldsUsed.push('learning_goal');

    const promptSnippet = [
      '--- VERIFIED STUDENT IDENTITY CONTEXT ---',
      'The student is explicitly inquiring about their identity, profile, or enrolled studies:',
      `- Name / Display Name: ${studentProfile.display_name || 'Sharon Anil'}`,
      `- Enrolled Class / Board: Class ${studentProfile.class || '10'} (${studentProfile.board || 'CBSE'}, ${studentProfile.syllabus || 'NCERT'})`,
      studentProfile.subjects ? `- Enrolled Subjects: ${studentProfile.subjects.join(', ')}` : null,
      studentProfile.learning_goal ? `- Primary Goal: ${studentProfile.learning_goal}` : null,
      '--- DIRECTIVE ---',
      'Answer the student\'s question warmly, accurately, and directly using these verified profile details.',
      'Explain that this data is securely configured to tailor their textbook curriculum and explanations.',
    ].filter(Boolean).join('\n');

    return {
      isIdentityQuery: true,
      personalizationUsed: true,
      personalizationFieldsUsed: fieldsUsed,
      systemPromptSnippet: promptSnippet,
    };
  }

  // Non-Identity Questions (Technical, Coding, Math, Science, Curriculum, General, Image, etc.)
  // CRITICAL REQUIREMENT 4 & 16:
  // - Name is NOT RELEVANT -> STRIPPED (Never exposed to the model)
  // - Subjects are NOT RELEVANT -> STRIPPED (Unless user specifically asks for study plan / subjects)
  // - Grade/Class is for SILENT difficulty/depth calibration only.
  const isStudyPlan = intent === RequestIntent.STUDY_PLAN;
  if (isStudyPlan && studentProfile.subjects && studentProfile.subjects.length > 0) {
    fieldsUsed.push('subjects');
  }

  const adaptationInstructions = [];

  // Difficulty & Grade Calibration (Silent)
  if (studentProfile.class || studentProfile.knowledge_level) {
    fieldsUsed.push('class');
    if (studentProfile.knowledge_level) fieldsUsed.push('knowledge_level');
    const grade = studentProfile.class || '10';
    const level = studentProfile.knowledge_level || 'Intermediate';
    adaptationInstructions.push(
      `- Conceptual Calibration: Calibrate vocabulary, explanation depth, and pacing for a secondary school student (Class ${grade}, ${level} level). Start with intuitive core concepts before technical formalisms.`
    );
  }

  // Preferred Language
  if (studentProfile.preferred_language && studentProfile.preferred_language.toLowerCase() !== 'english') {
    fieldsUsed.push('preferred_language');
    adaptationInstructions.push(
      `- Language Adaptation: Teach primarily in ${studentProfile.preferred_language} (or natural Manglish if Malayalam), but strictly keep all technical terms, code, and scientific formulas in standard English.`
    );
  }

  // Explanation Style & Preferred Examples
  if (studentProfile.explanation_style) {
    fieldsUsed.push('explanation_style');
    adaptationInstructions.push(`- Pedagogical Style: ${studentProfile.explanation_style}`);
  }
  if (studentProfile.preferred_examples) {
    fieldsUsed.push('preferred_examples');
    adaptationInstructions.push(`- Analogy Domain: Favor ${studentProfile.preferred_examples}.`);
  }

  // Learning Memories
  if (relevantMemories && relevantMemories.length > 0) {
    fieldsUsed.push('memories');
    adaptationInstructions.push(
      `- Verified Learning Style Hints:\n` +
      relevantMemories.map(m => `  * ${m.content}`).join('\n')
    );
  }

  const promptSnippet = [
    '--- PEDAGOGICAL ADAPTATION (BACKGROUND DIRECTIVES) ---',
    ...adaptationInstructions,
    '--- UNBREAKABLE PRIVACY & GREETING RULES ---',
    '1. DO NOT mention or announce the student\'s name, class, grade, board, or profile.',
    '2. DO NOT start with phrases like "Since you are in Class 10...", "I see from your profile...", "Hello [Name]...", or "Welcome back...".',
    '3. Answer the user\'s question immediately in the first sentence with clear, direct explanations.',
    '--- END PEDAGOGICAL ADAPTATION ---',
  ].join('\n');

  return {
    isIdentityQuery: false,
    personalizationUsed: fieldsUsed.length > 0,
    personalizationFieldsUsed: fieldsUsed,
    systemPromptSnippet: promptSnippet,
  };
}

module.exports = {
  ResponseMode,
  ComplexityLevel,
  AnimationType,
  ModeToAnimation,
  RequestIntent,
  classifyResponseMode,
  classifyRequestIntent,
  determineGreetingPolicy,
  filterProfileRelevance,
};
