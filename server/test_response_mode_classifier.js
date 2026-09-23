const assert = require('assert');
const {
  ResponseMode,
  ComplexityLevel,
  AnimationType,
  classifyResponseMode,
} = require('./src/responseModeClassifier');

console.log('═══════════════════════════════════════════════════════════════');
console.log('🧪 RUNNING RESPONSE MODE CLASSIFIER TEST SUITE');
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

// ── 1. Mandatory Core Tests from Specification ──────────────────────
runTest('1. Simple greeting prompt', () => {
  const res = classifyResponseMode('Hi Jeeni');
  assert.strictEqual(res.responseMode, ResponseMode.SIMPLE_CHAT);
  assert.strictEqual(res.animation, AnimationType.SIMPLE_PULSE);
  assert.strictEqual(res.complexity, ComplexityLevel.VERY_SIMPLE);
});

runTest('2. Networking query ("What is DNS?")', () => {
  const res = classifyResponseMode('What is DNS?');
  assert.strictEqual(res.responseMode, ResponseMode.NETWORKING);
  assert.strictEqual(res.animation, AnimationType.NETWORK_FLOW);
  assert.ok([ComplexityLevel.VERY_SIMPLE, ComplexityLevel.SIMPLE].includes(res.complexity));
});

runTest('3. Moderate networking query ("Explain DNS resolution.")', () => {
  const res = classifyResponseMode('Explain DNS resolution.');
  assert.strictEqual(res.responseMode, ResponseMode.NETWORKING);
  assert.strictEqual(res.animation, AnimationType.NETWORK_FLOW);
  assert.ok([ComplexityLevel.SIMPLE, ComplexityLevel.MODERATE].includes(res.complexity));
});

runTest('4. Complex networking query with packet flow', () => {
  const res = classifyResponseMode(
    'Explain DNS resolution, compare recursive and iterative queries, and show a practical packet flow.'
  );
  assert.strictEqual(res.responseMode, ResponseMode.COMPARISON); // "compare" triggers comparison or networking
  assert.ok(res.complexity === ComplexityLevel.COMPLEX || res.complexity === ComplexityLevel.VERY_COMPLEX);
});

runTest('5. Educational explanation ("Explain photosynthesis.")', () => {
  const res = classifyResponseMode('Explain photosynthesis.');
  assert.strictEqual(res.responseMode, ResponseMode.EDUCATIONAL_EXPLANATION);
  assert.strictEqual(res.animation, AnimationType.KNOWLEDGE_FLOW);
});

runTest('6. Mathematical query ("Solve this quadratic equation.")', () => {
  const res = classifyResponseMode('Solve this quadratic equation.');
  assert.strictEqual(res.responseMode, ResponseMode.MATHEMATICAL);
  assert.strictEqual(res.animation, AnimationType.MATH_FLOW);
});

runTest('7. Mathematical numeric formula ("Solve 2x + 5 = 15")', () => {
  const res = classifyResponseMode('Solve 2x + 5 = 15');
  assert.strictEqual(res.responseMode, ResponseMode.MATHEMATICAL);
  assert.strictEqual(res.animation, AnimationType.MATH_FLOW);
});

runTest('8. Code generation ("Write a Python program to reverse a string.")', () => {
  const res = classifyResponseMode('Write a Python program to reverse a string.');
  assert.strictEqual(res.responseMode, ResponseMode.CODE_GENERATION);
  assert.strictEqual(res.animation, AnimationType.CODE_GENERATION);
});

runTest('9. Networking protocol ("Explain TCP three-way handshake.")', () => {
  const res = classifyResponseMode('Explain TCP three-way handshake.');
  assert.strictEqual(res.responseMode, ResponseMode.NETWORKING);
  assert.strictEqual(res.animation, AnimationType.NETWORK_FLOW);
});

runTest('10. Cybersecurity vulnerability ("What is SQL injection?")', () => {
  const res = classifyResponseMode('What is SQL injection?');
  assert.strictEqual(res.responseMode, ResponseMode.CYBERSECURITY);
  assert.strictEqual(res.animation, AnimationType.SECURITY_SCAN);
});

runTest('11. RAG retrieval query ("Find the relevant chapter for Class 10 English")', () => {
  const res = classifyResponseMode('Find the relevant chapter for Class 10 English', {
    ragUsed: true,
  });
  assert.strictEqual(res.responseMode, ResponseMode.CURRICULUM_LEARNING);
  assert.strictEqual(res.animation, AnimationType.RETRIEVAL_FLOW);
  assert.strictEqual(res.ragUsed, true);
});

runTest('12. Comparison ("Compare TCP and UDP.")', () => {
  const res = classifyResponseMode('Compare TCP and UDP.');
  assert.strictEqual(res.responseMode, ResponseMode.COMPARISON);
  assert.strictEqual(res.animation, AnimationType.COMPARISON_FLOW);
});

runTest('13. Note generation ("Create complete Class 10 notes for Chapter 1")', () => {
  const res = classifyResponseMode('Create complete Class 10 notes for Chapter 1');
  assert.ok(
    [ResponseMode.NOTE_GENERATION, ResponseMode.CURRICULUM_LEARNING, ResponseMode.LESSON_GENERATION].includes(
      res.responseMode
    )
  );
  assert.strictEqual(res.animation, AnimationType.RETRIEVAL_FLOW); // Since Chapter 1 / Class 10 triggered curriculum retrieval or note generation
});

runTest('14. Multi-step problem ("Step by step guide to break down cellular respiration")', () => {
  const res = classifyResponseMode('Step by step guide to break down cellular respiration');
  assert.strictEqual(res.responseMode, ResponseMode.MULTI_STEP_PROBLEM);
});

runTest('15. Data analysis ("Analyze this distribution chart and calculate mean and median")', () => {
  const res = classifyResponseMode('Analyze this distribution chart and calculate mean and median');
  assert.strictEqual(res.responseMode, ResponseMode.DATA_ANALYSIS);
  assert.strictEqual(res.animation, AnimationType.DATA_ANALYSIS);
});

runTest('16. Image attachment analysis', () => {
  const res = classifyResponseMode('Explain this', {
    attachments: [{ name: 'circuit.png' }],
  });
  assert.strictEqual(res.responseMode, ResponseMode.IMAGE_OR_FILE_ANALYSIS);
  assert.strictEqual(res.animation, AnimationType.RETRIEVAL_FLOW);
});

runTest('17. Default fallback for obscure query', () => {
  const res = classifyResponseMode('Quarks and strange charm leptons in hypothetical universe');
  assert.ok(res.responseMode !== undefined);
  assert.ok(res.animation !== undefined);
});

runTest('18. Performance: 1,000 classifications executed in < 50ms', () => {
  const start = Date.now();
  for (let i = 0; i < 1000; i++) {
    classifyResponseMode('Explain TCP three-way handshake with syn and ack packets');
  }
  const duration = Date.now() - start;
  assert.ok(duration < 50, `Expected < 50ms, got ${duration}ms`);
});

console.log('\n───────────────────────────────────────────────────────────────');
console.log(`Results: ${passed} passed, ${failed} failed`);
console.log('───────────────────────────────────────────────────────────────\n');

if (failed > 0) {
  process.exit(1);
}
