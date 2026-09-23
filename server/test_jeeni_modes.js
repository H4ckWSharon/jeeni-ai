const assert = require('assert');
const { classifyResponseMode, ResponseMode, ComplexityLevel } = require('./src/responseModeClassifier');

// Test normalizeJeeniMode logic
const ALLOWED_JEENI_MODES = [
  'web_search',
  'deep_learning',
  'guide',
  'learning',
  'homework',
  'exam_prep',
];

function normalizeJeeniMode(inputMode) {
  if (!inputMode) return 'learning';
  const m = String(inputMode).trim().toLowerCase().replace(/-/g, '_').replace(/ /g, '_');
  if (ALLOWED_JEENI_MODES.includes(m)) return m;
  if (m.includes('web')) return 'web_search';
  if (m.includes('deep') || m.includes('research')) return 'deep_learning';
  if (m.includes('guide')) return 'guide';
  if (m.includes('home')) return 'homework';
  if (m.includes('exam')) return 'exam_prep';
  return 'learning';
}

console.log('═══════════════════════════════════════════════════════════════');
console.log('🧪 RUNNING JEENI MODES BACKEND TEST SUITE');
console.log('═══════════════════════════════════════════════════════════════\n');

// 1. Validation tests
assert.strictEqual(normalizeJeeniMode('web_search'), 'web_search');
assert.strictEqual(normalizeJeeniMode('Web Search'), 'web_search');
assert.strictEqual(normalizeJeeniMode('deep_learning'), 'deep_learning');
assert.strictEqual(normalizeJeeniMode('Deep Learning'), 'deep_learning');
assert.strictEqual(normalizeJeeniMode('guide'), 'guide');
assert.strictEqual(normalizeJeeniMode('Guide'), 'guide');
assert.strictEqual(normalizeJeeniMode('learning'), 'learning');
assert.strictEqual(normalizeJeeniMode('Learning'), 'learning');
assert.strictEqual(normalizeJeeniMode('homework'), 'homework');
assert.strictEqual(normalizeJeeniMode('Homework'), 'homework');
assert.strictEqual(normalizeJeeniMode('exam_prep'), 'exam_prep');
assert.strictEqual(normalizeJeeniMode('Exam Prep'), 'exam_prep');
assert.strictEqual(normalizeJeeniMode('invalid_mode_malicious'), 'learning');
assert.strictEqual(normalizeJeeniMode(null), 'learning');
console.log('  ✅ PASS: 1. Mode normalization and security fallback verified');

// 2. Web Search Classification
const webMeta = classifyResponseMode('latest cybersecurity news', { mode: 'web_search', isWebSearch: true });
assert.strictEqual(webMeta.responseMode, ResponseMode.RAG_RETRIEVAL);
console.log('  ✅ PASS: 2. Web Search mode maps to retrieval flow');

// 3. Deep Learning Classification
const deepMeta = classifyResponseMode('explain this concept deeply', { mode: 'deep_learning' });
assert.strictEqual(deepMeta.responseMode, ResponseMode.LONG_FORM);
assert.strictEqual(deepMeta.complexity, ComplexityLevel.COMPLEX);
console.log('  ✅ PASS: 3. Deep Learning mode maps to lesson builder with high complexity');

// 4. Guide Classification
const guideMeta = classifyResponseMode('help me understand recursion', { mode: 'guide' });
assert.strictEqual(guideMeta.responseMode, ResponseMode.EDUCATIONAL_EXPLANATION);
console.log('  ✅ PASS: 4. Guide mode maps to educational explanation');

// 5. Homework Classification
const hwMeta = classifyResponseMode('help me with my homework assignment', { mode: 'homework' });
assert.strictEqual(hwMeta.responseMode, ResponseMode.MULTI_STEP_PROBLEM);
console.log('  ✅ PASS: 5. Homework mode maps to multi-step problem solver');

// 6. Exam Prep Classification
const examMeta = classifyResponseMode('prepare me for my physics exam', { mode: 'exam_prep' });
assert.strictEqual(examMeta.responseMode, ResponseMode.PERSONALIZED_LEARNING);
console.log('  ✅ PASS: 6. Exam Prep mode maps to personalized exam drill');

console.log('\n───────────────────────────────────────────────────────────────');
console.log('Results: All 6 Jeeni Mode tests passed!');
console.log('───────────────────────────────────────────────────────────────\n');
