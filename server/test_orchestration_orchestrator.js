/**
 * ════════════════════════════════════════════════════════════════════════════
 * JEENI AI — PRODUCTION AI RESPONSE ORCHESTRATION TEST SUITE
 * Validates task priority, greeting policy state machine, profile relevance
 * filtering, response path consistency, and anti-hijacking architecture.
 * ════════════════════════════════════════════════════════════════════════════
 */

const assert = require('assert');
const {
  RequestIntent,
  classifyRequestIntent,
  determineGreetingPolicy,
  filterProfileRelevance,
  classifyResponseMode,
  ResponseMode,
} = require('./src/responseModeClassifier');
const { normalizeCurriculumIntent } = require('./src/zeroChunksHandler');

console.log('═══════════════════════════════════════════════════════════════');
console.log('🧪 RUNNING JEENI ORCHESTRATION & ANTI-HIJACKING TEST SUITE');
console.log('═══════════════════════════════════════════════════════════════\n');

let passed = 0;
let failed = 0;

function runTest(name, fn) {
  try {
    fn();
    console.log(`  ✅ PASS: ${name}`);
    passed++;
  } catch (err) {
    console.error(`  ❌ FAIL: ${name}`);
    console.error(`     Error: ${err.message}`);
    failed++;
  }
}

const mockProfile = {
  display_name: 'Sharon Anil',
  class: '10',
  board: 'CBSE',
  syllabus: 'NCERT',
  subjects: ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'English'],
  preferred_language: 'English',
  knowledge_level: 'Intermediate',
  explanation_style: 'Simple with analogies',
  learning_goal: 'Concept Clarity',
  personalization_enabled: true,
};

// ── 1. GENERAL QUERIES & GREETING STATE MACHINE ─────────────────────────────
runTest('1.1 Pure greeting: "Hello" -> GREETING intent and ALLOW_GREETING policy', () => {
  const intent = classifyRequestIntent('Hello');
  const policy = determineGreetingPolicy('Hello', []);
  assert.strictEqual(intent, RequestIntent.GREETING);
  assert.strictEqual(policy, 'ALLOW_GREETING');
});

runTest('1.2 General query: "What is AI?" -> DEFINITION intent and NO_AUTOMATIC_GREETING', () => {
  const intent = classifyRequestIntent('What is AI?');
  const policy = determineGreetingPolicy('What is AI?', []);
  assert.strictEqual(intent, RequestIntent.DEFINITION);
  assert.strictEqual(policy, 'NO_AUTOMATIC_GREETING');
});

runTest('1.3 Networking query: "What is DNS?" -> NETWORKING intent and NO_AUTOMATIC_GREETING', () => {
  const intent = classifyRequestIntent('What is DNS?');
  const policy = determineGreetingPolicy('What is DNS?', []);
  assert.strictEqual(intent, RequestIntent.NETWORKING);
  assert.strictEqual(policy, 'NO_AUTOMATIC_GREETING');
});

runTest('1.4 Networking query: "Explain TCP." -> NETWORKING intent and NO_AUTOMATIC_GREETING', () => {
  const intent = classifyRequestIntent('Explain TCP.');
  const policy = determineGreetingPolicy('Explain TCP.', []);
  assert.strictEqual(intent, RequestIntent.NETWORKING);
  assert.strictEqual(policy, 'NO_AUTOMATIC_GREETING');
});

runTest('1.5 Programming query: "What is recursion?" -> PROGRAMMING intent and NO_AUTOMATIC_GREETING', () => {
  const intent = classifyRequestIntent('What is recursion?');
  const policy = determineGreetingPolicy('What is recursion?', []);
  assert.strictEqual(intent, RequestIntent.PROGRAMMING);
  assert.strictEqual(policy, 'NO_AUTOMATIC_GREETING');
});

// ── 2. PROGRAMMING & DEBUGGING ──────────────────────────────────────────────
runTest('2.1 Code explanation: "Explain this Python code." -> CODE_EXPLANATION', () => {
  const intent = classifyRequestIntent('Explain this Python code.');
  assert.strictEqual(intent, RequestIntent.CODE_EXPLANATION);
});

