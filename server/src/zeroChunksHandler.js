/**
 * Zero Chunks Handling Engine for Jeeni AI
 *
 * Implements the RAG Architecture Zero Chunks Handling specification:
 * - Differentiates why vector search returned 0 chunks (Syllabus missing vs Content missing vs Search Error)
 * - Returns direct predefined backend responses
 * - Skips the second LLM API call entirely to save tokens and eliminate latency
 */

// ── 1. PREDEFINED RESPONSES CONFIGURATION ──────────────────────
const PREDEFINED_RESPONSES = {
  SYLLABUS_NOT_AVAILABLE:
    "Sorry, this syllabus is not currently available in Jeeni.",
  CONTENT_NOT_FOUND:
    "Sorry, I couldn't find the requested chapter or topic in the available study material. Please check the class, subject or chapter name.",
  SEARCH_ERROR:
    "Sorry, something went wrong while searching. Please try again later.",
};

// ── 2. SYLLABUS METADATA INDEX ────────────────────────────────
// Represents curricula and syllabi supported or tracked in Jeeni
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

/**
 * Normalizes string for comparison
 */
function normalize(str) {
  return str ? String(str).trim().toUpperCase() : '';
}

/**
 * Extracts class number from strings like "Class 10", "Grade 10", "10th", or 10
 */
function extractClassNumber(val) {
  if (val === null || val === undefined) return '';
  const str = String(val).trim();
  const match = str.match(/\d+/);
  return match ? match[0] : str.toUpperCase();
}

/**
 * Checks if a requested syllabus (board, class, subject) is recognized and available in Jeeni
 *
 * @param {Object} meta Metadata from Router AI or query
 * @param {Object} customIndex Optional custom syllabus index
 * @returns {boolean} true if syllabus is supported/available, false otherwise
 */
function isSyllabusAvailable(meta = {}, customIndex = DEFAULT_SYLLABUS_INDEX) {
  const reqBoard = normalize(meta.board);
  const reqClass = extractClassNumber(meta.class || meta.grade);
  const reqSubject = normalize(meta.subject);

  // If no curriculum constraints were specified by user/router, cannot rule out syllabus
  if (!reqBoard && !reqClass && !reqSubject) {
    return true;
  }

  // 1. If a board is explicitly specified, verify against recognized boards
  if (reqBoard) {
    const cleanBoard = reqBoard.replace(/_/g, ' ');
    const boardMatched = customIndex.boards.some(b => {
      const cleanB = b.replace(/_/g, ' ');
      return cleanBoard.includes(cleanB) || cleanB.includes(cleanBoard);
    });
    if (!boardMatched) {
      return false;
    }
  }

  // 2. If a class is explicitly specified, verify against recognized classes
  if (reqClass) {
    if (!customIndex.classes.includes(reqClass)) {
      return false;
    }
  }

  // 3. If a subject is explicitly specified, verify against recognized subjects
  if (reqSubject) {
    const subjectMatched = customIndex.subjects.some(s =>
      reqSubject.includes(s) || s.includes(reqSubject)
    );
    if (!subjectMatched) {
      return false;
    }
  }

  return true;
}

/**
 * Determines the exact reason for zero chunks
 *
 * Classification Flow (from Architecture Specification):
 * 1. Was there a search / system error (DB error, timeout, network failure)?
 *    -> SEARCH_ERROR
 * 2. Does the requested syllabus exist in Jeeni's syllabus metadata index?
 *    -> If NO -> SYLLABUS_NOT_AVAILABLE
 * 3. If syllabus exists, but chapter/topic/content is not indexed or returned no match:
 *    -> CONTENT_NOT_FOUND
 *
 * @param {Object} options
 * @param {Object} options.metadata Router AI metadata (board, class, subject, chapter, topic)
 * @param {Error|string|null} options.searchError Any DB or network error captured during search
 * @param {Object} [options.syllabusIndex] Optional syllabus index override
 * @returns {'SYLLABUS_NOT_AVAILABLE' | 'CONTENT_NOT_FOUND' | 'SEARCH_ERROR'}
 */
function determineZeroChunkReason({
  metadata = {},
  searchError = null,
  syllabusIndex = DEFAULT_SYLLABUS_INDEX
} = {}) {
  // 1. Check for system / search error
  if (searchError) {
    return 'SEARCH_ERROR';
  }

  // 2. Check if syllabus exists in the syllabus metadata index
  const syllabusExists = isSyllabusAvailable(metadata, syllabusIndex);
  if (!syllabusExists) {
    return 'SYLLABUS_NOT_AVAILABLE';
  }

  // 3. Syllabus exists, but specific chapter/content has no indexed chunks
  return 'CONTENT_NOT_FOUND';
}

/**
 * Retrieves the predefined response message for a given reason
 *
 * @param {'SYLLABUS_NOT_AVAILABLE' | 'CONTENT_NOT_FOUND' | 'SEARCH_ERROR'} type
 * @param {Object} [customMessages]
 * @returns {string}
 */
function getPredefinedMessage(type, customMessages = {}) {
  const messages = { ...PREDEFINED_RESPONSES, ...customMessages };
  return messages[type] || PREDEFINED_RESPONSES.CONTENT_NOT_FOUND;
}

/**
 * Builds the direct backend response object for zero chunks
 *
 * Conforms to both:
 * 1. Architecture specification: { success: true, type, answer }
 * 2. Flutter client compatibility: { content, sources: [], pipeline, routing }
 *
 * @param {Object} params
 * @param {'SYLLABUS_NOT_AVAILABLE' | 'CONTENT_NOT_FOUND' | 'SEARCH_ERROR'} params.type
 * @param {Object} [params.routingDecision]
 * @param {Object} [params.customMessages]
 * @returns {Object}
 */
function buildZeroChunkResponse({
  type,
  routingDecision = null,
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
    chunks_count: 0,
    tokens_saved: true,
  };
}

module.exports = {
  PREDEFINED_RESPONSES,
  DEFAULT_SYLLABUS_INDEX,
  isSyllabusAvailable,
  determineZeroChunkReason,
  getPredefinedMessage,
  buildZeroChunkResponse,
};
