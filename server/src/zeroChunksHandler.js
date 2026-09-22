/**
 * Zero Chunks & Retrieval Validation Engine for Jeeni AI
 *
 * Implements Production-Grade RAG Grounding & Zero Chunks Architecture:
 * - Deterministic Curriculum Intent Normalization (class, board, subject, chapter, topic)
 * - Deterministic Post-Retrieval Validation (Class, Board, Subject, and Chapter alignment)
 * - Cross-Chapter Bleed & Semantic Drift Protection
 * - Differentiates why vector search returned 0 or invalid chunks (Syllabus missing vs Content missing vs Wrong Chapter vs Search Error)
 * - Strict Hard Grounding Boundary (Zero downstream LLM tokens on invalid retrieval)
 */

// ── 1. PREDEFINED RESPONSES CONFIGURATION ──────────────────────
const PREDEFINED_RESPONSES = {
  SYLLABUS_NOT_AVAILABLE:
    "Sorry, this syllabus is not currently available in Jeeni.",
  CONTENT_NOT_FOUND:
    "Sorry, I couldn't find the requested chapter or topic in the available study material. Please check the class, subject or chapter name.",
  WRONG_CHAPTER:
    "Sorry, I couldn't find the requested chapter in the available study material. Please check the chapter name or number.",
  WRONG_CLASS:
    "Sorry, I couldn't find the requested content for your class in the available study material.",
  WRONG_BOARD:
    "Sorry, I couldn't find the requested content for your educational board in the available study material.",
  WRONG_SUBJECT:
    "Sorry, I couldn't find the requested content for that subject in the available study material.",
  SEARCH_ERROR:
    "Sorry, something went wrong while searching. Please try again later.",
};

// ── 2. SYLLABUS METADATA INDEX ────────────────────────────────
const DEFAULT_SYLLABUS_INDEX = {
  boards: ['CBSE', 'NCERT', 'KERALA STATE BOARD', 'SCERT', 'SCERT_KERALA', 'STATE BOARD'],
  classes: ['6', '7', '8', '9', '10', '11', '12'],
  subjects: [
    'ENGLISH',
    'PHYSICS',
    'CHEMISTRY',
    'BIOLOGY',
    'MATHEMATICS',
    'MATHS',
    'SCIENCE',
    'SOCIAL SCIENCE',
    'HISTORY',
    'GEOGRAPHY',
    'ECONOMICS',
    'POLITICAL SCIENCE',
    'COMPUTER SCIENCE',
    'MALAYALAM'
  ],
};

const NUMBER_WORDS = {
  'one': 1, 'first': 1, '1st': 1,
  'two': 2, 'second': 2, '2nd': 2,
  'three': 3, 'third': 3, '3rd': 3,
  'four': 4, 'fourth': 4, '4th': 4,
  'five': 5, 'fifth': 5, '5th': 5,
  'six': 6, 'sixth': 6, '6th': 6,
  'seven': 7, 'seventh': 7, '7th': 7,
  'eight': 8, 'eighth': 8, '8th': 8,
  'nine': 9, 'ninth': 9, '9th': 9,
  'ten': 10, 'tenth': 10, '10th': 10,
  'eleven': 11, 'twelfth': 12, '12th': 12,
};

function normalize(str) {
  return str ? String(str).trim().toUpperCase() : '';
}

function extractClassNumber(val) {
  if (val === null || val === undefined || val === '') return null;
  const str = String(val).trim();
  const match = str.match(/\d+/);
  return match ? match[0] : (str ? str.toUpperCase() : null);
}

function normalizeClass(val) {
  if (val === null || val === undefined || val === '') return null;
  const match = String(val).match(/\d+/);
  return match ? match[0] : null;
}

function normalizeBoard(val) {
  if (!val) return null;
  const v = String(val).trim().toUpperCase().replace(/\s+/g, ' ');
  if (v.includes('KERALA') || v.includes('SCERT') || v.includes('STATE BOARD')) return 'SCERT_KERALA';
  if (v === 'CBSE' || v.includes('CENTRAL BOARD')) return 'CBSE';
  if (v === 'NCERT') return 'NCERT';
  if (v === 'ICSE') return 'ICSE';
  return v;
}