runTest('2.2 Code debugging: "Why does this JavaScript fail?" -> CODE_DEBUGGING', () => {
  const intent = classifyRequestIntent('Why does this JavaScript fail?');
  assert.strictEqual(intent, RequestIntent.CODE_DEBUGGING);
});

runTest('2.3 Programming definition: "What is a function?" -> PROGRAMMING', () => {
  const intent = classifyRequestIntent('What is a function?');
  assert.strictEqual(intent, RequestIntent.PROGRAMMING);
});

// ── 3. CYBERSECURITY ────────────────────────────────────────────────────────
runTest('3.1 Cybersecurity: "What is phishing?" -> CYBERSECURITY', () => {
  const intent = classifyRequestIntent('What is phishing?');
  assert.strictEqual(intent, RequestIntent.CYBERSECURITY);
});

runTest('3.2 Cybersecurity: "Explain SQL injection." -> CYBERSECURITY', () => {
  const intent = classifyRequestIntent('Explain SQL injection.');
  assert.strictEqual(intent, RequestIntent.CYBERSECURITY);
});

runTest('3.3 Cybersecurity: "What is port 443?" -> CYBERSECURITY', () => {
  const intent = classifyRequestIntent('What is port 443?');
  assert.strictEqual(intent, RequestIntent.CYBERSECURITY);
});

// ── 4. EDUCATION (SCIENCE & MATH) ───────────────────────────────────────────
runTest('4.1 Science: "Explain photosynthesis." -> SCIENCE', () => {
  const intent = classifyRequestIntent('Explain photosynthesis.');
  assert.strictEqual(intent, RequestIntent.SCIENCE);
});

runTest('4.2 Science: "Explain Newton\'s laws." -> SCIENCE', () => {
  const intent = classifyRequestIntent("Explain Newton's laws.");
  assert.strictEqual(intent, RequestIntent.SCIENCE);
});

runTest('4.3 Mathematics: "Explain algebra." -> MATHEMATICS', () => {
  const intent = classifyRequestIntent('Explain algebra.');
  assert.strictEqual(intent, RequestIntent.MATHEMATICS);
});

// ── 5. CURRICULUM ───────────────────────────────────────────────────────────
runTest('5.1 Explicit chapter: "Explain Class 10 Chapter 2." -> CURRICULUM intent', () => {
  const curIntent = normalizeCurriculumIntent('Explain Class 10 Chapter 2.', null, mockProfile);
  const intent = classifyRequestIntent('Explain Class 10 Chapter 2.', { curriculumIntent: curIntent });
  assert.strictEqual(intent, RequestIntent.CURRICULUM);
  assert.strictEqual(curIntent.isCurriculumQuery, true);
  assert.strictEqual(curIntent.chapterNumber, 2);
  assert.strictEqual(curIntent.requiresSubject, true); // Missing subject -> will trigger clarification
});

runTest('5.2 Notes: "Give me notes for this chapter." -> NOTES intent', () => {
  const intent = classifyRequestIntent('Give me notes for this chapter.');
  assert.strictEqual(intent, RequestIntent.NOTES);
});

runTest('5.3 Quiz: "Quiz me on this topic." -> QUIZ intent', () => {
  const intent = classifyRequestIntent('Quiz me on this topic.');
  assert.strictEqual(intent, RequestIntent.QUIZ);
});

// ── 6. PROFILE RELEVANCE FILTER (ANTI-HIJACKING) ────────────────────────────
runTest('6.1 Identity: "What is my name?" -> Exposes display_name and isIdentityQuery = true', () => {
  const intent = classifyRequestIntent('What is my name?');
  assert.strictEqual(intent, RequestIntent.IDENTITY_OR_PROFILE);
  const filter = filterProfileRelevance(mockProfile, intent, 'What is my name?');
  assert.strictEqual(filter.isIdentityQuery, true);
  assert.ok(filter.systemPromptSnippet.includes('Sharon Anil'));
  assert.ok(filter.personalizationFieldsUsed.includes('display_name'));
});

