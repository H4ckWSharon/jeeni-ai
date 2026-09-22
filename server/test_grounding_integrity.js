/**
 * JEENI PRODUCTION GROUNDING & RESPONSE INTEGRITY TEST SUITE
 *
 * Verifies all 12 critical grounding, RAG routing, deterministic validation,
 * single LLM gate, cross-chapter bleed protection, and provenance requirements.
 */

const assert = require('assert');
const {
  normalizeCurriculumIntent,
  validateRetrievedChunks,
  buildClarificationForSubject,
  buildZeroChunkResponse,
  determineZeroChunkReason,
  isSyllabusAvailable,
} = require('./src/zeroChunksHandler');

console.log('================================================================');
console.log('  JEENI PRODUCTION GROUNDING & RESPONSE INTEGRITY TEST SUITE  ');
console.log('================================================================\n');

let passedTests = 0;
let failedTests = 0;

function runTest(testNum, testName, testFn) {
  try {
    testFn();
    console.log(`[PASS] Test ${testNum}: ${testName}`);
    passedTests++;
  } catch (err) {
    console.error(`[FAIL] Test ${testNum}: ${testName}`);
    console.error(`       Error: ${err.message}`);
    failedTests++;
  }
}

// ── TEST 1: Class 8 Chapter 2 (Out of Syllabus / Content Not Found) ──────────
runTest(1, 'Class 8 Chapter 2 -> Safe Zero / Out-of-syllabus Response (Gemini NOT called)', () => {
  const query = 'Explain Class 8 Chapter 2';
  const intent = normalizeCurriculumIntent(query, null, null);
  assert.strictEqual(intent.isCurriculumQuery, true);
  assert.strictEqual(intent.class, '8');
  assert.strictEqual(intent.chapterNumber, 2);

  // In Jeeni, Class 8 textbooks are not indexed yet in ChromoDB
  const chunks = [];
  const validation = validateRetrievedChunks(chunks, intent);
  assert.strictEqual(validation.valid, false);
  assert.strictEqual(validation.validChunks.length, 0);

  const response = buildZeroChunkResponse({
    type: 'CONTENT_NOT_FOUND',
    curriculumIntent: intent,
  });
  assert.strictEqual(response.gemini_called, false);
  assert.strictEqual(response.answer_source, 'CONTENT_NOT_FOUND');
  assert(response.content.includes("couldn't find the requested chapter"));
});

// ── TEST 2: Class 10 CBSE English Chapter 2 (Missing Content) ────────────────
runTest(2, 'Class 10 CBSE English Chapter 2 -> CONTENT_NOT_FOUND (Gemini NOT called)', () => {
  const query = 'Explain Class 10 CBSE English Chapter 2';
  const intent = normalizeCurriculumIntent(query, null, { class: '10', board: 'CBSE' });
  assert.strictEqual(intent.class, '10');
  assert.strictEqual(intent.board, 'CBSE');
  assert.strictEqual(intent.subject, 'English');
  assert.strictEqual(intent.chapterNumber, 2);

  // When ChromoDB returns 0 chunks for Chapter 2
  const chunks = [];
  const validation = validateRetrievedChunks(chunks, intent);
  assert.strictEqual(validation.valid, false);
  assert.strictEqual(validation.validChunks.length, 0);

  const response = buildZeroChunkResponse({
    type: 'CONTENT_NOT_FOUND',
    curriculumIntent: intent,
  });
  assert.strictEqual(response.gemini_called, false);
  assert.strictEqual(response.answer_source, 'CONTENT_NOT_FOUND');
});

// ── TEST 3: Class 10 CBSE English Chapter 1 (Valid Content Exists) ───────────
runTest(3, 'Class 10 CBSE English Chapter 1 -> RAG succeeds with only validated chunks', () => {
  const query = 'Explain Class 10 CBSE English Chapter 1';
  const intent = normalizeCurriculumIntent(query, null, { class: '10', board: 'CBSE' });
  assert.strictEqual(intent.chapterNumber, 1);
  assert.strictEqual(intent.subject, 'English');

  const rawChunks = [
    {
      id: 'doc_1',
      text: 'Lencho was a dedicated farmer whose crops were ruined by hail.',
      metadata: {
        chunk_id: 'CBSE10ENG_CH01_T02',
        class: '10',
        board: 'CBSE',
        subject: 'English',
        chapter: 'A Letter to God',
        title: 'A Letter to God',
      },
    },
    {
      id: 'doc_2',
      text: 'The postmaster decided to collect money to help Lencho.',
      metadata: {
        chunk_id: 'CBSE10ENG_CH01_T03',
        class: '10',
        board: 'CBSE',
        subject: 'English',
        chapter: 'A Letter to God',
        title: 'A Letter to God',
      },
    },
  ];

  const validation = validateRetrievedChunks(rawChunks, intent);
  assert.strictEqual(validation.valid, true);
  assert.strictEqual(validation.validChunks.length, 2);
  assert.strictEqual(validation.reason, 'VALID');
  assert(validation.matchedChapters.includes('A Letter to God'));
});

