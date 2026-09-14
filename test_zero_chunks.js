/**
 * Automated Verification Script for Zero Chunks Handling
 */
const {
  determineZeroChunkReason,
  buildZeroChunkResponse,
  isSyllabusAvailable,
  PREDEFINED_RESPONSES
} = require('./server/src/zeroChunksHandler');

function assert(condition, message) {
  if (!condition) {
    console.error(`❌ FAILED: ${message}`);
    process.exit(1);
  }
  console.log(`✅ PASSED: ${message}`);
}

console.log("=================================================");
console.log("TESTING ZERO CHUNKS HANDLING UNIT LOGIC");
console.log("=================================================\n");

// 1. Syllabus Availability Checks
console.log("--- 1. Testing Syllabus Availability ---");
assert(
  isSyllabusAvailable({ board: 'CBSE', class: '10', subject: 'Physics' }) === true,
  "CBSE Class 10 Physics should be recognized in syllabus index"
);
assert(
  isSyllabusAvailable({ board: 'CBSE', class: '10', subject: 'English' }) === true,
  "CBSE Class 10 English should be recognized in syllabus index"
);
assert(
  isSyllabusAvailable({ board: 'CAMBRIDGE', class: '5', subject: 'French' }) === false,
  "CAMBRIDGE Class 5 French should NOT be in syllabus index"
);
assert(
  isSyllabusAvailable({ board: 'CBSE', class: '2', subject: 'Physics' }) === false,
  "CBSE Class 2 Physics should NOT be recognized"
);
assert(
  isSyllabusAvailable({ board: 'CBSE', class: '10', subject: 'Robotics Engineering' }) === false,
  "Unsupported subject should NOT be in syllabus index"
);

// 2. Determine Zero Chunks Reason
console.log("\n--- 2. Testing Reason Classification ---");

// Case A: Missing Chapter in known syllabus (CBSE Class 10 Physics Chapter 8 - from image)
const reasonContent = determineZeroChunkReason({
  metadata: {
    board: 'CBSE',
    class: '10',
    subject: 'Physics',
    chapter: '8',
    topic: 'Light'
  }
});
assert(reasonContent === 'CONTENT_NOT_FOUND', "Should classify as CONTENT_NOT_FOUND when syllabus exists but chapter is missing");

// Case B: Syllabus Not Available
const reasonSyllabus = determineZeroChunkReason({
  metadata: {
    board: 'CAMBRIDGE_IGCSE',
    class: '8',
    subject: 'History'
  }
});
assert(reasonSyllabus === 'SYLLABUS_NOT_AVAILABLE', "Should classify as SYLLABUS_NOT_AVAILABLE for unknown syllabus");

// Case C: Search / DB Error
const reasonError = determineZeroChunkReason({
  metadata: { board: 'CBSE', class: '10', subject: 'Physics' },
  searchError: new Error("ChromoDB connection timeout")
});
assert(reasonError === 'SEARCH_ERROR', "Should classify as SEARCH_ERROR when DB error or timeout occurred");

// 3. Testing Direct Backend Responses
console.log("\n--- 3. Testing Predefined Direct Responses ---");

const resContent = buildZeroChunkResponse({
  type: 'CONTENT_NOT_FOUND',
  routingDecision: { action: 'rag_search' }
});
assert(resContent.success === true, "Response success should be true");
assert(resContent.type === 'CONTENT_NOT_FOUND', "Response type should be CONTENT_NOT_FOUND");
assert(resContent.answer === PREDEFINED_RESPONSES.CONTENT_NOT_FOUND, "Response answer matches predefined message");
assert(resContent.content === PREDEFINED_RESPONSES.CONTENT_NOT_FOUND, "Response content matches for Flutter compatibility");
assert(resContent.pipeline === 'ZERO_CHUNKS_CONTENT_NOT_FOUND', "Pipeline label is ZERO_CHUNKS_CONTENT_NOT_FOUND");
assert(resContent.tokens_saved === true, "Tokens saved flag is true");
assert(Array.isArray(resContent.sources) && resContent.sources.length === 0, "Sources should be empty array");

const resSyllabus = buildZeroChunkResponse({
  type: 'SYLLABUS_NOT_AVAILABLE',
  routingDecision: { action: 'rag_search' }
});
assert(resSyllabus.type === 'SYLLABUS_NOT_AVAILABLE', "Response type should be SYLLABUS_NOT_AVAILABLE");
assert(resSyllabus.answer === PREDEFINED_RESPONSES.SYLLABUS_NOT_AVAILABLE, "Response answer matches predefined message");

const resError = buildZeroChunkResponse({
  type: 'SEARCH_ERROR',
  routingDecision: { action: 'rag_search' }
});
assert(resError.type === 'SEARCH_ERROR', "Response type should be SEARCH_ERROR");
assert(resError.answer === PREDEFINED_RESPONSES.SEARCH_ERROR, "Response answer matches predefined message");

console.log("\n=================================================");
console.log("ALL UNIT TESTS PASSED SUCCESSFULLY! 🎉");
console.log("=================================================");