runTest('6.2 Identity: "What class am I in?" -> Exposes class and isIdentityQuery = true', () => {
  const intent = classifyRequestIntent('What class am I in?');
  assert.strictEqual(intent, RequestIntent.IDENTITY_OR_PROFILE);
  const filter = filterProfileRelevance(mockProfile, intent, 'What class am I in?');
  assert.strictEqual(filter.isIdentityQuery, true);
  assert.ok(filter.systemPromptSnippet.includes('Class 10'));
});

runTest('6.3 Identity: "What subjects do I study?" -> Exposes subjects and isIdentityQuery = true', () => {
  const intent = classifyRequestIntent('What subjects do I study?');
  assert.strictEqual(intent, RequestIntent.IDENTITY_OR_PROFILE);
  const filter = filterProfileRelevance(mockProfile, intent, 'What subjects do I study?');
  assert.strictEqual(filter.isIdentityQuery, true);
  assert.ok(filter.systemPromptSnippet.includes('Mathematics'));
});

runTest('6.4 Technical query: "Explain TCP." -> STRIPS display_name and enrolled subjects', () => {
  const intent = classifyRequestIntent('Explain TCP.');
  const filter = filterProfileRelevance(mockProfile, intent, 'Explain TCP.');
  assert.strictEqual(filter.isIdentityQuery, false);
  // CRITICAL CHECK: Student name must NEVER appear in the prompt snippet!
  assert.strictEqual(filter.systemPromptSnippet.includes('Sharon Anil'), false);
  // CRITICAL CHECK: Enrolled subjects list must NOT appear!
  assert.strictEqual(filter.systemPromptSnippet.includes('Enrolled Subjects:'), false);
  // CRITICAL CHECK: Negative greeting instruction must be present!
  assert.ok(filter.systemPromptSnippet.includes('DO NOT mention or announce the student\'s name, class, grade'));
  assert.ok(filter.systemPromptSnippet.includes('Answer the user\'s question immediately in the first sentence'));
});

runTest('6.5 Code debugging: "Why does this SQL query fail?" -> Name stripped, silent calibration only', () => {
  const intent = classifyRequestIntent('Why does this SQL query fail?');
  const filter = filterProfileRelevance(mockProfile, intent, 'Why does this SQL query fail?');
  assert.strictEqual(filter.systemPromptSnippet.includes('Sharon Anil'), false);
  assert.strictEqual(filter.isIdentityQuery, false);
  assert.ok(filter.systemPromptSnippet.includes('Calibrate vocabulary, explanation depth, and pacing for a secondary school student'));
});

// ── 7. PEDAGOGICAL MODES ────────────────────────────────────────────────────
runTest('7.1 @Guide + question: "Explain recursion" -> Guide mode maps to simple explanation', () => {
  const modeRes = classifyResponseMode('Explain recursion', { mode: 'guide' });
  assert.strictEqual(modeRes.responseMode, ResponseMode.EDUCATIONAL_EXPLANATION);
});

runTest('7.2 @Learning + question: "Explain recursion" -> maps to CODE_GENERATION with code keyword', () => {
  const modeRes = classifyResponseMode('Explain recursion', { mode: 'learning' });
  assert.strictEqual(modeRes.responseMode, ResponseMode.CODE_GENERATION);
});

runTest('7.3 @Homework + question: "Solve 2x + 5 = 15" -> maps to MATHEMATICAL', () => {
  const modeRes = classifyResponseMode('Solve 2x + 5 = 15', { mode: 'homework' });
  assert.strictEqual(modeRes.responseMode, ResponseMode.MATHEMATICAL);
});

runTest('7.4 @Exam Prep + question: "High yield points for Chapter 1" -> maps to CURRICULUM_LEARNING', () => {
  const modeRes = classifyResponseMode('High yield points for Chapter 1', { mode: 'exam_prep' });
  assert.strictEqual(modeRes.responseMode, ResponseMode.CURRICULUM_LEARNING);
});