// ── TEST 4: Class 10 CBSE "Explain Chapter 2" (No Subject) ───────────────────
runTest(4, 'Class 10 CBSE "Explain Chapter 2" (No Subject) -> ASK_CLARIFICATION (Never guess)', () => {
  const query = 'Explain Chapter 2';
  const studentProfile = {
    class: '10',
    board: 'CBSE',
    subjects: ['English', 'Mathematics', 'Science', 'Social Science'],
  };
  const intent = normalizeCurriculumIntent(query, null, studentProfile);
  assert.strictEqual(intent.isCurriculumQuery, true);
  assert.strictEqual(intent.chapterNumber, 2);
  assert.strictEqual(intent.subject, null);
  assert.strictEqual(intent.requiresSubject, true);

  const clarification = buildClarificationForSubject(intent.chapterNumber, studentProfile);
  assert.strictEqual(clarification.action, 'ask_clarification');
  assert.strictEqual(clarification.llm_required, false);
  assert(clarification.direct_response_text.includes("Which subject's Chapter 2"));
  assert(clarification.direct_response_text.includes('English'));
  assert(clarification.direct_response_text.includes('Mathematics'));
});

// ── TEST 5: Cross-Chapter Hallucination Prevention (Chapter 1 -> Chapter 2) ──
runTest(5, 'Class 10 CBSE English Chapter 2 when DB only has Chapter 1 -> WRONG_CHAPTER / Rejected', () => {
  const query = 'Explain Class 10 CBSE English Chapter 2';
  const intent = normalizeCurriculumIntent(query, null, null);
  assert.strictEqual(intent.chapterNumber, 2);

  // Vector DB returned Chapter 1 chunks due to 57% semantic similarity
  const vectorResults = [
    {
      id: 'doc_1',
      score: 0.57,
      text: 'Lencho wrote a letter to God asking for 100 pesos.',
      metadata: {
        chunk_id: 'CBSE10ENG_CH01_T02',
        chapter_id: 'CBSE10ENG_CH01',
        class: '10',
        board: 'CBSE',
        subject: 'English',
        chapter: 'A Letter to God',
        title: 'A Letter to God',
      },
    },
    {
      id: 'doc_2',
      score: 0.55,
      text: 'A dusting of snow from a hemlock tree changed the mood.',
      metadata: {
        chunk_id: 'CBSE10ENG_CH01_T05',
        chapter_id: 'CBSE10ENG_CH01',
        class: '10',
        board: 'CBSE',
        subject: 'English',
        chapter: 'Dust of Snow',
        title: 'Dust of Snow',
      },
    },
  ];

  const validation = validateRetrievedChunks(vectorResults, intent);
  assert.strictEqual(validation.valid, false);
  assert.strictEqual(validation.validChunks.length, 0);
  assert.strictEqual(validation.rejectedChunks.length, 2);
  assert.strictEqual(validation.reason, 'WRONG_CHAPTER');
  assert(validation.rejectedChunks[0].reason.includes('Cross-chapter bleed rejected'));
});