function normalizeSubject(val) {
  if (!val) return null;
  const s = String(val).trim();
  if (/^math(s|ematics)?$/i.test(s)) return 'Mathematics';
  return s.replace(/\w\S*/g, txt => txt.charAt(0).toUpperCase() + txt.slice(1).toLowerCase());
}

/**
 * Checks if a requested syllabus (board, class, subject) is recognized and available in Jeeni
 */
function isSyllabusAvailable(meta = {}, customIndex = DEFAULT_SYLLABUS_INDEX) {
  const reqBoard = normalize(meta.board);
  const reqClass = extractClassNumber(meta.class || meta.grade);
  const reqSubject = normalize(meta.subject);

  if (!reqBoard && !reqClass && !reqSubject) {
    return true;
  }

  if (reqBoard) {
    const cleanBoard = reqBoard.replace(/_/g, ' ');
    const boardMatched = customIndex.boards.some(b => {
      const cleanB = b.replace(/_/g, ' ');
      return cleanBoard.includes(cleanB) || cleanB.includes(cleanBoard);
    });
    if (!boardMatched) return false;
  }

  if (reqClass) {
    if (!customIndex.classes.includes(reqClass)) return false;
  }

  if (reqSubject) {
    const subjectMatched = customIndex.subjects.some(s =>
      reqSubject.includes(s) || s.includes(reqSubject)
    );
    if (!subjectMatched) return false;
  }

  return true;
}

/**
 * ── 3. STRUCTURED CURRICULUM INTENT NORMALIZER ──────────────────
 *
 * Produces a unified normalized intent object from query, Router AI, and student profile.
 */
function normalizeCurriculumIntent(query = '', routingDecision = null, studentProfile = null) {
  const q = String(query || '').trim();
  const lower = q.toLowerCase();
  const meta = routingDecision?.metadata || routingDecision?.rag_metadata || {};

  // Chapter number extraction
  let chapterNumber = null;
  if (meta.chapter_number !== undefined && meta.chapter_number !== null) {
    const num = parseInt(meta.chapter_number, 10);
    if (!isNaN(num)) chapterNumber = num;
  }

  if (chapterNumber === null) {
    // Regex matching: "chapter 2", "ch 2", "ch. 2", "lesson 2", "unit 2"
    const digitMatch = lower.match(/\b(?:chapter|ch|lesson|unit)\.?\s*(\d{1,2})\b/i);
    if (digitMatch) {
      chapterNumber = parseInt(digitMatch[1], 10);
    } else {
      // Word matching: "chapter two", "second chapter", "ch two"
      for (const [word, val] of Object.entries(NUMBER_WORDS)) {
        const wordRegex = new RegExp(`\\b(?:chapter|ch|lesson|unit)\\s+${word}\\b|\\b${word}\\s+(?:chapter|ch|lesson|unit)\\b`, 'i');
        if (wordRegex.test(lower)) {
          chapterNumber = val;
          break;
        }
      }
    }
  }

  // Class extraction
  let reqClass = null;
  const classMatch = q.match(/\b(?:class|grade|standard|std)\s*(\d{1,2})\b/i) ||
                     q.match(/\b(\d{1,2})(?:st|nd|rd|th)\s*(?:class|grade|standard|std)?\b/i);
  if (classMatch) {
    reqClass = classMatch[1];
  } else if (meta.class) {
    reqClass = extractClassNumber(meta.class);
  } else if (studentProfile?.class) {
    reqClass = extractClassNumber(studentProfile.class);
  }

  // Board extraction
  let reqBoard = null;
  const upper = q.toUpperCase();
  if (upper.includes('CBSE')) reqBoard = 'CBSE';
  else if (upper.includes('NCERT')) reqBoard = 'NCERT';
  else if (upper.includes('ICSE')) reqBoard = 'ICSE';
  else if (upper.includes('KERALA') || upper.includes('SCERT') || upper.includes('STATE BOARD')) reqBoard = 'SCERT_KERALA';
  else if (meta.board) reqBoard = normalizeBoard(meta.board);
  else if (studentProfile?.board) reqBoard = normalizeBoard(studentProfile.board);

  // Subject extraction
  let reqSubject = null;
  const subjects = ['ENGLISH', 'PHYSICS', 'CHEMISTRY', 'BIOLOGY', 'MATHEMATICS', 'MATHS', 'SCIENCE', 'SOCIAL SCIENCE', 'HISTORY', 'GEOGRAPHY', 'ECONOMICS', 'POLITICAL SCIENCE', 'COMPUTER SCIENCE', 'MALAYALAM'];
  for (const s of subjects) {
    const regex = new RegExp(`\\b${s}\\b`, 'i');
    if (regex.test(q)) {
      reqSubject = normalizeSubject(s);
      break;
    }
  }
  if (!reqSubject && meta.subject) {
    reqSubject = normalizeSubject(meta.subject);
  }

  // Determine if this is a curriculum query
  const hasExplicitCurriculumKeywords = /\b(chapter|ch\.|lesson|unit|exercise|textbook|syllabus|scert|cbse|ncert|question paper|pyq|hots)\b/i.test(q);
  const routerIsCurriculum = routingDecision?.action === 'rag_search' ||
    (routingDecision?.action === 'ask_clarification' && hasExplicitCurriculumKeywords);
  const isCurriculumQuery = hasExplicitCurriculumKeywords || routerIsCurriculum || Boolean(chapterNumber);

  return {
    isCurriculumQuery: Boolean(isCurriculumQuery),
    class: reqClass,
    board: reqBoard,
    subject: reqSubject,
    chapterNumber: chapterNumber,
    chapterName: meta.chapter || null,
    topic: meta.topic || null,
    language: meta.language || 'English',
    source: (classMatch || reqSubject || hasExplicitCurriculumKeywords) ? 'query' : 'router + profile',
    requiresSubject: Boolean(isCurriculumQuery && !reqSubject),
  };
}