// ── 8. MULTI-MODAL & FILES ──────────────────────────────────────────────────
runTest('8.1 Image attachment: Image + question -> IMAGE_ANALYSIS intent', () => {
  const intent = classifyRequestIntent('What is this diagram?', {
    attachments: [{ name: 'cell_diagram.png', type: 'image_url' }],
  });
  assert.strictEqual(intent, RequestIntent.IMAGE_ANALYSIS);
});

runTest('8.2 Document attachment: PDF + question -> DOCUMENT_ANALYSIS intent', () => {
  const intent = classifyRequestIntent('Summarize this document', {
    attachments: [{ name: 'study_guide.pdf' }],
  });
  assert.strictEqual(intent, RequestIntent.DOCUMENT_ANALYSIS);
});

// ── 9. CONSISTENCY VERIFICATION (Requirement 12) ───────────────────────────
runTest('9.1 Identical query consistency: 10 repeated runs of "Explain TCP three-way handshake" produce identical intent and path', () => {
  const results = [];
  for (let i = 0; i < 10; i++) {
    const curIntent = normalizeCurriculumIntent('Explain TCP three-way handshake.', null, mockProfile);
    const intent = classifyRequestIntent('Explain TCP three-way handshake.', { curriculumIntent: curIntent });
    const policy = determineGreetingPolicy('Explain TCP three-way handshake.', []);
    const filter = filterProfileRelevance(mockProfile, intent, 'Explain TCP three-way handshake.');
    results.push({
      intent,
      policy,
      isIdentity: filter.isIdentityQuery,
      hasNameLeak: filter.systemPromptSnippet.includes('Sharon Anil'),
    });
  }

  // Verify all 10 runs are identical
  const first = results[0];
  for (let i = 1; i < 10; i++) {
    assert.strictEqual(results[i].intent, first.intent);
    assert.strictEqual(results[i].policy, first.policy);
    assert.strictEqual(results[i].isIdentity, first.isIdentity);
    assert.strictEqual(results[i].hasNameLeak, first.hasNameLeak);
  }
  assert.strictEqual(first.intent, RequestIntent.NETWORKING);
  assert.strictEqual(first.policy, 'NO_AUTOMATIC_GREETING');
  assert.strictEqual(first.isIdentity, false);
  assert.strictEqual(first.hasNameLeak, false);
});

// ── 10. FOLLOW-UP CONVERSATION HISTORY ──────────────────────────────────────
runTest('10.1 Follow-up question: Q1 -> Q2 -> Q3 strictly preserves NO_AUTOMATIC_GREETING on follow-up turns', () => {
  const history = [
    { role: 'user', content: 'What is DNS?' },
    { role: 'assistant', content: 'DNS is the domain name system...' },
    { role: 'user', content: 'What port does it use?' },
    { role: 'assistant', content: 'It uses port 53...' },
  ];
  const followUpQuery = 'Can it use TCP as well?';
  const policy = determineGreetingPolicy(followUpQuery, history);
  const intent = classifyRequestIntent(followUpQuery);
  assert.strictEqual(policy, 'NO_AUTOMATIC_GREETING');
  assert.strictEqual(intent, RequestIntent.NETWORKING);
});

// ── 11. NO RAG HIJACK ON GENERAL TECHNICAL QUERIES (Requirement 9) ─────────
runTest('11.1 General technical query "Explain TCP" does NOT trigger isCurriculumQuery', () => {
  const intent = normalizeCurriculumIntent('Explain TCP.', null, mockProfile);
  assert.strictEqual(intent.isCurriculumQuery, false);
});

runTest('11.2 General coding query "Why does this SQL query fail?" does NOT trigger isCurriculumQuery', () => {
  const intent = normalizeCurriculumIntent('Why does this SQL query fail?', null, mockProfile);
  assert.strictEqual(intent.isCurriculumQuery, false);
});

console.log('\n====================================================');
console.log(`🏁 ORCHESTRATION RESULTS: ${passed} / ${passed + failed} TESTS PASSED`);
console.log('====================================================');

if (failed > 0) {
  process.exit(1);
} else {
  process.exit(0);
}