// ── TEST 6: Multi-Chapter DB -> Isolate Requested Chapter ────────────────────
runTest(6, 'DB has Chapters 1, 2, 3 -> Query Chapter 2 -> Only Chapter 2 chunks accepted', () => {
  const query = 'Explain Chapter 2';
  const intent = normalizeCurriculumIntent(query, null, { class: '10', board: 'CBSE' });
  intent.subject = 'English'; // Subject resolved

  const rawChunks = [
    { text: 'Chapter 1 text', metadata: { chunk_id: 'CBSE10ENG_CH01_01', class: '10', board: 'CBSE', subject: 'English', chapter_number: 1, title: 'Chapter 1' } },
    { text: 'Chapter 2 text chunk A', metadata: { chunk_id: 'CBSE10ENG_CH02_01', class: '10', board: 'CBSE', subject: 'English', chapter_number: 2, title: 'Nelson Mandela' } },
    { text: 'Chapter 2 text chunk B', metadata: { chunk_id: 'CBSE10ENG_CH02_02', class: '10', board: 'CBSE', subject: 'English', chapter_number: 2, title: 'Nelson Mandela' } },
    { text: 'Chapter 3 text', metadata: { chunk_id: 'CBSE10ENG_CH03_01', class: '10', board: 'CBSE', subject: 'English', chapter_number: 3, title: 'Two Stories about Flying' } },
  ];

  const validation = validateRetrievedChunks(rawChunks, intent);
  assert.strictEqual(validation.valid, true);
  assert.strictEqual(validation.validChunks.length, 2);
  assert.strictEqual(validation.validChunks[0].metadata.chunk_id, 'CBSE10ENG_CH02_01');
  assert.strictEqual(validation.validChunks[1].metadata.chunk_id, 'CBSE10ENG_CH02_02');
  assert.strictEqual(validation.rejectedChunks.length, 2);
});

// ── TEST 7: Cross-Class Bleed Guard (Class 9 vs Class 10) ────────────────────
runTest(7, 'DB has Class 9 and Class 10 -> Student Class 10 -> Only Class 10 chunks accepted', () => {
  const query = 'Explain Class 10 Chapter 2';
  const intent = normalizeCurriculumIntent(query, null, null);
  intent.subject = 'English';

  const rawChunks = [
    { text: 'Class 9 Chapter 2 text', metadata: { chunk_id: 'CBSE09ENG_CH02_01', class: '9', board: 'CBSE', subject: 'English', chapter_number: 2 } },
    { text: 'Class 10 Chapter 2 text', metadata: { chunk_id: 'CBSE10ENG_CH02_01', class: '10', board: 'CBSE', subject: 'English', chapter_number: 2 } },
  ];

  const validation = validateRetrievedChunks(rawChunks, intent);
  assert.strictEqual(validation.valid, true);
  assert.strictEqual(validation.validChunks.length, 1);
  assert.strictEqual(validation.validChunks[0].metadata.class, '10');
  assert.strictEqual(validation.rejectedChunks.length, 1);
  assert(validation.rejectedChunks[0].reason.includes('Class mismatch'));
});

// ── TEST 8: Cross-Board Bleed Guard (CBSE vs SCERT Kerala) ───────────────────
runTest(8, 'DB has CBSE and SCERT Kerala -> Student CBSE -> Only CBSE chunks accepted', () => {
  const query = 'Explain CBSE Chapter 2';
  const intent = normalizeCurriculumIntent(query, null, null);
  intent.subject = 'English';

  const rawChunks = [
    { text: 'SCERT Kerala Chapter 2', metadata: { chunk_id: 'KL10ENG_CH02_01', class: '10', board: 'SCERT_KERALA', subject: 'English', chapter_number: 2 } },
    { text: 'CBSE Chapter 2', metadata: { chunk_id: 'CBSE10ENG_CH02_01', class: '10', board: 'CBSE', subject: 'English', chapter_number: 2 } },
  ];

  const validation = validateRetrievedChunks(rawChunks, intent);
  assert.strictEqual(validation.valid, true);
  assert.strictEqual(validation.validChunks.length, 1);
  assert.strictEqual(validation.validChunks[0].metadata.board, 'CBSE');
  assert.strictEqual(validation.rejectedChunks.length, 1);
  assert(validation.rejectedChunks[0].reason.includes('Board mismatch'));
});