/**
 * ── 4. DETERMINISTIC RETRIEVAL VALIDATOR ────────────────────────
 *
 * Deterministically checks retrieved vector chunks against the requested curriculum intent.
 * Vector similarity score is evidence of semantic relevance, NOT proof of curriculum identity.
 * Validates Class, Board, Subject, and Chapter Number.
 */
function validateRetrievedChunks(chunks = [], curriculumIntent = {}) {
  if (!Array.isArray(chunks) || chunks.length === 0) {
    return {
      valid: false,
      validChunks: [],
      rejectedChunks: [],
      reason: 'CONTENT_NOT_FOUND',
      matchedChapters: [],
    };
  }

  const validChunks = [];
  const rejectedChunks = [];
  const matchedChapters = new Set();

  for (const chunk of chunks) {
    const meta = chunk.metadata || {};
    let isChunkValid = true;
    let rejectReason = '';

    // 1. Class Check
    if (curriculumIntent.class) {
      const chunkClass = extractClassNumber(meta.class);
      if (chunkClass && chunkClass !== curriculumIntent.class) {
        isChunkValid = false;
        rejectReason = `Class mismatch (expected: ${curriculumIntent.class}, got: ${chunkClass})`;
      }
    }

    // 2. Board Check
    if (isChunkValid && curriculumIntent.board) {
      const chunkBoard = normalizeBoard(meta.board);
      const reqBoard = normalizeBoard(curriculumIntent.board);
      if (chunkBoard && reqBoard && chunkBoard !== reqBoard) {
        isChunkValid = false;
        rejectReason = `Board mismatch (expected: ${reqBoard}, got: ${chunkBoard})`;
      }
    }

    // 3. Subject Check
    if (isChunkValid && curriculumIntent.subject) {
      const chunkSubject = normalizeSubject(meta.subject);
      const reqSubject = normalizeSubject(curriculumIntent.subject);
      if (chunkSubject && reqSubject && chunkSubject !== reqSubject) {
        // Allow 'Science' to match Physics/Chemistry/Biology if generalized
        const isScienceOverlap = (reqSubject === 'Science' && ['Physics', 'Chemistry', 'Biology'].includes(chunkSubject));
        const isMathOverlap = (['Maths', 'Mathematics'].includes(reqSubject) && ['Maths', 'Mathematics'].includes(chunkSubject));
        if (!isScienceOverlap && !isMathOverlap) {
          isChunkValid = false;
          rejectReason = `Subject mismatch (expected: ${reqSubject}, got: ${chunkSubject})`;
        }
      }
    }

    // 4. Chapter Number Check (Cross-Chapter Bleed Guard)
    if (isChunkValid && curriculumIntent.chapterNumber !== null && curriculumIntent.chapterNumber !== undefined) {
      const reqChapNum = curriculumIntent.chapterNumber;
      let chunkChapNum = null;

      if (meta.chapter_number !== undefined && meta.chapter_number !== null) {
        chunkChapNum = parseInt(meta.chapter_number, 10);
      }

      // Check chunk_id format e.g. "CBSE10ENG_CH01_T09" -> Chapter 1
      if (chunkChapNum === null && meta.chunk_id) {
        const chIdMatch = String(meta.chunk_id).match(/_CH(\d{1,2})_/i);
        if (chIdMatch) {
          chunkChapNum = parseInt(chIdMatch[1], 10);
        }
      }

      // Check chapter title or chunk title e.g. "Chapter 1", "Ch 1"
      if (chunkChapNum === null && (meta.chapter || meta.title)) {
        const textToSearch = `${meta.chapter || ''} ${meta.title || ''}`;
        const titleMatch = textToSearch.match(/\b(?:chapter|ch)\.?\s*(\d{1,2})\b/i);
        if (titleMatch) {
          chunkChapNum = parseInt(titleMatch[1], 10);
        }
      }

      // If chapter number is identifiable on the chunk and does NOT match requested chapter, REJECT
      if (chunkChapNum !== null && chunkChapNum !== reqChapNum) {
        isChunkValid = false;
        rejectReason = `Cross-chapter bleed rejected (requested Chapter ${reqChapNum}, chunk is Chapter ${chunkChapNum})`;
      }
    }

    if (isChunkValid) {
      validChunks.push(chunk);
      if (meta.chapter || meta.title) {
        matchedChapters.add(meta.chapter || meta.title);
      }
    } else {
      rejectedChunks.push({ chunk, reason: rejectReason });
    }
  }

  if (validChunks.length > 0) {
    return {
      valid: true,
      validChunks,
      rejectedChunks,
      reason: 'VALID',
      matchedChapters: Array.from(matchedChapters),
    };
  }

  // Determine specific rejection reason for telemetry
  let failureReason = 'CONTENT_NOT_FOUND';
  if (rejectedChunks.some(r => r.reason.includes('Cross-chapter bleed'))) {
    failureReason = 'WRONG_CHAPTER';
  } else if (rejectedChunks.some(r => r.reason.includes('Class mismatch'))) {
    failureReason = 'WRONG_CLASS';
  } else if (rejectedChunks.some(r => r.reason.includes('Board mismatch'))) {
    failureReason = 'WRONG_BOARD';
  } else if (rejectedChunks.some(r => r.reason.includes('Subject mismatch'))) {
    failureReason = 'WRONG_SUBJECT';
  }

  return {
    valid: false,
    validChunks: [],
    rejectedChunks,
    reason: failureReason,
    matchedChapters: Array.from(matchedChapters),
  };
}

