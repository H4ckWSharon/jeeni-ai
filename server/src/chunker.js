/**
 * Jeeni AI — Text & PDF Chunking Utility
 *
 * Chunks large text documents into overlapping semantic blocks
 * suitable for vector embedding and RAG retrieval.
 */

const pdfParse = require('pdf-parse');

/**
 * Extract clean text from a PDF buffer
 * @param {Buffer} pdfBuffer
 * @returns {Promise<{ text: string, numpages: number, info: object }>}
 */
async function extractTextFromPDF(pdfBuffer) {
  try {
    const data = await pdfParse(pdfBuffer);
    return {
      text: data.text,
      numpages: data.numpages,
      info: data.info || {},
    };
  } catch (err) {
    throw new Error(`Failed to parse PDF: ${err.message}`);
  }
}

/**
 * Split a long text into overlapping chunks
 *
 * @param {string} text - Raw text to chunk
 * @param {object} options
 * @param {number} options.chunkSize - Target words per chunk (default 300)
 * @param {number} options.overlap - Words overlap between consecutive chunks (default 50)
 * @param {object} options.metadata - Base metadata to attach to each chunk
 * @returns {Array<{ text: string, metadata: object }>}
 */
function chunkText(text, options = {}) {
  const {
    chunkSize = 300,
    overlap = 50,
    metadata = {}
  } = options;

  if (!text || typeof text !== 'string') return [];

  // Clean text: normalize newlines and multiple spaces
  const clean = text
    .replace(/\r\n/g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .replace(/[ \t]+/g, ' ')
    .trim();

  // Split into paragraphs first, then words
  const words = clean.split(/\s+/);
  if (words.length === 0) return [];

  const chunks = [];
  let startIndex = 0;
  let chunkIndex = 0;

  while (startIndex < words.length) {
    const endIndex = Math.min(startIndex + chunkSize, words.length);
    const chunkWords = words.slice(startIndex, endIndex);
    const chunkTextStr = chunkWords.join(' ');

    chunks.push({
      text: chunkTextStr,
      metadata: {
        ...metadata,
        chunk_index: chunkIndex,
        word_count: chunkWords.length,
        start_word: startIndex,
        end_word: endIndex,
      },
    });

    chunkIndex++;
    // Move start pointer forward by (chunkSize - overlap)
    startIndex += (chunkSize - overlap);

    // Prevent infinite loop if overlap >= chunkSize
    if (chunkSize <= overlap) break;
  }

  // Update total chunks in metadata
  chunks.forEach(c => {
    c.metadata.total_chunks = chunks.length;
  });

  return chunks;
}

module.exports = {
  extractTextFromPDF,
  chunkText,
};