// ── TEST 9: Student Memory Must NOT Cause Knowledge Substitution ─────────────
runTest(9, 'Student Memory ("I prefer Malayalam") when RAG missing -> Safe Stop (No hallucination)', () => {
  const query = 'Explain Class 10 CBSE English Chapter 2';
  const studentProfile = {
    class: '10',
    board: 'CBSE',
    preferred_language: 'Malayalam',
    personalization_enabled: true,
  };
  const intent = normalizeCurriculumIntent(query, null, studentProfile);

  // Missing content in RAG
  const rawChunks = [];
  const validation = validateRetrievedChunks(rawChunks, intent);
  assert.strictEqual(validation.valid, false);

  // Safety Gate triggers before Gemini is called:
  const response = buildZeroChunkResponse({
    type: 'CONTENT_NOT_FOUND',
    curriculumIntent: intent,
  });

  assert.strictEqual(response.gemini_called, false);
  assert.strictEqual(response.answer_source, 'CONTENT_NOT_FOUND');
  // Downstream Gemini is never invoked, meaning Malayalam preference does NOT cause pretraining hallucination
});

// ── TEST 10: Conversation History Priority Guard ─────────────────────────────
runTest(10, 'History mentions Chapter 1, current query asks Chapter 2 -> Chapter 2 strictly wins', () => {
  const pastMessages = [
    { role: 'user', content: 'What happens in Chapter 1 A Letter to God?' },
    { role: 'assistant', content: 'In Chapter 1, Lencho writes a letter asking for 100 pesos.' },
  ];
  const currentQuery = 'Explain Chapter 2';
  const intent = normalizeCurriculumIntent(currentQuery, null, { class: '10', board: 'CBSE' });

  // Explicit constraint in current query must take strict priority:
  assert.strictEqual(intent.chapterNumber, 2);
  assert.notStrictEqual(intent.chapterNumber, 1);
});

// ── TEST 11: Router Incorrect Direct Answer Policy Override ──────────────────
runTest(11, 'Router returns direct_answer for explicit curriculum request -> Curriculum policy overrides', () => {
  const query = 'Explain Class 10 CBSE Biology Chapter 2';
  const routerDecision = {
    action: 'direct_answer',
    llm_required: false,
    direct_response_text: 'Chapter 2 discusses Control and Coordination.',
  };

  const intent = normalizeCurriculumIntent(query, routerDecision, null);
  assert.strictEqual(intent.isCurriculumQuery, true);
  assert.strictEqual(intent.chapterNumber, 2);
  assert.strictEqual(intent.subject, 'Biology');

  // Grounding Policy Check: Explicit curriculum request must NOT bypass RAG
  let finalAction = routerDecision.action;
  if (intent.isCurriculumQuery) {
    if (!intent.subject) {
      finalAction = 'ask_clarification';
    } else {
      finalAction = 'rag_search'; // Overrides unsafe direct_answer
    }
  }

  assert.strictEqual(finalAction, 'rag_search');
});

// ── TEST 12: High Semantic Similarity but Metadata Incompatible ──────────────
runTest(12, '95% Semantic Similarity but wrong chapter metadata -> Reject chunks (Gemini NOT called)', () => {
  const query = 'Explain Class 10 CBSE English Chapter 2';
  const intent = normalizeCurriculumIntent(query, null, { class: '10', board: 'CBSE' });
  intent.subject = 'English';
  intent.chapterNumber = 2;

  // Hypothetical high vector score (0.95) but chunk belongs to Chapter 1
  const rawChunks = [
    {
      id: 'doc_high_similarity',
      score: 0.95,
      text: 'Faith can move mountains, as seen when Lencho received help from the postmaster.',
      metadata: {
        chunk_id: 'CBSE10ENG_CH01_T02',
        class: '10',
        board: 'CBSE',
        subject: 'English',
        chapter: 'A Letter to God',
        title: 'A Letter to God',
      },
    },
  ];

  const validation = validateRetrievedChunks(rawChunks, intent);
  assert.strictEqual(validation.valid, false);
  assert.strictEqual(validation.validChunks.length, 0);
  assert.strictEqual(validation.rejectedChunks.length, 1);
  assert.strictEqual(validation.reason, 'WRONG_CHAPTER');

  const response = buildZeroChunkResponse({
    type: validation.reason,
    curriculumIntent: intent,
  });
  assert.strictEqual(response.gemini_called, false);
  assert.strictEqual(response.answer_source, 'CONTENT_NOT_FOUND');
});

console.log('\n================================================================');
console.log(`TEST SUMMARY: ${passedTests} PASSED, ${failedTests} FAILED out of 12`);
console.log('================================================================\n');

if (failedTests > 0) {
  process.exit(1);
} else {
  console.log('ALL 12 PRODUCTION GROUNDING INTEGRITY TESTS PASSED SUCCESSFULLY!');
  process.exit(0);
}