/**
 * ── 5. SUBJECT CLARIFICATION BUILDER ────────────────────────────
 *
 * Builds a friendly targeted clarification asking the student which enrolled subject
 * they would like explained for the requested chapter, avoiding arbitrary guessing.
 */
function buildClarificationForSubject(chapterOrProfile, profileOrChapter = null) {
  let chapterNumber = null;
  let studentProfile = null;

  if (chapterOrProfile && typeof chapterOrProfile === 'object' && !Array.isArray(chapterOrProfile)) {
    studentProfile = chapterOrProfile;
    chapterNumber = profileOrChapter;
  } else {
    chapterNumber = chapterOrProfile;
    studentProfile = profileOrChapter;
  }

  const subjects = (studentProfile && Array.isArray(studentProfile.subjects) && studentProfile.subjects.length > 0)
    ? studentProfile.subjects
    : ['English', 'Mathematics', 'Science', 'Social Science'];

  const formattedSubjects = subjects.length <= 3
    ? subjects.join(', ')
    : `${subjects.slice(0, -1).join(', ')}, or ${subjects[subjects.length - 1]}`;

  const chapLabel = chapterNumber ? `Chapter ${chapterNumber}` : 'this chapter';
  const message = `Which subject's ${chapLabel} would you like me to explain — ${formattedSubjects}?`;

  return {
    action: 'ask_clarification',
    llm_required: false,
    direct_response_text: message,
    text: message,
    content: message,
    missing_parameter: 'subject',
    toString() { return message; },
    includes(str) { return message.includes(str); },
  };
}

