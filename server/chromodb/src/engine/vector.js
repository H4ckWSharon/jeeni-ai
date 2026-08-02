/**
 * ChromoDB — Vector Search Engine
 * Pure JavaScript cosine similarity — no native deps needed.
 * Fast for up to ~50k documents. HNSW can be added later.
 */

/**
 * Cosine similarity between two arrays.
 * Returns a value in [-1, 1]; higher = more similar.
 */
function cosineSimilarity(a, b) {
  let dot = 0, magA = 0, magB = 0;
  for (let i = 0; i < a.length; i++) {
    dot  += a[i] * b[i];
    magA += a[i] * a[i];
    magB += b[i] * b[i];
  }
  const denom = Math.sqrt(magA) * Math.sqrt(magB);
  return denom === 0 ? 0 : dot / denom;
}

/**
 * Search documents by vector similarity.
 *
 * @param {number[]}  queryVector  - Embedding of the search query
 * @param {object[]}  documents    - Array of {id, text, metadata, vector, ...}
 * @param {number}    topK         - How many results to return
 * @param {number}    threshold    - Minimum similarity score (0–1)
 * @returns {object[]} Sorted results with .score added
 */
function searchVectors(queryVector, documents, topK = 5, threshold = 0.0) {
  return documents
    .map(doc => ({
      ...doc,
      score: cosineSimilarity(queryVector, doc.vector),
    }))
    .filter(doc => doc.score >= threshold)
    .sort((a, b) => b.score - a.score)
    .slice(0, topK);
}

module.exports = { cosineSimilarity, searchVectors };