/**
 * Determines the exact reason for zero chunks
 */
function determineZeroChunkReason({
  metadata = {},
  searchError = null,
  syllabusIndex = DEFAULT_SYLLABUS_INDEX
} = {}) {
  if (searchError) return 'SEARCH_ERROR';
  const syllabusExists = isSyllabusAvailable(metadata, syllabusIndex);
  if (!syllabusExists) return 'SYLLABUS_NOT_AVAILABLE';
  return 'CONTENT_NOT_FOUND';
}

function getPredefinedMessage(type, customMessages = {}) {
  const messages = { ...PREDEFINED_RESPONSES, ...customMessages };
  return messages[type] || PREDEFINED_RESPONSES.CONTENT_NOT_FOUND;
}

/**
 * Builds the direct backend response object for zero chunks or invalid retrieval
 */
function buildZeroChunkResponse({
  type,
  routingDecision = null,
  curriculumIntent = null,
  customMessages = {}
}) {
  const answer = getPredefinedMessage(type, customMessages);

  return {
    success: true,
    type,
    answer,
    content: answer, // Backward compatibility for Flutter client
    sources: [],
    pipeline: `ZERO_CHUNKS_${type}`,
    routing: routingDecision,
    curriculum_intent: curriculumIntent,
    chunks_count: 0,
    tokens_saved: true,
    gemini_called: false,
    answer_source: (type === 'SYLLABUS_NOT_AVAILABLE' ? 'ZERO_CHUNKS' : 'CONTENT_NOT_FOUND'),
  };
}

/**
 * Returns a fully normalized canonical metadata object.
 * Always uses 'class' (not 'grade'), normalized board, title-case subject.
 */
function normalizeChunkMetadata(raw = {}) {
  const meta = { ...raw };
  const rawClass = meta.class ?? meta.grade ?? meta.class_level ?? null;
  meta.class = extractClassNumber(rawClass);
  delete meta.grade;
  delete meta.class_level;
  if (meta.board) meta.board = normalizeBoard(meta.board);
  if (meta.subject) meta.subject = normalizeSubject(meta.subject);
  return meta;
}

/**
 * Extracts curriculum constraints (class, board, subject) directly from user query.
 */
function extractCurriculumFromQuery(query) {
  if (!query || typeof query !== 'string') return {};
  const extracted = {};

  const classMatch = query.match(/\b(?:class|grade|standard|std)\s*(\d{1,2})\b/i) ||
                     query.match(/\b(\d{1,2})(?:st|nd|rd|th)\s*(?:class|grade|standard|std)?\b/i);
  if (classMatch) {
    extracted.class = classMatch[1];
  }

  const upper = query.toUpperCase();
  if (upper.includes('CBSE')) extracted.board = 'CBSE';
  else if (upper.includes('NCERT')) extracted.board = 'NCERT';
  else if (upper.includes('ICSE')) extracted.board = 'ICSE';
  else if (upper.includes('KERALA') || upper.includes('SCERT') || upper.includes('STATE BOARD')) extracted.board = 'SCERT_KERALA';

  const subjects = ['ENGLISH', 'PHYSICS', 'CHEMISTRY', 'BIOLOGY', 'MATHEMATICS', 'MATHS', 'SCIENCE', 'SOCIAL SCIENCE', 'HISTORY', 'GEOGRAPHY', 'ECONOMICS', 'POLITICAL SCIENCE', 'COMPUTER SCIENCE', 'MALAYALAM'];
  for (const s of subjects) {
    const regex = new RegExp(`\\b${s}\\b`, 'i');
    if (regex.test(query)) {
      extracted.subject = normalizeSubject(s);
      break;
    }
  }

  return extracted;
}

module.exports = {
  PREDEFINED_RESPONSES,
  DEFAULT_SYLLABUS_INDEX,
  isSyllabusAvailable,
  determineZeroChunkReason,
  getPredefinedMessage,
  buildZeroChunkResponse,
  normalizeCurriculumIntent,
  validateRetrievedChunks,
  buildClarificationForSubject,
  normalizeBoard,
  normalizeSubject,
  normalizeClass: extractClassNumber,
  extractClassNumber,
  extractCurriculumFromQuery,
  normalizeChunkMetadata,
};
